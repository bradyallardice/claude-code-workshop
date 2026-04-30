# ----- Installation and Loading of Required Packages for the Appendix -----

# List of packages actually used in the appendix code
required_packages <- c(
  "dplyr",            # data manipulation
  "tidyr",            # reshaping data
  "ggplot2",          # plotting
  "janitor",          # clean_names()
  "cregg",            # conjoint analysis (cj())
  "patchwork",        # combining ggplots
  "scales",           # formatting numbers and p-values
  "MetBrewer",        # color palettes
  "magrittr",         # the pipe operator (optional; dplyr already re-exports %>%)
  "marginaleffects",  # avg_predictions()
  "survey",           # svydesign(), svyglm() for survey analysis
  "broom",            # tidy() to display regression results
  "gtsummary",        # descriptive tables (tbl_summary())
  "gt"                # save table        
)

# Install any missing packages
installed_packages <- rownames(installed.packages())
for (pkg in required_packages) {
  if (!pkg %in% installed_packages) {
    install.packages(pkg, dependencies = TRUE)
  }
}

# For the 'cregg' package, ensure you install version 0.4.0
if (!("cregg" %in% installed_packages) || packageVersion("cregg") != "0.4.0") {
  if (!"remotes" %in% installed_packages) {
    install.packages("remotes")
  }
  remotes::install_version("cregg", version = "0.4.0", dependencies = TRUE)
}

# Load all required packages
lapply(required_packages, library, character.only = TRUE)  

rm(list = ls()) 

options(scipen=999)#turn off scientific notation or price of planes will be in scientific notation and the code for conjoint won't work.

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


#subset to variables we are going to use
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

#reshape dataset so we can analyze it
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
  #lastly, because the data are a mix of upper and lower case, I use clean_names to make the variables names follow a uniform convention (this is optional, but recommended)
  janitor::clean_names() 


# this is our dependent variable support for AI and offshoring, make sure it's numeric
multi2_reshape$qtable <- as.numeric(as.character(multi2_reshape$qtable))

#makes sure all of our other variables of interest are factors
multi2_reshape$csafter <- as.factor(as.character(multi2_reshape$csafter))
multi2_reshape$factoryafter <- as.factor(as.character(multi2_reshape$factoryafter))
multi2_reshape$dsafter <- as.factor(as.character(multi2_reshape$dsafter))
multi2_reshape$priceafter <- as.factor(as.character(multi2_reshape$priceafter))
multi2_reshape$treat_offshoring<- as.factor(multi2_reshape$treat_offshoring)
multi2_reshape$countr <- as.factor(as.character(multi2_reshape$countr))

#relevel our factors
multi2_reshape$csafter <- factor(multi2_reshape$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape$dsafter <- factor(multi2_reshape$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape$factoryafter <- factor(multi2_reshape$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape$priceafter <- factor(multi2_reshape$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape$priceafter <- relevel(multi2_reshape$priceafter, ref = c("Unchanged at 600$"))

# label our attributes
attr(multi2_reshape$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape$priceafter, "label") <- "Price after shock (baseline: 600$)"

# choose colors for plot
group.colors.treat <- c(Offshoring = "#E58606", AI = "#5D69B1")

########################################################
## Country differences: US and Canada figure B1
########################################################

# colors
group.country <- c(US = "#008080", Canada = "#FF7F50")

# marginal means by country
mm_by <- cregg::cj(multi2_reshape, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~countr + treat_offshoring)

# plot figure B1
mm_countries <- ggplot(
  mm_by,
  aes(x = estimate, y = level, color = countr, shape = treat_offshoring)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = ""
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4) + 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.country)

# save figure B1
ggsave("FigureB1.png", mm_countries, width = 6.5, height = 9, dpi = 300)

############################################################
### Partisanship with Controls (Figures C1 and C2)
############################################################

# colors for AI and offshoring
group.colors.treat <- c(Offshoring = "#E58606", AI = "#5D69B1")

## offshoring by country and party2 - US 

# colors for parties
group.colors <- c(Republican = clrs2[1], Other = "#4DAF4A", Democratic = clrs2[2])

# select variables we need
multi2 <- dplyr::select(data, qtable_1, qtable_2, qtable_3, qtable_4, price_after_1, price_after_2, price_after_3, price_after_4,
                        cs_after_1, cs_after_2, cs_after_3, cs_after_4, factory_after_1, factory_after_2, factory_after_3,
                        factory_after_4, ds_after_1, ds_after_2, ds_after_3, ds_after_4, ID,
                        countr, treat_offshoring, party, party2, education_bin, education, income, 
                        gender_bin, age_group)
# rename variables for conjoint
multi2 <- dplyr::rename(multi2, priceafter_1 = price_after_1,  priceafter_2 = price_after_2,  priceafter_3 = price_after_3,
                        priceafter_4 = price_after_4, csafter_1 = cs_after_1,csafter_2 = cs_after_2,csafter_3 = cs_after_3,
                        csafter_4 = cs_after_4, factoryafter_1 = factory_after_1, factoryafter_2 = factory_after_2, 
                        factoryafter_3 = factory_after_3, factoryafter_4 = factory_after_4, 
                        dsafter_1 = ds_after_1, dsafter_2 = ds_after_2,dsafter_3 = ds_after_3,dsafter_4 = ds_after_4)

#reshape dataset so we can analyze it
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
  #lastly, because the data are a mix of upper and lower case, I use clean_names to make the variables names follow a uniform convention (this is optional, but recommended)
  janitor::clean_names() 

# DV is numeric
multi2_reshape$qtable <- as.numeric(as.character(multi2_reshape$qtable))

# make sure all other variables are factors
multi2_reshape$csafter <- as.factor(as.character(multi2_reshape$csafter))
multi2_reshape$factoryafter <- as.factor(as.character(multi2_reshape$factoryafter))
multi2_reshape$dsafter <- as.factor(as.character(multi2_reshape$dsafter))
multi2_reshape$priceafter <- as.factor(as.character(multi2_reshape$priceafter))
multi2_reshape$treat_offshoring<- as.factor(multi2_reshape$treat_offshoring)
multi2_reshape$education_bin <- as.factor(as.character(multi2_reshape$education_bin))
multi2_reshape$age_group <- as.factor(as.character(multi2_reshape$age_group))
multi2_reshape$gender_bin <- as.factor(as.character(multi2_reshape$gender_bin))
multi2_reshape$income <- as.factor(as.character(multi2_reshape$income))
multi2_reshape$education <- as.factor(as.character(multi2_reshape$education))

# relevel attributes
multi2_reshape$csafter <- factor(multi2_reshape$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape$dsafter <- factor(multi2_reshape$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape$factoryafter <- factor(multi2_reshape$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape$priceafter <- factor(multi2_reshape$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape$priceafter <- relevel(multi2_reshape$priceafter, ref = c("Unchanged at 600$"))

#label attributes
attr(multi2_reshape$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape$priceafter, "label") <- "Price after shock (baseline: 600$)"

# keep offshoring treatment and US only, exclude those who identify with Other party
multi2_reshape_offshoring_us <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="Offshoring" & countr=="US" & party2 != "Other")

# relevel party
multi2_reshape_offshoring_us$party2 <- factor(multi2_reshape_offshoring_us$party2, levels=c("Democratic", "Republican"))

# prepare dataset for analysis with svyglm
off_svy_design <- svydesign(
  ids = ~id,
  weights = ~1,
  data = multi2_reshape_offshoring_us
)

# run fully interacted ols
model_svy <- svyglm(
  qtable ~ (priceafter + csafter + factoryafter +
              dsafter+ age_group + gender_bin + education + income)*party2,
  design = off_svy_design
)
# display results of regression
tidy(model_svy)

# Create a counterfactual grid for each attribute by partisanship


# Predict for priceafter
pred_price <- avg_predictions(model_svy, 
                              variables = c("party2", "priceafter"), 
                              by = c("party2", "priceafter"))

# Predict for csafter
pred_cs <- avg_predictions(model_svy, 
                           variables = c("party2", "csafter"), 
                           by = c("party2", "csafter"))

# Predict for factoryafter
pred_factory <- avg_predictions(model_svy, 
                                variables = c("party2", "factoryafter"), 
                                by = c("party2", "factoryafter"))

# Predict for dsafter
pred_ds <- avg_predictions(model_svy, 
                           variables = c("party2", "dsafter"), 
                           by = c("party2", "dsafter"))

# Combine all the predictions
pred_combined <- bind_rows(
  pred_price %>% mutate(feature = "priceafter"),
  pred_cs %>% mutate(feature = "csafter"),
  pred_factory %>% mutate(feature = "factoryafter"),
  pred_ds %>% mutate(feature = "dsafter")
)

# Use mutate with coalesce to create a single column 'values' with non-missing values
pred_combined <- pred_combined %>%
  dplyr::mutate(level = dplyr::coalesce(priceafter, csafter, factoryafter, dsafter)) 

pred_combined <- pred_combined %>%
  dplyr::select(-c(csafter, dsafter, factoryafter, priceafter))

##

# Renaming the attributes to match the first table format
pred_combined$feature[pred_combined$feature == "priceafter"] <- "Price after shock (baseline: 600$)"
pred_combined$feature[pred_combined$feature == "csafter"] <- "Customer service jobs after shock (baseline: 100)"
pred_combined$feature[pred_combined$feature == "factoryafter"] <- "Factory jobs after shock (baseline: 400)"
pred_combined$feature[pred_combined$feature == "dsafter"] <- "Data science jobs after shock (baseline: 200)"

# relevel features
pred_combined$feature <- factor(pred_combined$feature, 
                                levels = c("Price after shock (baseline: 600$)", 
                                           "Customer service jobs after shock (baseline: 100)", "Factory jobs after shock (baseline: 400)",
                                           "Data science jobs after shock (baseline: 200)"))
# plot offshoring for figure C1
mm_party_off <- ggplot(
  pred_combined,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Predicted support (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "Offshoring"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors)

## AI treatment and US excluding those who identify with Other party

multi2_reshape_ai_us <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="AI" & countr=="US" & party2 != "Other")
# relevel party
multi2_reshape_ai_us$party2 <- factor(multi2_reshape_ai_us$party2, levels=c("Democratic", "Republican"))

# prepare data for regression
ai_svy_design <- svydesign(
  ids = ~id,
  weights = ~1,
  data = multi2_reshape_ai_us
)

#fully interacted ols
model_svy <- svyglm(
  qtable ~ (priceafter + csafter + factoryafter +
              dsafter+ age_group + gender_bin + education + income)*party2,
  design = ai_svy_design
)

tidy(model_svy)

# Create a counterfactual grid for each attribute by partisanship


# Predict for priceafter
pred_price <- avg_predictions(model_svy, 
                              variables = c("party2", "priceafter"), 
                              by = c("party2", "priceafter"))

# Predict for csafter
pred_cs <- avg_predictions(model_svy, 
                           variables = c("party2", "csafter"), 
                           by = c("party2", "csafter"))

# Predict for factoryafter
pred_factory <- avg_predictions(model_svy, 
                                variables = c("party2", "factoryafter"), 
                                by = c("party2", "factoryafter"))

# Predict for dsafter
pred_ds <- avg_predictions(model_svy, 
                           variables = c("party2", "dsafter"), 
                           by = c("party2", "dsafter"))

# Combine all the predictions
pred_combined <- bind_rows(
  pred_price %>% mutate(feature = "priceafter"),
  pred_cs %>% mutate(feature = "csafter"),
  pred_factory %>% mutate(feature = "factoryafter"),
  pred_ds %>% mutate(feature = "dsafter")
)

# Use mutate with coalesce to create a single column 'values' with non-missing values
pred_combined <- pred_combined %>%
  dplyr::mutate(level = dplyr::coalesce(priceafter, csafter, factoryafter, dsafter)) 

pred_combined <- pred_combined %>%
  dplyr::select(-c(csafter, dsafter, factoryafter, priceafter))

##

# Renaming the attributes to match the first table format
pred_combined$feature[pred_combined$feature == "priceafter"] <- "Price after shock (baseline: 600$)"
pred_combined$feature[pred_combined$feature == "csafter"] <- "Customer service jobs after shock (baseline: 100)"
pred_combined$feature[pred_combined$feature == "factoryafter"] <- "Factory jobs after shock (baseline: 400)"
pred_combined$feature[pred_combined$feature == "dsafter"] <- "Data science jobs after shock (baseline: 200)"

pred_combined$feature <- factor(pred_combined$feature, 
                                levels = c("Price after shock (baseline: 600$)", 
                                           "Customer service jobs after shock (baseline: 100)", "Factory jobs after shock (baseline: 400)",
                                           "Data science jobs after shock (baseline: 200)"))
# AI plot for figure C1
mm_party_ai <- ggplot(
  pred_combined,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Predicted support (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "AI"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors)



# Adjust for the first plot to have y-axis labels and title
mm_party_off <-mm_party_off + theme(axis.text.y=element_blank(), axis.title.y=element_blank())

# combine AI and offshoring

combined_plot <- mm_party_ai + mm_party_off + 
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# Display the combined plot Figure A7
combined_plot

# save figure C1
ggsave("FigureC1.png", combined_plot, width = 9.5, height = 11, dpi = 300)


## Canada
# party colors
group.colors2 <- c(LPC = clrs2[1], NDP = "orange", CPC =clrs2[2], Other = "black")

## offshoring by country and party - Canada exclude Other

multi2_reshape_offshoring_can <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="Offshoring" & countr=="Canada" & party2 != "Other")
# relevel party
multi2_reshape_offshoring_can$party2 <- factor(multi2_reshape_offshoring_can$party2, levels=c("LPC", "CPC",  "NDP"))

# prepare data for regression
off_svy_design <- svydesign(
  ids = ~id,
  weights = ~1,
  data = multi2_reshape_offshoring_can
)

# fully interacted ols
model_svy <- svyglm(
  qtable ~ (priceafter + csafter + factoryafter +
              dsafter+ age_group + gender_bin + education + income)*party2,
  design = off_svy_design
)

tidy(model_svy)

# Create a counterfactual grid for each attribute by partisanship


# Predict for priceafter
pred_price <- avg_predictions(model_svy, 
                              variables = c("party2", "priceafter"), 
                              by = c("party2", "priceafter"))

# Predict for csafter
pred_cs <- avg_predictions(model_svy, 
                           variables = c("party2", "csafter"), 
                           by = c("party2", "csafter"))

# Predict for factoryafter
pred_factory <- avg_predictions(model_svy, 
                                variables = c("party2", "factoryafter"), 
                                by = c("party2", "factoryafter"))

# Predict for dsafter
pred_ds <- avg_predictions(model_svy, 
                           variables = c("party2", "dsafter"), 
                           by = c("party2", "dsafter"))

# Combine all the predictions
pred_combined <- bind_rows(
  pred_price %>% mutate(feature = "priceafter"),
  pred_cs %>% mutate(feature = "csafter"),
  pred_factory %>% mutate(feature = "factoryafter"),
  pred_ds %>% mutate(feature = "dsafter")
)

# Use mutate with coalesce to create a single column 'values' with non-missing values
pred_combined <- pred_combined %>%
  dplyr::mutate(level = dplyr::coalesce(priceafter, csafter, factoryafter, dsafter)) 

pred_combined <- pred_combined %>%
  dplyr::select(-c(csafter, dsafter, factoryafter, priceafter))

##


# Renaming the attributes to match the first table format
pred_combined$feature[pred_combined$feature == "priceafter"] <- "Price after shock (baseline: 600$)"
pred_combined$feature[pred_combined$feature == "csafter"] <- "Customer service jobs after shock (baseline: 100)"
pred_combined$feature[pred_combined$feature == "factoryafter"] <- "Factory jobs after shock (baseline: 400)"
pred_combined$feature[pred_combined$feature == "dsafter"] <- "Data science jobs after shock (baseline: 200)"

pred_combined$feature <- factor(pred_combined$feature, 
                                levels = c("Price after shock (baseline: 600$)", 
                                           "Customer service jobs after shock (baseline: 100)", "Factory jobs after shock (baseline: 400)",
                                           "Data science jobs after shock (baseline: 200)"))

# plot offshoring for Figure C2
mm_party_off_can <- ggplot(
  pred_combined,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Predicted support (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "Offshoring"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors2)

## subset AI, Canada and other

multi2_reshape_ai_can <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="AI" & countr=="Canada" & party2 != "Other")
# relevel party
multi2_reshape_ai_can$party2 <- factor(multi2_reshape_ai_can$party2, levels=c("LPC", "CPC",  "NDP"))

# prepare data for regression
ai_svy_design <- svydesign(
  ids = ~id,
  weights = ~1,
  data = multi2_reshape_ai_can
)
# run fully interacted ols
model_svy <- svyglm(
  qtable ~ (priceafter + csafter + factoryafter +
              dsafter+ age_group + gender_bin + education + income)*party2,
  design = ai_svy_design
)

tidy(model_svy)

# Create a counterfactual grid for each attribute by partisanship


# Predict for priceafter
pred_price <- avg_predictions(model_svy, 
                              variables = c("party2", "priceafter"), 
                              by = c("party2", "priceafter"))

# Predict for csafter
pred_cs <- avg_predictions(model_svy, 
                           variables = c("party2", "csafter"), 
                           by = c("party2", "csafter"))

# Predict for factoryafter
pred_factory <- avg_predictions(model_svy, 
                                variables = c("party2", "factoryafter"), 
                                by = c("party2", "factoryafter"))

# Predict for dsafter
pred_ds <- avg_predictions(model_svy, 
                           variables = c("party2", "dsafter"), 
                           by = c("party2", "dsafter"))

# Combine all the predictions
pred_combined <- bind_rows(
  pred_price %>% mutate(feature = "priceafter"),
  pred_cs %>% mutate(feature = "csafter"),
  pred_factory %>% mutate(feature = "factoryafter"),
  pred_ds %>% mutate(feature = "dsafter")
)

# Use mutate with coalesce to create a single column 'values' with non-missing values
pred_combined <- pred_combined %>%
  dplyr::mutate(level = dplyr::coalesce(priceafter, csafter, factoryafter, dsafter)) 

pred_combined <- pred_combined %>%
  dplyr::select(-c(csafter, dsafter, factoryafter, priceafter))

##

# Renaming the attributes to match the first table format
pred_combined$feature[pred_combined$feature == "priceafter"] <- "Price after shock (baseline: 600$)"
pred_combined$feature[pred_combined$feature == "csafter"] <- "Customer service jobs after shock (baseline: 100)"
pred_combined$feature[pred_combined$feature == "factoryafter"] <- "Factory jobs after shock (baseline: 400)"
pred_combined$feature[pred_combined$feature == "dsafter"] <- "Data science jobs after shock (baseline: 200)"

pred_combined$feature <- factor(pred_combined$feature, 
                                levels = c("Price after shock (baseline: 600$)", 
                                           "Customer service jobs after shock (baseline: 100)", "Factory jobs after shock (baseline: 400)",
                                           "Data science jobs after shock (baseline: 200)"))

# plot AI for figure C2
mm_party_ai_can <- ggplot(
  pred_combined,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Predicted support (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "AI"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors2)



# Adjust for the first plot to have y-axis labels and title
mm_party_off_can <-mm_party_off_can + theme(axis.text.y=element_blank(), axis.title.y=element_blank())


# combine AI and offshoring
combined_plot_can <- mm_party_ai_can + mm_party_off_can + 
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# Display the combined plot Figure C2
combined_plot_can
# save Figure C2
ggsave("FigureC2.png", combined_plot_can, width = 9.5, height = 11, dpi = 300)


##########################################################################################################
### all parties (including other and not incorporating leaners with Rep and Dem) Figures D1 and D2
########################################################################################################


# colors party
group.colors <- c(Republican = clrs2[1], Other = "#4DAF4A", Democratic = clrs2[2])

## subset offshoring treatment and country US

multi2_reshape_offshoring_us <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="Offshoring" & countr=="US")

# relevel party (now we have 3 levels not 2)
multi2_reshape_offshoring_us$party <- factor(multi2_reshape_offshoring_us$party, levels=c("Democratic", "Republican",  "Other"))

# label attributes
attr(multi2_reshape_offshoring_us$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring_us$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring_us$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring_us$priceafter, "label") <- "Price after shock (baseline: 600$)"

# marginal means by party
mm_by <- cregg::cj(multi2_reshape_offshoring_us, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party)

#plot offshoring for Figure D1
mm_party_off <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "Offshoring"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors)

## subset by AI treatment and country US

multi2_reshape_ai_us <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="AI" & countr=="US")

# relevel party (now 3 levels not 2)
multi2_reshape_ai_us$party <- factor(multi2_reshape_ai_us$party, levels=c("Democratic", "Republican",  "Other"))

# relabel attributes
attr(multi2_reshape_ai_us$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai_us$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai_us$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai_us$priceafter, "label") <- "Price after shock (baseline: 600$)"

# marginal means by party
mm_by <- cregg::cj(multi2_reshape_ai_us, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party)
# plot AI for figure D1
mm_party_ai <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "AI"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors)

# Adjust for the first plot to have y-axis labels and title
mm_party_off <-mm_party_off + theme(axis.text.y=element_blank(), axis.title.y=element_blank())

# combine AI and offshoring for the US

combined_plot <- mm_party_ai + mm_party_off + 
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# Display the combined plot Figure D1
combined_plot
# save Figure D1
ggsave("FigureD1.png", combined_plot, width = 9.5, height = 11, dpi = 300)

## Canada
# colors for party
group.colors2 <- c(LPC = clrs2[1], NDP = "orange", CPC =clrs2[2], Other = "black")

## subset by treatment offshoring and Canada

multi2_reshape_offshoring_can <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="Offshoring" & countr=="Canada")
# relevel party, now 4 levels rather than 3.
multi2_reshape_offshoring_can$party <- factor(multi2_reshape_offshoring_can$party, levels=c("LPC", "CPC",  "NDP", "Other"))
# relabel attributes
attr(multi2_reshape_offshoring_can$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring_can$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring_can$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring_can$priceafter, "label") <- "Price after shock (baseline: 600$)"

# marginal means by party
mm_by <- cregg::cj(multi2_reshape_offshoring_can, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party)

#plot offshoring for figure D2
mm_party_off_can <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "Offshoring"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors2)

## subset by treatment AI and country Canada

multi2_reshape_ai_can <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="AI" & countr=="Canada")
# relevel party (now 4 levels not 3)
multi2_reshape_ai_can$party <- factor(multi2_reshape_ai_can$party, levels=c("LPC", "CPC",  "NDP", "Other"))
# label attributes
attr(multi2_reshape_ai_can$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai_can$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai_can$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai_can$priceafter, "label") <- "Price after shock (baseline: 600$)"
# marginal means by party
mm_by <- cregg::cj(multi2_reshape_ai_can, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party)
# plot AI for figure D2
mm_party_ai_can <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "AI"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors2)

# Adjust for the first plot to have y-axis labels and title
mm_party_off_can <-mm_party_off_can + theme(axis.text.y=element_blank(), axis.title.y=element_blank())

# combine AI and offshoring

combined_plot_can <- mm_party_ai_can + mm_party_off_can + 
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# Display the combined plot D2
combined_plot_can

# save figure D2
ggsave("FigureD2.png", combined_plot_can, width = 9.5, height = 12, dpi = 300)

###########################################################
### Manipulation check: Figures E1 through E4
###########################################################

# select only those who passed the manipulation check
multi2 <- dplyr::filter(data, manipulation_check2=="Pass")

# select only variables we use
multi2 <- dplyr::select(multi2, qtable_1, qtable_2, qtable_3, qtable_4, price_after_1, price_after_2, price_after_3, price_after_4,
                        cs_after_1, cs_after_2, cs_after_3, cs_after_4, factory_after_1, factory_after_2, factory_after_3,
                        factory_after_4, ds_after_1, ds_after_2, ds_after_3, ds_after_4, ID,
                        countr, treat_offshoring, party, party2)
# rename variables for conjoint
multi2 <- dplyr::rename(multi2, priceafter_1 = price_after_1,  priceafter_2 = price_after_2,  priceafter_3 = price_after_3,
                        priceafter_4 = price_after_4, csafter_1 = cs_after_1,csafter_2 = cs_after_2,csafter_3 = cs_after_3,
                        csafter_4 = cs_after_4, factoryafter_1 = factory_after_1, factoryafter_2 = factory_after_2, 
                        factoryafter_3 = factory_after_3, factoryafter_4 = factory_after_4, 
                        dsafter_1 = ds_after_1, dsafter_2 = ds_after_2,dsafter_3 = ds_after_3,dsafter_4 = ds_after_4)

#reshape dataset so we can analyze it
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
  #lastly, because the data are a mix of upper and lower case, I use clean_names to make the variables names follow a uniform convention (this is optional, but recommended)
  janitor::clean_names() 

# make sure DV is numeric
multi2_reshape$qtable <- as.numeric(as.character(multi2_reshape$qtable))

# make sure all other variables are factors
multi2_reshape$csafter <- as.factor(as.character(multi2_reshape$csafter))
multi2_reshape$factoryafter <- as.factor(as.character(multi2_reshape$factoryafter))
multi2_reshape$dsafter <- as.factor(as.character(multi2_reshape$dsafter))
multi2_reshape$priceafter <- as.factor(as.character(multi2_reshape$priceafter))
multi2_reshape$treat_offshoring<- as.factor(multi2_reshape$treat_offshoring)
multi2_reshape$countr <- as.factor(as.character(multi2_reshape$countr))

# relevel attribute s
multi2_reshape$csafter <- factor(multi2_reshape$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape$dsafter <- factor(multi2_reshape$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape$factoryafter <- factor(multi2_reshape$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape$priceafter <- factor(multi2_reshape$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape$priceafter <- relevel(multi2_reshape$priceafter, ref = c("Unchanged at 600$"))

# label attributes
attr(multi2_reshape$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape$priceafter, "label") <- "Price after shock (baseline: 600$)"
# colors
group.colors.treat <- c(Offshoring = "#E58606", AI = "#5D69B1")
## marginal means
mm_by <- cregg::cj(multi2_reshape, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~treat_offshoring)

# Figure E1
plot <- ggplot(mm_by, aes(x = estimate, y = level, color = treat_offshoring)) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), size = 0.6) +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = ""
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4) + 
  scale_color_manual(values = group.colors.treat) +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) 
# save Figure E1
ggsave("FigureE1.png", plot, width = 6.5, height = 8, dpi = 300)

# AMCEs
# relevel attributes
multi2_reshape$csafter <- relevel(multi2_reshape$csafter, ref = c("Unchanged at 100"))
multi2_reshape$dsafter <- relevel(multi2_reshape$dsafter, ref = c("Unchanged at 200"))
multi2_reshape$factoryafter <- relevel(multi2_reshape$factoryafter, ref = c("Unchanged at 400"))
# relabel attributes
attr(multi2_reshape$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape$priceafter, "label") <- "Price after shock (baseline: 600$)"

#amces 
amces <- cregg::cj(multi2_reshape, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~treat_offshoring)
#differences in amces
diff_amces <- cregg::cj(multi2_reshape, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~treat_offshoring)

#legend
amces$legend_group <- dplyr::recode(amces$level, 
                                    `Unchanged at 600$` = "No change", 
                                    `Unchanged at 100` = "No change",
                                    `Unchanged at 200` = "No change",
                                    `Unchanged at 400` = "No change",
                                    `Decreases to 450$` = "Gains",
                                    `Decreases to 300$` = "Gains",
                                    `Increase to 125` = "Gains",
                                    `Increase to 250` = "Gains",
                                    `Increase to 500` = "Gains",
                                    `Decrease to 75` = "Losses",
                                    `Decrease to 150` = "Losses",
                                    `Decrease to 300` = "Losses")

diff_amces$legend_group <- dplyr::recode(diff_amces$level, 
                                         `Unchanged at 600$` = "No change", 
                                         `Unchanged at 100` = "No change",
                                         `Unchanged at 200` = "No change",
                                         `Unchanged at 400` = "No change",
                                         `Decreases to 450$` = "Gains",
                                         `Decreases to 300$` = "Gains",
                                         `Increase to 125` = "Gains",
                                         `Increase to 250` = "Gains",
                                         `Increase to 500` = "Gains",
                                         `Decrease to 75` = "Losses",
                                         `Decrease to 150` = "Losses",
                                         `Decrease to 300` = "Losses")
# combine amces and differences in amces
combined <- rbind(amces, diff_amces)

# figure E2
AMCE <- plot(combined, size=3) +  
  geom_pointrange(aes(x=estimate, xmin=upper, xmax=lower,y=level,color = legend_group))+
  ggplot2::facet_wrap(~BY, ncol = 3L) + 
  scale_color_manual(values = c("black", "#FA8072", "#32CD32"), 
                     limits = c("No change", "Losses", "Gains")) +#figure 5
  theme_mfx() +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        panel.grid = element_blank(),
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  )  # Add black borders around each facet) # Removes gridlines) 

# save figure E2
ggsave("FigureE2.png", AMCE, width = 10, height = 11, dpi = 300)


### partisanship by manipulation check

## offshoring by country and party - US

# colors for party
group.colors <- c(Republican = clrs2[1], Other = "#4DAF4A", Democratic = clrs2[2])
# relevel attributes
multi2_reshape$csafter <- factor(multi2_reshape$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape$dsafter <- factor(multi2_reshape$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape$factoryafter <- factor(multi2_reshape$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape$priceafter <- factor(multi2_reshape$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape$priceafter <- relevel(multi2_reshape$priceafter, ref = c("Unchanged at 600$"))
# subset to offshoring treatment, US, and exclude Other
multi2_reshape_offshoring_us <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="Offshoring" & countr=="US" & party2 != "Other")
# relevel party
multi2_reshape_offshoring_us$party2 <- factor(multi2_reshape_offshoring_us$party2, levels=c("Democratic", "Republican"))
# relabel attributes
attr(multi2_reshape_offshoring_us$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring_us$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring_us$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring_us$priceafter, "label") <- "Price after shock (baseline: 600$)"
#marginal means by party
mm_by <- cregg::cj(multi2_reshape_offshoring_us, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party2)

#plot offshoring for figure E3
mm_party_off <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "Offshoring"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  )  + 
  scale_color_manual(values = group.colors)

## AI by party2 and country -- US
# select AI treatment and country, exclude Other
multi2_reshape_ai_us <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="AI" & countr=="US" & party2 != "Other")
# relevel party
multi2_reshape_ai_us$party2 <- factor(multi2_reshape_ai_us$party2, levels=c("Democratic", "Republican"))
# relabel attributes
attr(multi2_reshape_ai_us$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai_us$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai_us$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai_us$priceafter, "label") <- "Price after shock (baseline: 600$)"
# marginal means
mm_by <- cregg::cj(multi2_reshape_ai_us, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party2)
# plot AI for figure E3
mm_party_ai <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "AI"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  )  + 
  scale_color_manual(values = group.colors)

# Adjust for the first plot to have y-axis labels and title
mm_party_off <-mm_party_off + theme(axis.text.y=element_blank(), axis.title.y=element_blank())

# combine offshoring and AI

combined_plot <- mm_party_ai + mm_party_off + 
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# Display the combined plot E3
combined_plot
# save Figure E3
ggsave("FigureE3.png", combined_plot, width = 9.5, height = 11, dpi = 300)


## Canada manipulation check partisanship

# colors for plot
group.colors2 <- c(LPC = clrs2[1], NDP = "orange", CPC =clrs2[2], Other = "black")

## offshoring by country and party - Canada
# select treatment offshoring, country Canada and exclude Others
multi2_reshape_offshoring_can <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="Offshoring" & countr=="Canada" & party2 != "Other")
# relevel party
multi2_reshape_offshoring_can$party2 <- factor(multi2_reshape_offshoring_can$party2, levels=c("LPC", "CPC",  "NDP"))
# relabel attributes
attr(multi2_reshape_offshoring_can$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring_can$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring_can$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring_can$priceafter, "label") <- "Price after shock (baseline: 600$)"
# marginal means
mm_by <- cregg::cj(multi2_reshape_offshoring_can, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party2)


#plot offshoring for figure E4
mm_party_off_can <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "Offshoring"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +
  scale_color_manual(values = group.colors2)

## AI by party2 and country -- Canada
# subset to AI treatment, Canada, and exclude Others
multi2_reshape_ai_can <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="AI" & countr=="Canada"& party2 != "Other")
# relevel party
multi2_reshape_ai_can$party2 <- factor(multi2_reshape_ai_can$party2, levels=c("LPC", "CPC",  "NDP"))
#relabel attributes
attr(multi2_reshape_ai_can$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai_can$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai_can$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai_can$priceafter, "label") <- "Price after shock (baseline: 600$)"
# marginal means
mm_by <- cregg::cj(multi2_reshape_ai_can, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~party2)
# plot AI for Figure E4
mm_party_ai_can <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = party2)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "AI"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +
  scale_color_manual(values = group.colors2)

# Adjust for the first plot to have y-axis labels and title
mm_party_off_can <-mm_party_off_can + theme(axis.text.y=element_blank(), axis.title.y=element_blank())

#combine offshoring and AI

combined_plot_can <- mm_party_ai_can + mm_party_off_can + 
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# Display the combined plot figure E4
combined_plot_can
# save figure E4
ggsave("FigureE4.png", combined_plot_can, width = 9.5, height = 11, dpi = 300)



##########################################
### Subgroup Analysis: Figures F1-F4
##########################################

# select variables we keep
multi2 <- dplyr::select(data, qtable_1, qtable_2, qtable_3, qtable_4, price_after_1, price_after_2, price_after_3, price_after_4,
                        cs_after_1, cs_after_2, cs_after_3, cs_after_4, factory_after_1, factory_after_2, factory_after_3,
                        factory_after_4, ds_after_1, ds_after_2, ds_after_3, ds_after_4, ID,
                        countr, treat_offshoring, party, party2, income,
                        gender_bin, age_group, education_bin)
# rename for conjoint
multi2 <- dplyr::rename(multi2, priceafter_1 = price_after_1,  priceafter_2 = price_after_2,  priceafter_3 = price_after_3,
                        priceafter_4 = price_after_4, csafter_1 = cs_after_1,csafter_2 = cs_after_2,csafter_3 = cs_after_3,
                        csafter_4 = cs_after_4, factoryafter_1 = factory_after_1, factoryafter_2 = factory_after_2, 
                        factoryafter_3 = factory_after_3, factoryafter_4 = factory_after_4, 
                        dsafter_1 = ds_after_1, dsafter_2 = ds_after_2,dsafter_3 = ds_after_3,dsafter_4 = ds_after_4)

#reshape dataset so we can analyze it
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
  #lastly, because the data are a mix of upper and lower case, I use clean_names to make the variables names follow a uniform convention (this is optional, but recommended)
  janitor::clean_names() 

# make sure DV is numeric
multi2_reshape$qtable <- as.numeric(as.character(multi2_reshape$qtable))

# all other variables as factors
multi2_reshape$csafter <- as.factor(as.character(multi2_reshape$csafter))
multi2_reshape$factoryafter <- as.factor(as.character(multi2_reshape$factoryafter))
multi2_reshape$dsafter <- as.factor(as.character(multi2_reshape$dsafter))
multi2_reshape$priceafter <- as.factor(as.character(multi2_reshape$priceafter))
multi2_reshape$treat_offshoring<- as.factor(multi2_reshape$treat_offshoring)
multi2_reshape$education_bin <- as.factor(as.character(multi2_reshape$education_bin))
multi2_reshape$income <- as.factor(as.character(multi2_reshape$income))
multi2_reshape$gender_bin <- as.factor(as.character(multi2_reshape$gender_bin))
multi2_reshape$age_group <- as.factor(as.character(multi2_reshape$age_group))
# relevel attributes
multi2_reshape$csafter <- factor(multi2_reshape$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape$dsafter <- factor(multi2_reshape$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape$factoryafter <- factor(multi2_reshape$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape$priceafter <- factor(multi2_reshape$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape$priceafter <- relevel(multi2_reshape$priceafter, ref = c("Unchanged at 600$"))
# label attributes
attr(multi2_reshape$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape$priceafter, "label") <- "Price after shock (baseline: 600$)"



#############
## Age Group
##############
# colors
group.colors_age <- c(`18 to 29` = clrs2[1], `30 to 44` = clrs2[2], `45 to 64` = clrs2[3], `65 or older` = clrs2[4])

# subset to offshoring first
multi2_reshape_offshoring <- multi2_reshape %>%
  dplyr::filter(treat_offshoring == "Offshoring")

# relevel variables

multi2_reshape_offshoring$csafter <- factor(multi2_reshape_offshoring$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape_offshoring$dsafter <- factor(multi2_reshape_offshoring$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape_offshoring$factoryafter <- factor(multi2_reshape_offshoring$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape_offshoring$priceafter <- factor(multi2_reshape_offshoring$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape_offshoring$priceafter <- relevel(multi2_reshape_offshoring$priceafter, ref = c("Unchanged at 600$"))
# label attributes
attr(multi2_reshape_offshoring$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring$priceafter, "label") <- "Price after shock (baseline: 600$)"

# Marginal means by age group for Offshoring
mm_by_age <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter + dsafter, id = ~ id, estimate = "mm", by = ~age_group)

# Plot for Offshoring by Age Group Figure F1
mm_age_off <- ggplot(mm_by_age, aes(x = estimate, y = level, color = age_group)) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), position = position_dodge(width = 0.5), size = 0.6) +
  labs(x = "Marginal mean (1 strongly oppose to 5 strongly support)", y = NULL, title = "Offshoring by Age Group") +
  facet_wrap(~feature, scales = "free_y", ncol = 1) +
  theme_mfx() +
  xlim(2, 4) +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors_age)

# Repeat the same for AI
multi2_reshape_ai <- multi2_reshape %>%
  dplyr::filter(treat_offshoring == "AI")


# relevel attributes
multi2_reshape_ai$csafter <- factor(multi2_reshape_ai$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape_ai$dsafter <- factor(multi2_reshape_ai$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape_ai$factoryafter <- factor(multi2_reshape_ai$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape_ai$priceafter <- factor(multi2_reshape_ai$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape_ai$priceafter <- relevel(multi2_reshape_ai$priceafter, ref = c("Unchanged at 600$"))
# label attributes
attr(multi2_reshape_ai$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai$priceafter, "label") <- "Price after shock (baseline: 600$)"


# Marginal means by age group for ai
mm_by_age_ai <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter + dsafter, id = ~ id, estimate = "mm", by = ~age_group)

# plot AI by age group for figure F1
mm_age_ai <- ggplot(mm_by_age_ai, aes(x = estimate, y = level, color = age_group)) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), position = position_dodge(width = 0.5), size = 0.6) +
  labs(x = "Marginal mean (1 strongly oppose to 5 strongly support)", y = NULL, title = "AI by Age Group") +
  facet_wrap(~feature, scales = "free_y", ncol = 1) +
  theme_mfx() +
  xlim(2, 4) +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors_age)

# Adjust for the first plot to have y-axis labels and title
mm_age_off <-mm_age_off + theme(axis.text.y=element_blank(), axis.title.y=element_blank())


# Combined plot for Age Group
combined_plot_age <- mm_age_ai + mm_age_off +
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# Figure F1
combined_plot_age

# Save the plot F1
ggsave("FigureF1.png", combined_plot_age, width = 10, height = 11, dpi = 300)

################## 
# AMCEs offshoring Age group

# relevel  attributes
multi2_reshape_offshoring$csafter <- relevel(multi2_reshape_offshoring$csafter, ref = c("Unchanged at 100"))
multi2_reshape_offshoring$dsafter <- relevel(multi2_reshape_offshoring$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_offshoring$factoryafter <- relevel(multi2_reshape_offshoring$factoryafter, ref = c("Unchanged at 400"))

amces <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~age_group)

#differences in amces
diff_amces <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~age_group)

#AMCEs AI Age group
# relevel attributes
multi2_reshape_ai$csafter <- relevel(multi2_reshape_ai$csafter, ref = c("Unchanged at 100"))
multi2_reshape_ai$dsafter <- relevel(multi2_reshape_ai$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_ai$factoryafter <- relevel(multi2_reshape_ai$factoryafter, ref = c("Unchanged at 400"))

amces <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~age_group)

#differences in amces
diff_amces <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~age_group)

##################
## Gender Figure F2
###################

group.colors_gender <- c(`Man` = clrs2[2], `Woman` = clrs2[1])

# subset to offshoring
multi2_reshape_offshoring <- multi2_reshape %>%
  dplyr::filter(treat_offshoring == "Offshoring")

# relevel attributes

multi2_reshape_offshoring$csafter <- factor(multi2_reshape_offshoring$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape_offshoring$dsafter <- factor(multi2_reshape_offshoring$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape_offshoring$factoryafter <- factor(multi2_reshape_offshoring$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape_offshoring$priceafter <- factor(multi2_reshape_offshoring$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape_offshoring$priceafter <- relevel(multi2_reshape_offshoring$priceafter, ref = c("Unchanged at 600$"))
# label attributes
attr(multi2_reshape_offshoring$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring$priceafter, "label") <- "Price after shock (baseline: 600$)"


# Marginal means by gender for Offshoring
mm_by_gender <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter + dsafter, id = ~ id, estimate = "mm", by = ~gender_bin)

# Plot for Offshoring by Gender for fig F2
mm_gender_off <- ggplot(mm_by_gender, aes(x = estimate, y = level, color = gender_bin)) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), position = position_dodge(width = 0.5), size = 0.6) +
  labs(x = "Marginal mean (1 strongly oppose to 5 strongly support)", y = NULL, title = "Offshoring by Gender") +
  facet_wrap(~feature, scales = "free_y", ncol = 1) +
  theme_mfx() +
  xlim(2, 4) +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors_gender)

# Repeat the same for AI

multi2_reshape_ai <- multi2_reshape %>%
  dplyr::filter(treat_offshoring == "AI")


#relevel attributes

multi2_reshape_ai$csafter <- factor(multi2_reshape_ai$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape_ai$dsafter <- factor(multi2_reshape_ai$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape_ai$factoryafter <- factor(multi2_reshape_ai$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape_ai$priceafter <- factor(multi2_reshape_ai$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape_ai$priceafter <- relevel(multi2_reshape_ai$priceafter, ref = c("Unchanged at 600$"))
# label attributes
attr(multi2_reshape_ai$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai$priceafter, "label") <- "Price after shock (baseline: 600$)"

# marginal means AI by gender
mm_by_gender_ai <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter + dsafter, id = ~ id, estimate = "mm", by = ~gender_bin)

# plot AI for fig F2
mm_gender_ai <- ggplot(mm_by_gender_ai, aes(x = estimate, y = level, color = gender_bin)) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), position = position_dodge(width = 0.5), size = 0.6) +
  labs(x = "Marginal mean (1 strongly oppose to 5 strongly support)", y = NULL, title = "AI by Gender") +
  facet_wrap(~feature, scales = "free_y", ncol = 1) +
  theme_mfx() +
  xlim(2, 4) +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors_gender)


# Adjust for the first plot to have y-axis labels and title
mm_gender_off <-mm_gender_off + theme(axis.text.y=element_blank(), axis.title.y=element_blank())


# Combined plot for Gender
combined_plot_gender <- mm_gender_ai + mm_gender_off +
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# figure F2
combined_plot_gender

# Save the plot figure F2
ggsave("FigureF2.png", combined_plot_gender, width = 10, height = 11, dpi = 300)

# Repeat the same steps for AMCE analysis for Gender 
# AMCE offshoring 

# relevel attributes
multi2_reshape_offshoring$csafter <- relevel(multi2_reshape_offshoring$csafter, ref = c("Unchanged at 100"))
multi2_reshape_offshoring$dsafter <- relevel(multi2_reshape_offshoring$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_offshoring$factoryafter <- relevel(multi2_reshape_offshoring$factoryafter, ref = c("Unchanged at 400"))

# amces
amces <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~gender_bin)

#differences in amces
diff_amces <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~gender_bin)

#AMCE AI
# relevel attributes
multi2_reshape_ai$csafter <- relevel(multi2_reshape_ai$csafter, ref = c("Unchanged at 100"))
multi2_reshape_ai$dsafter <- relevel(multi2_reshape_ai$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_ai$factoryafter <- relevel(multi2_reshape_ai$factoryafter, ref = c("Unchanged at 400"))
# amces
amces <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~gender_bin)

#differences in amces
diff_amces <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~gender_bin)
#########################
## Income figure F3
########################
# colors
group.colors_income <- c(`Low` = clrs2[1], `Middle` = clrs2[2], `High` = clrs2[3])
# subset to offshoring
multi2_reshape_offshoring <- multi2_reshape %>%
  dplyr::filter(treat_offshoring == "Offshoring")

# relevel attributes

multi2_reshape_offshoring$csafter <- factor(multi2_reshape_offshoring$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape_offshoring$dsafter <- factor(multi2_reshape_offshoring$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape_offshoring$factoryafter <- factor(multi2_reshape_offshoring$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape_offshoring$priceafter <- factor(multi2_reshape_offshoring$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape_offshoring$priceafter <- relevel(multi2_reshape_offshoring$priceafter, ref = c("Unchanged at 600$"))
# label attributes
attr(multi2_reshape_offshoring$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring$priceafter, "label") <- "Price after shock (baseline: 600$)"

# Reorder the income variable from low to high
multi2_reshape_offshoring$income <- factor(multi2_reshape_offshoring$income, 
                                           levels = c("Low", "Middle", "High"))



# Marginal means by income for Offshoring
mm_by_income <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter + dsafter, id = ~ id, estimate = "mm", by = ~income)

# Plot for Offshoring by Income for fig F3
mm_income_off <- ggplot(mm_by_income, aes(x = estimate, y = level, color = income)) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), position = position_dodge(width = 0.5), size = 0.6) +
  labs(x = "Marginal mean (1 strongly oppose to 5 strongly support)", y = NULL, title = "Offshoring by Income") +
  facet_wrap(~feature, scales = "free_y", ncol = 1) +
  theme_mfx() +
  xlim(2, 4) +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors_income)

# Repeat the same for AI

multi2_reshape_ai <- multi2_reshape %>%
  dplyr::filter(treat_offshoring == "AI")


# relevel attributes

multi2_reshape_ai$csafter <- factor(multi2_reshape_ai$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape_ai$dsafter <- factor(multi2_reshape_ai$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape_ai$factoryafter <- factor(multi2_reshape_ai$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape_ai$priceafter <- factor(multi2_reshape_ai$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape_ai$priceafter <- relevel(multi2_reshape_ai$priceafter, ref = c("Unchanged at 600$"))
# label attributes
attr(multi2_reshape_ai$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai$priceafter, "label") <- "Price after shock (baseline: 600$)"


# Reorder the income variable from low to high
multi2_reshape_ai$income <- factor(multi2_reshape_ai$income, 
                                   levels = c("Low", "Middle", "High"))
## marginal means AI
mm_by_income_ai <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter + dsafter, id = ~ id, estimate = "mm", by = ~income)

# plot AI for fig F3
mm_income_ai <- ggplot(mm_by_income_ai, aes(x = estimate, y = level, color = income)) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), position = position_dodge(width = 0.5), size = 0.6) +
  labs(x = "Marginal mean (1 strongly oppose to 5 strongly support)", y = NULL, title = "AI by Income") +
  facet_wrap(~feature, scales = "free_y", ncol = 1) +
  theme_mfx() +
  xlim(2, 4) +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors_income)

# Adjust for the first plot to have y-axis labels and title
mm_income_off <-mm_income_off + theme(axis.text.y=element_blank(), axis.title.y=element_blank())


# Combined plot for Income
combined_plot_income <- mm_income_ai + mm_income_off +
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# figure F3
combined_plot_income

# Save the plot F3
ggsave("FigureF3.png", combined_plot_income, width = 10, height = 11, dpi=300)

# AMCE offshoring income

# relevel attributes
multi2_reshape_offshoring$csafter <- relevel(multi2_reshape_offshoring$csafter, ref = c("Unchanged at 100"))
multi2_reshape_offshoring$dsafter <- relevel(multi2_reshape_offshoring$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_offshoring$factoryafter <- relevel(multi2_reshape_offshoring$factoryafter, ref = c("Unchanged at 400"))

# amces
amces <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~income)

#differences in amces
diff_amces <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~income)

#AMCE AI income

# relevel attributes
multi2_reshape_ai$csafter <- relevel(multi2_reshape_ai$csafter, ref = c("Unchanged at 100"))
multi2_reshape_ai$dsafter <- relevel(multi2_reshape_ai$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_ai$factoryafter <- relevel(multi2_reshape_ai$factoryafter, ref = c("Unchanged at 400"))
# amces
amces <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~income)
#differences in amces
diff_amces <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~income)

####################################
## Education Figure F4
####################################
# colors
group.colors <- c(`No college` = clrs2[3],  College = clrs2[4])

# subset to offshoring
multi2_reshape_offshoring <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="Offshoring")

# relevel attributes

multi2_reshape_offshoring$csafter <- factor(multi2_reshape_offshoring$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape_offshoring$dsafter <- factor(multi2_reshape_offshoring$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape_offshoring$factoryafter <- factor(multi2_reshape_offshoring$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape_offshoring$priceafter <- factor(multi2_reshape_offshoring$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape_offshoring$priceafter <- relevel(multi2_reshape_offshoring$priceafter, ref = c("Unchanged at 600$"))
# label attributes
attr(multi2_reshape_offshoring$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_offshoring$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_offshoring$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_offshoring$priceafter, "label") <- "Price after shock (baseline: 600$)"


# marginal means education
mm_by <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~education_bin)


#plot offshoring for figure F4
mm_educ_off <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = education_bin)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "Offshoring"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors)

## AI 

multi2_reshape_ai <- multi2_reshape %>%
  dplyr::filter(treat_offshoring=="AI")

# relevel attributes

multi2_reshape_ai$csafter <- factor(multi2_reshape_ai$csafter, levels = c("Decrease to 75", "Unchanged at 100", "Increase to 125"))
multi2_reshape_ai$dsafter <- factor(multi2_reshape_ai$dsafter, levels = c("Decrease to 150", "Unchanged at 200", "Increase to 250"))
multi2_reshape_ai$factoryafter <- factor(multi2_reshape_ai$factoryafter, levels = c("Decrease to 300", "Unchanged at 400", "Increase to 500"))
multi2_reshape_ai$priceafter <- factor(multi2_reshape_ai$priceafter, levels = c("Unchanged at 600$", "Decreases to 450$", "Decreases to 300$"))
multi2_reshape_ai$priceafter <- relevel(multi2_reshape_ai$priceafter, ref = c("Unchanged at 600$"))
# label attributes
attr(multi2_reshape_ai$csafter, "label") <- "Customer service jobs after shock (baseline: 100)"
attr(multi2_reshape_ai$factoryafter, "label") <- "Factory jobs after shock (baseline: 400)"
attr(multi2_reshape_ai$dsafter, "label") <- "Data science jobs after shock (baseline: 200)"
attr(multi2_reshape_ai$priceafter, "label") <- "Price after shock (baseline: 600$)"

# marginal means AI
mm_by <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "mm", by = ~education_bin)

# plot AI figure F4
mm_educ_ai <- ggplot(
  mm_by,
  aes(x = estimate,  y = level, color = education_bin)
) +
  geom_vline(xintercept = 3, linetype = "dashed") +
  geom_pointrange(aes(xmin = lower, xmax = upper), 
                  position=position_dodge(width=0.5), size=0.6) +
  #guides(color = "none") +
  labs(
    x = "Marginal mean (1 strongly oppose to 5 strongly support)",
    y = NULL,
    title = "AI"
  ) +
  facet_wrap(~feature, scales = "free_y", ncol = 1) + # Changed from facet_col to facet_wrap for a single column layout
  theme_mfx() +
  xlim(2, 4)+ 
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.grid = element_blank(),  # Removes gridlines
        axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
        axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +  
  scale_color_manual(values = group.colors)

# Adjust for the first plot to have y-axis labels and title
mm_educ_off <-mm_educ_off + theme(axis.text.y=element_blank(), axis.title.y=element_blank())


combined_plot <- mm_educ_ai + mm_educ_off + 
  plot_layout(ncol = 2, axis_titles = "collect_x", guides = "collect") &
  theme(legend.position = "bottom")

# Display the combined plot F4

combined_plot
# save figure F4
ggsave("FigureF4.png", combined_plot, width = 10, height = 11, dpi = 300)

# AMCE offshoring 
# relevel attributes
multi2_reshape_offshoring$csafter <- relevel(multi2_reshape_offshoring$csafter, ref = c("Unchanged at 100"))
multi2_reshape_offshoring$dsafter <- relevel(multi2_reshape_offshoring$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_offshoring$factoryafter <- relevel(multi2_reshape_offshoring$factoryafter, ref = c("Unchanged at 400"))
# amces
amces <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~education_bin)

#differences in amces
diff_amces <- cregg::cj(multi2_reshape_offshoring, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~education_bin)

#AI
# relevel attributes
multi2_reshape_ai$csafter <- relevel(multi2_reshape_ai$csafter, ref = c("Unchanged at 100"))
multi2_reshape_ai$dsafter <- relevel(multi2_reshape_ai$dsafter, ref = c("Unchanged at 200"))
multi2_reshape_ai$factoryafter <- relevel(multi2_reshape_ai$factoryafter, ref = c("Unchanged at 400"))
# amces
amces <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter +
                     dsafter, id= ~ id, estimate = "amce", 
                   by = ~education_bin)

#differences in amces
diff_amces <- cregg::cj(multi2_reshape_ai, qtable ~ priceafter + csafter + factoryafter +
                          dsafter, id= ~ id, estimate = "amce_diff", 
                        by = ~education_bin)

#################################################
#### Policy preferences Figures G1-G2
##################################################

# subset data to AI, US, and exclude others
data_ai_us <- data %>%
  dplyr::filter(treat_offshoring=="AI" & countr=="US" & party2 != "Other")

#social spending ols
soc_spen_ai <- lm(tables_policygr_1 ~ party2 + gender_bin + age_group + income + education, 
                  data=data_ai_us)
# predicted values 
soc_spen_ai_pred <- avg_predictions(soc_spen_ai, by = c("party2"), variables = c("party2"))

# basic income ols
bi_ai <- lm(tables_policygr_2 ~ party2 + gender_bin + age_group + income + education, 
            data=data_ai_us)
# predicted values 
bi_ai_pred <- avg_predictions(bi_ai, by = c("party2"), variables = c("party2"))

# retraining ols

ret_ai <- lm(tables_policygr_3 ~ party2 + gender_bin + age_group + income + education, 
             data=data_ai_us)
# predicted values 
ret_ai_pred <- avg_predictions(ret_ai, by = c("party2"), variables = c("party2"))

# immigration ols

immig_ai <-lm(tables_policygr_4 ~ party2 + gender_bin + age_group + income + education, 
              data=data_ai_us)
# predicted values 
immig_ai_pred <- avg_predictions(immig_ai, by = c("party2"), variables = c("party2"))

# trade ols

trade_ai <-lm(tables_policygr_5 ~ party2 + gender_bin + age_group + income + education, 
              data=data_ai_us)
# predicted values 
trade_ai_pred <- avg_predictions(trade_ai, by = c("party2"), variables = c("party2"))

# regulation ols

reg_ai <-lm(tables_policygr_6 ~ party2 + gender_bin + age_group + income + education, 
            data=data_ai_us)
# predicted values 
reg_ai_pred <- avg_predictions(reg_ai, by = c("party2"), variables = c("party2"))


# Combine predictions into one dataframe
combined_preds <- bind_rows(
  mutate(soc_spen_ai_pred, policy = "Social spending"),
  mutate(bi_ai_pred, policy = "Basic income"),
  mutate(ret_ai_pred, policy = "Retraining"),
  mutate(reg_ai_pred, policy = "Regulation"),
  mutate(immig_ai_pred, policy = "Immigration restrictions"),
  mutate(trade_ai_pred, policy = "Trade restrictions")
)
# relevel policy factor
combined_preds$policy <- factor(combined_preds$policy, 
                                levels = c("Social spending", "Basic income", 
                                           "Retraining", "Regulation", 
                                           "Immigration restrictions", "Trade restrictions"))

# Create the combined plot G1
combined_plot <-  ggplot(combined_preds, aes(x = estimate, y = party2, color = party2)) +
  geom_point(size = 3, position = position_dodge(width = 0.5)) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.2, position = position_dodge(width = 0.5)) +
  geom_vline(xintercept = 3, linetype = "dashed", color = "gray") +
  facet_wrap(~policy, scales = "fixed", ncol = 2) +  # ncol = 2 for two columns and fixed scales
  labs(x = "Predicted support (1 to 5)", y = "", color = "Party", title = "") +
  theme_mfx() +
  theme(
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank(),
    plot.title = element_text(hjust = 0.5),
    panel.grid = element_blank(),  # Removes gridlines
    axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
    axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +
  scale_color_manual(values = c("Republican" = clrs2[1], "Democratic" = clrs2[2])) +
  guides(color = guide_legend(override.aes = list(size = 4))) +
  xlim(2.5, 4.5)  # Setting x-axis limits for all plots

## see combined plot figure G1
combined_plot

# Save the plot G1
ggsave("FigureG1.png", plot = combined_plot, width = 10, height = 8, dpi = 300)



#### policy preferences in Canada
# subset data to AI, Canada, excluding Others
data_canada <- data %>%
  dplyr::filter(treat_offshoring=="AI" & countr=="Canada" & party2 != "Other")

# Social Spending ols
soc_spen_can <- lm(tables_policygr_1 ~ party2 + gender_bin + age_group + income + education, data = data_canada)
# predicted values
soc_spen_can_pred <- avg_predictions(soc_spen_can, by = c("party2"), variables = c("party2"))

# Basic Income ols
bi_can <- lm(tables_policygr_2 ~ party2 + gender_bin + age_group + income + education, data = data_canada)
# predicted values
bi_can_pred <- avg_predictions(bi_can, by = c("party2"), variables = c("party2"))

# Retraining ols
ret_can <- lm(tables_policygr_3 ~ party2 + gender_bin + age_group + income + education, data = data_canada)
# predicted values
ret_can_pred <- avg_predictions(ret_can, by = c("party2"), variables = c("party2"))

# Immigration Restrictions ols
immig_can <- lm(tables_policygr_4 ~ party2 + gender_bin + age_group + income + education, data = data_canada)
# predicted values
immig_can_pred <- avg_predictions(immig_can, by = c("party2"), variables = c("party2"))

# Trade Restrictions ols
trade_can <- lm(tables_policygr_5 ~ party2 + gender_bin + age_group + income + education, data = data_canada)
# predicted values
trade_can_pred <- avg_predictions(trade_can, by = c("party2"), variables = c("party2"))

# Regulation ols
reg_can <- lm(tables_policygr_6 ~ party2 + gender_bin + age_group + income + education, data = data_canada)
# predicted values
reg_can_pred <- avg_predictions(reg_can, by = c("party2"), variables = c("party2"))

# Combine predictions into one dataframe
combined_preds_can <- bind_rows(
  mutate(soc_spen_can_pred, policy = "Social spending"),
  mutate(bi_can_pred, policy = "Basic income"),
  mutate(ret_can_pred, policy = "Retraining"),
  mutate(reg_can_pred, policy = "Regulation"),
  mutate(immig_can_pred, policy = "Immigration restrictions"),
  mutate(trade_can_pred, policy = "Trade restrictions")
)

# Reorder policies
combined_preds_can$policy <- factor(combined_preds_can$policy, 
                                    levels = c("Social spending", "Basic income", 
                                               "Retraining", "Regulation", 
                                               "Immigration restrictions", "Trade restrictions"))

# Define Canadian party colors
group.colors2 <- c(LPC = clrs2[1], NDP = "orange", CPC = clrs2[2])

# Create the plot G2
combined_plot_can <- ggplot(combined_preds_can, aes(x = estimate, y = party2, color = party2)) +
  geom_point(size = 3, position = position_dodge(width = 0.5)) +
  geom_errorbar(aes(xmin = conf.low, xmax = conf.high), width = 0.2, position = position_dodge(width = 0.5)) +
  geom_vline(xintercept = 3, linetype = "dashed", color = "gray") +
  facet_wrap(~policy, scales = "fixed", ncol = 2) +  # ncol = 2 for two columns and fixed scales
  labs(x = "Predicted support (1 to 5)", y = "", color = "Party", title = "") +
  theme_mfx() +
  theme(
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    panel.grid.major = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank(),
    plot.title = element_text(hjust = 0.5),
    panel.grid = element_blank(),  # Removes gridlines
    axis.title.x = element_text(margin = margin(t = 10)),  # Adds space above x-axis title
    axis.title.y = element_text(margin = margin(r = 10))   # Adds space to the right of y-axis title (if present)
  ) +
  scale_color_manual(values = group.colors2) +
  guides(color = guide_legend(override.aes = list(size = 4))) +
  xlim(2.5, 4.5)  # Setting x-axis limits for all plots

# visualize combined plot G2
combined_plot_can

# Save the plot G2
ggsave("FigureG2.png", plot = combined_plot_can, width = 10, height = 8, dpi = 300)

#########################
#### Descriptives########
#########################

# Table A1 


### Prepare Data for Canada and US separately

### For Canada

canada_clean <- data %>%
  filter(countr == "Canada") %>%
  # Remove rows with unknown gender, and recode/reorder variables as desired.
  filter(gender != "Unknown") %>%
  mutate(
    # Recode gender: "Man" becomes "Male", "Woman" becomes "Female"
    gender = dplyr::recode(gender, "Man" = "Male", "Woman" = "Female"),
    # Define age group order
    age_group = factor(age_group, levels = c("18 to 29", "30 to 44", "45 to 64", "65 or older")),
    # Recode education and order the levels.
    education = factor(education,
                       levels = c("HS or less", "Some college", "College grad", "Postgrad"),
                       labels = c("High school or less", "Some college", "College grad", "Postgrad")
    ),
    # Recode party and set desired order.
    party = factor(party,
                   levels = c("CPC", "LPC", "NDP", "Other"),
                   labels = c("Conservative Party of Canada (CPC)",
                              "Liberal Party of Canada (LPC)",
                              "New Democratic Party (NDP)",
                              "Other")
    ),
    # For Canada, region_group is created from GeoPC_Region1.
    region_group = case_when(
      GeoPC_Region1 == 1 ~ "Alberta",
      GeoPC_Region1 == 2 ~ "British Columbia",
      GeoPC_Region1 == 3 ~ "Manitoba",
      GeoPC_Region1 == 4 ~ "New Brunswick",
      GeoPC_Region1 == 5 ~ "Newfoundland and Labrador",
      GeoPC_Region1 == 6 ~ "Northwest Territories",
      GeoPC_Region1 == 7 ~ "Nova Scotia",
      GeoPC_Region1 == 9 ~ "Ontario",
      GeoPC_Region1 == 10 ~ "Prince Edward Island",
      GeoPC_Region1 == 11 ~ "Quebec",
      GeoPC_Region1 == 12 ~ "Saskatchewan"
    ),
    # Order the provinces as desired.
    region_group = factor(region_group,
                          levels = c("Alberta", "British Columbia", "Manitoba", "New Brunswick",
                                     "Newfoundland and Labrador", "Northwest Territories", "Nova Scotia",
                                     "Ontario", "Prince Edward Island", "Quebec", "Saskatchewan")
    )
  )

unweighted_can <- canada_clean %>%
  tbl_summary(
    by = countr,
    include = c(gender, age_group, education, region_group, party),
    statistic = all_categorical() ~ "{n} ({p}%)",
    missing = "no",
    label = list(
      gender ~ "Gender",
      age_group ~ "Age Group",
      education ~ "Education",
      region_group ~ "Region",
      party ~ "Party ID"
    ),
  ) %>%
  modify_header(label = "**Variable**") %>%
  modify_caption("Descriptive statistics") %>%
  bold_labels()


### For US

usa_clean <- data %>%
  filter(countr == "US") %>%
  # Optionally remove rows with unknown gender if present
  filter(gender != "Unknown") %>%
  mutate(
    # # Recode gender: "Man" becomes "Male", "Woman" becomes "Female"
    gender = dplyr::recode(gender, "Man" = "Male", "Woman" = "Female"),
    age_group = factor(age_group, levels = c("18 to 29", "30 to 44", "45 to 64", "65 or older")),
    education = factor(education,
                       levels = c("HS or less", "Some college", "College grad", "Postgrad"),
                       labels = c("High school or less", "Some college", "College grad", "Postgrad")
    ),
    # Create a region variable based on your region indicator
    region_group = case_when(
      region == 1 ~ "Northeast",
      region == 2 ~ "Midwest",
      region == 3 ~ "South",
      region == 4 ~ "West",
      TRUE ~ NA_character_
    ),
    region_group = factor(region_group, levels = c("Northeast", "Midwest", "South", "West")),
    # For US, assume party is already recorded as "Democratic", "Republican", or "Other"
    party = factor(party, levels = c("Democratic", "Republican", "Other"))
  )

unweighted_us <- usa_clean %>%
  tbl_summary(
    by = countr,
    include = c(gender, age_group, education, region_group, party),
    statistic = all_categorical() ~ "{n} ({p}%)",
    missing = "no",
    label = list(
      gender ~ "Gender",
      age_group ~ "Age Group",
      education ~ "Education",
      region_group ~ "Region",
      party ~ "Party ID"
    ),
  ) %>%
  modify_header(label = "**Variable**") %>%
  modify_caption("Descriptive statistics") %>%
  bold_labels()


### Merge the Two Tables Side‐by‐Side

combined_table <- tbl_merge(
  tbls = list(Canada = unweighted_can, USA = unweighted_us),
  tab_spanner = c("", "")
) %>%
  modify_footnote(all_stat_cols() ~ NA)

combined_table

# Convert to a gt object
gt_table <- as_gt(combined_table)

# Save as an HTML file
gtsave(gt_table, "TableA1.html")