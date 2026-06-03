# Generate FX exchange rate time series figure for the Session 3 LaTeX exercise.
# Plots the CHF/PLN exchange rate over time, highlighting the SNB floor removal
# event (January 15, 2015) that shocked Polish FX loan holders.
#
# Run from the project root (AIAgentsCourse/):
#   Rscript session_3/scripts/generate_fx_figure.R

library(readr)
library(dplyr)
library(ggplot2)

# -- Load FX data -----------------------------------------------------
df <- read_csv("session_3/data/PLN_CHF_EUR_FXdata.csv", show_col_types = FALSE)
df$date <- as.Date(df$`YYYY/MM/DD`, format = "%Y/%m/%d")
df <- df %>% arrange(date)

# -- Plot -------------------------------------------------------------
event_date <- as.Date("2015-01-15")

p <- ggplot(df, aes(x = date, y = `CHF/PLN`)) +
  geom_line(color = "#1f4e79", linewidth = 0.7) +
  geom_vline(xintercept = event_date, color = "#c00000",
             linetype = "dashed", linewidth = 0.5, alpha = 0.8) +
  annotate("text",
           x = event_date, y = max(df$`CHF/PLN`) * 0.98,
           label = "SNB removes\nCHF/EUR floor\n(Jan 15, 2015)",
           hjust = -0.05, vjust = 1, size = 3, color = "#c00000") +
  scale_x_date(date_breaks = "2 months", date_labels = "%b %Y") +
  labs(x = "Date", y = "CHF/PLN Exchange Rate",
       title = "Swiss Franc to Polish Zloty Exchange Rate") +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    axis.text.x = element_text(angle = 30, hjust = 1),
    panel.grid.minor = element_blank()
  )

ggsave("session_3/output/fx_rate_figure.png", p,
       width = 9, height = 5, dpi = 300)

cat("Saved: session_3/output/fx_rate_figure.png\n")
