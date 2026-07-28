"use client";

import { useCallback, useEffect, useRef, useState } from "react";

// A single hidden kickoff turn so Claude greets the visitor first.
const KICKOFF = "Hello.";

export default function TalkPage() {
  const [started, setStarted] = useState(false);
  const [messages, setMessages] = useState([]); // {role, content} — visible turns only
  const [thinking, setThinking] = useState(false);
  const [error, setError] = useState("");
  const [input, setInput] = useState("");
  const [copied, setCopied] = useState(false);

  const historyRef = useRef([]); // full history incl. hidden kickoff, sent to the API
  const threadRef = useRef(null);
  const inputRef = useRef(null);

  const scrollDown = useCallback(() => {
    requestAnimationFrame(() => {
      if (threadRef.current) threadRef.current.scrollTop = threadRef.current.scrollHeight;
    });
  }, []);

  const send = useCallback(async (history) => {
    setThinking(true);
    setError("");
    try {
      const res = await fetch("/api/talk", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ messages: history }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "Something went wrong.");
      const reply = { role: "assistant", content: data.text };
      historyRef.current = [...history, reply];
      setMessages((m) => [...m, reply]);
    } catch (e) {
      setError(e.message || "Something went wrong. Please try again.");
    } finally {
      setThinking(false);
      scrollDown();
    }
  }, [scrollDown]);

  const begin = useCallback(() => {
    setStarted(true);
    const history = [{ role: "user", content: KICKOFF }];
    historyRef.current = history;
    send(history);
    setTimeout(() => inputRef.current && inputRef.current.focus(), 300);
  }, [send]);

  const submit = useCallback(() => {
    const text = input.trim();
    if (!text || thinking) return;
    const userTurn = { role: "user", content: text };
    const history = [...historyRef.current, userTurn];
    historyRef.current = history;
    setMessages((m) => [...m, userTurn]);
    setInput("");
    send(history);
    scrollDown();
  }, [input, thinking, send, scrollDown]);

  const onKeyDown = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      submit();
    }
  };

  const copyTranscript = useCallback(() => {
    const text = messages
      .map((m) => (m.role === "assistant" ? m.content : "— " + m.content))
      .join("\n\n");
    const done = () => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2200);
    };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(done, done);
    } else done();
  }, [messages]);

  useEffect(() => { scrollDown(); }, [messages, thinking, scrollDown]);

  return (
    <div className="page">
      {!started ? (
        <div className="intro">
          <div className="eyebrow">A short conversation</div>
          <h1>Before we begin, a short conversation.</h1>
          <p>
            It takes about fifteen minutes, and it isn&rsquo;t a form. It simply
            talks with you — one thing at a time — to understand you and your work
            properly. There are no right answers; the candid, unpolished version is
            the useful one.
          </p>
          <button className="btn primary" onClick={begin}>Begin the conversation</button>
          <p className="fineprint">
            When you&rsquo;re done, use &ldquo;Copy conversation&rdquo; and send it back.
          </p>
        </div>
      ) : (
        <div className="chat">
          <header className="bar">
            <span className="dot" aria-hidden="true" />
            <span className="title">In conversation</span>
            <button className="copy" onClick={copyTranscript}>
              {copied ? "Copied ✓" : "Copy conversation"}
            </button>
          </header>

          <div className="thread" ref={threadRef}>
            {messages.map((m, i) => (
              <div key={i} className={"row " + (m.role === "assistant" ? "them" : "me")}>
                {m.role === "assistant" && <div className="avatar" aria-hidden="true">&#9680;</div>}
                <div className="bubble">{renderText(m.content)}</div>
              </div>
            ))}
            {thinking && (
              <div className="row them">
                <div className="avatar" aria-hidden="true">&#9680;</div>
                <div className="bubble">
                  <span className="typing"><i /><i /><i /></span>
                </div>
              </div>
            )}
            {error && <div className="error">{error} <button onClick={() => send(historyRef.current)}>Retry</button></div>}
          </div>

          <div className="composer">
            <textarea
              ref={inputRef}
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={onKeyDown}
              placeholder={thinking ? "…" : "Type your reply…"}
              rows={1}
              disabled={thinking}
              aria-label="Your reply"
            />
            <button className="send" onClick={submit} disabled={thinking || !input.trim()} aria-label="Send">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14M13 6l6 6-6 6" /></svg>
            </button>
          </div>
        </div>
      )}

      <style jsx global>{`
        html { color-scheme: dark; }
        html, body { margin: 0; background: #0f1211; }
        /* The app's global ambient layer (body::before) breathes its opacity on
           a 16s loop and overlays this full-screen page — hide it on /talk so
           the text never fades. */
        body::before { display: none !important; }
      `}</style>
      <style jsx>{`
        .page {
          --ground: #0f1211; --surface: #242b27; --surface-2: #2d352f;
          --ink: #f4f5f0; --muted: #c3c7bd; --line: #3c443d;
          --accent: #5ec4b9; --accent-soft: #244a44;
          --serif: "Iowan Old Style", "Palatino Linotype", Palatino, "Book Antiqua", Georgia, serif;
          --sans: var(--font-inter), system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
          color-scheme: dark;
          position: relative; z-index: 1;
          min-height: 100vh; background: var(--ground); color: var(--ink);
          font-family: var(--sans); display: flex; flex-direction: column;
        }

        /* Intro */
        .intro { max-width: 620px; margin: 0 auto; padding: 14vh 24px 40px; }
        .eyebrow { font-size: 12px; letter-spacing: .18em; text-transform: uppercase; color: var(--accent); font-weight: 600; margin-bottom: 18px; }
        h1 { font-family: var(--serif); font-weight: 600; font-size: clamp(30px, 6vw, 44px); line-height: 1.08; letter-spacing: -.01em; margin: 0 0 18px; text-wrap: balance; }
        .intro p { font-size: 17.5px; line-height: 1.6; color: var(--muted); max-width: 54ch; margin: 0 0 28px; }
        .fineprint { font-size: 14px !important; margin-top: 22px !important; }
        .btn { font-family: var(--sans); font-size: 16px; font-weight: 600; padding: 13px 24px; border-radius: 12px; border: 1px solid var(--line); background: var(--surface-2); color: var(--ink); cursor: pointer; transition: transform .12s, border-color .2s; }
        .btn:hover { transform: translateY(-1px); border-color: var(--accent); }
        .btn.primary { background: var(--accent); color: #06110f; border-color: transparent; }

        /* Chat */
        .chat { display: flex; flex-direction: column; height: 100vh; max-width: 720px; width: 100%; margin: 0 auto; }
        .bar { display: flex; align-items: center; gap: 10px; padding: 16px 20px; border-bottom: 1px solid var(--line); background: var(--ground); }
        .dot { width: 9px; height: 9px; border-radius: 50%; background: var(--accent); box-shadow: 0 0 0 4px var(--accent-soft); }
        .title { font-family: var(--serif); font-size: 17px; font-weight: 600; flex: 1; }
        .copy { font-family: var(--sans); font-size: 13px; font-weight: 600; padding: 8px 13px; border-radius: 9px; border: 1px solid var(--line); background: var(--surface-2); color: var(--ink); cursor: pointer; }
        .copy:hover { border-color: var(--accent); }

        .thread { flex: 1; overflow-y: auto; padding: 24px 20px 8px; display: flex; flex-direction: column; gap: 16px; }
        .row { display: flex; gap: 12px; animation: rise .4s cubic-bezier(.22,1,.36,1) both; }
        .row.me { flex-direction: row-reverse; }
        @keyframes rise { from { opacity: 0; transform: translateY(8px); } }
        @media (prefers-reduced-motion: reduce) { .row { animation: none; } }
        .avatar { flex: 0 0 34px; width: 34px; height: 34px; border-radius: 50%; background: var(--accent); color: #06110f; display: grid; place-items: center; font-family: var(--serif); font-size: 15px; margin-top: 2px; }
        .bubble { background: var(--surface); border: 1px solid var(--line); border-radius: 15px; border-top-left-radius: 5px; padding: 12px 16px; font-size: 16px; line-height: 1.55; max-width: 80%; box-shadow: 0 1px 3px rgba(0,0,0,.12); white-space: pre-wrap; word-wrap: break-word; }
        .me .bubble { background: var(--accent-soft); border-color: transparent; border-top-left-radius: 15px; border-top-right-radius: 5px; }
        .bubble :global(strong) { font-weight: 600; }
        .bubble :global(.h) { font-family: var(--serif); font-weight: 600; display: block; margin: 10px 0 2px; }

        .typing { display: inline-flex; gap: 4px; padding: 4px 0; }
        .typing i { width: 7px; height: 7px; border-radius: 50%; background: var(--muted); animation: blink 1.2s infinite; }
        .typing i:nth-child(2) { animation-delay: .2s; } .typing i:nth-child(3) { animation-delay: .4s; }
        @keyframes blink { 0%,60%,100% { opacity: .25; transform: translateY(0); } 30% { opacity: 1; transform: translateY(-3px); } }

        .error { align-self: center; font-size: 14px; color: #b5432e; background: var(--surface); border: 1px solid var(--line); padding: 8px 14px; border-radius: 10px; }
        .error button { margin-left: 8px; background: none; border: 0; color: var(--accent); font-weight: 600; cursor: pointer; text-decoration: underline; }

        .composer { display: flex; gap: 10px; align-items: flex-end; padding: 14px 20px 20px; background: var(--ground); border-top: 1px solid var(--line); }
        textarea { flex: 1; resize: none; border: 1.5px solid var(--line); background: var(--surface); color: var(--ink); font-family: var(--sans); font-size: 16px; line-height: 1.5; border-radius: 14px; padding: 12px 16px; max-height: 160px; outline: none; box-shadow: 0 1px 3px rgba(0,0,0,.18); }
        textarea:focus { border-color: var(--accent); box-shadow: 0 0 0 3px var(--accent-soft); }
        textarea::placeholder { color: var(--muted); }
        .send { flex: 0 0 auto; width: 46px; height: 46px; border-radius: 13px; border: 0; background: var(--accent); color: #06110f; cursor: pointer; display: grid; place-items: center; transition: opacity .2s, transform .12s; }
        .send:hover:not(:disabled) { transform: translateY(-1px); }
        .send:disabled { opacity: .35; cursor: not-allowed; }
        .send svg { width: 20px; height: 20px; }
      `}</style>
    </div>
  );
}

// Minimal, safe Markdown-ish rendering: **bold**, ## headings, and paragraphs.
// No raw HTML is injected — we build React nodes from plain text.
function renderText(text) {
  const lines = String(text).split("\n");
  const nodes = [];
  lines.forEach((line, i) => {
    const heading = line.match(/^#{1,6}\s+(.*)$/);
    if (heading) {
      nodes.push(<span className="h" key={i}>{inline(heading[1])}</span>);
    } else {
      nodes.push(<span key={i}>{inline(line)}</span>);
    }
    if (i < lines.length - 1) nodes.push(<br key={"br" + i} />);
  });
  return nodes;
}

function inline(str) {
  const parts = String(str).split(/(\*\*[^*]+\*\*)/g);
  return parts.map((p, i) => {
    const b = p.match(/^\*\*([^*]+)\*\*$/);
    return b ? <strong key={i}>{b[1]}</strong> : <span key={i}>{p}</span>;
  });
}
