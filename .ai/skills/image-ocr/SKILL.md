---
name: image-ocr
description: >-
  Extracts the visible content of an image — a local file, a screenshot
  already in the working tree, or a remote URL — and writes it to a
  companion Markdown (.md) file next to the source image, preserving
  headings/lists/emphasis. For diagrams, flowcharts, or architecture
  schematics, it reconstructs the actual logical flow (what's parallel vs
  sequential, what depends on what) instead of dumping box labels in reading
  order. Can optionally add a short summary of what the image depicts. Use
  this skill whenever the user wants to "extract text from an image", "OCR a
  screenshot", "transcrire/extraire le texte d'une image ou capture", or turn
  a picture's content into a file — even if they don't say "OCR" explicitly
  (e.g. "qu'est-ce qui est écrit sur cette image", "récupère le texte de ce
  screenshot", "explique-moi ce schéma").
---

# Image OCR — extract text and diagrams from an image into Markdown

Claude's vision can read an image directly — no external OCR library is
needed. This skill is the workflow for turning that visual read into a
reliable Markdown artifact: resolve where the image actually lives, read it,
transcribe its text faithfully (as Markdown, not flat text), reconstruct any
diagram's real structure rather than its raw layout, and save it predictably.

## Workflow

1. **Resolve the image to a local file.**
   - Local path or an existing screenshot/capture in the working tree → use it as-is.
   - Remote URL → download it first (e.g. `curl -L -o <dest> "<url>"`) so a
     real local file exists before the next step. Pick a sensible `<dest>`
     name from the URL's last path segment; fall back to the scratchpad
     directory if the URL has no clear filename.

2. **Read the image** with the Read tool. Viewing the file surfaces its
   content (text, layout, diagrams) directly — treat this as the OCR step.
   If the text is small or dense, zoom/crop into regions and re-read them
   before transcribing — guessing at illegible text produces convincing but
   wrong output, which is worse than admitting a word is unclear.

3. **Separate flowing text from diagrams.** Most images mix the two: a
   heading, some explanatory bullets, then a box-and-arrow diagram. Handle
   each part differently — treating a diagram like prose (reading box labels
   left-to-right, top-to-bottom) scrambles the relationships it's meant to
   convey, which is the single biggest way this skill goes wrong.

4. **Transcribe flowing text verbatim, as Markdown.** Map what you see onto
   Markdown syntax instead of flattening it into plain lines: visual
   titles/section headers become `#`/`##`/`###` at the matching level,
   bulleted lists become `-`, numbered lists become `1.`, bold/emphasized
   text becomes `**bold**`/`*italic*` if visually distinguishable. Keep the
   wording, punctuation, and any placeholders (`{LIKE_THIS}`) exactly as
   written — this step is about reformatting for structure, not paraphrasing
   or translating.

5. **Reconstruct diagrams by their logic, not their geometry.** A diagram's
   boxes and connectors (arrows/lines) encode relationships: which steps run
   at the same time, which one waits for another to finish, which one
   combines results from several inputs. Before writing anything down, trace
   every arrow from its tail to its head and answer: which boxes start
   together with no dependency between them (genuinely parallel)? Which box
   has arrows arriving from more than one source (a join/synthesis point that
   must wait for *all* of its inputs, i.e. sequential relative to them)? Only
   write the diagram section once you can state the flow in your own words —
   e.g. "A and B start together; C runs once both finish and combines their
   results" — and that statement is what the rendering should communicate,
   not the raw position of each box on the canvas.

   Render it as a nested list under its own heading (`## Diagramme` /
   `## Schéma`), grouping sibling branches that run together and indenting
   branches that depend on a prior step finishing. State plainly when
   something is parallel vs sequential, since that distinction is usually
   the entire point of the diagram. If a connector's direction or a label is
   genuinely illegible, say so explicitly rather than guessing silently —
   a flagged uncertainty is far more useful than a confident wrong reading.

6. **Add a summary only if asked.** If the user separately requests an
   explanation of the image, append a `## Résumé`/`## Summary` section with a
   few sentences of higher-level prose. The diagram section from step 5 must
   already have the relationships right — the summary restates them in
   plain language for a skimming reader, it doesn't substitute for getting
   the logic correct in the first place.

7. **Write the output file.**
   - Default: same directory as the source image, same base filename, `.md`
     extension (`diagram.png` → `diagram.md`).
   - If the user names a different output path or filename, use that instead.
   - Processing several images in one request → write one `.md` file per
     image, each next to its source.

## Output format

```markdown
# <title from the image, if any>

<verbatim flowing text, reformatted as Markdown headings/lists/emphasis>

## Diagramme
- <top-level box/step>
  - <branch that starts at the same time, if parallel>
  - <branch that starts at the same time, if parallel>
- <next step, only once its dependencies above are met> — combines results from <...>
```

Add `## Résumé` only when a summary was requested.

If the image has no readable text or diagram, still write the file with a
single line noting that, rather than leaving it empty or skipping it:
```markdown
(No text detected in image.)
```

## Notes

- Works for any image format Claude can view (PNG, JPG, …) and for any kind
  of source: scanned documents, photos of text, UI screenshots, diagrams.
- Markdown is the point, not decoration: it's what lets headings, lists, and
  emphasis survive the trip from image to file instead of collapsing into an
  undifferentiated block of text.
- For pure prose/lists with no diagram, step 5 is simply skipped — there's
  nothing to reconstruct.