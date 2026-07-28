// Scope a committed dark color-scheme to the /talk route only. The
// <meta name="color-scheme" content="dark"> this emits tells force-dark
// browser extensions the page is already dark, so well-behaved ones leave it
// alone instead of re-tinting it.
export const metadata = {
  title: "A short conversation",
};

export const viewport = {
  colorScheme: "dark",
  themeColor: "#0f1211",
};

export default function TalkLayout({ children }) {
  return children;
}
