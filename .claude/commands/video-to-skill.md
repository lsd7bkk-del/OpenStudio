---
description: Download a video from a link, extract keyframes, transcribe the audio, and save it all as a reusable skill
argument-hint: <url-or-file> [--name slug] [--frames 20] [--model base]
allowed-tools: Bash(.claude/scripts/video-to-skill.sh:*), Bash(ls:*), Bash(cat:*), Bash(sed:*), Read, Edit, Write, Glob
---

Turn the video at `$ARGUMENTS` into a skill under `.claude/skills/`.

## 1. Run the pipeline

```bash
.claude/scripts/video-to-skill.sh $ARGUMENTS
```

It downloads the video, picks keyframes (scene-change detection on anything
under 30 minutes, an even spread above that), transcribes the audio, and writes
a skill directory. The last line of output is the path it wrote to.

The heavy video and audio files stay in a scratch dir and are deleted on exit —
only frames, transcript and metadata land in the skill.

If it fails, read the error and fix the cause rather than retrying blind:

| Error | Fix |
|---|---|
| `ffmpeg not found` | `brew install ffmpeg` / `sudo apt install ffmpeg` |
| `yt-dlp not found` | `pipx install yt-dlp` or `pip3 install --user yt-dlp` |
| `yt-dlp failed` | Private, geo-blocked, or login-walled. Re-run with `--cookies-from-browser chrome` appended, or ask the user for a file instead. |
| transcript `unavailable` | `pip3 install --user faster-whisper`, then re-run. Don't hand over a skill with an empty transcript. |

## 2. Read what it produced

Read in this order — don't skip to writing:

1. `<out>/metadata.json` — title, source, duration, how the transcript was made.
2. `<out>/transcript.md` — **the whole thing**, not the first screen. This is the substance.
3. `<out>/frames/index.md` — the frame → timestamp table.
4. The frames themselves. View every one for a short video; for 20 frames,
   view them all — they are cheap and they are the only visual record.

Line the frames up against the transcript by timestamp. A frame at `[00:04:12]`
explains whatever the transcript says at `[00:04:12]`.

## 3. Write the skill

`SKILL.md` arrives as a scaffold full of `TODO`s. Replace all of them. It is a
skill, not a summary — write it so that a future Claude session loading it can
act on the content without the video.

- **`description`** (frontmatter): what it gives Claude *and* when to load it.
  Include the words a user would actually type. One or two sentences, third
  person. This is the only part always in context, so it carries the whole
  trigger.
- **Key points**: the claims, rules or numbers worth reusing. Cite `[hh:mm:ss]`
  on each one so anything can be traced back.
- **Walkthrough**: only if the video demonstrates a procedure. Steps, each
  pointing at the frame that shows it (`frames/frame-007.jpg` at `[00:02:30]`).
- **Verbatim quotes**: only lines genuinely worth exact wording. Delete the
  section otherwise.
- **Caveats**: what the video asserts without evidence, what has dated, what a
  reader should verify independently. Don't launder the video's claims into
  fact — it is one source, and attributing its claims to it is the point.

Rules:
- Everything in the skill comes from the transcript and the frames. No outside
  knowledge, no filling gaps with what you assume the video meant.
- Where the transcript is garbled or the audio was unclear, say so rather than
  guessing at the words.
- Delete frames that carry nothing (black frames, transition blur, duplicate
  slides) and renumber nothing — just drop the rows from `frames/index.md`.
- If the video turns out to be unusable for a skill (no speech and no
  informative visuals, or purely entertainment with nothing to reuse), say so
  plainly and ask whether to keep the raw capture instead of inventing content.

## 4. Report back

Tell the user: the skill path, its `description` line, the frame count, how the
transcript was produced (captions vs. local whisper — captions can be sloppy
auto-generated ones), and anything you dropped or couldn't make out.

Skills in `.claude/skills/` load on the next session. Mention that.
