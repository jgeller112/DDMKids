# Scripts/ddm_schematic.R
#
# Illustrative drift diffusion model figure for the manuscript: the four
# parameters (a, z, v, Ter) labelled, upper boundary = Reject (red),
# lower boundary = Accept (green), with simulated evidence paths and the
# resulting response-time distributions at each boundary.
#
# Parameter values are illustrative only, not estimates.
# Run from the project root:  Rscript Scripts/ddm_schematic.R
# Output: analysis/figures/ddm-schematic.png and .pdf

library(ggplot2)

reject_col <- "#C62828"
accept_col <- "#2E7D32"
ink <- "#222222"
muted <- "#6b6b6b"

# Illustrative parameters
a <- 2       # boundary separation
z <- 0.5     # relative starting point (0 = accept, 1 = reject); 0.5 = unbiased
v <- 0.8     # mean drift rate (positive = toward Reject)
sv <- 1.0    # across-trial drift variability: makes the less likely (Accept)
             # responses slower and more right-skewed ("slow errors")
v_arrow <- 0.9  # slope of the illustrative drift arrow (direction of evidence accumulation)
ter <- 0.3   # non-decision time (s)
dt <- 0.002
s <- 1       # diffusion noise
t_max <- 2.2

simulate_path <- function() {
  x <- z * a
  xs <- x
  v_i <- rnorm(1, v, sv)
  while (x > 0 && x < a && length(xs) * dt < t_max - ter) {
    x <- x + v_i * dt + s * sqrt(dt) * rnorm(1)
    xs <- c(xs, x)
  }
  xs <- pmin(pmax(xs, 0), a)
  data.frame(t = ter + (seq_along(xs) - 1) * dt, x = xs,
             hit = if (xs[length(xs)] >= a) "reject" else if (xs[length(xs)] <= 0) "accept" else "none")
}

# First-passage times for the RT distributions (vectorised simulation)
set.seed(11)
n_sim <- 40000
x <- rep(z * a, n_sim)
v_i <- rnorm(n_sim, v, sv)
rt <- rep(NA_real_, n_sim)
hit <- rep(NA_character_, n_sim)
active <- rep(TRUE, n_sim)
t_now <- ter
while (any(active) && t_now < t_max) {
  t_now <- t_now + dt
  idx <- which(active)
  x[idx] <- x[idx] + v_i[idx] * dt + s * sqrt(dt) * rnorm(length(idx))
  up <- idx[x[idx] >= a]
  lo <- idx[x[idx] <= 0]
  rt[up] <- t_now; hit[up] <- "reject"
  rt[lo] <- t_now; hit[lo] <- "accept"
  active[c(up, lo)] <- FALSE
}

# Defective densities: each curve's area is proportional to how often that
# response occurs, so Reject (favoured by v > 0) is larger, and drift
# variability makes the Accept distribution slower and more skewed.
dens_for <- function(h) {
  d <- density(rt[hit %in% h], from = ter, to = t_max, adjust = 1.2)
  data.frame(t = d$x, y = d$y * mean(hit %in% h))
}
d_rej <- dens_for("reject")
d_acc <- dens_for("accept")
scale_k <- 0.6 / max(d_rej$y, d_acc$y)
dens_reject <- data.frame(t = d_rej$t, ymin = a, ymax = a + d_rej$y * scale_k)
dens_accept <- data.frame(t = d_acc$t, ymin = 0, ymax = -d_acc$y * scale_k)
message(sprintf("P(reject) = %.2f; median RT reject = %.2f, accept = %.2f",
                mean(hit %in% "reject"), median(rt[hit %in% "reject"]),
                median(rt[hit %in% "accept"])))

# Example paths: 4 ending at Reject, 2 at Accept (reflecting the drift); one of each highlighted
set.seed(4)
paths <- list()
n_hit <- c(reject = 0, accept = 0)
want <- c(reject = 4, accept = 2)
while (sum(n_hit) < sum(want)) {
  p <- simulate_path()
  h <- p$hit[1]
  if (h != "none" && n_hit[h] < want[h] && max(p$t) < t_max - 0.3) {
    paths[[length(paths) + 1]] <- p
    n_hit[h] <- n_hit[h] + 1
  }
}
paths <- do.call(rbind, Map(\(p, i) cbind(p, id = i), paths, seq_along(paths)))
hi_reject <- paths[paths$hit == "reject", ]
# highlight the fastest Reject path so it stays clear of the v label
end_t <- tapply(hi_reject$t, hi_reject$id, max)
hi_reject <- hi_reject[hi_reject$id == as.integer(names(which.min(end_t))), ]
hi_accept <- paths[paths$hit == "accept", ]
hi_accept <- hi_accept[hi_accept$id == min(hi_accept$id), ]

x0 <- z * a
arrow_len <- 0.55
txt <- 3.6

g <- ggplot() +
  # RT distributions
  geom_ribbon(data = dens_reject, aes(t, ymin = ymin, ymax = ymax), fill = reject_col, alpha = 0.25) +
  geom_line(data = dens_reject, aes(t, ymax), colour = reject_col, linewidth = 0.6) +
  geom_ribbon(data = dens_accept, aes(t, ymin = ymax, ymax = ymin), fill = accept_col, alpha = 0.25) +
  geom_line(data = dens_accept, aes(t, ymax), colour = accept_col, linewidth = 0.6) +
  # Boundaries
  annotate("segment", x = 0, xend = t_max, y = a, yend = a, colour = reject_col, linewidth = 1.2) +
  annotate("segment", x = 0, xend = t_max, y = 0, yend = 0, colour = accept_col, linewidth = 1.2) +
  annotate("text", x = 0, y = a + 0.08, vjust = 0, hjust = 0, label = "Reject", colour = reject_col,
           fontface = "bold", size = 4.4) +
  annotate("text", x = 0, y = -0.08, vjust = 1, hjust = 0, label = "Accept", colour = accept_col,
           fontface = "bold", size = 4.4) +
  # Non-decision time
  annotate("rect", xmin = 0, xmax = ter, ymin = 0, ymax = a, fill = "grey85", alpha = 0.6) +
  annotate("segment", x = 0, xend = ter, y = a * 0.15, yend = a * 0.15, colour = ink,
           arrow = arrow(ends = "both", length = unit(0.08, "in")), linewidth = 0.4) +
  annotate("text", x = ter / 2, y = a * 0.25, label = "italic(T[er])", parse = TRUE,
           size = txt + 0.6, colour = ink) +
  annotate("text", x = ter / 2, y = a * 0.62, label = "Non-\ndecision\ntime",
           size = 2.9, colour = muted, lineheight = 0.9) +
  # Paths
  geom_path(data = paths[paths$hit == "reject", ], aes(t, x, group = id),
            colour = reject_col, alpha = 0.35, linewidth = 0.35) +
  geom_path(data = paths[paths$hit == "accept", ], aes(t, x, group = id),
            colour = accept_col, alpha = 0.35, linewidth = 0.35) +
  geom_path(data = hi_reject, aes(t, x), colour = reject_col, linewidth = 0.55) +
  geom_path(data = hi_accept, aes(t, x), colour = accept_col, linewidth = 0.55) +
  # Starting point
  annotate("segment", x = ter, xend = ter, y = 0, yend = x0, colour = ink,
           arrow = arrow(length = unit(0.08, "in")), linewidth = 0.4, linetype = "22") +
  annotate("point", x = ter, y = x0, size = 2.6, colour = ink) +
  annotate("text", x = ter - 0.04, y = x0, label = "italic(z)", parse = TRUE,
           hjust = 1, size = txt + 0.6, colour = ink) +
  # Drift rate
  annotate("segment", x = ter, xend = ter + arrow_len, y = x0, yend = x0 + v_arrow * arrow_len,
           colour = ink, linewidth = 0.9, arrow = arrow(length = unit(0.12, "in"), type = "closed")) +
  annotate("label", x = ter + arrow_len + 0.04, y = x0 + v_arrow * arrow_len + 0.1,
           label = "italic(v)", parse = TRUE, hjust = 0, size = txt + 0.6, colour = ink,
           fill = "white", border.colour = NA, label.padding = unit(0.08, "lines")) +
  # Boundary separation
  annotate("segment", x = -0.1, xend = -0.1, y = 0, yend = a, colour = ink,
           arrow = arrow(ends = "both", length = unit(0.08, "in")), linewidth = 0.4) +
  annotate("text", x = -0.16, y = a / 2, label = "italic(a)", parse = TRUE,
           hjust = 1, size = txt + 0.6, colour = ink) +
  labs(caption = paste0(
    "a = boundary separation (response caution);  z = starting point (a priori bias);\n",
    "v = drift rate (evidence accumulation; positive toward reject);  Ter = non-decision time.\n",
    "Lines: simulated evidence paths, colored by the response they end in (one of each highlighted).\nShaded curves: response-time distributions at each boundary; area reflects response probability."
  )) +
  scale_x_continuous("Time (s)", breaks = seq(0, 2, 0.5), expand = expansion(mult = c(0.02, 0.01))) +
  scale_y_continuous("Evidence", breaks = NULL) +
  coord_cartesian(xlim = c(-0.25, t_max), ylim = c(-0.75, a + 0.75), clip = "off") +
  theme_classic(base_family = "sans", base_size = 11) +
  theme(
    axis.line.y = element_blank(),
    axis.line.x = element_line(colour = muted, linewidth = 0.3),
    axis.ticks.x = element_line(colour = muted),
    axis.title = element_text(colour = ink),
    axis.text = element_text(colour = muted),
    plot.caption = element_text(hjust = 0, colour = muted, size = 8.5, lineheight = 1.1,
                                margin = margin(t = 8)),
    plot.caption.position = "plot",
    plot.margin = margin(10, 12, 6, 6)
  )

dir.create(file.path("analysis", "figures"), showWarnings = FALSE)
ggsave(file.path("analysis", "figures", "ddm-schematic.png"), g, width = 7, height = 4.6, dpi = 300, bg = "white")
ggsave(file.path("analysis", "figures", "ddm-schematic.pdf"), g, width = 7, height = 4.6, bg = "white")
message("Wrote analysis/figures/ddm-schematic.{png,pdf}")
