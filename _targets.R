# _targets.R -- pipeline for the DDM-for-kids analysis.
#
# Run from the project root:
#   targets::tar_make()        # build / update everything that is out of date
#   targets::tar_visnetwork()  # see the dependency graph and what is outdated
#   targets::tar_outdated()    # list targets that would rerun
#
# Flow: raw data -> prepped_data -> four brms fits (AI/DI x informative/weak
# prior) -> three Quarto reports. The model definition lives once in
# R/models.R; the reports only read results with targets::tar_read().

library(targets)
library(tarchetypes)

tar_option_set(packages = c("tidyverse", "brms", "cmdstanr", "emmeans", "modelbased"))

tar_source("R")                # model definition, fit_ddm(), sensitivity helpers
source("Scripts/split_rds.R")  # split/recombine helpers (functions only)

# One row per model. `model_file` keeps the existing cache names so the
# already-fitted models are reused rather than refit.
model_grid <- tibble::tribble(
  ~group, ~prior_type,   ~model_file,
  "ai",   "informative", "analysis/models/ai_ddm_3way_bs_bias_re_ndraws",
  "ai",   "weak",        "analysis/models/ai_ddm_3way_bs_bias_re_weakprior",
  "di",   "informative", "analysis/models/di_3way_bs_bias_re_ndraws",
  "di",   "weak",        "analysis/models/di_3way_bs_bias_re_weakprior"
)

list(
  # ---- Data ----------------------------------------------------------------
  tar_target(raw_data_file, "data/explicit.norms.rxn.time.csv", format = "file"),
  tar_target(data_prep_script, "Scripts/data_prep.R", format = "file"),

  # list(ai = explicit_ai, di = explicit_di), built by Scripts/data_prep.R.
  tar_target(prepped_data, {
    raw_data_file
    env <- new.env()
    sys.source(data_prep_script, envir = env)
    list(ai = env$explicit_ai, di = env$explicit_di)
  }),

  # ---- Models --------------------------------------------------------------
  # Creates fit_ai_informative, fit_ai_weak, fit_di_informative, fit_di_weak,
  # and a matching summary_* target for each.
  # Each returns the .rds path followed by its git-tracked split parts.
  # fit_ddm() loads the saved fit unless the data, model code, or sampler
  # settings changed; only then does it run MCMC and re-split.
  tar_map(
    values = model_grid,
    names = c("group", "prior_type"),
    tar_target(fit, fit_ddm(prepped_data[[group]], prior_type, model_file), format = "file"),
    # equal - unequal contrasts + convergence diagnostics for each fit, read
    # by the documents' prior sensitivity check (summary_ai_weak, ...).
    tar_target(summary, summarize_fit(fit))
  ),

  # ---- Software citations --------------------------------------------------
  # Every package used anywhere in the project (scanned from the root so R/,
  # _targets.R, and all documents count), cited in ddm-combined.qmd via
  # grateful. RWiener is added by hand: brms calls it for the Wiener
  # likelihood (log_lik()), so no code loads it directly.
  tar_target(
    packages_used,
    unique(c(as.data.frame(grateful::scan_packages())$pkg, "RWiener")),
    cue = tar_cue(mode = "always")
  ),

  # Standalone citation report (analysis/grateful-report.html): R and each
  # package with its version and citation. Self-contained, so the .bib
  # grateful writes alongside it is removed (the combined document keeps its
  # own analysis/grateful-refs.bib).
  tar_target(software_report, {
    tmp <- tempfile("grateful")
    dir.create(tmp)
    grateful::cite_packages(
      output = "file", out.format = "html", out.dir = tmp, pkgs = packages_used
    )
    out <- "analysis/grateful-report.html"
    file.copy(file.path(tmp, "grateful-report.html"), out, overwrite = TRUE)
    unlink(tmp, recursive = TRUE)
    out
  }, format = "file"),

  # ---- Reports -------------------------------------------------------------
  # Dependencies are detected from the tar_read() calls inside each .qmd.
  tar_quarto(report_ai, "analysis/ai/ddm-ai.qmd", extra_files = c("R/models.R", "R/sensitivity.R")),
  tar_quarto(report_di, "analysis/di/ddm-di.qmd", extra_files = c("R/models.R", "R/sensitivity.R")),
  tar_quarto(report_combined, "analysis/ddm-combined.qmd", extra_files = c("R/models.R", "R/sensitivity.R"))
)
