# DDM-for-kids

Drift diffusion model (DDM) analysis of children's decisions in the Inequity
Game, testing whether experimental prompt condition (fairness / autonomous /
baseline) and age shape the underlying decision process — not just the final
accept/reject choice — separately for the Advantageous Inequity (AI) and
Disadvantageous Inequity (DI) conditions.

Models are hierarchical Bayesian Wiener diffusion models fit with `brms`
(Stan/`cmdstanr` backend), decomposing each trial's response time and choice
into drift rate (`mu`), non-decision time (`ndt`), starting point (`bias`),
and boundary separation (`bs`).

## Repo structure

```
data/
  explicit.norms.rxn.time.csv       Raw trial-level data
  Explicit Norms Data Dictionary.xlsx

Scripts/
  data_prep.R                       Shared preprocessing (exclusions, AI/DI split).
                                     Sourced by both analysis/ai/ and analysis/di/
                                     documents so exclusion criteria can't drift
                                     out of sync between them.

analysis/
  ai/ddm-ai.qmd                     AI-group model, results, and write-up
  di/ddm-di.qmd                     DI-group model, results, and write-up
  ddm-comparison.qmd                Loads both fitted models and compares them
                                     directly (no refitting)
  models/
    ai_ddm_3way_bias1.rds           Cached AI model fit
    di_3way_full.rds                Cached DI model fit

archive/                            Orphaned files from earlier iterations, not
                                     referenced by any current document. Nothing
                                     deleted, just moved out of the way.
  ddm-katie.qmd                     Earlier, superseded exploratory notebook
                                     (model comparison across main-effects/
                                     2-way/3-way/cogmod variants). Its cached
                                     .rds fits are no longer present, so it
                                     will not re-render as-is.
  Models/                           Cached fits from that notebook's earlier
                                     naming scheme
  *.rds                             Other superseded cached model fits

LICENSE                             MIT
```

## Running the analysis

Then render any document with Quarto:

```r
quarto::quarto_render("analysis/ai/ddm-ai.qmd")
quarto::quarto_render("analysis/di/ddm-di.qmd")
quarto::quarto_render("analysis/ddm-comparison.qmd")
```

All three load their models from `analysis/models/*.rds` by default
(`brms`'s `file_refit = "never"`) rather than refitting — delete the
relevant `.rds` to force a fresh fit. Fitting from scratch requires
`cmdstanr` with a working CmdStan installation.

Every number quoted in the `## Results`/`## Summary`/`## Conclusion`
prose in all three documents is pulled live from the fitted models via
inline R (`modelbased::estimate_contrasts()` + small formatting helpers
defined in each document) — nothing is hand-typed, so re-running a
document after refitting updates the write-up automatically.

## Key methodological notes

- **Credibility criterion**: 95% credible interval excludes zero *and*
  `pd > 97.5%` (probability of direction). ROPE percentages are computed
  and available (each parameter gets its own scaled range — the automatic
  default has no supported method for a multi-parameter Wiener/DDM family)
  but are reported for supplementary context only, not as the primary
  credibility criterion.
- **Random effects**: by-subject random intercept/slope for `dist` on `mu`
  only. Random effects on `ndt`/`bias` were explored and abandoned —
  individual differences in those parameters aren't well identified from
  this few trials per subject per cell.
- See each document's own "Model Specification" section for the full
  formula, priors, and links.
