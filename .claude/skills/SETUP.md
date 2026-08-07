# Social Media Skills — Setup

This folder contains the [social-media-skills](https://github.com/charlie947/social-media-skills)
library by Charlie Hills — 17 Claude skills behind a content system with 350k+ followers
across LinkedIn, Instagram, Substack, X, and YouTube. MIT-licensed.

## The 17 skills

| Category | Skills |
|---|---|
| **Foundation** | `voice-builder`, `newsletter-voice`, `niche-research`, `profile-optimizer` |
| **Writing & formatting** | `post-writer`, `post-formatter`, `hook-generator`, `post-scorer` |
| **Visual / video** | `graphic-designer`, `gemini-carousel`, `gemini-infographic`, `youtube-thumbnail`, `reels-scripting` |
| **Analytics & community** | `analytics-dashboard`, `content-matrix`, `pinned-comment`, `quote-post` |

**Start with `voice-builder`.** It runs a short interview plus 3–5 writing samples and
produces `about-me.md` and `voice.md`. Every other skill reads those two files before
drafting a single line, so run it first.

Trigger any skill by describing the task in plain language, e.g. "write a LinkedIn post
about X", "score my post", "build me a carousel".

---

## Install globally on your own machine (permanent)

On a local Claude Code install, `~/.claude/skills/` persists forever and makes these
skills available in **every** project. Run this once.

### macOS / Linux

```bash
# 1. Clone the library
git clone https://github.com/charlie947/social-media-skills.git

# 2. Copy all 17 skills into your personal skills folder
mkdir -p ~/.claude/skills
cp -R social-media-skills/skills/* ~/.claude/skills/

# 3. Verify (should list 17 folders)
ls ~/.claude/skills
```

### Windows (PowerShell)

```powershell
git clone https://github.com/charlie947/social-media-skills.git
New-Item -ItemType Directory -Force -Path "$HOME\.claude\skills"
Copy-Item -Recurse social-media-skills\skills\* "$HOME\.claude\skills\"
Get-ChildItem "$HOME\.claude\skills"
```

Restart Claude Code (or run `/doctor`) and the skills will be picked up.

### Updating later

```bash
cd social-media-skills && git pull
cp -R skills/* ~/.claude/skills/
```

---

## Per-repo install (Claude Code on the web)

In a remote/web session the home directory (`~/.claude/`) is ephemeral and gets wiped
between sessions, so global installs there don't persist. The durable approach on the web
is to commit the skills into each repo's `.claude/skills/` folder — which is exactly how
they're installed in this repo. They reload automatically every session.

To add them to another repo:

```bash
git clone https://github.com/charlie947/social-media-skills.git
mkdir -p /path/to/your-repo/.claude/skills
cp -R social-media-skills/skills/* /path/to/your-repo/.claude/skills/
# then commit them to that repo
```

---

## API tokens (optional)

Most skills work with no setup. A few use external services for their live-data steps and
need environment variables set — the skill still loads without them, you just can't run
the integration step:

| Skill | Needs |
|---|---|
| `reels-scripting` | `APIFY_API_TOKEN`, `GOOGLE_AI_API_KEY` |
| `post-scorer` | Apify (for pulling your post history) |
| `niche-research` | Claude for Chrome extension (live browsing) |

Set these in your shell profile or Claude Code environment as needed.
