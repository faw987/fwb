# Forensic Workbench Dashboard (FWB) — Product Requirements

## Vision
Provide a fast, browser-only tool that lets a reviewer triage every page of one or more PDFs, capture per-page notes, and selectively apply an LLM to a chosen page using a curated library of prompts.

## Why a single HTML file
- Trivial to share — one HTML file plus a markdown user guide hosted on GitHub Pages.
- PDFs never leave the browser; only a chosen page image plus the user's prompt is sent over the network.
- LLM access is mediated by an external gateway, so provider API keys are never embedded in the client.

## Current scope
- Drop or pick one or more PDFs.
- Render every page as a thumbnail in a summary table with columns: *File, Page, Thumbnail, Notes, LLM Response*.
- Editable `Notes` column per row.
- Click a thumbnail to open a single shared viewer popup that displays the page at higher resolution.
- In the viewer:
  - Pill list of saved library prompts (single-click copies into the prompt area; double-click runs immediately).
  - Free-text prompt area for ad-hoc queries.
  - **Examine page using LLM** sends the rendered page plus the prompt to a configured gateway and writes the response into the row's *LLM Response* column.
- Hamburger menu (☰):
  - **Load Demo Data** — fetches sample library and test PDF from GitHub.
  - **AI Gateway Settings** — configurable `/chat` endpoint with a hosted Cloud Run default.
  - **Prompt Library** — Edit (separate window), Import (JSON), Export (JSON).
  - **User Guide** — renders `FWB_user_doc.md` from GitHub in a modal.

## Non-goals (for now)
- No server-side state, login, or per-user storage.
- No OCR for scanned PDFs (vision models handle this in practice).
- No bulk LLM operations across multiple rows.
- No automatic persistence of notes, library, or settings — Export is the persistence path.

## Planned next
1. Persist gateway endpoint, prompt library, and notes in `localStorage` with explicit Reset.
2. Multi-row selection + bulk apply of a library prompt.
3. Re-orderable / hideable columns; CSV export of the table.
4. Per-row LLM history (multiple prompts and responses against the same page).
5. OCR fallback for scanned PDFs (Tesseract.js or similar) when vision-model output is unsatisfactory.

## Architecture notes
- Page rendering is local via PDF.js (CDN, version-pinned).
- The page viewer is built from a `Blob` URL inside the main script — keeps the whole app in `fwb.html`.
- The prompt-library editor uses the same Blob-URL popup pattern; mutations are postMessaged back to the main window, which is the source of truth.
- The LLM gateway is `ai_proxy` (`POST /chat`), responsible for provider keys, CORS, and request-size limits.
- Demo files and the user guide are hosted at `https://faw987.github.io/` (`fwb-prompt-library.json`, `forensic_test_00.pdf`, `FWB_user_doc.md`).

## File layout
- `fwb.html` — the application.
- `FWB_user_doc.md` — user guide, surfaced via the hamburger menu.
- `FWB_PRD.md` — this document.
- Sample data lives on GitHub Pages alongside the docs.
