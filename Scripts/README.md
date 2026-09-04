# Scripts/

- **`data_prep.R`** — Shared preprocessing sourced by both
  `analysis/ai/ddm-ai.qmd` and `analysis/di/ddm-di.qmd` so exclusion
  criteria can't drift out of sync between the two documents. Reads
  `data/explicit.norms.rxn.time.csv`, recodes `dec`, drops RTs outside
  0.2–2.5s or beyond ±3 SD of a participant's mean RT, drops participants
  without at least 2 trials of each `dist` type, then splits the result
  into `explicit_ai` and `explicit_di`.
- **`split_rds.R`** — Adapted from [`split_qs2.R`](https://github.com/jgeller112/exGauss_commentary/blob/main/split_qs2.R).
  GitHub hard-rejects pushes of files over 100MB. `split_rds_file()`
  breaks an oversized `.rds` into `<90MB` `.rds.partNNN` chunks that git
  can push; the matching original is then `.gitignore`d and the parts
  tracked instead. `combine_rds_file()` (or `check_and_combine_rds()`
  to sweep a whole directory) reassembles the original from its parts —
  it's a no-op if the combined file already exists and matches the
  parts' total size, so it's safe to call unconditionally on every render.

  Wired into `analysis/ai/ddm-ai.qmd`, `analysis/di/ddm-di.qmd`, and
  `analysis/ddm-combined.qmd`: each sources this script and calls
  `check_and_combine_rds(here("analysis", "models"))` right before its
  `brm(..., file = ...)` calls, so a fresh clone reassembles any split
  models automatically before they're loaded. Currently splits
  `analysis/models/ai_ddm_3way_bs_bias_re_ndraws.rds` and
  `di_3way_bs_bias_re_ndraws.rds` (both >190MB); see
  `analysis/models/README.md` for the full list of tracked models and
  which are split.

  To split a newly-added oversized model yourself: run
  `split_rds_file("analysis/models/<name>.rds")`, add `<name>.rds` to
  `.gitignore`, then `git add` the resulting `<name>.rds.partNNN` files.
