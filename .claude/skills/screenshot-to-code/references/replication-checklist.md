# Exact-replication checklist

The goal stated to the model in screenshot-to-code's own prompt is blunt and worth keeping just as blunt here: *"Make sure the web page looks exactly like the screenshot."* Treat every mismatch as a bug, not a stylistic choice. Concretely:

- **Text**: copy it verbatim, including capitalization, punctuation, and any obvious placeholder-style copy ("Lorem ipsum...") if that's literally what's in the image. Don't "clean up" or rephrase copy the design actually shows.
- **Layout**: match the structure (columns, rows, grid vs. flex arrangement, alignment, ordering of elements) as it reads visually, not just an approximation that has "similar vibes."
- **Colors**: pull the actual hex/RGB values you can read off the image for backgrounds, text, borders, and accents rather than guessing a nearby Tailwind/Bootstrap default color that's close but not exact.
- **Spacing and sizing**: keep proportions consistent with the screenshot — padding, gaps between elements, and relative sizes of text/images/buttons.
- **Typography**: match font weight and relative size for headings vs. body vs. captions; if the design clearly uses a distinctive typeface (not a generic system font), source it from Google Fonts or similar rather than defaulting silently.

## Multiple screenshots in one request

Don't assume they all belong on one page. Figure out the relationship first:

- **Different pages of the same site/app** → build them as separate, linked pages (or routes/components, depending on stack) with real navigation between them.
- **Different tabs or view-states of the same screen** → build one view with working navigation/state that switches between them, matching how the original app would behave.
- **Apparently unrelated screenshots** → don't force a relationship. Build a simple scaffold that separates them clearly (e.g., "Screenshot 1", "Screenshot 2", ...) so each is easy to find and review independently.
- **Mobile screenshots** → build only the actual app/site UI. Skip the device frame, status bar, and any browser chrome that's just an artifact of how the screenshot was captured — it's not part of the design.

## Targeted edits to already-generated code

When a follow-up request is about changing one specific element (the user points at something in a rendered preview, pastes a snippet of markup, or describes one component precisely — "make the CTA button in the hero larger"), scope the change narrowly:

1. Locate the exact code producing that element by matching tag, classes/ids, and text content — keep in mind that what's visible in a live DOM can differ slightly from the source (JSX compiles `className` differently than it's written, Vue templates use directives/interpolations that render into different markup, and libraries like Bootstrap/Ionic can inject classes or attributes at runtime).
2. Apply the change only to that element and the logic that renders it. Leave the rest of the file untouched — use Edit with an exact string match rather than rewriting the whole file, so nothing else shifts as a side effect.
3. If the requested change is ambiguous about *which* element it means (e.g., there are three buttons that could all be "the button"), ask rather than guessing, or make the most visually obvious match and say which one you picked.
