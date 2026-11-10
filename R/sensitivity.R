# R/sensitivity.R -- summaries behind the prior sensitivity check.
#
# summarize_fit() runs in the pipeline (one target per fit) so the
# documents can report the sensitivity comparison with inline R instead of
# hand-typed numbers. The contrasts are computed exactly as in the Results
# sections of ddm-ai.qmd / ddm-di.qmd: equal - unequal, by condition x age
# group, via modelbased::estimate_contrasts(backend = "emmeans"). A cell is
# credible when its 95% CrI excludes 0 and pd > 97.5%.

ddm_parameters <- c(
  mu = "Drift rate",
  ndt = "Non-decision time",
  bias = "Starting point",
  bs = "Boundary separation"
)

# Report every contrast as eq - uneq, whatever order emmeans used.
orient_eq_minus_uneq <- function(df) {
  flip <- df$Level1 == "uneq"
  if (any(flip)) {
    lo <- -df$CI_high[flip]
    hi <- -df$CI_low[flip]
    df$Difference[flip] <- -df$Difference[flip]
    df$CI_low[flip] <- lo
    df$CI_high[flip] <- hi
  }
  df
}

dist_contrasts <- function(fit, pd_threshold = 0.975) {
  out <- lapply(names(ddm_parameters), function(p) {
    df <- modelbased::estimate_contrasts(
      fit, contrast = "dist", by = c("condition", "age.group"),
      predict = p, backend = "emmeans"
    ) |>
      as.data.frame() |>
      orient_eq_minus_uneq()
    data.frame(
      parameter = p,
      condition = as.character(df$condition),
      age.group = as.character(df$age.group),
      estimate = df$Difference,
      CI_low = df$CI_low,
      CI_high = df$CI_high,
      pd = df$pd,
      credible = (df$CI_low > 0 | df$CI_high < 0) & df$pd > pd_threshold
    )
  })
  do.call(rbind, out)
}

#' Contrasts plus convergence diagnostics for one saved fit.
#' @param fit_files Output of a fit_* target (the .rds path comes first).
summarize_fit <- function(fit_files) {
  fit <- readRDS(fit_files[1])
  np <- brms::nuts_params(fit)
  sim <- fit$fit@sim
  list(
    contrasts = dist_contrasts(fit),
    divergences = sum(np$Value[np$Parameter == "divergent__"]),
    max_rhat = max(brms::rhat(fit), na.rm = TRUE),
    chains = sim$chains,
    iter = sim$iter,
    warmup = sim$warmup,
    thin = sim$thin
  )
}

# ---- Formatting helpers used inline in the documents ------------------------

# "norm@4-5y". The @ is escaped so Pandoc doesn't read it as a citation.
cell_label <- function(condition, age.group) {
  paste0(condition, "\\@", sub("&", "-", age.group), "y")
}

# Lost/gained credible cells for one parameter, primary -> sensitivity.
credibility_changes <- function(main, weak, parameter) {
  m <- main$contrasts[main$contrasts$parameter == parameter, ]
  w <- weak$contrasts[weak$contrasts$parameter == parameter, ]
  w <- w[match(paste(m$condition, m$age.group), paste(w$condition, w$age.group)), ]
  cells <- cell_label(m$condition, m$age.group)
  list(
    n_main = sum(m$credible),
    n_weak = sum(w$credible),
    lost = cells[m$credible & !w$credible],
    gained = cells[!m$credible & w$credible],
    kept = cells[m$credible & w$credible]
  )
}

# Comma-separated list, or "none".
list_cells <- function(x) if (length(x) == 0) "none" else paste(x, collapse = ", ")

# The markdown table: credible cells per parameter under each prior.
sensitivity_table <- function(main, weak) {
  rows <- lapply(names(ddm_parameters), function(p) {
    ch <- credibility_changes(main, weak, p)
    n_flip <- length(ch$lost) + length(ch$gained)
    detail <- c(
      if (length(ch$lost)) paste("lost:", list_cells(ch$lost)),
      if (length(ch$gained)) paste("gained:", list_cells(ch$gained))
    )
    data.frame(
      Parameter = ddm_parameters[[p]],
      `Credible cells, informative prior` = paste(ch$n_main, "/ 9"),
      `Credible cells, weak prior` = paste(ch$n_weak, "/ 9"),
      `Cells that flip` = if (n_flip == 0) "0" else paste0(n_flip, " (", paste(detail, collapse = "; "), ")"),
      check.names = FALSE
    )
  })
  do.call(rbind, rows)
}

# "-0.553 [-1.04, -0.07] -> -0.694 [-1.70, 0.31]" for one cell.
cell_change <- function(main, weak, parameter, condition, age.group) {
  pick <- function(s) {
    d <- s$contrasts
    d[d$parameter == parameter & d$condition == condition & d$age.group == age.group, ]
  }
  f <- function(r) sprintf("%.3f \\[%.2f, %.2f\\]", r$estimate, r$CI_low, r$CI_high)
  paste(f(pick(main)), "→", f(pick(weak)))
}

# "0 divergent transitions, max Rhat 1.006 across 4 chains x 5,000 iterations"
convergence_text <- function(s) {
  sprintf(
    "%d divergent transitions, max Rhat %.3f across %d chains x %s iterations",
    s$divergences, s$max_rhat, s$chains, format(s$iter, big.mark = ",")
  )
}
