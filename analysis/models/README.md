# analysis/models/

Cached `brms` model fits (hierarchical Bayesian Wiener diffusion models,
Stan/`cmdstanr` backend), produced and kept up to date by the `targets`
pipeline (`_targets.R` at the project root). Don't edit or create files here
by hand: the model is defined in `R/models.R` and fit with
`targets::tar_make()`.

## How the cache works

Each file is written by `fit_ddm()` (`R/models.R`) through
`brm(file = ..., file_refit = "on_change")`:

- A saved fit is **reloaded** unless the Stan code, the data, or the sampler
  settings (`sampler_settings()`: chains, iterations, warmup, thinning)
  have changed. In that case it is **refit**, which takes hours.
- Fits over GitHub's 100 MB push limit are committed as `<90 MB` chunks
  (`<name>.rds.partNNN`, via `Scripts/split_rds.R`). The full `.rds` is
  git-ignored. `fit_ddm()` rebuilds it from the chunks on a fresh clone,
  or when the chunks are newer than the local `.rds` (e.g. after pulling a
  collaborator's refit), and writes fresh chunks after a refit.
- To force a refit, delete the `.rds` and its `.partNNN` chunks, then run
  `targets::tar_make()`.

## Models

All four models share one definition (`R/models.R`): the same formula,
family, starting values, and sampler settings (4 chains x 5000 iterations,
1000 warmup, thin 1 = 16,000 post-warmup draws). They differ only in
data (AI vs DI) and prior.

| File | Pipeline target | Group | Prior | Used in |
|---|---|---|---|---|
| `ai_ddm_3way_bs_bias_re_ndraws.rds` | `fit_ai_informative` | AI | Primary | **Paper**; `ai/ddm-ai.qmd`, `ddm-combined.qmd` |
| `di_3way_bs_bias_re_ndraws.rds` | `fit_di_informative` | DI | Primary | **Paper**; `di/ddm-di.qmd`, `ddm-combined.qmd` |
| `ai_ddm_3way_bs_bias_re_weakprior.rds` | `fit_ai_weak` | AI | Sensitivity | Prior sensitivity check in `ai/ddm-ai.qmd` |
| `di_3way_bs_bias_re_weakprior.rds` | `fit_di_weak` | DI | Sensitivity | Prior sensitivity check in `di/ddm-di.qmd` |

`mu` (drift rate), `ndt` (non-decision time), `bias` (starting point), and
`bs` (boundary separation) each get `0 + condition:dist:age.group`
cell-means coding, which gives one directly interpretable parameter per cell
(3 conditions x 2 split types x 3 age groups = 18 cells). `mu`, `bs`, and
`bias` share correlated by-subject random intercepts and `dist` slopes
(`(1 + dist | p | sn)`). `ndt` has no random effects. See the Model
Specification section of `ai/ddm-ai.qmd` for the rationale.

## Priors

Both priors are **weakly informative on the fixed effects**. What the
sensitivity check varies is the **random-effect SD prior**: tight in the
primary model, HDDM's defaults (Wiecki et al., 2013) in the sensitivity
model. The file names and target names say "weak" for short, but the
sensitivity model is not flat or uninformative.

| Parameter | Primary (`ddm_prior_informative()`) | Sensitivity (`ddm_prior_weak()`) | Change |
|---|---|---|---|
| `mu` fixed effects | Normal(0, 1) | Normal(0, 3) | 3x wider |
| `ndt` fixed effects | Normal(0.3, 0.1), [0, min RT] | Normal(0.3, 0.3), [0, min RT] | 3x wider |
| `bias` fixed effects (logit) | Normal(0, 1) | Normal(0, 3) | 3x wider |
| `bs` fixed effects | Normal(2, 1), > 0 | Normal(2, 3), > 0 | 3x wider |
| `mu` random-effect SDs | Normal⁺(0, 0.03) | Normal⁺(0, 2) | ~67x wider |
| `bs` random-effect SDs | Normal⁺(0, 0.03) | Normal⁺(0, 0.1) | ~3x wider |
| `bias` random-effect SDs (logit) | Normal⁺(0, 0.03) | Normal⁺(0, 0.05) | ~1.7x wider |

- **Fixed effects:** posterior SDs come out an order of magnitude narrower
  than either prior, so the data, not the prior, drive these estimates.
  `ndt` keeps its `[0, min RT]` truncation in both. That bound is a
  structural identifiability requirement, not a strength-of-belief choice.
- **Random-effect SDs:** the primary model's `Normal⁺(0, 0.03)` is
  deliberately **informative**, much tighter than field-standard defaults.
  It was chosen because looser priors produced severe sampler divergence in
  earlier versions of this model on sparse per-subject data (134 AI / 125
  DI subjects, median 5 trials per subject per `dist` level). See the Priors
  section of `ai/ddm-ai.qmd` for the full justification.

## Sensitivity results

Both sensitivity fits converge cleanly (0 divergences; max Rhat 1.006 AI,
1.002 DI).

Number of credible equal-vs-unequal (`dist`) contrasts, out of 9
condition x age-group cells:

| Parameter | AI: primary -> sensitivity | DI: primary -> sensitivity |
|---|---|---|
| Drift rate | 5/9 -> 3/9 | 9/9 -> 8/9 |
| Non-decision time | 3/9 -> 3/9 (1 lost, 1 gained) | 0/9 -> 0/9 |
| Starting point | 1/9 -> 1/9 | 4/9 -> 5/9 |
| Boundary separation | 4/9 -> **1/9** | 2/9 -> 1/9 |

AI's boundary-separation findings depend on the prior: most of the "norm
condition widens boundaries" result rests on the tight random-effect prior
and does not hold up under HDDM's defaults. DI's results are essentially
unaffected by the prior (at most one cell changes per parameter, none of
them cells the write-up relies on). See each document's Prior sensitivity
check section for which cells flip.
