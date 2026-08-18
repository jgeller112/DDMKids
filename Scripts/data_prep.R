# Shared data preparation for ddm-ai.qmd and ddm-di.qmd.
# Produces explicit_ai and explicit_di, ready for DDM fitting.
#
# Paths use here::here(), resolved relative to the project root, so this
# works no matter which directory sources it -- unlike a manual "../../"
# relative path, which only works from one specific calling depth.

library(tidyverse)

explicit <- read_csv(here::here("data", "explicit.norms.rxn.time.csv"))

# Recode dec so 1 = error, add factor types.
explicit_all <- explicit |>
  select(sn, condition, duration, trialnum, dist, distribution, dec, age.group) |>
  mutate(
    sn = as.factor(sn),
    condition = as.factor(condition),
    duration = as.numeric(duration),
    age.group = as.factor(age.group),
    dec_recode = ifelse(dec == 0, 1, 0)
  )

# Exclude extreme RTs (150ms, 2500ms) and trials beyond +/-3 SD of a
# participant's mean RT.
explicit_rt_all <- explicit_all |>
  filter(duration >= 0.2, duration <= 2.5) |>
  group_by(sn) |>
  filter(
    abs(duration - mean(duration, na.rm = TRUE)) <= 3 * sd(duration, na.rm = TRUE)
  ) |>
  ungroup()

# Keep participants with at least 2 trials of each dist type.
explicit_rt_filtered <- explicit_rt_all |>
  group_by(sn, dist) |>
  filter(n() >= 2) |>
  group_by(sn) |>
  filter(n_distinct(dist) == 2) |>
  ungroup()

explicit_ai <- explicit_rt_filtered |> filter(distribution == "ai")
explicit_di <- explicit_rt_filtered |> filter(distribution == "di")
