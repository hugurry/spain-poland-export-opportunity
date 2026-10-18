# 08_cars_chart.R
# Goal: compare the growth of Poland's passenger-car imports with Spain's
# car exports to Poland (index 2019 = 100).

library(tidyverse)

cars_year <- read_csv("data/processed/cars_8703_year.csv", show_col_types = FALSE)

cars_index <- cars_year |>
  mutate(
    market = 100 * poland_imports_usd_bn / poland_imports_usd_bn[year == 2019],
    spain  = 100 * from_spain_usd_bn / from_spain_usd_bn[year == 2019]
  ) |>
  select(year, market, spain) |>
  pivot_longer(c(market, spain), names_to = "series", values_to = "index") |>
  mutate(series = factor(
    series,
    levels = c("market", "spain"),
    labels = c("Poland's car imports (all origins)", "Spain's car exports to Poland")
  ))

p_cars <- ggplot(cars_index, aes(x = year, y = index, colour = series)) +
  geom_hline(yintercept = 100, linetype = "dashed", colour = "grey60") +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_text(
    data = filter(cars_index, year == 2024),
    aes(label = round(index)),
    vjust = -1, show.legend = FALSE
  ) +
  scale_colour_manual(values = c("#6c757d", "#e76f51"), name = NULL) +
  scale_x_continuous(breaks = 2017:2024) +
  labs(
    title = "Poland's car market took off; Spain's sales did not keep pace",
    subtitle = "Passenger cars (HS 8703), index 2019 = 100, current USD",
    x = NULL,
    y = "Index (2019 = 100)",
    caption = "Source: CEPII BACI (HS17, v202601)."
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")

ggsave("output/figures/cars_index.png", p_cars, width = 9, height = 5.5, dpi = 300)

p_cars