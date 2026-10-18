# 09_totals_chart.R
# Goal: chart of Spain's exports to Poland and Spain's share of Polish imports,
# 2017-2024, saved as a PNG for the report and for sharing.

library(tidyverse)

hs2_year <- read_csv("data/processed/hs2_year.csv", show_col_types = FALSE)

# Totals by year, summing all HS2 chapters
totals <- hs2_year |>
  group_by(year) |>
  summarise(
    poland_imports = sum(poland_imports_kusd) / 1e6,
    from_spain     = sum(from_spain_kusd) / 1e6,
    .groups = "drop"
  ) |>
  mutate(share = 100 * from_spain / poland_imports)

p_totals <- ggplot(totals, aes(x = year, y = from_spain)) +
  geom_col(fill = "#e76f51", width = 0.7) +
  geom_text(aes(label = paste0(round(share, 1), "%")), vjust = -0.6, size = 4.5) +
  scale_x_continuous(breaks = 2017:2024) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(
    title = "Spain's exports to Poland grew 64%, but its market share stayed flat",
    subtitle = "Bars: Spanish exports (USD bn). Labels: Spain's share of Polish imports",
    x = NULL, y = "USD bn",
    caption = "Source: CEPII BACI (HS17, v202601), current USD."
  ) +
  theme_minimal(base_size = 14)

dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
ggsave("output/figures/totals_share.png", p_totals, width = 9, height = 5.5, dpi = 300)

p_totals