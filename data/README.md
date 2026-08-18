# data/

Raw, unprocessed trial-level data. Nothing in this folder is written by any
analysis script — it's read-only input.

- **`explicit.norms.rxn.time.csv`** — One row per trial. Key columns:
  `sn` (subject ID), `condition` (fairness / autonomous / baseline prompt),
  `distribution` (`ai` = Advantageous Inequity, `di` = Disadvantageous
  Inequity), `dist` (`eq`/`uneq`, the offer type), `dec` (accept/reject
  choice), `duration` (response time, seconds), `trialnum`, and
  `age.group`. Loaded and filtered by `Scripts/data_prep.R` — see that
  script for exclusion criteria before using this file directly.
- **`Explicit Norms Data Dictionary.xlsx`** — Column-by-column definitions
  for the CSV above.
