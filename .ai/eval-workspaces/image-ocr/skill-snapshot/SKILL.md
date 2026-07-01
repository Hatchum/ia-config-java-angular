---
name: image-ocr
description: >-
  Extracts the visible text from an image — a local file, a screenshot already
  in the working tree, or a remote URL — and writes it to a companion .txt
  file next to the source image. Optionally adds a short summary of what the
  image depicts (useful for architecture diagrams, slides, or annotated
  screenshots where the text alone doesn't capture the meaning). Use this
  skill whenever the user wants to "extract text from an image", "OCR a
  screenshot", "transcrire/extraire le texte d'une image ou capture", or turn
  a picture's content into a text file — even if they don't say "OCR"
  explicitly (e.g. "qu'est-ce qui est écrit sur cette image", "récupère le
  texte de ce screenshot").
---

# Image OCR — extract text from an image into a file

Claude's vision can read an image directly — no external OCR library is
needed. This skill is the workflow for turning that visual read into a
reliable text-file artifact: resolve where the image actually lives, read it,
transcribe what's written, and save it predictably so the user (or another
step in their pipeline) can find it without guessing a filename.

## Workflow

1. **Resolve the image to a local file.**
   - Local path or an existing screenshot/capture in the working tree → use it as-is.
   - Remote URL → download it first (e.g. `curl -L -o <dest> "<url>"`) so a
     real local file exists before the next step. Pick a sensible `<dest>`
     name from the URL's last path segment; fall back to the scratchpad
     directory if the URL has no clear filename.

2. **Read the image** with the Read tool. Viewing the file surfaces its
   content (text, layout, diagrams) directly — treat this as the OCR step.

3. **Transcribe the text verbatim.** Copy out every piece of text visible in
   the image, preserving line breaks and reading order (top-to-bottom,
   left-to-right) as laid out in the image. Do not paraphrase, translate, or
   silently fix typos — transcribe exactly what's written, in whatever
   language it appears (French, English, mixed, etc.).

4. **Add a summary only if asked.** By default the output file holds only the
   transcribed text. If the user separately asks for an explanation of the
   image (common for architecture diagrams, slides, schemas), append a short
   "Summary" section below the transcription — a few sentences on what the
   image shows, not a restatement of the text already transcribed.

5. **Write the output file.**
   - Default: same directory as the source image, same base filename, `.txt`
     extension (`diagram.png` → `diagram.txt`).
   - If the user names a different output path or filename, use that instead.
   - Processing several images in one request → write one `.txt` file per
     image, each next to its source.

## Output format

No summary requested:
```
<verbatim transcribed text>
```

Summary requested:
```
<verbatim transcribed text>

---
Summary: <2-4 sentence description of what the image shows>
```

If the image has no readable text, still write the file with a single line
noting that, rather than leaving it empty or skipping it:
```
(No text detected in image.)
```

## Notes

- Works for any image format Claude can view (PNG, JPG, …) and for any kind of
  source: scanned documents, photos of text, UI screenshots, diagrams.
- Keep the transcription separate from the optional summary — they serve
  different readers (someone grepping for exact text vs. someone skimming for
  meaning).
