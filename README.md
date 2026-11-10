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
                                     Run once by the pipeline (prepped_data) and
                                     shared by both groups, so exclusion criteria
                                     can't drift out of sync between them.
  split_rds.R                       Split/recombine large .rds fits for GitHub.

analysis/
  ai/ddm-ai.qmd                     AI-group model, results, and write-up
  di/ddm-di.qmd                     DI-group model, results, and write-up
  models/
    ai_ddm_3way_bs_bias_re_ndraws.rds           Cached AI model fit
    di_3way_bs_bias_re_ndraws.rds                Cached DI model fit

R/
  models.R                          Model definition shared by AI and DI (formula,
                                     priors, inits, sampler settings) + fit_ddm()
  sensitivity.R                     Contrasts/convergence summaries behind the
                                     prior sensitivity check, + inline formatters

_targets.R                          targets pipeline: data -> model fits -> reports

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

The analysis runs as a [`targets`](https://docs.ropensci.org/targets/)
pipeline defined in [`_targets.R`](_targets.R):

```
data/explicit.norms.rxn.time.csv + Scripts/data_prep.R
  -> prepped_data                     (explicit_ai, explicit_di)
  -> fit_ai_informative, fit_ai_weak, fit_di_informative, fit_di_weak
  -> summary_ai_informative, ...      (contrasts + convergence per fit)
  -> report_ai, report_di, report_combined   (the three .qmd documents)

packages_used                         (every R package the project uses)
  -> Software section of ddm-combined.qmd
  -> software_report                   (analysis/grateful-report.html)
```

From the project root (Quarto must be on your `PATH`; fitting from scratch
also needs a working CmdStan installation):

```r
targets::tar_make()              # build/update everything that is out of date
targets::tar_outdated()          # what would rerun, without running it
targets::tar_visnetwork()        # interactive dependency graph
targets::tar_make(report_ai)     # one document (plus anything it needs)
targets::tar_read(prepped_data)  # inspect any target's value
```

### Where the model lives

The model is defined once in [`R/models.R`](R/models.R), shared by both
groups: `ddm_formula()`, `ddm_family()`, `ddm_prior_informative()`,
`ddm_prior_weak()`, `ddm_inits()`, and `sampler_settings()`. `fit_ddm()`
wraps `brm()`. The documents never call `brm()`; they load fits with
`tar_read()` and show the code from `R/models.R` via `knitr::read_chunk()`,
so the code in the write-up is the code that was fit. To change the model
(a prior, the formula, iterations), edit `R/models.R` and run `tar_make()`.

### Model caching and refits

Each fit is cached as `analysis/models/<name>.rds`. Files over GitHub's
100 MB limit are committed as `.rds.partNNN` chunks (`Scripts/split_rds.R`),
and the full `.rds` is git-ignored. `fit_ddm()`:

1. rebuilds the `.rds` from its parts when the `.rds` is missing (fresh
   clone) or older than its parts (e.g. after pulling a collaborator's refit);
2. calls `brm(file_refit = "on_change")`, which reloads the saved fit unless
   the Stan code or data changed. It also refits if the saved fit's
   chains, iterations, warmup, or thinning differ from `sampler_settings()`,
   which brms doesn't check by itself;
3. after a refit, replaces the old `.partNNN` chunks with new ones.

So on a fresh clone `tar_make()` just loads the saved fits, in seconds. A
refit takes hours. To force one, delete the `.rds` and its `.partNNN`
chunks. If a newly fit model is large enough to be split, add its `.rds` to
`.gitignore`.

The `_targets/` cache directory is git-ignored.

### Prior sensitivity check and software citations

The sensitivity check in `ddm-ai.qmd` and `ddm-di.qmd` compares each primary
fit with its weak-prior counterpart. The comparison (credible-cell counts,
which cells flip, convergence diagnostics) comes from the `summary_*`
targets (`R/sensitivity.R`) and is written into the prose with inline R,
so a refit updates it automatically.

`ddm-combined.qmd` ends with a Software section generated by
[`grateful`](https://pakillo.github.io/grateful/): it cites R and every
package the project uses (the `packages_used` target scans the whole
project) and writes `analysis/grateful-refs.bib`. `RWiener` is added by
hand because only brms calls it.

The `software_report` target also writes `analysis/grateful-report.html`,
a standalone page listing every package with its version and citation.

Every number quoted in the `## Results`/`## Summary`/`## Conclusion`
prose in both documents is pulled live from the fitted models via
inline R (`modelbased::estimate_contrasts()` + small formatting helpers
defined in each document) — nothing is hand-typed, so re-running a
document after refitting updates the write-up automatically.
