#!/usr/bin/env python3
"""
sync-config.py — Generate tool-specific config from .ai/config/ sources.

Sources (edit these):
  .ai/config/permissions.yaml  → Claude permissions + Codex execution policy
  .ai/config/hooks.yaml        → Claude + Codex event hooks

Outputs (DO NOT edit directly — regenerate with this script):
  .claude/settings.json
  .codex/config.toml
  .codex/rules/execution-policy.rules
"""
import json, subprocess, sys
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
    """Build the shared {event: [{matcher, hooks:[...]}]} structure.

    `optional_fields` lists which extra per-command keys to carry through for the
    target tool; the common keys (type, command) are always included.
    """
    result = {}
    for event, entries in events.items():
        result[event] = []
        for entry in entries:
            block = {"matcher": entry["matcher"], "hooks": []}
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
    perms = load_yaml(PERMISSIONS_SRC)
    hooks = load_yaml(HOOKS_SRC)

    if not validate(perms):
        print("[sync-config] Validation failed — aborting.")
        return 1

    print("[sync-config] Generating outputs...")
    gen_settings(perms, hooks)
    gen_config_toml()
    gen_starlark(perms)
    gen_codex_hooks(hooks)
    print("[sync-config] Done.")
    return 0

if __name__ == "__main__":
    sys.exit(main())