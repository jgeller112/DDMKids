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
  can push; the matching original would then be `.gitignore`d and the
  parts tracked instead. `combine_rds_file()` (or `check_and_combine_rds()`
  to sweep a whole directory) reassembles the original from its parts.
  Not currently wired into any `.qmd` — nothing tracked in
  `analysis/models/` is over the limit, and `archive/` is excluded from
  git entirely. Kept here in case a future tracked model needs it.
