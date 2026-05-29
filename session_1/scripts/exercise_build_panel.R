# Exercise: Build a county-level panel joining election returns with IPUMS demographics.
#
# This script works but has no validation, no logging, and no edge case handling.
# Your task: ask Claude Code to improve it.

data_dir <- file.path("session_1", "data")
output_dir <- file.path("session_1", "output")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# --- Load election data ---

elec <- read.csv(file.path(data_dir, "election", "countypres_sample.csv"),
                 stringsAsFactors = FALSE)
elec <- elec[elec$mode == "TOTAL", ]
elec <- elec[!is.na(elec$county_fips), ]
elec$county_fips <- sprintf("%05d", as.integer(elec$county_fips))

major <- elec[elec$party %in% c("DEMOCRAT", "REPUBLICAN"), ]
votes <- aggregate(candidatevotes ~ county_fips + year + state + county_name +
                     totalvotes + party,
                   data = major, FUN = sum)
votes <- reshape(votes,
                 idvar = c("county_fips", "year", "state", "county_name", "totalvotes"),
                 timevar = "party", direction = "wide")
names(votes)[names(votes) == "candidatevotes.DEMOCRAT"] <- "dem_votes"
names(votes)[names(votes) == "candidatevotes.REPUBLICAN"] <- "rep_votes"

votes$dem_share <- votes$dem_votes / (votes$dem_votes + votes$rep_votes)
votes$rep_share <- votes$rep_votes / (votes$dem_votes + votes$rep_votes)
votes$turnout <- votes$totalvotes

election <- votes[, c("county_fips", "year", "state", "county_name",
                      "dem_votes", "rep_votes", "dem_share", "rep_share", "turnout")]

# --- Load and aggregate IPUMS data ---

election_to_ipums <- c("2012" = "census_2012_sample.csv.gz",
                       "2016" = "census_2016_sample.csv.gz",
                       "2020" = "census_2020_sample.csv.gz",
                       "2024" = "census_2024_sample.csv.gz")

wmean <- function(x, w) sum(x * w) / sum(w)

census_panels <- list()
for (yr in names(election_to_ipums)) {
  filepath <- file.path(data_dir, "ipums", election_to_ipums[[yr]])
  df <- read.csv(gzfile(filepath), stringsAsFactors = FALSE)
  df <- df[df$COUNTYFIP != 0, ]
  df$county_fips <- paste0(sprintf("%02d", df$STATEFIP),
                           sprintf("%03d", df$COUNTYFIP))

  agg <- do.call(rbind, by(df, df$county_fips, function(g) {
    data.frame(
      county_fips   = g$county_fips[1],
      population    = sum(g$PERWT),
      mean_age      = wmean(g$AGE, g$PERWT),
      share_college = wmean(g$EDUC >= 10, g$PERWT),
      share_white   = wmean(g$RACE == 1, g$PERWT),
      share_hispanic = wmean(g$HISPAN > 0, g$PERWT),
      mean_wage     = wmean(g$INCWAGE, g$PERWT),
      stringsAsFactors = FALSE
    )
  }))
  agg$year <- as.integer(yr)
  census_panels[[yr]] <- agg
}

census <- do.call(rbind, census_panels)

# --- Merge and save ---

panel <- merge(election, census, by = c("county_fips", "year"))
write.csv(panel, file.path(output_dir, "county_panel.csv"), row.names = FALSE)

# ==================================================================
#  EXPLORATORY DATA ANALYSIS
# ==================================================================

cat(strrep("=", 60), "\n")
cat("PANEL SUMMARY\n")
cat(strrep("=", 60), "\n")
cat("Rows:", nrow(panel), " Cols:", ncol(panel), "\n")
cat("Years:", paste(sort(unique(panel$year)), collapse = ", "), "\n")
cat("Counties:", length(unique(panel$county_fips)), "\n\n")

# --- Mean vote share by year ---
cat("Mean two-party vote share by year:\n")
year_means <- aggregate(cbind(dem_share, rep_share) ~ year, data = panel, FUN = mean)
print(year_means, digits = 4)
cat("\n")

# --- Year-to-year swings (biggest in absolute terms) ---
cat("Largest year-to-year swings in Democratic vote share:\n")
panel <- panel[order(panel$county_fips, panel$year), ]
panel$dem_share_lag <- ave(panel$dem_share, panel$county_fips,
                           FUN = function(x) c(NA, head(x, -1)))
panel$swing <- panel$dem_share - panel$dem_share_lag
swings <- panel[!is.na(panel$swing), ]
swings$abs_swing <- abs(swings$swing)
top_swings <- head(swings[order(-swings$abs_swing),
                          c("county_fips", "county_name", "state", "year",
                            "dem_share_lag", "dem_share", "swing")], 20)
print(top_swings, digits = 4, row.names = FALSE)
cat("\n")

# ==================================================================
#  GRAPHICS
# ==================================================================

# --- Plot 1: Mean vote share over time ---
png(file.path(output_dir, "vote_share_over_time.png"), width = 800, height = 500)
plot(year_means$year, year_means$dem_share, type = "b", pch = 19, lwd = 2,
     col = "blue", ylim = c(0.3, 0.7), xlab = "Year", ylab = "Vote Share",
     main = "Mean Two-Party Vote Share Over Time")
lines(year_means$year, year_means$rep_share, type = "b", pch = 19, lwd = 2, col = "red")
legend("topright", legend = c("Democratic", "Republican"),
       col = c("blue", "red"), lwd = 2, pch = 19)
dev.off()
cat("Saved: vote_share_over_time.png\n")

# --- Plot 2: Mean demographic variables over time ---
demo_vars <- c("mean_age", "share_college", "share_white", "share_hispanic", "mean_wage")
demo_labels <- c("Mean Age", "Share College", "Share White", "Share Hispanic", "Mean Wage")
demo_means <- aggregate(panel[, demo_vars], by = list(year = panel$year), FUN = mean)

png(file.path(output_dir, "demographics_over_time.png"), width = 1400, height = 800)
par(mfrow = c(2, 3))
for (i in seq_along(demo_vars)) {
  plot(demo_means$year, demo_means[[demo_vars[i]]], type = "b", pch = 19, lwd = 2,
       col = "steelblue", xlab = "Year", ylab = "", main = demo_labels[i])
}
dev.off()
cat("Saved: demographics_over_time.png\n")

cat("\nDone!\n")
