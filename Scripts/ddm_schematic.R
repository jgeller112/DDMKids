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
v <- 0       # drift rate used for simulation: 0 so both responses are equally likely
v_arrow <- 0.9  # slope of the illustrative drift arrow (direction of evidence accumulation)
ter <- 0.3   # non-decision time (s)
dt <- 0.002
s <- 1       # diffusion noise
t_max <- 2.2

simulate_path <- function() {
  x <- z * a
  xs <- x
  while (x > 0 && x < a && length(xs) * dt < t_max - ter) {
    x <- x + v * dt + s * sqrt(dt) * rnorm(1)
    xs <- c(xs, x)
  }
  xs <- pmin(pmax(xs, 0), a)
  data.frame(t = ter + (seq_along(xs) - 1) * dt, x = xs,
             hit = if (xs[length(xs)] >= a) "reject" else if (xs[length(xs)] <= 0) "accept" else "none")
}

# First-passage times for the RT distributions
set.seed(11)
fpt <- do.call(rbind, lapply(1:4000, \(i) {
  p <- simulate_path()
  data.frame(rt = max(p$t), hit = p$hit[1])
}))
fpt <- fpt[fpt$hit != "none", ]

# With v = 0 and z = .5 the model is symmetric, so both boundaries share one
# RT distribution. Pool all first-passage times (removes simulation noise)
# and draw the same curve above Reject and mirrored below Accept.
d_rt <- density(fpt$rt, from = ter, to = t_max, adjust = 1.2)
d_y <- d_rt$y / max(d_rt$y) * 0.6
dens_reject <- data.frame(t = d_rt$x, ymin = a, ymax = a + d_y)
dens_accept <- data.frame(t = d_rt$x, ymin = 0, ymax = -d_y)

# Example paths: 3 ending at Reject, 3 at Accept; one of each highlighted
set.seed(4)
paths <- list()
n_hit <- c(reject = 0, accept = 0)
want <- c(reject = 3, accept = 3)
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
hi_reject <- hi_reject[hi_reject$id == min(hi_reject$id), ]
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
    "Lines: simulated evidence paths, colored by the response they end in (one of each highlighted).\nShaded curves: response-time distributions at each boundary."
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
