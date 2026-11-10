# R/models.R -- the single definition of the DDM used for both groups.
#
# The AI and DI models are identical apart from their data, so the formula,
# family, priors, starting values, and sampler settings live here once.
# _targets.R fits the models with fit_ddm(); the Quarto documents source
# this file and display these definitions via knitr::read_chunk(), so the
# code shown in the write-up is the code that was actually fit.
#
# Each "## ---- name ----" line marks a knitr chunk that the documents
# pull in by label.

# Register this file's labelled sections as knitr chunks (called from the
# .qmd files; kept here because knitr's dependency scanner can't parse a
# nested call inside read_chunk() written directly in a document).
register_model_chunks <- function() {
  knitr::read_chunk(here::here("R", "models.R"))
}

## ---- ddm-formula ----
ddm_formula <- function() {
  brms::bf(
    duration | dec(dec_recode) ~ 0 + condition:dist:age.group +
      (1 + dist | p | sn),
    ndt ~ 0 + condition:dist:age.group,
    bias ~ 0 + condition:dist:age.group +
      (1 + dist | p | sn),
    bs ~ 0 + condition:dist:age.group +
      (1 + dist | p | sn)
  )
}

## ---- ddm-family ----
ddm_family <- function() {
  brms::wiener(link_bs = "identity", link_ndt = "identity", link_bias = "logit")
}

## ---- ddm-prior-informative ----
ddm_prior_informative <- function() {
  brms::prior(normal(0, 1), class = b) +                                      # drift rate (mu) fixed effects
    brms::prior(normal(0.3, 0.1), class = b, dpar = ndt, lb = 0, ub = "min_Y") + # ndt fixed effects
    brms::prior(normal(0, 1), class = b, dpar = bias) +                         # bias, logit scale: 0.5 <-> logit 0
    brms::prior(normal(2, 1), class = b, dpar = bs, lb = 0) +                   # bs fixed effects; centered near the pooled single-parameter fit (~2.6-2.7)
    brms::prior(normal(0, 0.03), class = sd, group = sn, lb = 0) +              # by-subject random effects (mu)
    brms::prior(normal(0, 0.03), class = sd, dpar = bs, group = sn, lb = 0) +   # by-subject random effects (bs) -- same tight scale as mu, made explicit
    brms::prior(normal(0, 0.03), class = sd, dpar = bias, group = sn, lb = 0)   # by-subject random effects (bias, logit scale) -- same tight scale again
}

## ---- ddm-prior-weak ----
ddm_prior_weak <- function() {
  brms::prior(normal(0, 3), class = b) +                                      # drift rate (mu) fixed effects -- 3x wider
    brms::prior(normal(0.3, 0.3), class = b, dpar = ndt, lb = 0, ub = "min_Y") + # ndt fixed effects -- 3x wider SD, same structural bounds
    brms::prior(normal(0, 3), class = b, dpar = bias) +                         # bias, logit scale -- 3x wider
    brms::prior(normal(2, 3), class = b, dpar = bs, lb = 0) +                   # bs fixed effects -- 3x wider
    brms::prior(normal(0, 2), class = sd, group = sn, lb = 0) +                 # by-subject REs (mu) -- HDDM's own default scale
    brms::prior(normal(0, 0.1), class = sd, dpar = bs, group = sn, lb = 0) +    # by-subject REs (bs) -- HDDM's own default scale
    brms::prior(normal(0, 0.05), class = sd, dpar = bias, group = sn, lb = 0)   # by-subject REs (bias) -- HDDM's own default scale
}

## ---- ddm-prior ----
ddm_prior <- function(type = c("informative", "weak")) {
  switch(match.arg(type),
    informative = ddm_prior_informative(),
    weak = ddm_prior_weak()
  )
}

## ---- ddm-inits ----
# Custom starting values, since default inits tend to land somewhere the
# wiener likelihood can't evaluate. Returns a function, as brm(init = ) expects.
ddm_inits <- function(data, prior) {
  sdat <- brms::make_standata(ddm_formula(), family = ddm_family(), data = data, prior = prior)
  function() {
    list(
      b = rnorm(sdat$K, 0, 0.2),
      b_bs = rnorm(sdat$K_bs, 2, 0.3),
      b_ndt = runif(sdat$K_ndt, 0.001, 0.05),
      b_bias = rnorm(sdat$K_bias, 0, 0.1),
      sd_1 = runif(sdat$M_1, 0.05, 0.1),
      z_1 = matrix(rnorm(sdat$M_1 * sdat$N_1, 0, 0.01), sdat$M_1, sdat$N_1),
      L_1 = diag(sdat$M_1)
    )
  }
}

## ---- sampler-settings ----
sampler_settings <- function() {
  list(
    chains = 4,
    iter = 5000,
    warmup = 1000,
    thin = 1,
    adapt_delta = .95,
    max_treedepth = 15,
    threads = 2
  )
}

## ---- end-of-display-chunks ----

postwarmup_draws <- function(s = sampler_settings()) {
  (s$iter - s$warmup) / s$thin * s$chains
}

# ---- Fitting (used by _targets.R) -------------------------------------------

# Parts of a split .rds (see Scripts/split_rds.R), in order.
rds_parts <- function(rds) {
  sort(list.files(dirname(rds),
    pattern = paste0("^", gsub(".", "\\.", basename(rds), fixed = TRUE), "\\.part[0-9]+$"),
    full.names = TRUE
  ))
}

# TRUE if a saved fit was run with different sampler settings than `s`.
# brms's file_refit = "on_change" only compares Stan code and data, so a
# change to iter/warmup/thin/chains would otherwise be silently ignored.
settings_changed <- function(rds, s) {
  if (!file.exists(rds)) return(FALSE)
  sim <- readRDS(rds)$fit@sim
  saved <- c(chains = sim$chains, iter = sim$iter, warmup = sim$warmup, thin = sim$thin)
  wanted <- c(chains = s$chains, iter = s$iter, warmup = s$warmup, thin = s$thin)
  changed <- !isTRUE(all.equal(saved, wanted))
  if (changed) {
    message(
      "Sampler settings differ from ", rds, " (saved: ",
      paste(names(saved), saved, sep = "=", collapse = ", "), "); refitting."
    )
  }
  changed
}

#' Fit (or load) one DDM and keep its git-tracked split parts in sync.
#'
#' The saved .rds is the cache: brm(file_refit = "on_change") loads it when
#' the Stan code and data still match, so a fresh clone or a rerun costs
#' seconds, not hours. A new fit is re-split for GitHub's 100 MB limit.
#'
#' @return The .rds path followed by its part files (for format = "file").
fit_ddm <- function(data, prior_type, file, settings = sampler_settings()) {
  rds <- paste0(file, ".rds")
  parts <- rds_parts(rds)

  # Rebuild the .rds from its parts on a fresh clone, or when the parts are
  # newer (e.g. pulled after a collaborator refit).
  if (length(parts) > 0 &&
      (!file.exists(rds) || max(file.mtime(parts)) > file.mtime(rds))) {
    unlink(rds)
    combine_rds_file(rds)
  }

  mtime_before <- if (file.exists(rds)) file.mtime(rds) else NA
  prior <- ddm_prior(prior_type)

  brms::brm(ddm_formula(),
    data = data,
    family = ddm_family(),
    prior = prior, init = ddm_inits(data, prior),
    chains = settings$chains, cores = settings$chains,
    iter = settings$iter, warmup = settings$warmup, thin = settings$thin,
    sample_prior = TRUE,
    save_pars = brms::save_pars(all = TRUE),
    control = list(adapt_delta = settings$adapt_delta, max_treedepth = settings$max_treedepth),
    backend = "cmdstanr", threads = brms::threading(settings$threads),
    file = file,
    file_refit = if (settings_changed(rds, settings)) "always" else "on_change"
  )

  # If brm() wrote a new fit, replace the old parts with fresh ones.
  if (is.na(mtime_before) || file.mtime(rds) != mtime_before) {
    unlink(rds_parts(rds))
    split_rds_file(rds, max_size_mb = 90)
  }

  c(rds, rds_parts(rds))
}
