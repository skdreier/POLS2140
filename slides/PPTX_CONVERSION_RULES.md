# PPTX → Quarto (clean-revealjs) Conversion Rules

Rules to follow when converting a `.pptx` file into a `.qmd` deck using `sarah_slide_template.qmd` conventions.

## Rule: Preserve click-triggered animations as pauses

PowerPoint's "click to build" animations (an entrance effect set to appear "On Click") are functionally the same idea as a reveal.js pause — both mean "don't show this yet; wait for the presenter to advance." **This is detectable and preservable**, verified against real files in `for_quarto_convert/`.

**How to detect it, per slide:**

1. A `.pptx` is a zip file. Unzip it and open `ppt/slides/slideN.xml` for the slide in question.
2. Look for a `<p:timing>...</p:timing>` block. If there isn't one, the slide has no animations — convert it plainly, no pauses needed.
3. Inside `<p:timing>`, find nodes with `nodeType="clickEffect"`. Each one is a distinct "wait for a click" step. **The order these nodes appear in the XML is the reveal order** — first `clickEffect` = first pause, second = second pause, etc.
4. Each `clickEffect` node contains one or more `<p:spTgt spid="X"/>` tags — these `spid` values are shape IDs targeted by that click step. A single click can reveal multiple shapes at once (grouped together under one pause).
5. Cross-reference each `spid` against `<p:cNvPr id="X" name="...">` elsewhere in the same slide XML to find the actual shape (`<p:sp>`, `<p:pic>`, or `<p:graphicFrame>`) and pull its real content — text runs are in `<a:t>` tags; images are referenced via relationship IDs in the shape's `<a:blip r:embed="...">`, resolved through `ppt/slides/_rels/slideN.xml.rels`.
6. Any shape on the slide **not** referenced by any `clickEffect` shows immediately — no pause before it.

**How to translate into the `.qmd`:**

- Content with no animation reference → plain markdown/HTML, no wrapping.
- Content in the Nth `clickEffect` group → preceded by a pause, in that same order:
  - Use `. . .` (three dots, own line, blank-line separated) for plain slide markdown.
  - Use `::: {.fragment}` / `<div class="fragment">` instead if the content sits inside a raw HTML wrapper (where dots silently fail — see `cheat_sheet.qmd`) or is one bullet in a list where `.incremental` doesn't apply cleanly.
- Shapes revealed together in the same `clickEffect` group → wrapped in the same pause step, not split into separate ones.

**What doesn't map cleanly — don't try to force it:**

- Exit animations, emphasis animations (color pulse, spin, grow/shrink emphasis), and motion-path animations have no clean reveal.js equivalent. Treat any click-triggered *entrance*-family effect as "goes behind a pause" regardless of its exact PowerPoint style (fade/fly-in/wipe/etc. all just become "appears on click") — don't attempt to replicate the specific animation style, only the fact that it was gated behind a click and its position in the sequence.
- "With previous" / "after previous" (0-delay) effects chained off a `clickEffect` are part of that same click's reveal group, not a separate pause.

## Rule: Duplicate/variant source files

Several files in `for_quarto_convert/` are duplicate or dated variants of the same numbered slide (e.g. `9_lab_r-introduction.pptx` vs `9_lab_r-introduction-mar25.pptx`). Confirm with Sarah which is canonical before converting either — don't guess.

## Rule: Shrink text so it all visually fits on the slide

Every line of text that was on the original PowerPoint slide must remain **visible on the slide itself** in the converted deck — not cut off, not silently pushed into speaker notes, not split onto an extra slide the original didn't have. If a slide's content is dense enough that it would overflow at normal size, shrink the text rather than hide/relocate/split it:

1. **Base rule: set the slide to `font-size: 0.9em` first** — `## Slide Title {style="font-size: 0.9em;"}` on the heading, which scales the whole generated `<section>`. This is the default first move, not `{.smaller}` (a bigger, less predictable preset jump) — and never combine the two on the same slide, they compound and overshoot into unreadably tiny.
2. If a slide is still too dense at 0.9em, rebalance layout columns, cap images with `max-height` in `vh`, tighten line-height/margins, and only then drop the font-size further (adjust the `0.9em` value down as needed).
3. After rendering, actually check the output — render the `.html` and visually confirm (or inspect the DOM) that nothing is clipped/overflowing before considering that slide done.

This differs from the density-editing approach used earlier this session on the from-scratch decks (1–3), where verbose content was sometimes trimmed on-slide and moved into speaker notes instead. For **converted** decks, the original slide's full visible content is the source of truth — preserve all of it on-slide by shrinking, don't summarize or relocate it, unless Sarah says otherwise for a specific slide.

## Rule: Standard opening/closing slides

Every deck — converted or from-scratch — opens with two blank slides, in this order: `## Reading Prompt`, then `## Announcements` (left empty — these get filled in by hand each time the deck is actually taught; no "Wrap up from last class" slide). It ends with, in order: a **next-class reading slide**, `## TL;DR`, `## References`. See "Rule: Next-class reading slide" and "Rule: Cite sources with `@key`" below for those last two.

## Rule: Section-divider slides carry the contrast background

Any full-bleed section-break slide — a single `#` (one-hash) heading used to split the lecture into parts — must have `{background-color="#2c3e50"}` on the heading (e.g. `# Course Datasets {background-color="#2c3e50"}`). That slate is the standard contrast color across the course decks (`4_human_judgment.qmd`, `sarah_slide_template.qmd`, `cheat_sheet.qmd`); the theme flips the heading text to light automatically. A bare `#` divider with no background color is an omission to fix. When a PowerPoint has its own section-break slides (often a colored full-slide title), convert each to a `#` heading with this background.

## Rule: Next-class reading slide

Immediately before `## TL;DR`, every deck gets one slide naming the *next* class meeting and its assigned reading(s):

- **Heading:** `## For [Day]:` — matches the existing "For Thursday:" / "For Tuesday:" pattern already used in this course's decks.
- **Content:** the reading(s)/task(s) assigned for that next meeting, pulled from and verified against the syllabus's Course Schedule (`New_2140_syllabus/POLS2140_Syllabus_F26.qmd`) — never invented or guessed from memory.
- **Link:** the slide links to the published syllabus (`https://skdreier.github.io/POLS2140/`) so students can click through to the full schedule.
- **TL;DR then References** follow it, in that order — always include the References slide, even in a deck with nothing yet cited. See `sarah_slide_template.qmd` / `cheat_sheet.qmd` for the live example.

## Rule: Reading Prompt slide content

The blank `## Reading Prompt` slide (see "Standard opening/closing slides" above) eventually gets filled in with a real question each time the deck is taught. When writing that question, it should be:

- **Quick** — answerable in about 3–5 minutes, in class, without needing to re-consult the text.
- **Approachable/low-bar** — answerable by a student who read the assigned material once, not carefully. Not a question that requires synthesis, argument, or precise recall of a definition.
- **Grounded in one concrete, memorable detail** from that week's actual assigned reading — a specific example, story, place/date, or analogy the author used — not an abstract "define X" or "summarize the chapter" prompt.
- **Verified against the real source**, not invented or assumed. For scanned/image PDFs with no text layer, this means actually viewing the relevant pages (e.g., rendering to PNG with PyMuPDF and reading them) rather than guessing at content from a table of contents or title alone.

**Example** (Kellstedt & Whitten, *Fundamentals*, Ch. 1): "Chapter 1 uses the 16th-century example of astronomers abandoning the idea that the Earth was the center of the universe to introduce the term 'paradigm shift.' In your own words, what is a paradigm shift — and why does the book say political scientists disagree about whether their own field has ever had one?" — a vivid, self-contained anecdote stated plainly in the text, answerable without having absorbed any of the book's own technical vocabulary.

## Rule: Where files go after conversion

- **Leave the source `.pptx` where it is** — in `for_quarto_convert/`. Don't move or delete it once converted; it stays as the retained original.
- **Save the output `.qmd` (and its rendered `.html` + any supporting files) directly in `quarto_slides/`** — the parent folder, alongside `1_course_intros.qmd`, `2_political_science.qmd`, etc. Not inside `for_quarto_convert/`.

## Rule: Cite sources with `@key`, not hand-written links

Any source/attribution that appears on a converted slide (a book, article, figure credit, "Source: …" line) must be a Quarto `@key` citation keyed to `references_2140.bib`, **not** a hand-written `<a href>` link or a plain-text "(Author Year)" string. This matches the style used in `4_human_judgment.qmd` (e.g. the Silberzahn figure-source lines) and `sarah_slide_template.qmd`.

- Add a BibTeX entry to `references_2140.bib` if the source isn't there yet.
- In-text: `[@key]` (parenthetical), `@key` (narrative), `@key [p. 54]` / `@key [Fig. 2, p. 346]` (with locator).
- Figure-source lines go in a fenced div (`::: {style="…"}`), not a raw `<div>` — citeproc doesn't process citations inside raw HTML.
- Keep `bibliography: references_2140.bib` and `csl: apa.csl` in the YAML; do **not** add `biblio-title:`.
- End the deck with a `## References {.smaller}` slide containing `::: {#refs}` / `:::` (nothing between the heading and the div). Place it right before or after the `## TL;DR` slide.
