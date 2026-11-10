# analysis/ai/

Advantageous Inequity (AI) group: model, results, and write-up.

- **`ddm-ai.qmd`**: Source document, rendered by the pipeline's
  `report_ai` target. It reads `explicit_ai` from the `prepped_data`
  target and the two fits below, and displays the model code from
  `R/models.R`. Numbers in the prose, including the Prior
  sensitivity check (from the `summary_*` targets), are computed from the
  fitted models with inline R, so a refit updates them.
- **`ddm-ai.html`**: Rendered output of the `.qmd` above.
- **`ddm-ai_files/`**: Quarto-generated assets (figures, libs) for the
  rendered HTML. Auto-generated on render; safe to delete and regenerate,
  not hand-edited.

Models loaded (see `../models/README.md`):

- `fit_ai_informative`: `../models/ai_ddm_3way_bs_bias_re_ndraws.rds`
  (primary model, used in the paper)
- `fit_ai_weak`: `../models/ai_ddm_3way_bs_bias_re_weakprior.rds`
  (prior sensitivity check)
