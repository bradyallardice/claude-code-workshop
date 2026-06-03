# Build a county-level panel joining presidential vote shares with IPUMS demographics.
#
# Reads:
#   - session_1/data/election/countypres_sample.csv (MIT Election Data + Science Lab)
#   - session_1/data/IPUMS/census_{year}_sample.csv.gz (IPUMS USA microdata)
#
# Outputs:
#   - session_1/output/county_panel.csv
#   - session_1/output/vote_share_2p_over_time.png
#   - session_1/output/vote_share_total_over_time.png
#   - session_1/output/demographics_over_time.png
#
# Variable coding (from IPUMS codebooks):
#   EDUC: 0=N/A or no schooling, 1=nursery-grade 4, 2=grade 5-8, 3=grade 9,
#         4=grade 10, 5=grade 11, 6=grade 12, 7=1yr college, 8=2yr college,
#         9=3yr college, 10=4yr college (bachelor's), 11=5+ years (graduate)
#   INCWAGE: 0=no wage income, 999998=missing, 999999=N/A
#   RACE: 1=White, 2=Black/African American, 3=AIAN, 4=Chinese, 5=Japanese,
#         6=Other Asian/PI, 7=Other, 8=Two major races, 9=Three+ major races
#   HISPAN: 0=Not Hispanic, 1=Mexican, 2=Puerto Rican, 3=Cuban, 4=Other,
#           9=Not Reported
#
# Run from the project root (AIAgentsCourse/):
#   Rscript session_2/scripts/build_county_panel.R

library(readr)
library(dplyr)
library(tidyr)

DATA_DIR   <- "session_1/data"
OUTPUT_DIR <- "session_1/output"
dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

ELECTION_TO_IPUMS <- c(
  "2012" = "census_2012_sample.csv.gz",
  "2016" = "census_2016_sample.csv.gz",
  "2020" = "census_2020_sample.csv.gz",
  "2024" = "census_2024_sample.csv.gz"
)
PANEL_YEARS <- as.integer(names(ELECTION_TO_IPUMS))


weighted_median <- function(values, weights) {
  # Compute the weighted median of a vector.
  idx <- order(values)
  v <- values[idx]; w <- weights[idx]
  cumulative <- cumsum(w)
  cutoff <- cumulative[length(cumulative)] / 2.0
  v[cumulative >= cutoff][1]
}


load_election_data <- function() {
  # Load and reshape presidential election data to county-year vote shares.
  df <- read_csv(file.path(DATA_DIR, "election", "countypres_sample.csv"),
                 show_col_types = FALSE)
  n_raw <- nrow(df)

  # Keep only TOTAL mode rows (excludes absentee/provisional breakdowns in 2020)
  df <- df %>% filter(mode == "TOTAL")
  cat(sprintf("  Kept %d of %d rows (mode == TOTAL)\n", nrow(df), n_raw))

  # Drop rows with missing FIPS
  n_before <- nrow(df)
  df <- df %>% filter(!is.na(county_fips))
  n_dropped <- n_before - nrow(df)
  if (n_dropped > 0) cat(sprintf("  WARNING: Dropped %d rows with missing county_fips\n", n_dropped))

  # Build clean 5-digit FIPS
  df$county_fips <- sprintf("%05d", as.integer(df$county_fips))

  # Pivot to get dem/rep votes per county-year
  major <- df %>% filter(party %in% c("DEMOCRAT", "REPUBLICAN"))
  votes <- major %>%
    group_by(county_fips, year, state, county_name, totalvotes, party) %>%
    summarise(candidatevotes = sum(candidatevotes), .groups = "drop") %>%
    pivot_wider(names_from = party, values_from = candidatevotes) %>%
    rename(dem_votes = DEMOCRAT, rep_votes = REPUBLICAN)

  # Check for missing vote counts (counties with only one party reporting)
  missing_dem <- sum(is.na(votes$dem_votes))
  missing_rep <- sum(is.na(votes$rep_votes))
  if (missing_dem > 0 || missing_rep > 0) {
    cat(sprintf("  WARNING: %d counties missing Dem votes, %d missing Rep votes\n",
                missing_dem, missing_rep))
    votes$dem_votes[is.na(votes$dem_votes)] <- 0
    votes$rep_votes[is.na(votes$rep_votes)] <- 0
  }

  # Two-party vote share
  total_major <- votes$dem_votes + votes$rep_votes
  votes$dem_share_2p <- votes$dem_votes / total_major
  votes$rep_share_2p <- votes$rep_votes / total_major

  # Total vote share (as fraction of all votes cast, including third parties)
  votes$turnout <- votes$totalvotes
  votes$dem_share_total <- votes$dem_votes / votes$turnout
  votes$rep_share_total <- votes$rep_votes / votes$turnout
  votes$third_party_share <- 1 - votes$dem_share_total - votes$rep_share_total

  cat(sprintf("  %d county-year observations\n", nrow(votes)))
  cat(sprintf("  %d unique counties, %d elections\n",
              n_distinct(votes$county_fips), n_distinct(votes$year)))
  cat(sprintf("  Mean third-party share: %.4f\n", mean(votes$third_party_share)))

  votes %>% select(county_fips, year, state, county_name,
                   dem_votes, rep_votes, turnout,
                   dem_share_2p, rep_share_2p,
                   dem_share_total, rep_share_total, third_party_share)
}


load_ipums_county <- function(year) {
  # Load IPUMS microdata for a given year and aggregate to county level.
  #
  # Variable handling:
  #   COUNTYFIP == 0: unidentified county, dropped
  #   EDUC == 0: N/A or no schooling, included in denominator for education shares
  #   INCWAGE == 999999: N/A (not in universe), excluded from wage calculations
  #   INCWAGE == 999998: missing, excluded from wage calculations
  #   INCWAGE == 0: no wage income, excluded (we want mean/median among earners)
  #   HISPAN == 9: not reported, excluded from Hispanic share calculation
  #   RACE: general version, 1-9 scale (see header for full coding)
  filename <- ELECTION_TO_IPUMS[[as.character(year)]]
  filepath <- file.path(DATA_DIR, "IPUMS", filename)

  if (!file.exists(filepath)) {
    cat(sprintf("  WARNING: %s not found, skipping year %d\n", filepath, year))
    return(NULL)
  }

  cat(sprintf("  Loading %s...\n", filename))
  df <- read_csv(filepath, show_col_types = FALSE)
  n_raw <- nrow(df)

  # Drop unidentified counties (COUNTYFIP == 0)
  df <- df %>% filter(COUNTYFIP != 0)
  n_dropped <- n_raw - nrow(df)
  if (n_dropped > 0)
    cat(sprintf("  Dropped %d observations with unidentified county (COUNTYFIP == 0)\n", n_dropped))

  if (nrow(df) == 0) {
    cat(sprintf("  WARNING: No identified counties in %s\n", filename))
    return(NULL)
  }

  # Build 5-digit FIPS from state + county codes
  df$county_fips <- sprintf("%02d%03d", df$STATEFIP, df$COUNTYFIP)

  # --- Age / Education / Race (weighted shares over full population) ---
  agg <- df %>% group_by(county_fips) %>% summarise(
    population        = sum(PERWT),
    mean_age          = weighted.mean(AGE, PERWT),
    share_age_18_34   = weighted.mean(AGE >= 18 & AGE <= 34, PERWT),
    share_age_65_plus = weighted.mean(AGE >= 65, PERWT),
    share_college     = weighted.mean(EDUC >= 10, PERWT),
    share_no_hs       = weighted.mean(EDUC <= 5, PERWT),
    share_white       = weighted.mean(RACE == 1, PERWT),
    share_black       = weighted.mean(RACE == 2, PERWT),
    .groups = "drop"
  )

  # --- Income: restrict to wage earners (INCWAGE > 0 and < 999998) ---
  workers <- df %>% filter(INCWAGE > 0, INCWAGE < 999998)
  n_excluded <- nrow(df) - nrow(workers)
  cat(sprintf("  Income: %d wage earners, %d excluded (N/A, missing, or no wage income)\n",
              nrow(workers), n_excluded))

  if (nrow(workers) > 0) {
    wage_agg <- workers %>% group_by(county_fips) %>% summarise(
      median_wage = weighted_median(INCWAGE, PERWT),
      mean_wage   = weighted.mean(INCWAGE, PERWT),
      .groups = "drop"
    )
    agg <- left_join(agg, wage_agg, by = "county_fips")
  } else {
    agg$median_wage <- NA_real_
    agg$mean_wage   <- NA_real_
  }

  # --- Hispanic origin: exclude HISPAN == 9 (Not Reported) ---
  hispan_valid <- df %>% filter(HISPAN != 9)
  if (nrow(hispan_valid) < nrow(df))
    cat(sprintf("  Hispanic: excluded %d observations with HISPAN == 9 (Not Reported)\n",
                nrow(df) - nrow(hispan_valid)))
  hisp_agg <- hispan_valid %>% group_by(county_fips) %>% summarise(
    share_hispanic = weighted.mean(HISPAN %in% c(1, 2, 3, 4), PERWT),
    .groups = "drop"
  )
  agg <- left_join(agg, hisp_agg, by = "county_fips")

  agg$year <- year
  cat(sprintf("  -> %d counties with identified FIPS\n", nrow(agg)))
  agg
}


validate_merge <- function(election, census, merged, year) {
  # Check that every county in each dataset found exactly one match.
  elec_fips <- unique(election$county_fips[election$year == year])
  cens_fips <- unique(census$county_fips)
  matched <- intersect(elec_fips, cens_fips)

  cat(sprintf("\n  Year %d merge validation:\n", year))
  cat(sprintf("    Election counties:  %d\n", length(elec_fips)))
  cat(sprintf("    Census counties:    %d\n", length(cens_fips)))
  cat(sprintf("    Matched:            %d\n", length(matched)))
  cat(sprintf("    Only in election:   %d\n", length(setdiff(elec_fips, cens_fips))))
  cat(sprintf("    Only in census:     %d\n", length(setdiff(cens_fips, elec_fips))))

  dupes <- merged %>% filter(year == !!year) %>% count(county_fips)
  n_dupes <- sum(dupes$n > 1)
  if (n_dupes > 0) cat(sprintf("    WARNING: %d counties have duplicate rows after merge!\n", n_dupes))
  else cat("    No duplicate matches (1:1 confirmed)\n")
}


main <- function() {
  cat("Loading presidential election data...\n")
  election <- load_election_data()
  cat(sprintf("  %d county-year observations across %d elections\n\n",
              nrow(election), n_distinct(election$year)))

  cat("Loading and aggregating IPUMS data by county...\n")
  census_panels <- list()
  for (year in sort(PANEL_YEARS)) {
    cat(sprintf("\nYear %d:\n", year))
    county_data <- load_ipums_county(year)
    if (!is.null(county_data)) census_panels[[as.character(year)]] <- county_data
  }
  census <- bind_rows(census_panels)
  cat(sprintf("\n\nTotal census county-year observations: %d\n", nrow(census)))

  # Merge
  cat("\n--- Merging datasets ---\n")
  panel <- inner_join(election, census, by = c("county_fips", "year"))
  cat(sprintf("Merged panel (before balancing): %d county-year observations, %d counties\n",
              nrow(panel), n_distinct(panel$county_fips)))

  # Validate each year (pre-balancing)
  for (year in sort(PANEL_YEARS)) {
    census_year <- census %>% filter(year == !!year)
    if (nrow(census_year) > 0) validate_merge(election, census_year, panel, year)
  }

  # --- Balance the panel: keep only counties present in all years ---
  cat("\n--- Balancing panel ---\n")
  n_years <- length(ELECTION_TO_IPUMS)
  county_year_counts <- panel %>% group_by(county_fips) %>% summarise(n = n_distinct(year))
  balanced_counties <- county_year_counts$county_fips[county_year_counts$n == n_years]
  n_before <- n_distinct(panel$county_fips)
  panel <- panel %>% filter(county_fips %in% balanced_counties)
  cat(sprintf("  Kept %d counties present in all %d years\n", length(balanced_counties), n_years))
  cat(sprintf("  Dropped %d counties with incomplete coverage\n", n_before - length(balanced_counties)))
  cat(sprintf("  Balanced panel: %d county-year observations\n", nrow(panel)))

  # --- Final validation ---
  cat("\n--- Final panel validation ---\n")
  dupes <- panel %>% count(county_fips, year)
  stopifnot(sum(dupes$n > 1) == 0)
  cat("  No duplicate county-year observations (1:1 confirmed)\n")

  stopifnot(setequal(unique(panel$year), PANEL_YEARS))
  cat(sprintf("  All %d expected years present\n", length(PANEL_YEARS)))

  for (col in c("county_fips", "year", "dem_share_2p", "rep_share_2p",
                "dem_share_total", "rep_share_total", "third_party_share",
                "population", "mean_age")) {
    n_na <- sum(is.na(panel[[col]]))
    if (n_na > 0) cat(sprintf("  WARNING: %d missing values in %s\n", n_na, col))
    else cat(sprintf("  %s: no missing values\n", col))
  }

  stopifnot(all(panel$dem_share_2p >= 0 & panel$dem_share_2p <= 1))
  stopifnot(all(panel$rep_share_2p >= 0 & panel$rep_share_2p <= 1))
  stopifnot(all(round(panel$dem_share_2p + panel$rep_share_2p, 10) == 1.0))
  cat("  Two-party shares valid (sum to 1)\n")

  share_sum_total <- round(panel$dem_share_total + panel$rep_share_total + panel$third_party_share, 10)
  stopifnot(all(share_sum_total == 1.0))
  stopifnot(all(panel$third_party_share >= 0 & panel$third_party_share <= 1))
  cat("  Total shares valid (dem + rep + third party sum to 1)\n")

  stopifnot(all(panel$population > 0))
  cat(sprintf("  Population: all positive (min=%s, max=%s)\n",
              format(min(panel$population), big.mark = ",", scientific = FALSE),
              format(max(panel$population), big.mark = ",", scientific = FALSE)))

  # Save panel
  outpath <- file.path(OUTPUT_DIR, "county_panel.csv")
  write_csv(panel, outpath)
  cat(sprintf("\nPanel saved to %s\n", outpath))
  cat(sprintf("Shape: %d x %d\n", nrow(panel), ncol(panel)))
  cat(sprintf("Years: %s\n", paste(sort(unique(panel$year)), collapse = ", ")))
  cat(sprintf("Unique counties: %d\n", n_distinct(panel$county_fips)))

  # ================================================================
  #  EXPLORATORY DATA ANALYSIS
  # ================================================================
  cat("\n", strrep("=", 60), "\n", sep = "")
  cat("EXPLORATORY DATA ANALYSIS\n")
  cat(strrep("=", 60), "\n", sep = "")

  cat("\nMean two-party vote share by year:\n")
  year_means_2p <- panel %>% group_by(year) %>%
    summarise(dem_share_2p = mean(dem_share_2p), rep_share_2p = mean(rep_share_2p))
  print(as.data.frame(year_means_2p), digits = 4)

  cat("\nMean total vote share by year:\n")
  year_means_total <- panel %>% group_by(year) %>%
    summarise(dem_share_total = mean(dem_share_total),
              rep_share_total = mean(rep_share_total),
              third_party_share = mean(third_party_share))
  print(as.data.frame(year_means_total), digits = 4)

  # --- Year-to-year swings (two-party) ---
  cat("\nLargest year-to-year swings in Democratic two-party vote share:\n")
  panel_sorted <- panel %>% arrange(county_fips, year) %>% group_by(county_fips) %>%
    mutate(dem_2p_lag = lag(dem_share_2p), swing_2p = dem_share_2p - dem_2p_lag,
           dem_total_lag = lag(dem_share_total), swing_total = dem_share_total - dem_total_lag) %>%
    ungroup()
  top_swings <- panel_sorted %>% filter(!is.na(swing_2p)) %>%
    mutate(abs_swing = abs(swing_2p)) %>% arrange(desc(abs_swing)) %>% head(20) %>%
    select(county_fips, county_name, state, year, dem_2p_lag, dem_share_2p, swing_2p)
  print(as.data.frame(top_swings), digits = 4, row.names = FALSE)

  cat("\nLargest year-to-year swings in Democratic total vote share:\n")
  top_swings_t <- panel_sorted %>% filter(!is.na(swing_total)) %>%
    mutate(abs_swing = abs(swing_total)) %>% arrange(desc(abs_swing)) %>% head(20) %>%
    select(county_fips, county_name, state, year, dem_total_lag, dem_share_total, swing_total)
  print(as.data.frame(top_swings_t), digits = 4, row.names = FALSE)

  # --- Largest change from 2012 ---
  cat("\nLargest change from 2012 Democratic two-party vote share (any year):\n")
  baseline <- panel %>% filter(year == 2012) %>%
    select(county_fips, dem_2p_2012 = dem_share_2p)
  panel_with_base <- panel %>% left_join(baseline, by = "county_fips") %>%
    mutate(change_from_2012 = dem_share_2p - dem_2p_2012, abs_change = abs(change_from_2012))
  changes <- panel_with_base %>% filter(year != 2012)
  max_change <- changes %>% group_by(county_fips) %>%
    slice_max(abs_change, n = 1, with_ties = FALSE) %>% ungroup()
  top_changes <- max_change %>% arrange(desc(abs_change)) %>% head(20) %>%
    select(county_fips, county_name, state, year, dem_2p_2012, dem_share_2p, change_from_2012)
  print(as.data.frame(top_changes), digits = 4, row.names = FALSE)

  # ================================================================
  #  GRAPHICS
  # ================================================================

  # --- Plot 1: Two-party vote share over time ---
  png(file.path(OUTPUT_DIR, "vote_share_2p_over_time.png"), width = 8, height = 5,
      units = "in", res = 150)
  plot(year_means_2p$year, year_means_2p$dem_share_2p, type = "b", pch = 19,
       col = "#1f77b4", lwd = 2, ylim = c(0.3, 0.7),
       xlab = "Year", ylab = "Vote Share", main = "Mean Two-Party Vote Share Over Time")
  lines(year_means_2p$year, year_means_2p$rep_share_2p, type = "b", pch = 19,
        col = "#d62728", lwd = 2)
  legend("topright", legend = c("Democratic", "Republican"),
         col = c("#1f77b4", "#d62728"), lwd = 2, pch = 19)
  grid()
  dev.off()
  cat("\nSaved: vote_share_2p_over_time.png\n")

  # --- Plot 2: Total vote share over time (including third parties) ---
  png(file.path(OUTPUT_DIR, "vote_share_total_over_time.png"), width = 8, height = 5,
      units = "in", res = 150)
  plot(year_means_total$year, year_means_total$dem_share_total, type = "b", pch = 19,
       col = "#1f77b4", lwd = 2, ylim = c(0, 0.7),
       xlab = "Year", ylab = "Vote Share",
       main = "Mean Total Vote Share Over Time (Including Third Parties)")
  lines(year_means_total$year, year_means_total$rep_share_total, type = "b", pch = 19,
        col = "#d62728", lwd = 2)
  lines(year_means_total$year, year_means_total$third_party_share, type = "b", pch = 15,
        col = "gray", lwd = 2, lty = 2)
  legend("topright", legend = c("Democratic", "Republican", "Third Party"),
         col = c("#1f77b4", "#d62728", "gray"), lwd = 2, pch = c(19, 19, 15),
         lty = c(1, 1, 2))
  grid()
  dev.off()
  cat("Saved: vote_share_total_over_time.png\n")

  # --- Plot 3: Mean demographic variables over time ---
  demo_vars   <- c("mean_age", "share_college", "share_white", "share_hispanic", "mean_wage")
  demo_labels <- c("Mean Age", "Share College", "Share White", "Share Hispanic", "Mean Wage")
  demo_means  <- panel %>% group_by(year) %>%
    summarise(across(all_of(demo_vars), mean))

  png(file.path(OUTPUT_DIR, "demographics_over_time.png"), width = 14, height = 8,
      units = "in", res = 150)
  par(mfrow = c(2, 3), oma = c(0, 0, 3, 0))
  for (i in seq_along(demo_vars)) {
    plot(demo_means$year, demo_means[[demo_vars[i]]], type = "b", pch = 19,
         col = "steelblue", lwd = 2, xlab = "Year", ylab = "", main = demo_labels[i])
    grid()
  }
  plot.new()  # 6th cell left blank
  mtext("Mean Demographic Variables Over Time (County-Level)", outer = TRUE, cex = 1.2)
  dev.off()
  cat("Saved: demographics_over_time.png\n")

  cat("\nDone!\n")
}

main()
