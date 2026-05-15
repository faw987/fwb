# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

FWB (Forensic Workbench Dashboard) is a **single-file browser app** for forensic PDF review. The entire application — HTML, CSS, all JavaScript — lives in `fwb.html`. There is no build step, no bundler, no package manager, no test framework, no lint config. The only third-party code is PDF.js loaded from a CDN (version-pinned in `PDFJS_VERSION`).

## Run and deploy

- **Run locally**: open `fwb.html` in a browser. No server needed unless you want to fetch demo data (which uses `https://faw987.github.io/`).
- **Sanity-check JS after edits**: `node -e "const fs=require('fs');const h=fs.readFileSync('fwb.html','utf8');const m=h.match(/<script>\\n\\(\\(\\) => \\{([\\s\\S]*)\\}\\)\\(\\);\\n<\\/script>/);new Function('(()=>{'+m[1]+'})()');console.log('OK');"`
- **Deploy**: `./deploy.sh` copies `fwb.html`, `FWB_user_doc.md`, and `FWB_PRD.md` to the sibling repo `/Users/franka.wallace/Projects/faw987.github.io/`, then commits + pushes. Live at https://faw987.github.io/fwb.html. Both docs are loaded into the in-app Documentation modal from GH Pages, so edits only appear in-app after a deploy.
- **Verifying UI changes**: there is no test harness. Open the deployed page and click through. The user often deploys themselves, then reports. Browser cache is real — suggest hard-refresh (⌘-Shift-R) when behavior seems wrong after a redeploy.

## Architecture

### Multi-window postMessage pattern
The main window opens two popup windows, each built as an inline HTML string and served via `URL.createObjectURL(blob)`:
- **Viewer** — `buildViewerHtml()` (~line 1500+). Displays a single page at high resolution; receives page-render requests and renders prompts as clickable pills. Used for ad-hoc, single-page LLM calls.
- **Library editor** — `buildEditorHtml()` (~line 1300+). Edits the prompt library; both windows mirror the same array.

Cross-window protocol (`postMessage`, type-tagged objects):
- Main → Viewer: page render requests (with `ArrayBuffer` transferred once per file), `llmSettings`, `promptLibrary`
- Viewer → Main: `viewerReady`, `llmResponse` (pending/success/error)
- Main ↔ Editor: `promptLibrary` (full round-trip; whichever side mutated last wins)

Both popups send a `*Ready` message when loaded; the main window queues sends until ready. The viewer caches loaded PDFs by `fileId` so each file's bytes are shipped only once per session.

### State model (in-memory only — no persistence yet)
- `files[]` — `{file, pdfDoc, id}`. `id` is unique per session.
- `promptLibrary[]` — `{id, name, text, manual, summaryColumn}`. Flags default to `manual: true, summaryColumn: false` on import for legacy files. (The user doc references a planned third flag `aggregationColumn` for an AGG-detail column; it's not in code yet.)
- `currentSummaryPrompts[]` — **snapshot** of `promptLibrary.filter(p => p.summaryColumn)` taken at Create Summary Table time. Editing flags later does **not** change table columns until the user rebuilds.
- `aggregations[]` — `{id, name, pageRefs: [{fileId, pageNum}], notes}`.
- `selectedAggregationId` — drives which aggregation's detail table is shown.

### Three tables, with dependencies
- **Page Summary** — primary table built from `files[]`. Columns are *Select, File, Page, Thumbnail, Notes, LLM Response*, plus one column per `currentSummaryPrompts` entry. `thead` is rebuilt by `buildTableHeader()`.
- **AGG Summary** — appears below when `aggregations.length > 0`. Mirrors page-table column layout. Its thumbnails are **copied** from the page-summary canvas (`cloneThumbnailFromPageTable`) — so it depends on the page table being built first.
- **AGG Detail** — appears when an aggregation is selected. Its cells read **live text** from page-summary DOM rows via `readCellText(sourceTr, selector)`. It is rebuilt only when the user (re-)selects an aggregation or adds/removes pages; edits to source rows after that won't propagate without a re-click.

### Apply flow (`runApplyMatrix`)
1. Collect checked rows from `.row-select:checked` and checked prompt columns from `.col-select-prompt:checked`.
2. For each selected row: render the page once to a 1024px-wide PNG data URL.
3. For each selected prompt: POST to `llmSettings.endpoint` with `{provider, model, input: [{role, content: [{type:'text'...}, {type:'image', image_url, detail:'high'}]}]}`. Cell shows pending → success/error.
4. Serial across the whole matrix (rows × prompts), one HTTP call at a time.

Apply uses a hardcoded `DEFAULT_APPLY_MODEL = 'gpt-5.4-nano'`. The viewer's manual button has its own radio-button model selection — they are not linked.

### LLM gateway
- Endpoint: `ai_proxy` `POST /chat`, default `https://llm-gateway-730560815836.us-central1.run.app/chat`.
- Payload shape: `{provider, model, input}` where `input` is an OpenAI-style messages array. Image input requires `provider: 'openai'`.
- Response: `{response: "<text>"}` on success, `{error: "..."}` on failure.

### Button-state choreography
Several enable/disable rules live in `updateButtons()` → `updateApplyButton()` / `updateAggButton()`. Two listeners drive recomputation when row checkboxes change: a delegated `table.addEventListener('change', ...)` and a direct `change` listener attached when each `row-select` checkbox is created (belt-and-suspenders — both must call `updateApplyButton()` AND `updateAggButton()` or buttons go stale). The hamburger panel state is centralized through `setSettingsOpen(open)` — never set the `.open` class on `#settings-toggle` or `#settings-panel` directly.

### Important conventions
- **Don't try to add a build step or framework** — the single-file constraint is deliberate (per `FWB_PRD.md` "Why a single HTML file"). One-file sharability is a core property.
- **No emojis in code or docs** unless explicitly requested.
- **Edit `FWB_user_doc.md`** when adding user-facing features — it's loaded into the User Guide modal from the deployed copy on GitHub Pages, so changes only appear in-app after `./deploy.sh`.
- **Aggregation page refs survive page-table rebuilds** but **not** Clear (which wipes `files[]`). Don't add logic that invalidates aggregations on rebuild.
- **`currentSummaryPrompts` is a snapshot** — if a feature needs live tracking of which prompts have a flag, it should read from `promptLibrary` directly, not the snapshot.

## Repository layout

- `fwb.html` — the application (single file).
- `FWB_user_doc.md` — user guide. Loaded into the in-app modal from GH Pages; deploy to refresh.
- `FWB_PRD.md` — product requirements. Deployed to GH Pages and loaded into the in-app Documentation modal (Product Requirements button).
- `deploy.sh` — copies + pushes to the sibling `faw987.github.io` repo.
- `sources/` — gitignored working PDFs / screenshots, not part of the app.
- `forensic_test_00.pdf` — bundled sample PDF (also hosted on GH Pages for the Load Demo Data button).
