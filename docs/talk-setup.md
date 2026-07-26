# Option C — the hosted one-click conversation (`/talk`)

A fully self-hosted version of the conversation, built into OpenStudio. Your
client opens one link, clicks **Begin**, and talks to Claude right there — no
copy-paste, no Claude account, and the prompt is never visible. The interviewer
persona lives server-side; the browser only ever sees the chat.

## What was added

| File | Role |
|------|------|
| `app/talk/page.js` | The client-facing chat page (route: **`/talk`**) |
| `app/api/talk/route.js` | Server route that holds the hidden prompt + your API key and calls Claude |

## One-time setup

1. **Get an Anthropic API key** from [console.anthropic.com](https://console.anthropic.com).
2. **Set it as an environment variable** where OpenStudio runs:

   ```bash
   # local dev — add to .env.local (never commit real keys)
   ANTHROPIC_API_KEY=sk-ant-...
   ```

   On a host (Vercel, a container, etc.), set `ANTHROPIC_API_KEY` in that
   platform's environment/secrets settings.
3. Run the app (`npm run dev`, or your deploy) and open **`/talk`**.

If the key isn't set, the page loads but the conversation replies with a polite
"not configured yet" message — set the key and it works immediately.

## How it works

- The client posts the running conversation to `/api/talk`.
- The route prepends the hidden interviewer persona as the `system` prompt,
  calls the Anthropic Messages API with **your** key, and returns only Claude's
  next message. The persona, the key, and the model choice never reach the
  browser.
- Claude greets the visitor first, holds a natural ~15-minute conversation
  (reading their taste and sensibility indirectly), and ends by reflecting back
  what it understood. The visitor taps **Copy conversation** and sends it to you.

## Cost & notes

- Each conversation runs on your key — roughly a few cents to ~20 cents,
  depending on length. The model is `claude-opus-5` at low effort for a snappy,
  low-cost chat; the system prompt is cached across turns to keep costs down.
- The route caps conversation length and input size defensively. It is a public
  endpoint once deployed — if you expect volume, put it behind your own rate
  limiting or a simple access gate.
- Outbound access to `api.anthropic.com` must be allowed by the environment's
  network policy for the route to work.
- Prefer the no-code route? See [`claude-project-setup.md`](./claude-project-setup.md)
  (Option B) — a Claude Project with the same hidden prompt.
