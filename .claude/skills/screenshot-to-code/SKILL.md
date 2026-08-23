---
name: screenshot-to-code
description: Turn a screenshot, mockup, wireframe, or design image (or a short screen-recording/video) into working front-end code that replicates it pixel-for-pixel. Use this whenever the user shares an image of a UI and asks you to build it, clone it, recreate it, "make this real", turn a Figma/Dribbble/design export into a page, match a competitor's site/landing page, or convert a hand-drawn wireframe into HTML/React. Also use it for follow-up requests to tweak or extend code that was generated this way. Trigger even if the user doesn't say "screenshot to code" explicitly — the presence of a UI image plus an intent to get code back is enough.
---

# Screenshot to Code

Replicate a provided UI image as real, working code — not a description of the UI, not a rough approximation. The bar is "looks exactly like the screenshot," because that's what makes the output immediately useful: the user can drop it in and compare side-by-side.

This skill adapts the prompting approach from the open-source [screenshot-to-code](https://github.com/abi/screenshot-to-code) project to Claude Code's own file tools (Read, Write, Edit) — there's no special image-extraction or image-generation tool here, so see "Handling images and assets" below for how to cover that gap.

## Workflow

1. **Look at the image closely first.** Read it with the Read tool before writing any code. Note the exact layout (grid/flex structure, spacing, alignment), every piece of visible text, the color palette, typography (weight, size, letter-spacing where it's distinctive), and any interactive-looking elements (buttons, inputs, nav, modals).
2. **Pick a stack.** If the user names one, use it. Otherwise:
   - If you're working inside an existing project, match its conventions (e.g. a Next.js/React + Tailwind app should get a React component, not a standalone HTML file). Check for a framework and CSS approach already in use before deciding.
   - If there's no surrounding project, default to a single self-contained `index.html` file using Tailwind via CDN — it's the fastest way for the user to open it and see the result, and needs no build step.
   - See `references/stacks.md` for the exact script tags / setup snippet for each stack (html_css, html_tailwind, bootstrap, react_tailwind, ionic_tailwind, vue_tailwind) and framework-specific gotchas (e.g. pinning the Babel standalone version for in-browser JSX).
3. **Generate the whole thing in one pass** for a new build — don't scaffold half a page and iterate line-by-line against the image; get a complete first draft, then refine.
4. **Compare your output back against the source image** before calling it done. Re-read the screenshot side-by-side with what you wrote (mentally or by rendering it if you have a way to) and fix mismatches: wrong spacing, a missed section, text that doesn't match verbatim, a color that's close-but-not-quite.
5. **For follow-up change requests** ("make the button bigger", "add a dark mode toggle"), edit the existing file with targeted changes (Edit tool, exact string replacement) rather than regenerating it from scratch — this preserves everything that already matched and avoids introducing new regressions. See `references/replication-checklist.md` for how to handle a request that references an element the user selected/pointed at in a live preview.

## Replication instructions

These are the details that separate "close enough" from "looks exactly like it," per `references/replication-checklist.md` (read it for the full list — summarized here):

- Use the **exact text** from the screenshot, not a paraphrase.
- Match colors, spacing, border radii, and typography as closely as you can read them from the image.
- If multiple screenshots are provided, figure out how they relate (different pages of one site → separate linked pages; different tabs/states of one view → one page with navigation between them; unrelated → a simple scaffold labeled "Screenshot 1", "Screenshot 2", etc.) rather than mashing them into one layout.
- For a mobile screenshot, build the actual UI only — skip the phone bezel / status bar / browser chrome that's just part of how the screenshot was captured.

## Handling images and assets

The original screenshot-to-code app has dedicated tools to crop real asset images out of the screenshot, generate new ones, remove backgrounds, and render a live preview to self-check against. Claude Code doesn't have those, so:

- **Don't try to embed the whole screenshot as one background image** — that produces a page that "looks right" as a picture but isn't real, usable code. The point of this skill is working markup, not a screenshot wrapped in an `<img>` tag.
- For photos/illustrations/icons that are clearly distinct image assets in the design (a product photo, an avatar, a hero illustration): if the user has the source image file(s) available, ask for them or use what's provided; otherwise use a placeholder image service like `https://placehold.co/<width>x<height>` sized to match, or an inline SVG/CSS shape for simple icons, and say plainly that it's a placeholder standing in for the real asset.
- For icons that map to a common icon set (arrows, hamburger menus, social logos, etc.), prefer a real icon font/library already listed in `references/stacks.md` (Font Awesome, or Ionicons for the Ionic stack) over a placeholder.
- If you do have a way to render/screenshot your own output (e.g. a browser tool), use it to visually diff against the source image and catch layout problems — don't skip this just because it's optional.

## Reference files

- `references/stacks.md` — CDN script tags and setup notes per stack, plus general instructions that apply across all of them (fonts, icons).
- `references/replication-checklist.md` — the detailed exact-replication checklist and how to scope an edit to one selected element.
