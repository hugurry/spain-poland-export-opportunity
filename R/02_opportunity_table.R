# 02_opportunity_table.R
# Goal: build a first opportunity table by HS2 chapter for Spain in Poland.

library(tidyverse)

hs2_year <- read_csv("data/processed/hs2_year.csv", show_col_types = FALSE)

opportunity <- hs2_year |>
  filter(year %in% c(2019, 2024)) |>
  pivot_wider(
    names_from  = year,
    values_from = c(poland_imports_kusd, from_spain_kusd)
  ) |>
  # Keep chapters with at least USD 1 bn of Polish imports in 2024
  filter(poland_imports_kusd_2024 >= 1e6, poland_imports_kusd_2019 > 0) |>
  mutate(
    market_2024_usd_bn = poland_imports_kusd_2024 / 1e6,
    market_cagr_pct    = ((poland_imports_kusd_2024 / poland_imports_kusd_2019)^(1 / 5) - 1) * 100,
    spain_share_2019   = 100 * from_spain_kusd_2019 / poland_imports_kusd_2019,
    spain_share_2024   = 100 * from_spain_kusd_2024 / poland_imports_kusd_2024,
    share_change_pp    = spain_share_2024 - spain_share_2019
  ) |>
  select(hs2, market_2024_usd_bn, market_cagr_pct,
         spain_share_2019, spain_share_2024, share_change_pp) |>
  arrange(desc(market_2024_usd_bn))

opportunity |>
  mutate(across(where(is.numeric), \(x) round(x, 2))) |>
  print(n = 30)
# Save the opportunity table for the chart and the report
write_csv(opportunity, "data/processed/opportunity_hs2.csv")
