---
name: security-review
description: Security checklist for OpenStudio. Use when touching API-key handling, the /api proxy routes or middleware, file uploads, rendering model or user output, the Electron main/preload process, install scripts, or dependencies.
metadata:
  origin: Adapted from ECC (github.com/affaan-m/ECC, MIT). Trimmed to OpenStudio's stack; Electron and BYOK sections added.
---

# Security Review

OpenStudio is a bring-your-own-key app: users paste a MuAPI key, the client stores it, and
Next.js API routes or `middleware.js` forward requests to MuAPI. It also ships as an Electron
app and installs via `curl | bash` / PowerShell scripts. Most risk sits in those four places.

## When to Activate

- Changing how the MuAPI key is read, stored, sent, or displayed
- Adding or changing a route under `app/api/` or the rewrite rules in `middleware.js`
- Handling file uploads (`upload-binary`, `get_upload_url`)
- Rendering text or HTML that came from a model, a user, or a remote API
- Editing `electron/main.js` or `electron/preload.js`
- Editing `install.sh`, `install.ps1`, `Dockerfile`, or adding a dependency

## 1. The User's API Key

- [ ] Never hardcode a key, even a test key. Never commit `.env*` files with real values.
- [ ] Never log the key: no `console.log(headers)`, `console.log(config)` or error objects
      that carry request headers. Redact before logging.
- [ ] The key is only ever sent to MuAPI. No other host, analytics call, or error reporter
      receives it.
- [ ] Error messages shown to the user must not echo the key or full request headers.
- [ ] The key is stored in `localStorage`, so any XSS can steal it. That makes section 3
      (XSS) the most important section for this app.

## 2. Proxy Routes (`app/api/**`, `middleware.js`)

- [ ] The upstream host is fixed (`https://api.muapi.ai`). Never build the target URL from
      a user-supplied host, full URL, or header — that is SSRF.
- [ ] Path segments from `[[...path]]` are appended to the fixed base only. Reject `..`,
      `//`, `@`, and absolute URLs in the path.
- [ ] Forward only the headers MuAPI needs. Do not forward cookies or `Host`.
- [ ] Return generic errors to the client; keep upstream error details in server logs
      only, without the key.

```js
// FAIL: target host comes from the request
const target = new URL(req.nextUrl.searchParams.get('url'));

// PASS: fixed base, user input only as a path under it
const target = new URL(url.pathname + url.search, 'https://api.muapi.ai');
```

## 3. XSS (Protects the Stored Key)

- [ ] Prefer plain JSX text rendering. React escapes it.
- [ ] Any `dangerouslySetInnerHTML` with model output, scripts, or user text must go
      through a sanitizer (e.g. DOMPurify) with a tight allow-list.
- [ ] Never `eval`, `new Function`, or inject `<script>` from model output.
- [ ] Links from model or user output: allow only `http:`/`https:`; block `javascript:`.
- [ ] Media URLs returned by models go into `src` attributes only, never into HTML strings.

```js
// FAIL
<div dangerouslySetInnerHTML={{ __html: modelReply }} />

// PASS
<div>{modelReply}</div>
```

## 4. File Uploads

- [ ] Check size and MIME type server-side, not just in the browser.
- [ ] Allow-list types (image/video/audio formats the feature needs); do not block-list.
- [ ] Do not trust the client file name for paths. Never write uploads to disk using it.

## 5. Electron (`electron/main.js`, `electron/preload.js`)

- [ ] Keep `contextIsolation: true` and `nodeIntegration: false`.
- [ ] `webSecurity: false` disables same-origin protection. Treat it as debt: document why
      it is needed and prefer fixing the underlying CORS issue (e.g. route through the
      local API proxy) over keeping it off.
- [ ] `preload.js` exposes narrow, named functions via `contextBridge`. Never expose
      `ipcRenderer`, `require`, `fs`, or `shell` wholesale.
- [ ] Validate every IPC message argument in the main process.
- [ ] Open external links with `shell.openExternal` only for `https:` URLs, and block
      in-app navigation to remote origins (`will-navigate`, `setWindowOpenHandler`).

## 6. Install Scripts and Dependencies

- [ ] `install.sh` / `install.ps1` download only from this project's own repo, over HTTPS.
- [ ] No `sudo` or admin elevation unless unavoidable, and say so to the user.
- [ ] Commit `package-lock.json`; use `npm ci` in CI and Docker.
- [ ] Run `npm audit` after adding or bumping a dependency. Check that a new package is the
      real one (name, publisher, weekly downloads) — typosquats target AI/media tooling.

## Report Format

List each finding as: file:line — what is wrong — concrete failure scenario — fix.
Skip checklist items that pass. Say plainly if nothing was found.
