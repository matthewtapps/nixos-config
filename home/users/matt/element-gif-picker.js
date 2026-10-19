// KLIPY's terms forbid re-hosting, so this sends the GIF's link and each
// reader's browser loads it from KLIPY.
const React = window.React;
const { useEffect, useRef, useState } = React;
const h = React.createElement;

const KLIPY_LINK = /^https:\/\/static\.klipy\.com\/\S+$/;

async function klipy(apiKey, query, page) {
  const endpoint = query ? "search" : "trending";
  const params = new URLSearchParams({ page, per_page: 24, content_filter: "low" });
  if (query) params.set("q", query);
  const res = await fetch(`https://api.klipy.com/api/v1/${apiKey}/gifs/${endpoint}?${params}`);
  if (!res.ok) throw new Error(`KLIPY search failed (${res.status}).`);
  const { data } = await res.json();
  return data;
}

function Picker({ apiKey, onSubmit }) {
  const [query, setQuery] = useState("");
  const [gifs, setGifs] = useState([]);
  const [page, setPage] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState(null);
  const search = useRef(0);

  const load = async (q, next) => {
    const id = ++search.current;
    setBusy(true);
    setError(null);
    try {
      const data = await klipy(apiKey, q, next);
      if (id !== search.current) return;
      setGifs((old) => (next > 1 ? [...old, ...data.data] : data.data));
      setPage(data.has_next ? data.current_page : null);
    } catch (e) {
      if (id === search.current) setError(e.message);
    } finally {
      if (id === search.current) setBusy(false);
    }
  };

  useEffect(() => {
    const timer = setTimeout(() => load(query.trim(), 1), 300);
    return () => clearTimeout(timer);
  }, [query]);

  const onScroll = (e) => {
    const el = e.currentTarget;
    if (page && !busy && el.scrollTop + el.clientHeight > el.scrollHeight - 200) {
      load(query.trim(), page + 1);
    }
  };

  return h(
    "div",
    { style: { width: "min(560px, 80vw)" } },
    h("input", {
      type: "search",
      autoFocus: true,
      placeholder: "Search KLIPY",
      "aria-label": "Search KLIPY",
      value: query,
      onChange: (e) => setQuery(e.target.value),
      style: { width: "100%", boxSizing: "border-box", marginBottom: 8 },
    }),
    error && h("p", { role: "alert" }, error),
    h(
      "div",
      {
        onScroll,
        style: {
          height: "50vh",
          overflowY: "auto",
          display: "grid",
          gridTemplateColumns: "repeat(auto-fill, minmax(120px, 1fr))",
          gridAutoRows: 120,
          gap: 4,
        },
      },
      gifs.map((gif) =>
        h(
          "button",
          {
            key: gif.id,
            type: "button",
            title: gif.title,
            "aria-label": gif.title || "GIF",
            onClick: () => onSubmit((gif.file.md.webp || gif.file.md.gif).url),
            style: { padding: 0, border: 0, background: "none", cursor: "pointer" },
          },
          h("img", {
            src: (gif.file.sm.webp || gif.file.sm.gif).url,
            alt: "",
            loading: "lazy",
            style: { width: "100%", height: "100%", objectFit: "cover" },
          }),
        ),
      ),
    ),
    h("p", { style: { textAlign: "right", fontSize: "0.8em", margin: "8px 0 0" } }, "Powered by KLIPY"),
  );
}

function isKlipyGif(event) {
  const { msgtype, body } = event.content;
  return msgtype === "m.text" && typeof body === "string" && KLIPY_LINK.test(body.trim());
}

export default class GifPicker {
  static moduleApiVersion = "^1.17.0";

  constructor(api) {
    this.api = api;
  }

  async load() {
    const apiKey = this.api.config.get("co.countersight.klipy_api_key");
    this.api.composer.addFileUploadOption({
      type: "co.countersight.klipy",
      label: "GIF",
      onSelected: async (_roomId, view) => {
        const { ok, model } = await this.api.openDialog({ title: "Send a GIF" }, Picker, { apiKey }).finished;
        if (ok) this.api.composer.insertPlaintextIntoComposer(model, view);
      },
    });
    this.api.customComponents.registerMessageRenderer(isKlipyGif, ({ mxEvent }) =>
      h("img", {
        src: mxEvent.content.body.trim(),
        alt: "GIF",
        loading: "lazy",
        style: { display: "block", maxWidth: 320, maxHeight: 320, borderRadius: 8 },
      }),
    );
  }
}
