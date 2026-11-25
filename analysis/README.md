# analysis/

The current, non-archived analysis. Everything here is built by the
`targets` pipeline: run `targets::tar_make()` from the project root (see
the root `README.md`).

- **`ai/`**: Advantageous Inequity group: model diagnostics, results, and
  write-up (`ddm-ai.qmd`, pipeline target `report_ai`).
- **`di/`**: Disadvantageous Inequity group: same, for DI (`ddm-di.qmd`,
  target `report_di`).
- **`ddm-combined.qmd`** / **`ddm-combined.html`**: Both groups' primary
  models side by side, with the paper tables and figures (target
  `report_combined`).
- **`ddm-combined-tables.docx`**: Native Word versions of the
  combined document's tables, written on render.
- **`ddm-model-tables.docx`**: APA-style Word table of the model
  specification (links, fixed and random effects) and both prior sets
  (primary and sensitivity), for the manuscript. Written on render by the
  `model-spec-table` chunk of `ddm-combined.qmd`, which reads the priors and
  sampler settings straight from `R/models.R`.
- **`ddm-combined_files/`**: Quarto-generated assets (figures, libs) for
  `ddm-combined.html`. Auto-generated on render; safe to delete and
  regenerate, not hand-edited.
- **`grateful-report.html`**: Every R package the project uses, with
  version and citation (pipeline target `software_report`).
- **`grateful-refs.bib`**: Package references cited in the Software section
  of `ddm-combined.qmd`; written by `grateful` on render.
- **`models/`**: Cached `brms` fits written by the pipeline and read by
  all three documents. See `models/README.md`.

None of the documents fit models themselves. They load results with
`targets::tar_read()`, and the model code they display comes from
`R/models.R`.
