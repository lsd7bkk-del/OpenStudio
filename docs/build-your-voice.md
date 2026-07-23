# Build Your Own Voice as a `.md` File

Instead of re-explaining your writing style to an AI every time you open a chat,
you distill your voice **once** into a single Markdown file. From then on you
attach or paste that file and the model writes as *you* — same rhythm, same
vocabulary, same formatting habits.

This is the workflow popularized by creators like
[Ruben Hassid](https://x.com/rubenhassid). Below is a repeatable version of it,
plus a fill-in template ([`voice.template.md`](./voice.template.md)) you can
copy and use with OpenStudio's **Scripts** and **Reels** modules — or any AI.

---

## Why a voice file beats a prompt

- **Consistency** — every generation starts from the same style baseline.
- **Portability** — one file works across Claude, ChatGPT, the Scripts module, etc.
- **Editable** — your voice evolves; you tweak the file, not 50 saved prompts.
- **Sharable** — hand it to a ghostwriter, a teammate, or an agent.

A voice file captures **how you write**, never **what you write about**. Topics
change every day; your voice shouldn't.

---

## The 4-step method

### 1. Gather your best raw material
Collect **10–20 pieces you actually wrote** and are proud of — LinkedIn posts,
newsletter issues, tweets, video scripts. Real writing only. No AI-generated
samples (they'll pollute the profile with generic patterns).

> Tip: pick pieces that *sound like you at your best*, not just your most viral
> ones. Virality and voice are different things.

### 2. Have the AI reverse-engineer the patterns
Paste your samples and ask the model to extract, specifically:

- **Tone** — warm/blunt, formal/casual, earnest/ironic
- **Sentence rhythm** — short punchy lines? long flowing ones? fragments?
- **Structure** — how you open (hooks), build, and close (CTAs)
- **Vocabulary** — signature words, phrases, and words you *never* use
- **Formatting** — line breaks, lists, emoji, capitalization habits
- **Point of view** — "I", "you", "we"; how personal you get

Use this extraction prompt:

```text
Here are 15 pieces I wrote. Analyze ONLY my writing style, not the topics.
Produce a reusable style profile covering: tone, sentence rhythm, structure
(how I open and close), signature vocabulary, words I avoid, formatting habits,
and point of view. Include 3–5 verbatim example lines that best capture my voice.
Be specific and prescriptive — write it as instructions a ghostwriter could follow.

[paste your samples]
```

### 3. Save it as `voice.md`
Take the output, drop it into the template, and clean it up by hand. **Read
every line** — cut anything that doesn't sound like you, sharpen anything vague.
The template's "Do / Don't" rules are the highest-leverage part: be specific.

### 4. Use it everywhere
- **In a chat:** start with *"Write in the voice defined below,"* then paste the file.
- **In OpenStudio Scripts/Reels:** paste the voice block ahead of your brief so
  generated hooks and scripts inherit your style.
- **With agents/tools:** attach `voice.md` as context.

---

## Keeping it sharp

- **Re-tune quarterly.** Feed in your latest best posts and diff the profile.
- **Version it.** Keep `voice.md` in git so you can see how your voice drifts.
- **Test it blind.** Generate 3 posts, then ask a friend "did I write this?" If
  they can't tell, the file is working.

---

## Quick start

```bash
cp docs/voice.template.md voice.md
# fill in each section using the extraction prompt above, then paste voice.md
# into the Scripts or Reels module before your brief.
```

See [`voice.template.md`](./voice.template.md) for the fillable structure.
