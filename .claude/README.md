# `.claude/`

Project-local Claude Code configuration.

## Commands

| Command | What it does |
|---|---|
| `/video-to-skill <url\|file>` | Downloads a video, extracts keyframes, transcribes the audio, and writes the result to `.claude/skills/<slug>/` as a skill Claude can load later. |

## Scripts

`scripts/video-to-skill.sh` is the deterministic half of `/video-to-skill` —
fetch, frame extraction and transcription. Run it standalone too:

```bash
.claude/scripts/video-to-skill.sh https://example.com/talk --frames 24 --model small
.claude/scripts/video-to-skill.sh ./local.mp4 --subs ./local.srt
.claude/scripts/video-to-skill.sh --help
```

Requires `ffmpeg` (always), `yt-dlp` (for URLs) and `faster-whisper`
(only when the source has no captions):

```bash
brew install ffmpeg          # or: sudo apt install ffmpeg
pipx install yt-dlp
pip3 install --user faster-whisper
```

The first whisper run downloads the model from huggingface.co (~75 MB for
`base`, ~3 GB for `large-v3`) and caches it in `~/.cache/huggingface`.

Video and audio files stay in `$TMPDIR/video-to-skill/` and are deleted on exit
— only frames, transcript and metadata are written into the skill. Re-running
over an existing skill moves the old one to `<slug>.bak-<timestamp>` (gitignored).
