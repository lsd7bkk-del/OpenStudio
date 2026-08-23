# Stack setup reference

Pick one stack for the whole build (don't mix, e.g., don't add Bootstrap classes to a React/Tailwind build). These snippets are adapted from the [screenshot-to-code](https://github.com/abi/screenshot-to-code) system prompt, which is a well-tested source for "what actually works when rendered standalone, no build step."

## html_tailwind (default when no project context exists)

Plain HTML + Tailwind, no JS framework.

```html
<script src="https://cdn.tailwindcss.com"></script>
```

## html_css

Plain HTML, CSS, and vanilla JS only. Do **not** pull in Tailwind or any CSS framework for this one — that's the point of picking it.

## bootstrap

```html
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
```

## react_tailwind

For a standalone single-file React build (no bundler):

```html
<script src="https://cdn.jsdelivr.net/npm/react@18.0.0/umd/react.development.js"></script>
<script src="https://cdn.jsdelivr.net/npm/react-dom@18.0.0/umd/react-dom.development.js"></script>
<script src="https://unpkg.com/@babel/standalone@7.25.6/babel.min.js"></script>
<script src="https://cdn.tailwindcss.com"></script>
```

Pin that exact Babel standalone version (`7.25.6`). The unversioned `https://unpkg.com/@babel/standalone/babel.min.js` URL now resolves to Babel 8, whose automatic JSX runtime injects an `import` statement that breaks in-browser transforms — it will fail silently or throw at runtime. Never use `https://cdn.babeljs.io/babel.min.js`; it's the wrong version.

If you're instead working inside an existing React project (Next.js, Vite, CRA, etc.) rather than producing a standalone file, skip all of this and just write a normal component using the project's existing build pipeline and styling conventions — the CDN/no-bundler setup above is only for producing something that runs by opening a single HTML file directly.

## ionic_tailwind

```html
<script type="module" src="https://cdn.jsdelivr.net/npm/@ionic/core/dist/ionic/ionic.esm.js"></script>
<script nomodule src="https://cdn.jsdelivr.net/npm/@ionic/core/dist/ionic/ionic.js"></script>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@ionic/core/css/ionic.bundle.css" />
<script src="https://cdn.tailwindcss.com"></script>
```

Icons — use Ionicons instead of Font Awesome for this stack, placed near the end of `<body>`:

```html
<script type="module">
  import ionicons from 'https://cdn.jsdelivr.net/npm/ionicons/+esm'
</script>
<script nomodule src="https://cdn.jsdelivr.net/npm/ionicons/dist/esm/ionicons.min.js"></script>
<link href="https://cdn.jsdelivr.net/npm/ionicons/dist/collection/components/icon/icon.min.css" rel="stylesheet">
```

## vue_tailwind

```html
<script src="https://registry.npmmirror.com/vue/3.3.11/files/dist/vue.global.js"></script>
<script src="https://cdn.tailwindcss.com"></script>
```

Use the global build:

```html
<div id="app">{{ message }}</div>
<script>
  const { createApp, ref } = Vue
  createApp({
    setup() {
      const message = ref('Hello vue!')
      return { message }
    }
  }).mount('#app')
</script>
```

## Across all stacks

- Google Fonts (or any other publicly-hosted font) are fair game when the design calls for a specific typeface.
- For icons, use Font Awesome unless you're on the Ionic stack (which uses Ionicons instead):
  ```html
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css">
  ```
