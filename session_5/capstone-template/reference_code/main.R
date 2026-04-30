# List of required packages
required_packages <- c(
  "dplyr",
  "tidyr",
  "ggplot2",
  "janitor",
  "cregg",
  "patchwork",
  "scales",
  "MetBrewer",
  "rcartocolor",
  "magrittr"
)

# Install any packages that are not already installed
installed_packages <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!pkg %in% installed_packages) {
    install.packages(pkg, dependencies = TRUE)
  }
}

# For the 'cregg' package, ensure you install version 0.4.0 if needed
if (packageVersion("cregg") != "0.4.0") {
  if (!"remotes" %in% installed_packages) {
    install.packages("remotes")
  }
  remotes::install_version("cregg", version = "0.4.0", dependencies = TRUE)
}

# Load required packages
lapply(required_packages, library, character.only = TRUE)     

# Clear environment

rm(list = ls()) 

options(scipen=999)#turn off scientific notation.

# Format numbers 
nice_number <- label_number(style_negative = "minus", accuracy = 0.01)
nice_p <- label_pvalue(prefix = c("p < ", "p = ", "p > "))

# Custom ggplot theme
theme_mfx <- function(base_size = 12) {
  theme_minimal(base_family = "Georgia", base_size = base_size) +
    theme(
      panel.grid.minor   = element_blank(),
      strip.background   = element_rect(fill = "grey80", color = NA),
      strip.text = element_text(color = "black", face = "plain"),
      text               = element_text(color = "black", face = "plain"),  # All text in black, plain
      axis.title         = element_text(face = "plain"),                   # Axis titles in plain
      axis.text          = element_text(color = "black", face = "plain"),  # Axis text in black, plain
      plot.title         = element_text(color = "black", face = "plain")   # Plot title in black, plain
    )
}

# Johnson color palette
clrs <- met.brewer("Johnson",12)
# Austria color palette
clrs2 <- met.brewer("Austria",7)


# load data
data <- read.csv("clean_AJPS.csv")

# Subset and clean data
multi2 <- dplyr::select(data, qtable_1, qtable_2, qtable_3, qtable_4, price_after_1, price_after_2, price_after_3, price_after_4,
                        cs_after_1, cs_after_2, cs_after_3, cs_after_4, factory_after_1, factory_after_2, factory_after_3,
                        factory_after_4, ds_after_1, ds_after_2, ds_after_3, ds_after_4, ID,
                        countr, treat_offshoring, party, party2)

#rename variables to analyze conjoint data
multi2 <- dplyr::rename(multi2, priceafter_1 = price_after_1,  priceafter_2 = price_after_2,  priceafter_3 = price_after_3,
                        priceafter_4 = price_after_4, csafter_1 = cs_after_1,csafter_2 = cs_after_2,csafter_3 = cs_after_3,
                        csafter_4 = cs_after_4, factoryafter_1 = factory_after_1, factoryafter_2 = factory_after_2, 
                        factoryafter_3 = factory_after_3, factoryafter_4 = factory_after_4, 
                        dsafter_1 = ds_after_1, dsafter_2 = ds_after_2,dsafter_3 = ds_after_3,dsafter_4 = ds_after_4)

# Reshape data for conjoint analysis
multi2_reshape <- multi2 %>% 
  #first step is gathering all the variables that we want to use as our attributes;
  #because we have named each task iteration in this format, using contains will get each conjoint-related variable
  gather(key = task, value = score, contains("_1"), contains("_2"), contains("_3"), contains("_4")) %>% 
  #we need to separate these variables out by characteristics; this can be done using `separate`, because variable were meaningfully named using underscores 
  separate(task, c("variable", "iteration", "index")) %>% 
  #creating an indicator of variables that were a part of an index
  dplyr::mutate(index = ifelse(is.na(index), "", index))  %>%
  #create a variable specific column
  unite("variable_index", c("variable", "index"), sep = "") %>% 
  #spreading out the variables so that each meaningful variable (or attribute) is a column
  tidyr::spread(key = variable_index, value = score) %>% 
  #lastly, because the data are a mix of upper and lower case, use clean_names to make the variables names follow a uniform convention (this is optional, but recommended)
  janitor::clean_names() 

# Convert and relevel factors
# this is our dependent variable support for AI and offshoring, make sure it's numeric
multi2_reshape$qtable <- as.numeric(as.character(multi2_reshape$qtable))

#makes sure all of our other variables of interest are factors
multi2_reshape$csafter <- as.factor(as.character(multi2_reshape$csafter))
multi2_reshape$factoryafter <- as.factor(as.character(multi2_reshape$factoryafter))
multi2_reshape$dsafter <- as.factor(as.character(multi2_reshape$dsafter))
multi2_reshape$priceafter <- as.factor(as.character(multi2_reshape$priceafter))
multi2_reshape$treat_offshoring<- as.factor(multi2_reshape$treat_offshoring)
multi2_reshape$countr <- as.factor(as.character(multi2_reshape$countr))

# Use mutate and recode to rename 'priceafter' values
multi2_reshape <- multi2_reshape %>%
  mutate(priceafter = dplyr::recode(priceafter,
                                    "Decreases to 300$" = "Decreases to $300",
                                    "Decreases to 450$" = "Decreases to $450",
                                    "Unchanged at 600$" = "Unchanged at $600"))

#relevel our factors
multi2_reshape$csafter <- factor(multi2_reshape$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape$dsafter <- factor(multi2_reshape$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape$factoryafter <- factor(multi2_reshape$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape$priceafter <- factor(multi2_reshape$priceafter, levels = c("Unchanged at $600", "Decreases to $450", "Decreases to $300"))
multi2_reshape$priceafter <- relevel(multi2_reshape$priceafter, ref = c("Unchanged at $600"))

# label our attributes
attr(multi2_reshape$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape$priceafter, "label") <- "Price after shock (baseline: $600)"

# choose colors for plot
group.colors.treat <- c(Offshoring = "#E58606", AI = "#5D69B1")

# Marginal Means
mm_by <- cregg::cj(multi2_reshape, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~treat_offshoring)

# Figure 1
plot <- ggplot(mm_by, aes(x = estimate, y = level, color = treat_offshoring)) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), size = 0.4) +
  labs(
    x = "Marginal mean",
    y = NULL,
    title = ""
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) +
  theme_mfx(base_size = 12) +
  xlim(2, 4) +
  scale_color_manual(values = group.colors.treat) +
  theme(
    legend.title    = element_blank(),
    legend.position = "bottom",
    plot.title      = element_text(hjust = 0.5),
    panel.grid      = element_blank(),  # Removes gridlines
    axis.title.x    = element_text(margin = margin(t = 10)),
    axis.title.y    = element_text(margin = margin(r = 10))
  )

# Save Figure 1
ggsave("Figure1.png", plot,  width = 6.5, height = 8, dpi = 300)

### Compute AMCE

# relevel our attributes and label them
multi2_reshape$csafter <- relevel(multi2_reshape$csafter, ref = c("Unchanged at 100"))
multi2_reshape$dsafter <- relevel(multi2_reshape$dsafter, ref = c("Unchanged at 200"))
multi2_reshape$factoryafter <- relevel(multi2_reshape$factoryafter, ref = c("Unchanged at 400"))
attr(multi2_reshape$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape$priceafter, "label") <- "Price after shock (baseline: $600)"

# Average Marginal Component Effects (AMCEs)
amces <- cregg::cj(multi2_reshape, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~treat_offshoring)
#differences in amces
diff_amces <- cregg::cj(multi2_reshape, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~treat_offshoring)

#legend
amces$legend_group <- dplyr::recode(amces$level, 
                                    `Unchanged at $600` = "No change", 
                                    `Unchanged at 100` = "No change",
                                    `Unchanged at 200` = "No change",
                                    `Unchanged at 400` = "No change",
                                    `Decreases to $450` = "Gains",
                                    `Decreases to $300` = "Gains",
                                    `Increase to 125` = "Gains",
                                    `Increase to 250` = "Gains",
                                    `Increase to 500` = "Gains",
                                    `Decrease to 75` = "Losses",
                                    `Decrease to 150` = "Losses",
                                    `Decrease to 300` = "Losses")

diff_amces$legend_group <- dplyr::recode(diff_amces$level, 
                                         `Unchanged at $600` = "No change", 
                                         `Unchanged at 100` = "No change",
                                         `Unchanged at 200` = "No change",
                                         `Unchanged at 400` = "No change",
                                         `Decreases to $450` = "Gains",
                                         `Decreases to $300` = "Gains",
                                         `Increase to 125` = "Gains",
                                         `Increase to 250` = "Gains",
                                         `Increase to 500` = "Gains",
                                         `Decrease to 75` = "Losses",
                                         `Decrease to 150` = "Losses",
                                         `Decrease to 300` = "Losses")
#combine amces and differences in amces
combined <- rbind(amces, diff_amces)

# Create and save AMCE plot
#plot Figure A1 in online SI

AMCE <- plot(combined, size=3) +  
  geom_pointrange(aes(x=estimate, xmin=upper, xmax=lower,y=level,color = legend_group))+
  ggplot2::facet_wrap(~BY, ncol = 3L) + 
  scale_color_manual(values = c("black", "#FA8072", "#32CD32"), 
                     limits = c("No change", "Losses", "Gains")) +
  theme_mfx() +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        panel.grid = element_blank(),
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  )  # Add black borders around each facet) # Removes gridlines) 

# save Figure A1
ggsave("FigureA1.png",  AMCE,  width = 10, height = 11, dpi = 300)

## Create best, worst and same scenario.

## compute marginal means
mms <- cj(multi2_reshape, qtable ~ factoryafter,
          id= ~ id, estimate = "mm",  by = ~ priceafter + csafter + dsafter + treat_offshoring)

combined <- mms %>%
  group_by(treat_offshoring) %>%  # Group by AI and Offshoring
  mutate(rank = rank(estimate)) %>%  # Rank by support estimate
  ungroup()


# Define number of observations to select (10% of the 81 combinations = 8 scenarios)
n <- 8

# Select top 10%, middle 10%, and bottom 10%
top_10 <- combined %>%
  group_by(treat_offshoring) %>%
  top_n(n = n, wt = estimate) %>%
  mutate(scenario = "Best 10%")  # Label these as best-case scenarios

bottom_10 <- combined %>%
  group_by(treat_offshoring) %>%
  top_n(n = -n, wt = estimate) %>%
  mutate(scenario = "Worst 10%")  # Label these as worst-case scenarios

# Middle 10% (mid-rank)
middle_10 <- combined %>%
  group_by(treat_offshoring) %>%
  filter(rank > (max(rank) - n)/2 & rank <= (max(rank) + n)/2) %>%
  mutate(scenario = "Middle 10%")  # Label these as middle-case scenarios

# Combine top, middle, and bottom scenarios
selected_scenarios <- bind_rows(top_10, middle_10, bottom_10)


# Calculate the average of estimate, lower, and upper for each scenario
average_scenarios <- selected_scenarios %>%
  dplyr::group_by(treat_offshoring, scenario) %>%
  dplyr::summarise(
    estimate = mean(estimate, na.rm = TRUE),
    lower = mean(lower, na.rm = TRUE),
    upper = mean(upper, na.rm = TRUE)
  )

# Now create the plot for the average of the selected scenarios, this is Figure 2
best_worst_avg <- ggplot(average_scenarios, aes(x = estimate, color = treat_offshoring, y = scenario)) + 
  geom_vline(xintercept = 3, linetype = "dashed") + 
  geom_pointrange(aes(xmin = lower, xmax = upper), size = 1,
                  position = position_dodge(width = 0.5)) +
  labs(y = "", x = "Predicted support") +
  theme_mfx() +
  xlim(2,4) +
  scale_color_manual(values = group.colors.treat) +
  theme(
    text = element_text(size = 15),
    axis.title = element_text(size = 20),
    axis.text = element_text(size = 15),
    legend.text = element_text(size = 15),
    legend.title    = element_blank(),
    legend.position = "bottom",
    plot.title      = element_text(hjust = 0.5),
    panel.grid      = element_blank(),  # Removes gridlines
    axis.title.x    = element_text(margin = margin(t = 15)),
    axis.title.y    = element_text(margin = margin(r = 15))
  )

# Save the plot of Figure 2
ggsave("Figure2.png", best_worst_avg, width = 11, height = 9, dpi = 300)

#############
### Analyses by partisanship
################

# re-level the attributes
multi2_reshape$csafter <- factor(multi2_reshape$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape$dsafter <- factor(multi2_reshape$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape$factoryafter <- factor(multi2_reshape$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape$priceafter <- factor(multi2_reshape$priceafter, levels = c("Unchanged at $600", "Decreases to $450", "Decreases to $300"))
multi2_reshape$priceafter <- relevel(multi2_reshape$priceafter, ref = c("Unchanged at $600"))
# label attributes
attr(multi2_reshape$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape$priceafter, "label") <- "Price after shock (baseline: $600)"

## offshoring by country and party - US

#colors for parties
group.colors <- c(Republican = clrs2[1], Other = "#4DAF4A", Democratic = clrs2[2])

# filter by US and offshoring treatment, and exclude respondents who are not Democrats or Republicans
multi2_reshape_offshoring_us <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="Offshoring" & countr=="US" & party2 != "Other")
# relevel partisanship
multi2_reshape_offshoring_us$party2 <- factor(multi2_reshape_offshoring_us$party2, levels=c("Democratic", "Republican"))

#relabel attributes
attr(multi2_reshape_offshoring_us$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring_us$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring_us$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring_us$priceafter, "label") <- "Price after shock (baseline: $600)"
# Marginal Means
mm_by <- cregg::cj(multi2_reshape_offshoring_us, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party2)

#plot offshoring for Figure 3
mm_party_off <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean",
    y = NULL,
    title = "(b) Offshoring"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx(base_size = 12) +
  xlim(2, 4)+ 
  theme( legend.title = element_blank(),
         legend.position = "bottom",
         plot.title = element_text(
           hjust = 0.5,                        # Centers the title
           margin = margin(b = 15)             # Adds space below the title
         ),
         panel.grid = element_blank(),  # Removes gridlines
         axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
         axis.title.y = element_text(margin = margin(r = 10))# Adds space to the right of y-axis title (if present)
  ) + 
  scale_color_manual(values = group.colors)

## AI by party and country -- US

# subset country US and treatment AI, and exclude respondents who do not identify with the Republican or Democratic party
multi2_reshape_ai_us <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="AI" & countr=="US" & party2 != "Other")
# relevel party variable
multi2_reshape_ai_us$party2 <- factor(multi2_reshape_ai_us$party2, levels=c("Democratic", "Republican"))
#relabel attributes
attr(multi2_reshape_ai_us$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai_us$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai_us$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai_us$priceafter, "label") <- "Price after shock (baseline: $600)"

# marginal means by party
mm_by <- cregg::cj(multi2_reshape_ai_us, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party2)

# plot AI for Figure 3
mm_party_ai <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean",
    y = NULL,
    title = "(a) Artificial Intelligence"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx(base_size = 12) +
  xlim(2, 4)+ 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(
          hjust = 0.5,                        # Centers the title
          margin = margin(b = 15)             # Adds space below the title
        ),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))
  )  +  
  scale_color_manual(values = group.colors)

# Adjust for the first plot to have y-axis labels and title
mm_party_off <-mm_party_off + theme(axis.text.y=element_blank(), axis.title.y=element_blank())

# combine offshoring and AI
combined_plot <- mm_party_ai + mm_party_off + 
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# Display the combined plot
combined_plot


ggsave("Figure3.png", combined_plot, width = 9.5, height = 11, dpi = 300)

## AMCEs AI
# relevel attributes
multi2_reshape_ai_us$csafter <- relevel(multi2_reshape_ai_us$csafter, ref = c("Unchanged at 100"))
multi2_reshape_ai_us$dsafter <- relevel(multi2_reshape_ai_us$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_ai_us$factoryafter <- relevel(multi2_reshape_ai_us$factoryafter, ref = c("Unchanged at 400"))
# relabel attributes
attr(multi2_reshape_ai_us$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai_us$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai_us$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai_us$priceafter, "label") <- "Price after shock (baseline: $600)"

#amces
amces <- cregg::cj(multi2_reshape_ai_us, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~party2)
#differences in amces
diff_amces <- cregg::cj(multi2_reshape_ai_us, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~party2)

# legend
amces$legend_group <- dplyr::recode(amces$level, 
                                    `Unchanged at $600` = "No change", 
                                    `Unchanged at 100` = "No change",
                                    `Unchanged at 200` = "No change",
                                    `Unchanged at 400` = "No change",
                                    `Decreases to $450` = "Gains",
                                    `Decreases to $300` = "Gains",
                                    `Increase to 125` = "Gains",
                                    `Increase to 250` = "Gains",
                                    `Increase to 500` = "Gains",
                                    `Decrease to 75` = "Losses",
                                    `Decrease to 150` = "Losses",
                                    `Decrease to 300` = "Losses")

diff_amces$legend_group <- dplyr::recode(diff_amces$level, 
                                         `Unchanged at $600` = "No change", 
                                         `Unchanged at 100` = "No change",
                                         `Unchanged at 200` = "No change",
                                         `Unchanged at 400` = "No change",
                                         `Decreases to $450` = "Gains",
                                         `Decreases to $300` = "Gains",
                                         `Increase to 125` = "Gains",
                                         `Increase to 250` = "Gains",
                                         `Increase to 500` = "Gains",
                                         `Decrease to 75` = "Losses",
                                         `Decrease to 150` = "Losses",
                                         `Decrease to 300` = "Losses")
# combine amces and differences in amces
combined <- rbind(amces, diff_amces)

# figure A2
AMCE_AI_US <- plot(combined, size=3) +  
  geom_pointrange(aes(x=estimate, xmin=upper, xmax=lower,y=level,color = legend_group))+
  ggplot2::facet_wrap(~BY, ncol = 3L) + 
  scale_color_manual(values = c("black", "#FA8072", "#32CD32"), 
                     limits = c("No change", "Losses", "Gains")) +
  theme_mfx() +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        panel.grid = element_blank(),
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  )  # Add black borders around each facet) # Removes gridlines) 

# Figure A2
ggsave("FigureA2.png", AMCE_AI_US, width = 10, height = 11, dpi = 300)

# AMCEs offshoring US

#relevel variables
multi2_reshape_offshoring_us$csafter <- relevel(multi2_reshape_offshoring_us$csafter, ref = c("Unchanged at 100"))
multi2_reshape_offshoring_us$dsafter <- relevel(multi2_reshape_offshoring_us$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_offshoring_us$factoryafter <- relevel(multi2_reshape_offshoring_us$factoryafter, ref = c("Unchanged at 400"))

# relabel attributes
attr(multi2_reshape_offshoring_us$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring_us$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring_us$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring_us$priceafter, "label") <- "Price after shock (baseline: $600)"

#amces
amces <- cregg::cj(multi2_reshape_offshoring_us, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~party2)
#differences in amces
diff_amces <- cregg::cj(multi2_reshape_offshoring_us, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~party2)

# legend
amces$legend_group <- dplyr::recode(amces$level, 
                                    `Unchanged at $600` = "No change", 
                                    `Unchanged at 100` = "No change",
                                    `Unchanged at 200` = "No change",
                                    `Unchanged at 400` = "No change",
                                    `Decreases to $450` = "Gains",
                                    `Decreases to $300` = "Gains",
                                    `Increase to 125` = "Gains",
                                    `Increase to 250` = "Gains",
                                    `Increase to 500` = "Gains",
                                    `Decrease to 75` = "Losses",
                                    `Decrease to 150` = "Losses",
                                    `Decrease to 300` = "Losses")

diff_amces$legend_group <- dplyr::recode(diff_amces$level, 
                                         `Unchanged at $600` = "No change", 
                                         `Unchanged at 100` = "No change",
                                         `Unchanged at 200` = "No change",
                                         `Unchanged at 400` = "No change",
                                         `Decreases to $450` = "Gains",
                                         `Decreases to $300` = "Gains",
                                         `Increase to 125` = "Gains",
                                         `Increase to 250` = "Gains",
                                         `Increase to 500` = "Gains",
                                         `Decrease to 75` = "Losses",
                                         `Decrease to 150` = "Losses",
                                         `Decrease to 300` = "Losses")
# combine amces and differences in amces
combined <- rbind(amces, diff_amces)

# plot figure A3
AMCE_Off_US <- plot(combined, size=3) +  
  geom_pointrange(aes(x=estimate, xmin=upper, xmax=lower,y=level,color = legend_group))+
  ggplot2::facet_wrap(~BY, ncol = 3L)  +
  scale_color_manual(values = c("black", "#FA8072", "#32CD32"), 
                     limits = c("No change", "Losses", "Gains")) +
  theme_mfx() +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        panel.grid = element_blank(),
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  )  # Add black borders around each facet) # Removes gridlines) 


#save figure A3
ggsave("FigureA3.png", AMCE_Off_US, width = 10, height = 11, dpi = 300)


###########
## Canada
############
# colors for parties
group.colors2 <- c(LPC = clrs2[1], NDP = "orange", CPC =clrs2[2], Other = "black")

## offshoring by country and party - Canada, exclude those who identify with Other parties

multi2_reshape_offshoring_can <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="Offshoring" & countr=="Canada" & party2 != "Other")
# relevel the variable party
multi2_reshape_offshoring_can$party2 <- factor(multi2_reshape_offshoring_can$party2, levels=c("LPC", "CPC",  "NDP"))
# relabel attributes
attr(multi2_reshape_offshoring_can$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring_can$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring_can$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring_can$priceafter, "label") <- "Price after shock (baseline: $600)"

# marginal means by party
mm_by <- cregg::cj(multi2_reshape_offshoring_can, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party2)

#plot offshoring in figure A5
mm_party_off_can <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean",
    y = NULL,
    title = "(b) Offshoring"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme( legend.title = element_blank(),
         legend.position = "bottom",
         plot.title = element_text(
           hjust = 0.5,                        # Centers the title
           margin = margin(b = 15)             # Adds space below the title
         ),
         panel.grid = element_blank(),  # Removes gridlines
         axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
         axis.title.y = element_text(margin = margin(r = 10))
  ) + 
  scale_color_manual(values = group.colors2)

## AI by party2 and country -- Canada, exclude those who identify with Other party

multi2_reshape_ai_can <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="AI" & countr=="Canada"& party2 != "Other")
# relevel party variable
multi2_reshape_ai_can$party2 <- factor(multi2_reshape_ai_can$party2, levels=c("LPC", "CPC",  "NDP"))
# relabel attributes
attr(multi2_reshape_ai_can$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai_can$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai_can$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai_can$priceafter, "label") <- "Price after shock (baseline: $600)"
#marginal means by party
mm_by <- cregg::cj(multi2_reshape_ai_can, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party2)
# plot AI for Figure 4
mm_party_ai_can <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean",
    y = NULL,
    title = "(a) Artificial Intelligence"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme( legend.title = element_blank(),
         legend.position = "bottom",
         plot.title = element_text(
           hjust = 0.5,                        # Centers the title
           margin = margin(b = 15)             # Adds space below the title
         ),
         panel.grid = element_blank(),  # Removes gridlines
         axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
         axis.title.y = element_text(margin = margin(r = 10))
  ) +
  scale_color_manual(values = group.colors2)

# # Adjust for the first plot to have y-axis labels and title
mm_party_off_can <-mm_party_off_can + theme(axis.text.y=element_blank(), axis.title.y=element_blank())

#combine AI and offshoring

combined_plot_can <- mm_party_ai_can + mm_party_off_can + 
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# Display the combined plot Figure 4
combined_plot_can

# save Figure 4
ggsave("Figure4.png", combined_plot_can, width = 9.5, height = 11, dpi = 300)
## AMCEs


#amce ai Canada

# relevel attributes
multi2_reshape_ai_can$csafter <- relevel(multi2_reshape_ai_can$csafter, ref = c("Unchanged at 100"))
multi2_reshape_ai_can$dsafter <- relevel(multi2_reshape_ai_can$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_ai_can$factoryafter <- relevel(multi2_reshape_ai_can$factoryafter, ref = c("Unchanged at 400"))
# relabel attributes
attr(multi2_reshape_ai_can$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai_can$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai_can$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai_can$priceafter, "label") <- "Price after shock (baseline: $600)"

# amces

amces <- cregg::cj(multi2_reshape_ai_can, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~party2)
#differences in amces
diff_amces <- cregg::cj(multi2_reshape_ai_can, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~party2)

# legend
amces$legend_group <- dplyr::recode(amces$level, 
                                    `Unchanged at $600` = "No change", 
                                    `Unchanged at 100` = "No change",
                                    `Unchanged at 200` = "No change",
                                    `Unchanged at 400` = "No change",
                                    `Decreases to $450` = "Gains",
                                    `Decreases to $300` = "Gains",
                                    `Increase to 125` = "Gains",
                                    `Increase to 250` = "Gains",
                                    `Increase to 500` = "Gains",
                                    `Decrease to 75` = "Losses",
                                    `Decrease to 150` = "Losses",
                                    `Decrease to 300` = "Losses")

diff_amces$legend_group <- dplyr::recode(diff_amces$level, 
                                         `Unchanged at $600` = "No change", 
                                         `Unchanged at 100` = "No change",
                                         `Unchanged at 200` = "No change",
                                         `Unchanged at 400` = "No change",
                                         `Decreases to $450` = "Gains",
                                         `Decreases to $300` = "Gains",
                                         `Increase to 125` = "Gains",
                                         `Increase to 250` = "Gains",
                                         `Increase to 500` = "Gains",
                                         `Decrease to 75` = "Losses",
                                         `Decrease to 150` = "Losses",
                                         `Decrease to 300` = "Losses")


# combine amces and differences in AMCEs
combined <- rbind(amces, diff_amces)
#plot figure A4
AMCE_AI_Can <- plot(combined, size=3) +  
  geom_pointrange(aes(x=estimate, xmin=upper, xmax=lower,y=level,color = legend_group))+
  ggplot2::facet_wrap(~BY, ncol = 3L) + 
  scale_color_manual(values = c("black", "#FA8072", "#32CD32"), 
                     limits = c("No change", "Losses", "Gains")) +
  theme_mfx() +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        panel.grid = element_blank(),
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  )  # Add black borders around each facet) # Removes gridlines) 

# save figure A4
ggsave("FigureA4.png", AMCE_AI_Can, width = 9.5, height = 11, dpi = 300)

# amces offshoring Canada
#relevel attributes
multi2_reshape_offshoring_can$csafter <- relevel(multi2_reshape_offshoring_can$csafter, ref = c("Unchanged at 100"))
multi2_reshape_offshoring_can$dsafter <- relevel(multi2_reshape_offshoring_can$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_offshoring_can$factoryafter <- relevel(multi2_reshape_offshoring_can$factoryafter, ref = c("Unchanged at 400"))

# relabel attributes
attr(multi2_reshape_offshoring_can$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring_can$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring_can$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring_can$priceafter, "label") <- "Price after shock (baseline: $600)"

# amces
amces <- cregg::cj(multi2_reshape_offshoring_can, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~party2)
#differences in amces
diff_amces <- cregg::cj(multi2_reshape_offshoring_can, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~party2)

# legend
amces$legend_group <- dplyr::recode(amces$level, 
                                    `Unchanged at $600` = "No change", 
                                    `Unchanged at 100` = "No change",
                                    `Unchanged at 200` = "No change",
                                    `Unchanged at 400` = "No change",
                                    `Decreases to $450` = "Gains",
                                    `Decreases to $300` = "Gains",
                                    `Increase to 125` = "Gains",
                                    `Increase to 250` = "Gains",
                                    `Increase to 500` = "Gains",
                                    `Decrease to 75` = "Losses",
                                    `Decrease to 150` = "Losses",
                                    `Decrease to 300` = "Losses")

diff_amces$legend_group <- dplyr::recode(diff_amces$level, 
                                         `Unchanged at $600` = "No change", 
                                         `Unchanged at 100` = "No change",
                                         `Unchanged at 200` = "No change",
                                         `Unchanged at 400` = "No change",
                                         `Decreases to $450` = "Gains",
                                         `Decreases to $300` = "Gains",
                                         `Increase to 125` = "Gains",
                                         `Increase to 250` = "Gains",
                                         `Increase to 500` = "Gains",
                                         `Decrease to 75` = "Losses",
                                         `Decrease to 150` = "Losses",
                                         `Decrease to 300` = "Losses")


# combined amces and differences in amces
combined <- rbind(amces, diff_amces)

# figure A5
AMCE_Off_Can <- plot(combined, size=3) +  
  geom_pointrange(aes(x=estimate, xmin=upper, xmax=lower,y=level,color = legend_group))+
  ggplot2::facet_wrap(~BY, ncol = 3L) + 
  scale_color_manual(values = c("black", "#FA8072", "#32CD32"), 
                     limits = c("No change", "Losses", "Gains")) +
  theme_mfx() +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        panel.grid = element_blank(),
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  )  # Add black borders around each facet) # Removes gridlines) 


# save figure A5
ggsave("FigureA5.png", AMCE_Off_Can, width = 9.5, height = 11, dpi = 300)





