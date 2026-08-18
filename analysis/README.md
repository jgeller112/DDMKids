# analysis/

The current, non-archived analysis. See the repo root `README.md` for how
to render these documents.

- **`ai/`** — Advantageous Inequity model, results, and write-up.
- **`di/`** — Disadvantageous Inequity model, results, and write-up.
- **`models/`** — Cached `brms` fits shared by the documents above and by
  the comparison below.
- **`ddm-comparison.qmd`** / **`ddm-comparison.html`** — Loads both fitted
  models from `models/` and compares them directly, without refitting.
- **`ddm-comparison_files/`** — Quarto-generated assets (figures, libs)
  for `ddm-comparison.html`. Auto-generated on render; safe to delete and
  regenerate, not hand-edited.
