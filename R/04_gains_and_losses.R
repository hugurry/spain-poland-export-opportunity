# 04_gains_and_losses.R
# Goal: translate share changes into an approximate USD value gap,
# i.e. how much more/less Spain would sell if it had kept its 2019 share.

library(tidyverse)

opportunity <- read_csv("data/processed/opportunity_hs2.csv", show_col_types = FALSE)

gap <- opportunity |>
  filter(!hs2 %in% c(27, 93)) |>
  mutate(value_gap_usd_bn = share_change_pp / 100 * market_2024_usd_bn) |>
  select(hs2, market_2024_usd_bn, spain_share_2019, spain_share_2024,
         share_change_pp, value_gap_usd_bn) |>
  mutate(across(where(is.numeric), \(x) round(x, 2)))

# Biggest losses
gap |> arrange(value_gap_usd_bn) |> head(8)

# Biggest gains
gap |> arrange(desc(value_gap_usd_bn)) |> head(8)