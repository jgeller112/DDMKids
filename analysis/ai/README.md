# analysis/ai/

Advantageous Inequity (AI) condition: model, results, and write-up.

- **`ddm-ai.qmd`** — Source document. Sources `Scripts/data_prep.R` for
  `explicit_ai`, fits/loads the hierarchical Wiener DDM, and generates the
  `## Results`/`## Summary`/`## Conclusion` prose from the fitted model
  via inline R — nothing in that prose is hand-typed.
- **`ddm-ai.html`** — Rendered output of the `.qmd` above.
- **`ddm-ai_files/`** — Quarto-generated assets (figures, libs) for the
  rendered HTML. Auto-generated on render; safe to delete and regenerate,
  not hand-edited.

The cached model fit this document loads from (rather than refitting) is
`../models/ai_ddm_3way_bias1.rds`.
