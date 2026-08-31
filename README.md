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
  models/
    ai_ddm_3way_bias1.rds           Cached AI model fit
    di_3way_full.rds                Cached DI model fit

LICENSE                             MIT
```

## Environment (renv)

Package versions are pinned with [`renv`](https://rstudio.github.io/renv/)
(`renv.lock`), so the analysis reproduces on another machine instead of
drifting as packages update.

**First time setup:**

```r
install.packages("renv")   # if not already installed
renv::restore()            # installs the exact package versions from renv.lock
```

`renv::restore()` reads `renv.lock` and installs every package (including
`cmdstanr`, from the `stan-dev` r-universe repo) into an isolated,
project-local library under `renv/library/` — it won't touch or be affected
by packages installed elsewhere on your system.

Once restored, just open the project in this directory as usual (or `cd`
into it and start R) — `.Rprofile` activates the project library
automatically via `source("renv/activate.R")`.

**Note on CmdStan itself:** `renv` manages the `cmdstanr` *R package* but not
the CmdStan *toolchain* it drives. If `cmdstanr::cmdstan_version()` errors,
install CmdStan separately with:

```r
cmdstanr::install_cmdstan()
```

**If you add or update a package** while working on the analysis, record it
in the lockfile before committing:

```r
renv::snapshot()
```

## Running the analysis

Then render any document with Quarto:

```r
quarto::quarto_render("analysis/ai/ddm-ai.qmd")
quarto::quarto_render("analysis/di/ddm-di.qmd")
```

Both load their models from `analysis/models/*.rds` by default
(`brms`'s `file_refit = "never"`) rather than refitting — delete the
relevant `.rds` to force a fresh fit. Fitting from scratch requires
`cmdstanr` with a working CmdStan installation.

Every number quoted in the `## Results`/`## Summary`/`## Conclusion`
prose in both documents is pulled live from the fitted models via
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
