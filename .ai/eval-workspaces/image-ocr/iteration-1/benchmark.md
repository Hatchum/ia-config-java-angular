# Skill Benchmark: image-ocr

**Model**: <model-name>
**Date**: 2026-06-23T12:37:15Z
**Evals**: 0, 1, 2 (3 runs each per configuration)

## Summary

| Metric | With Skill | Without Skill | Delta |
|--------|------------|---------------|-------|
| Pass Rate | 100% ± 0% | 67% ± 38% | +0.33 |
| Time | 127.4s ± 66.8s | 79.4s ± 67.3s | +48.1s |
| Tokens | 33701 ± 4826 | 27678 ± 1178 | +6023 |

## Notes

- eval-plain-ocr (id 0) doesn't discriminate: both configurations scored 100% on this image, because its text was legible enough for the unguided baseline to transcribe it just as well.
- eval-summary-diagram (id 1) is where the skill clearly pays off: with_skill scored 100% with a faithful verbatim transcription plus a tight summary, while without_skill scored 25% — it paraphrased into invented Markdown headers, introduced transcription errors on small text, used a .md extension instead of .txt, and produced an overlong summary that re-enumerated the transcription instead of staying brief.
- eval-multi-image (id 2) without_skill mostly held up structurally (separate files, no cross-contamination) but failed on accuracy in the denser of the two images: wrong placeholder name, a hallucinated duplicate section, and a typo ('régradation' vs 'dégradation') that the with_skill run avoided.
- with_skill runs used noticeably more tool calls and time on the two denser images (14 and 27 tool calls vs 13 and 5) — both with_skill executors cropped/upscaled the image into overlapping regions before transcribing, trading time for accuracy. This is a real cost worth surfacing to the user, not just a benchmark artifact.
- without_skill's only structural miss was file extension/format (.md with invented headers instead of plain .txt) — suggests the skill's explicit, fixed output format (plain text, optional '---'/'Summary:' block) is doing real work, not just the transcription instructions.