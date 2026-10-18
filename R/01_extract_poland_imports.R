# 01_extract_poland_imports.R
# Goal: extract Poland's imports by year and HS2 chapter from CEPII BACI,
# and keep track of how much of them comes from Spain.
# Source: BACI HS17, version 202601 (values in thousand USD).

library(tidyverse)
library(DBI)
library(duckdb)

# BACI country codes: Spain = 724, Poland = 616
spain_code  <- 724
poland_code <- 616

# Open a temporary DuckDB connection (SQL engine that reads the CSV files directly)
con <- dbConnect(duckdb())

# Poland's imports and Spain's exports to Poland, by year and HS2 chapter
hs2_year <- dbGetQuery(con, sprintf("
  SELECT t AS year,
         CAST(FLOOR(TRY_CAST(k AS BIGINT) / 10000) AS INTEGER) AS hs2,
         SUM(v) AS poland_imports_kusd,
         SUM(CASE WHEN i = %d THEN v ELSE 0 END) AS from_spain_kusd
  FROM read_csv_auto('data/BACI_HS17_Y*_V202601.csv')
  WHERE j = %d
  GROUP BY t, hs2
  ORDER BY t, hs2
", spain_code, poland_code))

# Save the result so later scripts do not need to read the large raw files
dir.create("data/processed", showWarnings = FALSE)
write_csv(hs2_year, "data/processed/hs2_year.csv")

dbDisconnect(con, shutdown = TRUE)