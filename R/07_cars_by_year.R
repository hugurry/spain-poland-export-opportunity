# 07_cars_by_year.R
# Goal: yearly evolution of Spain's exports of passenger cars (HS 8703) to Poland,
# and check what HS 8710 is in the product code table.

library(tidyverse)
library(DBI)
library(duckdb)

con <- dbConnect(duckdb())

cars_year <- dbGetQuery(con, "
  SELECT t AS year,
         ROUND(SUM(v) / 1e6, 2) AS poland_imports_usd_bn,
         ROUND(SUM(CASE WHEN i = 724 THEN v ELSE 0 END) / 1e6, 3) AS from_spain_usd_bn,
         ROUND(100.0 * SUM(CASE WHEN i = 724 THEN v ELSE 0 END) / SUM(v), 2) AS spain_share_pct
  FROM read_csv_auto('data/BACI_HS17_Y*_V202601.csv')
  WHERE j = 616
    AND FLOOR(TRY_CAST(k AS BIGINT) / 100) = 8703
  GROUP BY t
  ORDER BY t
")

dbDisconnect(con, shutdown = TRUE)

print(cars_year)

# What products are inside HS 8710? (we do not assume the column names)
product_codes <- read_csv("data/product_codes_HS17_V202601.csv", show_col_types = FALSE)
product_codes |>
  filter(if_any(everything(), \(x) str_starts(as.character(x), "8710"))) |>
  print(width = Inf)
# Save the yearly car table for the chart and the report
write_csv(cars_year, "data/processed/cars_8703_year.csv")