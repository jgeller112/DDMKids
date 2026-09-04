# analysis/models/

Cached `brms` model fits (hierarchical Bayesian Wiener diffusion models,
Stan/`cmdstanr` backend). Loaded by default (`file_refit = "never"`)
rather than refit on every render — delete a file here to force a fresh
fit next render.

## Currently used

Each of the four `condition:dist:age.group` cells gets its own directly-
interpretable parameter (`0 + condition:dist:age.group` cell-means
coding) on `mu`, `ndt`, `bias`, and `bs`, with correlated by-subject
random intercepts and `dist` slopes (`(1 + dist | p | sn)`) shared across
`mu`, `bs`, and `bias`. See `analysis/ai/ddm-ai.qmd`'s Model
Specification and Priors sections for the full derivation.

- **`ai_ddm_3way_bs_bias_re_ndraws.rds`** — Primary AI (Advantageous Inequity)
  model. Loaded by `analysis/ai/ddm-ai.qmd` and `analysis/ddm-combined.qmd`.
- **`di_3way_bs_bias_re_ndraws.rds`** — Primary DI (Disadvantageous Inequity)
  model, same structure. Loaded by `analysis/di/ddm-di.qmd` and
  `analysis/ddm-combined.qmd`.
- **`ai_ddm_3way_bs_bias_re_weakprior.rds`** — Same formula and data as
  the primary AI model, weakly informative priors throughout instead
  (see below). Loaded only by `analysis/ai/ddm-ai.qmd`'s Prior
  sensitivity check.
- **`di_3way_bs_bias_re_weakprior.rds`** — Same, for DI. Loaded only by
  `analysis/di/ddm-di.qmd`'s Prior sensitivity check.

### Priors used in the primary models (informative)

```r
prior(normal(0, 1), class = b) +                                      # drift rate (mu) fixed effects
prior(normal(0.3, 0.1), class = b, dpar = ndt, lb = 0, ub = "min_Y") + # ndt fixed effects
prior(normal(0, 1), class = b, dpar = bias) +                         # bias, logit scale
prior(normal(2, 1), class = b, dpar = bs, lb = 0) +                   # bs fixed effects
prior(normal(0, 0.03), class = sd, group = sn, lb = 0) +              # by-subject REs (mu)
prior(normal(0, 0.03), class = sd, dpar = bs, group = sn, lb = 0) +   # by-subject REs (bs)
prior(normal(0, 0.03), class = sd, dpar = bias, group = sn, lb = 0)   # by-subject REs (bias)
```

The fixed-effect priors (`mu`/`bias`/`bs`) are weakly informative — posterior
SDs come back an order of magnitude narrower than the prior. The
`normal(0, 0.03)` random-effect SD priors are deliberately **informative**,
not weakly informative: this scale is considerably tighter than
field-standard defaults (HDDM's `HalfNormal(2)`/`0.1`/`0.05` for the
analogous parameters; Wiecki et al., 2013), chosen because looser priors
produced severe sampler divergence on this project's sparse per-subject
data (134 AI / 125 DI subjects, median 5 trials per subject per
`dist` level). See `ddm-ai.qmd`'s Priors section for the full
justification.

### Priors used in the weak-prior sensitivity-check models

```r
prior(normal(0, 3), class = b) +                                      # drift rate -- 3x wider
prior(normal(0.3, 0.3), class = b, dpar = ndt, lb = 0, ub = "min_Y") + # ndt -- 3x wider SD, same structural bounds
prior(normal(0, 3), class = b, dpar = bias) +                         # bias -- 3x wider
prior(normal(2, 3), class = b, dpar = bs, lb = 0) +                   # bs -- 3x wider
prior(normal(0, 2), class = sd, group = sn, lb = 0) +                 # by-subject REs (mu) -- HDDM's own default scale
prior(normal(0, 0.1), class = sd, dpar = bs, group = sn, lb = 0) +    # by-subject REs (bs) -- HDDM's own default scale
prior(normal(0, 0.05), class = sd, dpar = bias, group = sn, lb = 0)   # by-subject REs (bias) -- HDDM's own default scale
```

Fixed-effect SDs are tripled (low-stakes, since even the tighter primary
priors are already dominated by the likelihood). `ndt` keeps its
`[0, min_Y]` truncation in both versions — a structural identifiability
requirement, not a strength-of-belief choice. The random-effect SDs
switch to HDDM's own default scales, the literature-standard alternative
to the tight `0.03` used in the primary models.

Both weak-prior fits converge cleanly (0 divergences, Rhat < 1.01 in
both groups) but are not substantively equivalent to the primary models.
Comparing the same `dist` (equal-vs-unequal) contrasts by
condition x age.group:

| Parameter | AI: informative -> weak | DI: informative -> weak |
|---|---|---|
| Drift rate | 5/9 -> 3/9 credible | 9/9 -> 8/9 credible |
| Non-decision time | 3/9 -> 3/9 (net unchanged) | 0/9 -> 1/9 |
| Starting point | 1/9 -> 1/9 | 4/9 -> 5/9 |
| Boundary separation | 4/9 -> **1/9** | 2/9 -> 1/9 |

AI's boundary-separation findings are prior-sensitive — most of the
"norm condition widens boundaries" result rests on the tight `0.03`
prior rather than surviving under a field-standard alternative. DI's
results are essentially prior-robust throughout (at most one cell
changes status per parameter, none of them cells the write-up leans on).
See each document's Prior sensitivity check section for the full
breakdown and which specific cells flip.
