# analysis/models/

Cached `brms` model fits (hierarchical Bayesian Wiener diffusion models,
Stan/`cmdstanr` backend). Loaded by default (`file_refit = "never"`)
rather than refit on every render — delete a file here to force a fresh
fit next render.

- **`ai_ddm_3way_bias1.rds`** — Fitted model for `analysis/ai/ddm-ai.qmd`.
- **`di_3way_full.rds`** — Fitted model for `analysis/di/ddm-di.qmd`.

Both are also loaded together, read-only, by `analysis/ddm-comparison.qmd`.
