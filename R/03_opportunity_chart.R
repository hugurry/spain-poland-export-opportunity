# 03_opportunity_chart.R
# Goal: plot market growth vs. change in Spain's market share, by HS2 chapter.
# Only the chapters that matter are labelled (large markets or large USD effect).

library(tidyverse)
library(ggrepel)

opportunity <- read_csv("data/processed/opportunity_hs2.csv", show_col_types = FALSE)

# Short names for the chapters that can appear as labels
hs2_names <- tribble(
  ~hs2, ~chapter,
  85, "Electrical equipment",
  84, "Machinery",
  87, "Vehicles",
  39, "Plastics",
  30, "Pharmaceuticals",
  72, "Iron & steel",
  62, "Apparel (woven)",
  61, "Apparel (knitted)",
  33, "Cosmetics",
  8,  "Fruit",
  2,  "Meat",
  7,  "Vegetables"
)

# Exclude fuels (27: commodity) and arms (93: state defence purchases)
plot_data <- opportunity |>
  filter(!hs2 %in% c(27, 93)) |>
  mutate(value_gap_usd_bn = share_change_pp / 100 * market_2024_usd_bn) |>
  left_join(hs2_names, by = "hs2") |>
  # Label large markets (> USD 10 bn) or chapters with a USD effect above 50 million
  mutate(label = if_else(
    market_2024_usd_bn >= 10 | abs(value_gap_usd_bn) >= 0.05,
    chapter, NA_character_
  ))

median_growth <- median(plot_data$market_cagr_pct)

p <- ggplot(plot_data, aes(x = market_cagr_pct, y = share_change_pp)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_vline(xintercept = median_growth, linetype = "dashed", colour = "grey50") +
  geom_point(aes(size = market_2024_usd_bn, colour = share_change_pp > 0), alpha = 0.7) +
  geom_text_repel(aes(label = label), size = 3.2, na.rm = TRUE,
                  box.padding = 0.6, max.overlaps = Inf, seed = 1) +
  scale_size_area(max_size = 14, name = "Poland imports 2024\n(USD bn)") +
  scale_colour_manual(values = c("TRUE" = "#2a9d8f", "FALSE" = "#e76f51"), guide = "none") +
  labs(
    title = "Where is Spain gaining or losing ground in Poland?",
    subtitle = "HS2 chapters with > USD 1 bn of Polish imports, 2019-2024",
    x = "Growth of Polish imports (CAGR 2019-2024, %)",
    y = "Change in Spain's market share (percentage points)",
    caption = "Source: CEPII BACI (HS17, v202601), values in current USD. Excludes fuels (27) and arms (93)."
  ) +
  theme_minimal()

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
ggsave("output/figures/opportunity_map.png", p, width = 10, height = 6.5, dpi = 300)

p