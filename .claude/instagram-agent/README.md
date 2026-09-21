# Instagram agent skill pack

Source: https://github.com/Jakeschincariol/instagram-agent-skill (MIT, © Jake Schincariol)

The 13 skills (`ig-audit`, `ig-caption`, `ig-carousel`, `ig-comment`, `ig-dm`,
`ig-human`, `ig-plan`, `ig-profile`, `ig-reel`, `ig-reply`, `ig-repurpose`,
`ig-story`, `ig-viral`) are installed as project skills under
`.claude/skills/`, so `/ig-reel`, `/ig-caption`, etc. work in any Claude Code
session on this repo.

`templates/voice.md` here is the pack's voice-profile template. Several
skills (`ig-reel`, `ig-plan`) read a personalized copy from
`~/.claude/instagram/voice.md` if present — copy and edit this template
there to give the skills your own voice.
