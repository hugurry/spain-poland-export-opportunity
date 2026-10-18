# 05_vehicles_drilldown.R
# Goal: break down chapter 87 (vehicles) into HS4 headings to see which
# products explain Spain's loss of market share in Poland.

library(tidyverse)
library(DBI)
library(duckdb)

con <- dbConnect(duckdb())

# Poland's imports of chapter 87 by HS4 heading, only for 2019 and 2024
vehicles_hs4 <- dbGetQuery(con, "
  SELECT t AS year,
         CAST(FLOOR(TRY_CAST(k AS BIGINT) / 100) AS INTEGER) AS hs4,
         SUM(v) AS poland_imports_kusd,
         SUM(CASE WHEN i = 724 THEN v ELSE 0 END) AS from_spain_kusd
  FROM read_csv_auto(['data/BACI_HS17_Y2019_V202601.csv',
                      'data/BACI_HS17_Y2024_V202601.csv'])
  WHERE j = 616
    AND FLOOR(TRY_CAST(k AS BIGINT) / 10000) = 87
  GROUP BY t, hs4
")

dbDisconnect(con, shutdown = TRUE)

vehicles_summary <- vehicles_hs4 |>
  pivot_wider(
    names_from  = year,
    values_from = c(poland_imports_kusd, from_spain_kusd)
  ) |>
  # Keep headings with at least USD 100 million of Polish imports in 2024
  filter(poland_imports_kusd_2024 >= 1e5) |>
  mutate(
    market_2024_usd_bn = poland_imports_kusd_2024 / 1e6,
    spain_share_2019   = 100 * from_spain_kusd_2019 / poland_imports_kusd_2019,
    spain_share_2024   = 100 * from_spain_kusd_2024 / poland_imports_kusd_2024,
    share_change_pp    = spain_share_2024 - spain_share_2019,
    value_gap_usd_bn   = share_change_pp / 100 * market_2024_usd_bn
  ) |>
  select(hs4, market_2024_usd_bn, spain_share_2019, spain_share_2024,
         share_change_pp, value_gap_usd_bn) |>
  arrange(desc(market_2024_usd_bn)) |>
  mutate(across(where(is.numeric), \(x) round(x, 3)))

print(vehicles_summary, width = Inf)