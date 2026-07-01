#!/usr/bin/env python3
"""
sync-config.py — Generate tool-specific config from .ai/config/ sources.

Sources (edit these):
  .ai/config/permissions.yaml  → Claude permissions + Codex execution policy
  .ai/config/hooks.yaml        → Claude + Codex event hooks
  .ai/config/workflows.yaml    → cross-validated against subagents.yaml (P1)
  .ai/config/subagents.yaml    → validated + ROLE BINDING block projected into
                                 each .claude/agents/*.md (region-granular)

Outputs (DO NOT edit directly — regenerate with this script):
  .claude/settings.json
  .codex/config.toml
  .codex/rules/execution-policy.rules
  .codex/hooks.json
  .claude/agents/*.md — ONLY the <!-- BEGIN ROLE BINDING ... --> block is
  generated; the rest of each agent file (frontmatter, system prompt) stays
  hand-authored, so these files carry no whole-file GENERATED marker.
"""
import json, re, subprocess, sys
from pathlib import Path

# ── Bootstrap PyYAML if absent ────────────────────────────────────────────────
try:
    import yaml
except ImportError:
    print("[sync-config] PyYAML not found — installing...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyyaml", "-q"])
    import yaml

# ── Paths ─────────────────────────────────────────────────────────────────────
ROOT = Path(__file__).resolve().parent.parent
AI_CFG   = ROOT / ".ai" / "config"
CLAUDE   = ROOT / ".claude"
CODEX    = ROOT / ".codex"

PERMISSIONS_SRC = AI_CFG / "permissions.yaml"
HOOKS_SRC       = AI_CFG / "hooks.yaml"
WORKFLOWS_SRC   = AI_CFG / "workflows.yaml"
SUBAGENTS_SRC   = AI_CFG / "subagents.yaml"
AGENTS_DIR      = CLAUDE / "agents"

SETTINGS_OUT     = CLAUDE / "settings.json"
CONFIG_TOML_OUT  = CODEX  / "config.toml"
STARLARK_OUT     = CODEX  / "rules" / "execution-policy.rules"
CODEX_HOOKS_OUT  = CODEX  / "hooks.json"

GENERATED_MARKER = "GENERATED FROM .ai/config"

# ── Guard: refuse to overwrite a manually-edited generated file ───────────────
def _has_generated_marker(path: Path) -> bool:
    """Return True if the file contains the GENERATED marker (comment or JSON key)."""
    text = path.read_text(encoding="utf-8")
    return GENERATED_MARKER in text

def _safe_write(path: Path, content: str) -> None:
    if path.exists():
        if not _has_generated_marker(path):
            print(f"[sync-config] SKIP {path.relative_to(ROOT)} — no GENERATED marker (manual file?)")
            print(f"              Add a «{GENERATED_MARKER}» marker to allow overwrite.")
            return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print(f"[sync-config] WROTE {path.relative_to(ROOT)}")

# ── Load sources ──────────────────────────────────────────────────────────────
def load_yaml(path: Path) -> dict:
    if not path.exists():
        print(f"[sync-config] WARNING {path.relative_to(ROOT)} not found — skipping.")
        return {}
    with path.open(encoding="utf-8") as f:
        return yaml.safe_load(f) or {}

# ── Generator: .claude/settings.json ─────────────────────────────────────────
def gen_settings(perms: dict, hooks: dict) -> None:
    cp = perms.get("permissions", {})
    ch = hooks.get("claude", {})

    settings = {
        "$schema": "https://json.schemastore.org/claude-code-settings.json",
        "_generated": GENERATED_MARKER + " — DO NOT EDIT DIRECTLY",
        "permissions": {
            "deny":  cp.get("deny",  []),
            "ask":   cp.get("ask",   []),
            "allow": cp.get("allow", []),
        },
        "hooks": _build_hooks(ch, _CLAUDE_HOOK_FIELDS),
    }
    content = json.dumps(settings, indent=2, ensure_ascii=False) + "\n"
    _safe_write(SETTINGS_OUT, content)

# Optional per-command fields each tool understands. Unknown fields are dropped
# so a Claude-only key (`shell`, `if`) never leaks into Codex output and vice versa.
_CLAUDE_HOOK_FIELDS = ("if", "shell")
_CODEX_HOOK_FIELDS  = ("timeout", "statusMessage")

def _build_hooks(events: dict, optional_fields: tuple) -> dict:
    """Build the shared {event: [{matcher?, hooks:[...]}]} structure.

    `optional_fields` lists which extra per-command keys to carry through for the
    target tool; the common keys (type, command) are always included.
    `matcher` itself is optional: events like Stop don't support matchers, so
    an entry with no `matcher` key in the source YAML omits it from the output
    too, rather than emitting a matcher: null.
    """
    result = {}
    for event, entries in events.items():
        result[event] = []
        for entry in entries:
            block = {}
            if "matcher" in entry:
                block["matcher"] = entry["matcher"]
            block["hooks"] = []
            for cmd in entry.get("commands", []):
                hook = {"type": cmd.get("type", "command")}
                for field in optional_fields:
                    if field in cmd:
                        hook[field] = cmd[field]
                hook["command"] = cmd["command"]
                block["hooks"].append(hook)
            result[event].append(block)
    return result

# ── Generator: .codex/hooks.json ─────────────────────────────────────────────
def gen_codex_hooks(hooks: dict) -> None:
    ch = hooks.get("codex", {})
    if not ch:
        print("[sync-config] INFO no codex hooks defined — skipping .codex/hooks.json")
        return
    payload = {"_generated": GENERATED_MARKER + " — DO NOT EDIT DIRECTLY"}
    payload.update(_build_hooks(ch, _CODEX_HOOK_FIELDS))
    content = json.dumps(payload, indent=2, ensure_ascii=False) + "\n"
    _safe_write(CODEX_HOOKS_OUT, content)

# ── Generator: .codex/config.toml ────────────────────────────────────────────
def gen_config_toml() -> None:
    lines = [
        f"# {GENERATED_MARKER} — DO NOT EDIT DIRECTLY",
        "# Generator: scripts/sync-config.ps1",
        "# Adjust [model] and [sandbox] sections to match your Codex version.",
        "#",
        "# Event hooks are generated separately into .codex/hooks.json",
        "# (same JSON schema as Claude). Execution policy lives in .codex/rules/.",
        "",
        "# [model]",
        '# name = "codex-mini-latest"',
        "",
        "# [sandbox]",
        "# network = false",
        "",
        "[execution]",
        'policy = ".codex/rules/execution-policy.rules"',
        "",
    ]
    _safe_write(CONFIG_TOML_OUT, "\n".join(lines))

# ── Claude → Codex permission transform ──────────────────────────────────────
def _to_codex_patterns(entries: list) -> list:
    """Derive Codex substring patterns from a list of Claude permission entries.

    Only Bash(...) entries map to Codex (it governs commands, not Read/Edit).
    `Bash(<cmd>*)` and `Bash(<cmd>:*)` collapse to the substring `<cmd>`.
    Read(...)/Edit(...)/etc. are dropped (Claude-only by design).
    """
    patterns = []
    for entry in entries:
        if not (entry.startswith("Bash(") and entry.endswith(")")):
            continue
        inner = entry[len("Bash("):-1]          # strip Bash(  )
        if inner.endswith("*"):                 # drop trailing glob
            inner = inner[:-1]
        if inner.endswith(":"):                 # drop Claude :* matcher residue
            inner = inner[:-1]
        if inner:
            patterns.append(inner)
    return patterns

# ── Generator: .codex/rules/execution-policy.rules (Starlark) ────────────────
def gen_starlark(perms: dict) -> None:
    cp = perms.get("permissions", {})
    deny  = _to_codex_patterns(cp.get("deny",  []))
    ask   = _to_codex_patterns(cp.get("ask",   []))
    allow = _to_codex_patterns(cp.get("allow", []))

    def _list(name: str, items: list) -> str:
        body = "".join(f'    "{i}",\n' for i in items)
        return f"{name} = [\n{body}]"

    content = "\n".join([
        f"# {GENERATED_MARKER} — DO NOT EDIT DIRECTLY",
        "# Codex execution policy (Starlark).",
        "# See: https://developers.openai.com/codex/rules",
        "# Adjust the filter() signature to match your Codex version if needed.",
        "",
        _list("DENY", deny),
        _list("ASK", ask),
        _list("ALLOW", allow),
        "",
        "def filter(action_type, command, ctx):",
        "    for p in DENY:",
        "        if p in command:",
        '            return {"action": "deny", "message": "Blocked: " + p}',
        "    for p in ASK:",
        "        if p in command:",
        '            return {"action": "ask"}',
        "    for p in ALLOW:",
        "        if p in command:",
        '            return {"action": "allow"}',
        "    return None",
        "",
    ])
    _safe_write(STARLARK_OUT, content)

# ── Orchestration layer: validation + ROLE BINDING projection (task P1) ──────
# workflows.yaml/subagents.yaml are data for the ORCHESTRATOR (main session) —
# they are not projected into settings.json. The generator's job here is:
#   1. cross-validate the two files (a broken role reference must fail loudly
#      at sync time, not mid-workflow), and
#   2. project the small generated ROLE BINDING comment block into each
#      .claude/agents/*.md. Only that region is generated; the rest of each
#      agent file stays hand-authored (see docs/research/agentique.md §Génération).

ROLE_BINDING_RE = re.compile(r"<!--\s*BEGIN ROLE BINDING.*?-->", re.DOTALL)

def validate_orchestration(workflows: dict, subagents: dict) -> bool:
    """Cross-validate workflows.yaml against subagents.yaml (see file headers)."""
    if not workflows and not subagents:
        print("[sync-config] INFO no workflows/subagents sources — skipping orchestration layer.")
        return True
    ok = True
    roles = subagents.get("roles") or {}
    sop   = subagents.get("sop") or {}
    if not isinstance(roles, dict) or not roles:
        print("[sync-config] ERROR subagents.yaml must define a non-empty 'roles' mapping")
        return False

    # (1) every subagent bound to a role has an agent file on disk
    for role, agents in roles.items():
        if not isinstance(agents, list) or not agents:
            print(f"[sync-config] ERROR subagents.yaml roles.{role} must be a non-empty list")
            ok = False
            continue
        for name in agents:
            if not (AGENTS_DIR / f"{name}.md").exists():
                print(f"[sync-config] ERROR roles.{role} references '{name}' but "
                      f".claude/agents/{name}.md does not exist")
                ok = False

    # (2) every workflow step references a known role; every role used has a SOP.
    # Note: the reviewer role's SOP is archetype-independent by design (its
    # agents always follow the review-refactor anatomy), so a missing exact
    # sop.<role>.<archetype> key is only an INFO when the role has another entry.
    for wf_name, wf_def in (workflows.get("workflows") or {}).items():
        archetype = wf_def.get("archetype")
        for step in wf_def.get("steps") or []:
            role = step.get("role")
            if role not in roles:
                print(f"[sync-config] ERROR workflows.{wf_name} step '{step.get('id')}' "
                      f"references unknown role '{role}' (not in subagents.yaml roles:)")
                ok = False
                continue
            if role not in sop:
                print(f"[sync-config] ERROR sop.{role} missing in subagents.yaml "
                      f"(role used by workflows.{wf_name})")
                ok = False
            elif archetype and archetype not in sop[role]:
                print(f"[sync-config] INFO sop.{role}.{archetype} not defined — "
                      f"'{role}' falls back to its own SOP entries ({', '.join(sop[role])})")

    # (3) default_archetype_workflow values point at existing workflows (or null)
    wf_keys = set((workflows.get("workflows") or {}).keys())
    for archetype, wf_name in (workflows.get("default_archetype_workflow") or {}).items():
        if wf_name is not None and wf_name not in wf_keys:
            print(f"[sync-config] ERROR default_archetype_workflow.{archetype} -> "
                  f"'{wf_name}' is not a workflow defined in workflows.yaml")
            ok = False

    # (4) hitl convention is present and complete
    hitl = subagents.get("hitl") or {}
    if not hitl.get("status_token_prefix") or not hitl.get("values"):
        print("[sync-config] ERROR subagents.yaml hitl: must define "
              "'status_token_prefix' and 'values'")
        ok = False

    # (5) team_overrides file exists and parses with a top-level 'overrides' key
    overrides_path = subagents.get("team_overrides")
    if overrides_path:
        p = ROOT / overrides_path
        if not p.exists():
            print(f"[sync-config] ERROR team_overrides points at missing file: {overrides_path}")
            ok = False
        else:
            data = load_yaml(p)
            if "overrides" not in data:
                print(f"[sync-config] ERROR {overrides_path} must have a top-level 'overrides' key")
                ok = False
    return ok

def project_role_bindings(subagents: dict) -> None:
    """Inject/refresh ONLY the ROLE BINDING comment block in each agent file.

    Deliberately bypasses _safe_write: agent files are hand-authored (no
    whole-file GENERATED marker); the guard here is region-granular — nothing
    outside the <!-- BEGIN ROLE BINDING ... --> block is touched.
    """
    roles = subagents.get("roles") or {}
    for role, agents in roles.items():
        if not isinstance(agents, list):
            continue
        for name in agents:
            path = AGENTS_DIR / f"{name}.md"
            if not path.exists():
                continue  # already reported by validate_orchestration
            text = path.read_text(encoding="utf-8")
            siblings = [a for a in agents if a != name]
            lines = [
                "<!-- BEGIN ROLE BINDING (GENERATED FROM .ai/config/subagents.yaml by",
                "     scripts/sync-config.py — edit the YAML, then rerun the generator)",
                f"Role: {role}",
            ]
            if siblings:
                lines.append(f"Also bound to this role: {', '.join(siblings)}")
            lines.append("-->")
            block = "\n".join(lines)
            if ROLE_BINDING_RE.search(text):
                new_text = ROLE_BINDING_RE.sub(lambda _m: block, text, count=1)
            else:
                # No block yet: insert right after the closing frontmatter fence.
                m = re.match(r"^---\n.*?\n---\n", text, re.DOTALL)
                if not m:
                    print(f"[sync-config] ERROR {path.relative_to(ROOT)} has no frontmatter — "
                          "cannot place ROLE BINDING block")
                    continue
                new_text = text[:m.end()] + "\n" + block + "\n" + text[m.end():]
            if new_text != text:
                path.write_text(new_text, encoding="utf-8")
                print(f"[sync-config] WROTE ROLE BINDING block in {path.relative_to(ROOT)}")

# ── Validation ────────────────────────────────────────────────────────────────
def validate(perms: dict) -> bool:
    ok = True
    if "permissions" not in perms:
        print("[sync-config] ERROR permissions.yaml must have a top-level 'permissions' key")
        return False
    for key in ("deny", "ask", "allow"):
        val = perms.get("permissions", {}).get(key, [])
        if not isinstance(val, list):
            print(f"[sync-config] ERROR permissions.yaml permissions.{key} must be a list")
            ok = False
    return ok

# ── Entry point ───────────────────────────────────────────────────────────────
def main() -> int:
    print("[sync-config] Loading sources...")
    perms     = load_yaml(PERMISSIONS_SRC)
    hooks     = load_yaml(HOOKS_SRC)
    workflows = load_yaml(WORKFLOWS_SRC)
    subagents = load_yaml(SUBAGENTS_SRC)

    if not validate(perms):
        print("[sync-config] Validation failed — aborting.")
        return 1
    if not validate_orchestration(workflows, subagents):
        print("[sync-config] Orchestration validation failed — aborting.")
        return 1

    print("[sync-config] Generating outputs...")
    gen_settings(perms, hooks)
    gen_config_toml()
    gen_starlark(perms)
    gen_codex_hooks(hooks)
    if subagents:
        project_role_bindings(subagents)
    print("[sync-config] Done.")
    return 0

if __name__ == "__main__":
    sys.exit(main())