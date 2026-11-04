#!/usr/bin/env bash
# video-to-skill.sh — download a video, extract keyframes, transcribe audio,
# and lay the result out as a Claude Code skill directory.
#
# Usage:
#   video-to-skill.sh <url|file> [options]
#
# Options:
#   --name <slug>      skill directory name (default: derived from title)
#   --frames <n>       number of keyframes to keep (default: 20)
#   --mode <auto|scene|uniform>
#                      frame selection (default: auto -> scene for <30min, else uniform)
#   --threshold <f>    scene-change sensitivity 0..1 (default: 0.25)
#   --width <px>       frame width, height auto (default: 1280)
#   --model <size>     faster-whisper model: tiny|base|small|medium|large-v3 (default: base)
#   --lang <code>      force transcription language (default: autodetect)
#   --no-subs          ignore the video's own captions, always run whisper
#   --subs <file>      use this .srt/.vtt as the transcript instead of running whisper
#   --skills-dir <d>   where the skill is written (default: <repo>/.claude/skills)
#   --work-dir <d>     scratch dir for video/audio (default: $TMPDIR/video-to-skill)
#   --keep-media       don't delete the downloaded video/audio when done
#   -h | --help        this text
#
# Writes: <skills-dir>/<slug>/{SKILL.md,transcript.md,frames/,frames/index.md,metadata.json}
# Heavy media stays in the work dir, never in the skill.

set -euo pipefail

die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
log()  { printf '\033[36m▸\033[0m %s\n' "$*" >&2; }
warn() { printf '\033[33m!\033[0m %s\n' "$*" >&2; }

usage() { sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; $d'; exit 0; }

# ---------------------------------------------------------------- args
SRC=""
NAME=""
FRAMES=20
MODE=auto
THRESHOLD=0.25
WIDTH=1280
MODEL=base
LANG=""
USE_SUBS=1
SUBS_OVERRIDE=""
SKILLS_DIR=""
WORK_ROOT="${TMPDIR:-/tmp}/video-to-skill"
KEEP_MEDIA=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)     usage ;;
    --name)        NAME="${2:?}"; shift 2 ;;
    --frames)      FRAMES="${2:?}"; shift 2 ;;
    --mode)        MODE="${2:?}"; shift 2 ;;
    --threshold)   THRESHOLD="${2:?}"; shift 2 ;;
    --width)       WIDTH="${2:?}"; shift 2 ;;
    --model)       MODEL="${2:?}"; shift 2 ;;
    --lang)        LANG="${2:?}"; shift 2 ;;
    --no-subs)     USE_SUBS=0; shift ;;
    --subs)        SUBS_OVERRIDE="${2:?}"; shift 2 ;;
    --skills-dir)  SKILLS_DIR="${2:?}"; shift 2 ;;
    --work-dir)    WORK_ROOT="${2:?}"; shift 2 ;;
    --keep-media)  KEEP_MEDIA=1; shift ;;
    -*)            die "unknown option: $1 (try --help)" ;;
    *)             [ -n "$SRC" ] && die "more than one source given"; SRC="$1"; shift ;;
  esac
done

[ -n "$SRC" ] || usage
case "$FRAMES" in ''|*[!0-9]*) die "--frames must be a positive integer";; esac
[ "$FRAMES" -ge 1 ] || die "--frames must be >= 1"
case "$MODE" in auto|scene|uniform) ;; *) die "--mode must be auto, scene or uniform";; esac
if [ -n "$SUBS_OVERRIDE" ]; then
  [ -f "$SUBS_OVERRIDE" ] || die "no such subtitle file: $SUBS_OVERRIDE"
  SUBS_OVERRIDE="$(cd "$(dirname "$SUBS_OVERRIDE")" && pwd)/$(basename "$SUBS_OVERRIDE")"
fi

# ---------------------------------------------------------------- deps
command -v ffmpeg  >/dev/null || die "ffmpeg not found. macOS: brew install ffmpeg | Debian: sudo apt install ffmpeg"
command -v ffprobe >/dev/null || die "ffprobe not found (ships with ffmpeg)"
command -v python3 >/dev/null || die "python3 not found"

IS_URL=0
case "$SRC" in
  http://*|https://*) IS_URL=1 ;;
  *) [ -f "$SRC" ] || die "no such file: $SRC" ;;
esac

YTDLP=""
if [ "$IS_URL" = 1 ]; then
  if command -v yt-dlp >/dev/null; then YTDLP="yt-dlp"
  elif python3 -c 'import yt_dlp' 2>/dev/null; then YTDLP="python3 -m yt_dlp"
  else die "yt-dlp not found. Install it: pipx install yt-dlp (or pip3 install --user yt-dlp)"
  fi
fi

# ---------------------------------------------------------------- paths
if [ -z "$SKILLS_DIR" ]; then
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  SKILLS_DIR="$REPO_ROOT/.claude/skills"
fi

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]\+/-/g' -e 's/^-\+//' -e 's/-\+$//' \
    | cut -c1-60
}

RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
WORK="$WORK_ROOT/$RUN_ID"
MEDIA="$WORK/media"
mkdir -p "$MEDIA"
KEEP_LOG=0
cleanup() {
  if [ "$KEEP_MEDIA" = 0 ] && [ -d "$MEDIA" ]; then rm -rf "$MEDIA"; fi
  if [ "$KEEP_LOG" = 0 ] && [ -d "$WORK" ]; then rm -f "$WORK"/_transcribe.py "$WORK"/*.txt; fi
}
trap cleanup EXIT

# ---------------------------------------------------------------- 1. fetch
TITLE=""; UPLOADER=""; SOURCE_URL=""; UPLOAD_DATE=""; DESCRIPTION=""
SUB_FILE=""
VIDEO=""

if [ "$IS_URL" = 1 ]; then
  log "downloading: $SRC"
  SUBARGS=()
  [ "$USE_SUBS" = 1 ] && SUBARGS=(--write-subs --write-auto-subs --sub-langs "en.*,en,-live_chat" --convert-subs srt)
  # shellcheck disable=SC2086
  $YTDLP \
    --no-playlist --no-progress --no-warnings \
    --restrict-filenames \
    -f 'bv*[height<=720]+ba/b[height<=720]/bv*+ba/b' \
    --merge-output-format mp4 \
    --write-info-json \
    "${SUBARGS[@]}" \
    -o "$MEDIA/source.%(ext)s" \
    "$SRC" || die "yt-dlp failed. Private/geo-blocked video, or the site needs cookies (--cookies-from-browser)."

  VIDEO="$(find "$MEDIA" -maxdepth 1 -type f ! -name '*.info.json' ! -name '*.srt' ! -name '*.vtt' -print | head -1)"
  [ -n "$VIDEO" ] || die "download produced no media file"

  INFO="$(find "$MEDIA" -maxdepth 1 -name '*.info.json' -print | head -1)"
  if [ -n "$INFO" ]; then
    read_json() { python3 -c 'import json,sys;print((json.load(open(sys.argv[1])).get(sys.argv[2]) or ""))' "$INFO" "$1" 2>/dev/null || true; }
    TITLE="$(read_json title)"
    UPLOADER="$(read_json uploader)"
    SOURCE_URL="$(read_json webpage_url)"
    UPLOAD_DATE="$(read_json upload_date)"
    DESCRIPTION="$(read_json description)"
  fi
  if [ "$USE_SUBS" = 1 ]; then
    SUB_FILE="$(find "$MEDIA" -maxdepth 1 -name '*.srt' -print | head -1)"
  fi
else
  VIDEO="$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")"
  TITLE="$(basename "${SRC%.*}")"
fi

[ -n "$TITLE" ] || TITLE="$(basename "${VIDEO%.*}")"
[ -n "$SOURCE_URL" ] || { [ "$IS_URL" = 1 ] && SOURCE_URL="$SRC"; } || true
[ -n "$NAME" ] || NAME="$(slugify "$TITLE")"
[ -n "$NAME" ] || NAME="video-skill"
SLUG="$(slugify "$NAME")"

DURATION="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO" 2>/dev/null | cut -d. -f1)"
case "$DURATION" in ''|*[!0-9]*) DURATION=0 ;; esac
[ "$DURATION" -gt 0 ] || die "could not read a duration from $VIDEO — is it a valid video?"

HAS_VIDEO=0; HAS_AUDIO=0
ffprobe -v error -select_streams v:0 -show_entries stream=codec_type -of csv=p=0 "$VIDEO" 2>/dev/null \
  | grep -q video && HAS_VIDEO=1
ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 "$VIDEO" 2>/dev/null \
  | grep -q audio && HAS_AUDIO=1
[ "$HAS_VIDEO" = 1 ] || [ "$HAS_AUDIO" = 1 ] || die "$VIDEO has neither a video nor an audio stream"

OUT="$SKILLS_DIR/$SLUG"
if [ -e "$OUT" ]; then
  warn "$OUT exists — moving it to $OUT.bak-$RUN_ID"
  mv "$OUT" "$OUT.bak-$RUN_ID"
fi
mkdir -p "$OUT/frames"
log "skill: $OUT  (source ${DURATION}s)"

# ---------------------------------------------------------------- 2. frames
if [ "$HAS_VIDEO" = 0 ]; then
  warn "audio-only source — skipping frame extraction"
  MODE=none
elif [ "$MODE" = auto ]; then
  if [ "$DURATION" -le 1800 ]; then MODE=scene; else MODE=uniform; fi
fi

TS_FILE="$WORK/timestamps.txt"
: > "$TS_FILE"

if [ "$MODE" = scene ]; then
  log "detecting scene changes (threshold $THRESHOLD)"
  ffmpeg -nostdin -hide_banner -v error -i "$VIDEO" \
    -vf "select='gt(scene,$THRESHOLD)',metadata=print:file=-" -an -f null - 2>/dev/null \
    | sed -n 's/.*pts_time:\([0-9.]*\).*/\1/p' > "$WORK/scenes.txt" || true
  log "  $(wc -l < "$WORK/scenes.txt" | tr -d ' ') scene cuts found"
fi

# Pick the final timestamp list: scene cuts thinned to $FRAMES, topped up with an
# even spread when there are too few. Always anchor one frame near the start.
python3 - "$WORK/scenes.txt" "$DURATION" "$FRAMES" > "$TS_FILE" <<'PY'
import os, sys
scenes_path, duration, want = sys.argv[1], float(sys.argv[2]), int(sys.argv[3])
scenes = []
if os.path.exists(scenes_path):
    with open(scenes_path) as fh:
        for line in fh:
            line = line.strip()
            if line:
                try: scenes.append(float(line))
                except ValueError: pass
scenes = [t for t in scenes if 0.0 <= t <= duration]

def spread(seq, n):
    if len(seq) <= n: return list(seq)
    step = (len(seq) - 1) / (n - 1) if n > 1 else 0
    return [seq[round(i * step)] for i in range(n)]

picked = spread(sorted(set(scenes)), want)
if len(picked) < want:
    gaps = want - len(picked)
    uniform = [duration * (i + 0.5) / (gaps + 1) for i in range(gaps + 1)]
    picked += uniform
anchor = min(1.0, duration / 20.0)
picked.append(anchor)

final, seen = [], []
for t in sorted(picked):
    t = max(0.0, min(t, max(duration - 0.1, 0.0)))
    if any(abs(t - s) < 0.75 for s in seen):   # drop near-duplicates
        continue
    seen.append(t); final.append(t)
for t in spread(final, want):
    print(f"{t:.3f}")
PY

FRAME_COUNT=0
printf '# Keyframes — %s\n\n' "$TITLE" > "$OUT/frames/index.md"
if [ "$HAS_VIDEO" = 1 ]; then
  printf 'Frame | Timestamp | File\n----- | --------- | ----\n' >> "$OUT/frames/index.md"
fi

while read -r T; do
  [ -n "$T" ] || continue
  [ "$HAS_VIDEO" = 1 ] || break
  FRAME_COUNT=$((FRAME_COUNT + 1))
  N="$(printf '%03d' "$FRAME_COUNT")"
  HMS="$(python3 -c 'import sys;t=float(sys.argv[1]);print("%02d:%02d:%06.3f"%(t//3600,(t%3600)//60,t%60))' "$T")"
  if ffmpeg -nostdin -hide_banner -v error -ss "$T" -i "$VIDEO" \
       -frames:v 1 -vf "scale=$WIDTH:-2:flags=lanczos" -q:v 3 \
       "$OUT/frames/frame-$N.jpg" 2>/dev/null && [ -s "$OUT/frames/frame-$N.jpg" ]; then
    printf '%s | %s | frames/frame-%s.jpg\n' "$N" "$HMS" "$N" >> "$OUT/frames/index.md"
  else
    warn "frame at ${T}s failed, skipping"
    rm -f "$OUT/frames/frame-$N.jpg"
    FRAME_COUNT=$((FRAME_COUNT - 1))
  fi
done < "$TS_FILE"

if [ "$HAS_VIDEO" = 1 ]; then
  log "extracted $FRAME_COUNT frames (mode: $MODE)"
  [ "$FRAME_COUNT" -gt 0 ] || die "no frames could be extracted — the video stream may be unreadable"
else
  printf '_Audio-only source: no frames._\n' >> "$OUT/frames/index.md"
fi

# ---------------------------------------------------------------- 3. transcript
TRANSCRIPT="$OUT/transcript.md"
TRANSCRIPT_SOURCE=""

srt_to_md() {   # $1 = srt file, $2 = out md
  python3 - "$1" "$2" "$TITLE" <<'PY'
import re, sys
src, dst, title = sys.argv[1], sys.argv[2], sys.argv[3]
raw = open(src, encoding="utf-8", errors="replace").read()
blocks = re.split(r"\n\s*\n", raw.strip())
rows, last = [], None
for b in blocks:
    lines = [l for l in b.splitlines() if l.strip()]
    if not lines: continue
    if lines[0].strip().isdigit(): lines = lines[1:]
    if not lines or "-->" not in lines[0]: continue
    start = lines[0].split("-->")[0].strip().replace(",", ".")[:8]
    text = " ".join(lines[1:])
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    if not text or text == last: continue
    last = text
    rows.append((start, text))
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(f"# Transcript — {title}\n\n")
    for start, text in rows:
        fh.write(f"**[{start}]** {text}\n\n")
print(len(rows))
PY
}

[ -n "$SUBS_OVERRIDE" ] && SUB_FILE="$SUBS_OVERRIDE"

if [ -n "$SUB_FILE" ] && [ -s "$SUB_FILE" ]; then
  log "using the video's own captions: $(basename "$SUB_FILE")"
  if srt_to_md "$SUB_FILE" "$TRANSCRIPT" >/dev/null; then
    TRANSCRIPT_SOURCE="captions ($(basename "$SUB_FILE"))"
  fi
fi

if [ -z "$TRANSCRIPT_SOURCE" ] && [ "$HAS_AUDIO" = 0 ]; then
  warn "no audio stream — transcript will be empty"
  printf '# Transcript — %s\n\n_No audio track in the source._\n' "$TITLE" > "$TRANSCRIPT"
  TRANSCRIPT_SOURCE="none (no audio)"
fi

if [ -z "$TRANSCRIPT_SOURCE" ]; then
  log "extracting audio"
  AUDIO="$MEDIA/audio.wav"
  if ! ffmpeg -nostdin -hide_banner -v error -i "$VIDEO" -vn -ac 1 -ar 16000 -c:a pcm_s16le "$AUDIO" 2>/dev/null \
     || [ ! -s "$AUDIO" ]; then
    warn "ffmpeg could not decode the audio — transcript will be empty"
    printf '# Transcript — %s\n\n_Audio stream present but could not be decoded._\n' "$TITLE" > "$TRANSCRIPT"
    TRANSCRIPT_SOURCE="none (audio unreadable)"
  elif python3 -c 'import faster_whisper' 2>/dev/null; then
    log "transcribing with faster-whisper ($MODEL) — first run downloads the model"
    cat > "$WORK/_transcribe.py" <<'PY'
import sys
from faster_whisper import WhisperModel
audio, dst, title, model_size, lang = sys.argv[1:6]
model = WhisperModel(model_size, device="cpu", compute_type="int8")
segments, info = model.transcribe(audio, language=(lang or None), vad_filter=True,
                                  beam_size=5, condition_on_previous_text=False)
def hms(t): return "%02d:%02d:%02d" % (t // 3600, (t % 3600) // 60, t % 60)
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(f"# Transcript — {title}\n\n")
    fh.write(f"_Language: {info.language} (confidence {info.language_probability:.2f}) · "
             f"model: {model_size}_\n\n")
    n = 0
    for s in segments:
        text = s.text.strip()
        if not text: continue
        fh.write(f"**[{hms(s.start)}]** {text}\n\n")
        n += 1
print(n)
PY
    if ( cd "$WORK" && python3 "$WORK/_transcribe.py" "$AUDIO" "$TRANSCRIPT" "$TITLE" "$MODEL" "$LANG" ) \
         >/dev/null 2>"$WORK/whisper.log"; then
      TRANSCRIPT_SOURCE="faster-whisper ($MODEL)"
    else
      warn "faster-whisper failed: $(grep -v '^ ' "$WORK/whisper.log" | tail -1)"
      warn "  full log: $WORK/whisper.log"
      KEEP_LOG=1
    fi
  fi

  if [ -z "$TRANSCRIPT_SOURCE" ] && [ -n "${OPENAI_API_KEY:-}" ] && command -v curl >/dev/null; then
    log "falling back to the OpenAI transcription API"
    SIZE_MB=$(( $(wc -c < "$MEDIA/audio.wav") / 1048576 ))
    if [ "$SIZE_MB" -lt 24 ]; then
      if curl -sS -f https://api.openai.com/v1/audio/transcriptions \
           -H "Authorization: Bearer $OPENAI_API_KEY" \
           -F file=@"$MEDIA/audio.wav" -F model=whisper-1 -F response_format=srt \
           -o "$MEDIA/api.srt" && [ -s "$MEDIA/api.srt" ]; then
        srt_to_md "$MEDIA/api.srt" "$TRANSCRIPT" >/dev/null && TRANSCRIPT_SOURCE="OpenAI whisper-1"
      fi
    else
      warn "audio is ${SIZE_MB}MB, over the API's 25MB limit — skipping"
    fi
  fi
fi

if [ -z "$TRANSCRIPT_SOURCE" ]; then
  if python3 -c 'import faster_whisper' 2>/dev/null; then
    warn "faster-whisper is installed but could not run — see the log above."
    warn "  A first run must reach huggingface.co to fetch the '$MODEL' model."
    REASON="faster-whisper is installed but failed to run (model download or decode error)"
  else
    warn "no transcription backend. Install one:  pip3 install --user faster-whisper"
    REASON="no captions were available and no ASR backend is installed"
  fi
  printf '# Transcript — %s\n\n_Transcription unavailable: %s._\n\nFix the cause and re-run `video-to-skill.sh` to fill this in.\n' \
    "$TITLE" "$REASON" > "$TRANSCRIPT"
  TRANSCRIPT_SOURCE="unavailable"
fi
log "transcript: $TRANSCRIPT_SOURCE"

# ---------------------------------------------------------------- 4. metadata
V2S_TITLE="$TITLE" V2S_SLUG="$SLUG" V2S_SOURCE="${SOURCE_URL:-$SRC}" \
V2S_UPLOADER="$UPLOADER" V2S_DATE="$UPLOAD_DATE" V2S_DURATION="$DURATION" \
V2S_FRAMES="$FRAME_COUNT" V2S_MODE="$MODE" V2S_TSRC="$TRANSCRIPT_SOURCE" \
V2S_DESC="$DESCRIPTION" V2S_MODEL="$MODEL" \
python3 - "$OUT/metadata.json" <<'PY'
import json, os, sys, datetime
env = os.environ.get
json.dump({
    "title": env("V2S_TITLE", ""),
    "slug": env("V2S_SLUG", ""),
    "source": env("V2S_SOURCE", ""),
    "uploader": env("V2S_UPLOADER", ""),
    "upload_date": env("V2S_DATE", ""),
    "duration_seconds": int(env("V2S_DURATION", "0") or 0),
    "frames": int(env("V2S_FRAMES", "0") or 0),
    "frame_mode": env("V2S_MODE", ""),
    "transcript_source": env("V2S_TSRC", ""),
    "whisper_model": env("V2S_MODEL", ""),
    "extracted_at": datetime.datetime.now(datetime.timezone.utc)
                     .strftime("%Y-%m-%dT%H:%M:%SZ"),
    "description": (env("V2S_DESC", "") or "")[:4000],
}, open(sys.argv[1], "w", encoding="utf-8"), indent=2, ensure_ascii=False)
PY

# ---------------------------------------------------------------- 5. skill scaffold
DUR_HMS="$(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))"
cat > "$OUT/SKILL.md" <<EOF
---
name: $SLUG
description: TODO — one or two sentences on what this skill gives Claude and when to load it. Name the subject and the trigger words a user would actually type.
---

<!-- SCAFFOLD: written by .claude/scripts/video-to-skill.sh. Replace every TODO.
     Read transcript.md end to end and view the frames before writing. -->

# ${TITLE}

| | |
|---|---|
| Source | ${SOURCE_URL:-$SRC} |
| Author | ${UPLOADER:-unknown} |
| Duration | $DUR_HMS |
| Captured | $(date -u +%Y-%m-%d) |
| Transcript | $TRANSCRIPT_SOURCE |
| Frames | $FRAME_COUNT ($MODE) |

## What this covers

TODO

## Key points

TODO — the claims, steps or rules worth reusing, each with a \`[hh:mm:ss]\` citation.

## Walkthrough

TODO — if the video demonstrates a procedure, write the steps here and reference
the frame that shows each one, e.g. \`frames/frame-004.jpg\` at \`[00:01:12]\`.

## Verbatim quotes

TODO — only lines worth quoting exactly, with timestamps. Delete if none.

## Caveats

TODO — what the video asserts without evidence, what is dated, what to verify.

## Files

- \`transcript.md\` — timestamped transcript ($TRANSCRIPT_SOURCE)
- \`frames/index.md\` — frame → timestamp table
- \`frames/\` — $FRAME_COUNT keyframes
- \`metadata.json\` — provenance
EOF

printf '\n'
log "done"
printf '%s\n' "$OUT"
