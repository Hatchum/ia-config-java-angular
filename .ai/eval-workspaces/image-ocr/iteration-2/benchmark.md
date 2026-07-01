# Skill Benchmark: image-ocr

**Model**: <model-name>
**Date**: 2026-06-23T13:30:29Z
**Evals**: 0, 1, 2 (3 runs each per configuration)

## Summary

| Metric | Old Skill | With Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 55% ± 18% | 100% ± 0% | -0.45 |
| Time | 129.8s ± 77.4s | 211.0s ± 131.8s | -81.2s |
| Tokens | 32947 ± 4393 | 39516 ± 8960 | -6568 |

## Notes

- Markdown output format change (eval-plain-ocr) is now confirmed working: with_skill writes .md with real heading/list structure on all 3 evals, 100% pass rate vs 55% for old_skill.
- eval-summary-diagram (id 1) is where iteration-1 user feedback bit hardest, and where the fix shows clearest: with_skill now states the diagram correctly in both the Diagramme and Resume sections (Agent 1 + Agent 2 launched in parallel by the Head Agent, Agent 3 runs after both finish and synthesizes their results). old_skill scored only 40% here because its raw box-label dump repeats AGENT 3 once under a PARALLELE label and again under SEQUENTIEL, the exact ambiguity the user originally flagged.
- old_skill is not a strictly worse model, it is the same instructions as iteration-1, run again, so its scores here are a fair like-for-like baseline rather than a strawman: its Resume prose is still reasonably correct on its own (same finding as iteration-1), but its Diagramme section is structurally confusing because it transcribes box positions in reading order instead of tracing dependency arrows.
- with_skill spent more time and tokens on the diagram-heavy evals (210s/38.9k tokens and 343s/48.8k tokens) than old_skill (44.7s/28.4k and 196s/37.2k on the same evals) because the new workflow requires explicitly tracing every arrow before writing the Diagramme section. This is the direct cost of the correctness fix and is worth surfacing, not hiding: old_skill is cheaper but wrong about the one thing that mattered most to the user.
- eval-multi-image (id 2) exemple-prompt-B output was accurate in both configurations this run, unlike iteration-1 where the baseline made transcription errors on the same image. This is most likely run-to-run variance in the unguided/old-skill baseline rather than a property of the skill change, so it should not be read as evidence either way about plain-text transcription accuracy.