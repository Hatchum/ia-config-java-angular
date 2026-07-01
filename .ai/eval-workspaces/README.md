# eval-workspaces/

Benchmark/eval artifacts produced by the `skill-creator` skill (iterations,
grading, timings, skill snapshots). Kept **outside** `.ai/skills/` on purpose:
that directory must contain only real skills — a workspace's `skill-snapshot/
SKILL.md` would otherwise pollute skill discovery (both agents scan
`.claude/skills` / `.agents/skills`, which link to `.ai/skills`).

- `image-ocr/` — two eval iterations of the `image-ocr` skill (2026-06), run
  against the course screenshots in `a_trier/`.

Kit-internal provenance material — do **not** copy into target projects.
