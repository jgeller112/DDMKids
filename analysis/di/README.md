# analysis/di/

Disadvantageous Inequity (DI) group: model, results, and write-up.

- **`ddm-di.qmd`**: Source document, rendered by the pipeline's
  `report_di` target. It reads `explicit_di` from the `prepped_data`
  target and the two fits below, and displays the model code from
  `R/models.R`, the same definition as the AI group. Numbers in the prose, including the Prior
  sensitivity check (from the `summary_*` targets), are computed from the
  fitted models with inline R, so a refit updates them.
- **`ddm-di.html`**: Rendered output of the `.qmd` above.
- **`ddm-di_files/`**: Quarto-generated assets (figures, libs) for the
  rendered HTML. Auto-generated on render; safe to delete and regenerate,
  not hand-edited.

Models loaded (see `../models/README.md`):

- `fit_di_informative`: `../models/di_3way_bs_bias_re_ndraws.rds`
  (primary model, used in the paper)
- `fit_di_weak`: `../models/di_3way_bs_bias_re_weakprior.rds`
  (prior sensitivity check)
