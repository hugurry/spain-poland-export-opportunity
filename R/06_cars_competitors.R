# 06_cars_competitors.R
# Goal: see which exporters supply Poland's passenger-car imports (HS 8703)
# and how their shares changed between 2019 and 2024.

library(tidyverse)
library(DBI)
library(duckdb)

con <- dbConnect(duckdb())

# Poland's imports of passenger cars by exporting country
cars_by_exporter <- dbGetQuery(con, "
  SELECT t AS year,
         i AS exporter_code,
         SUM(v) AS imports_kusd
  FROM read_csv_auto(['data/BACI_HS17_Y2019_V202601.csv',
                      'data/BACI_HS17_Y2024_V202601.csv'])
  WHERE j = 616
    AND FLOOR(TRY_CAST(k AS BIGINT) / 100) = 8703
  GROUP BY t, i
")

dbDisconnect(con, shutdown = TRUE)

country_codes <- read_csv("data/country_codes_V202601.csv", show_col_types = FALSE)

cars_summary <- cars_by_exporter |>
  group_by(year) |>
  mutate(share_pct = 100 * imports_kusd / sum(imports_kusd)) |>
  ungroup() |>
  left_join(country_codes |> select(country_code, country_name),
            by = c("exporter_code" = "country_code")) |>
  select(year, country_name, imports_kusd, share_pct) |>
  pivot_wider(
    names_from  = year,
    values_from = c(imports_kusd, share_pct),
    values_fill = 0
  ) |>
  mutate(
    imports_2024_usd_bn = imports_kusd_2024 / 1e6,
    share_change_pp     = share_pct_2024 - share_pct_2019
  ) |>
  arrange(desc(imports_kusd_2024)) |>
  select(country_name, imports_2024_usd_bn, share_pct_2019,
         share_pct_2024, share_change_pp) |>
  mutate(across(where(is.numeric), \(x) round(x, 2)))

print(head(cars_summary, 12), width = Inf)
# Save the competitor table for the report
write_csv(cars_summary, "data/processed/cars_competitors.csv")