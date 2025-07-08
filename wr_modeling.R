library(dplyr)
library(readr)
library(stringr)
library(ggplot2)
library(Hmisc)
library(sjPlot)
library(MASS)
library(car)
library(condformat)
library(lmtest)


# Set working directory for the project ----
folder <- "C:/Users/tianc/OneDrive/Desktop/Projects/fantasy_football_projections"
setwd(folder)

# Load all relevant data files ----
filtered_players <- read_csv("data/filtered_players.csv")
ftps_2023 <- read_csv("data/fantasypoints_2023.csv")
age <- read_csv("data/age_2023.csv")
yprr <- read_csv("data/yprr_2022.csv")
competition_change <- read_csv("data/competition_change2023.csv")
qb_skill <- read_csv("data/qb_skill2023.csv")
target_share <- read_csv("data/target_share2022.csv")

# Standardize player names across all datasets ----
clean_player_name <- function(name) {
  name %>%
    str_remove("^[0-9. ]+") %>%                # Remove leading numbers, dots, spaces
    str_remove("\\s+(Jr|Sr)\\.?$") %>%         # Remove Jr/Sr suffixes
    str_replace_all("[[:punct:]]", "") %>%     # Remove punctuation
    str_squish()                              # Remove extra whitespace
}

target_share <- target_share %>% mutate(player_name = clean_player_name(player_name))
yprr <- yprr %>% mutate(player_name = clean_player_name(player_name))
age <- age %>% mutate(player_name = clean_player_name(player_name))
filtered_players <- filtered_players %>% mutate(player_name = clean_player_name(player_name))
ftps_2023 <- ftps_2023 %>% mutate(player_name = clean_player_name(player_name))
qb_skill <- qb_skill %>% mutate(player_name = clean_player_name(player_name))
competition_change <- competition_change %>% mutate(player_name = clean_player_name(player_name))

# Fix specific player name inconsistencies (e.g., Allen Robinson, Josh Palmer) ----
target_share <- target_share %>%
  mutate(player_name = case_when(
    player_name == "Allen Robinson" ~ "Allen Robinson II",
    player_name == "Josh Palmer" ~ "Joshua Palmer",
    TRUE ~ player_name
  ))
yprr <- yprr %>%
  mutate(player_name = case_when(
    player_name == "Allen Robinson" ~ "Allen Robinson II",
    player_name == "Josh Palmer" ~ "Joshua Palmer",
    TRUE ~ player_name
  ))

# Merge all datasets into a single master data frame ----
master <- filtered_players %>%
  left_join(age, by = c("player_name", "team")) %>%
  left_join(competition_change, by = c("player_name", "team")) %>%
  left_join(ftps_2023, by = c("player_name", "team")) %>%
  left_join(qb_skill, by = c("player_name", "team")) %>%
  left_join(target_share, by = c("player_name", "team")) %>%
  left_join(yprr, by = "player_name") 

# Convert relevant columns to numeric and remove rows with missing values ----
master <- master %>%
  mutate(
    target_share = as.numeric(target_share),
    yprr = as.numeric(yprr),
    competition_change = as.numeric(competition_change),
    qb_skill = as.numeric(qb_skill),
    age_2023 = as.numeric(age_2023),
    fantasy_points_2023 = as.numeric(fantasy_points_2023)
  ) %>%
  na.omit()

# Visualize summary statistics ----

# Histogram: Distribution of target share
p1 <- ggplot(master, aes(x = target_share)) +
  geom_histogram(binwidth = 0.02, fill = "dodgerblue", color = "white") +
  labs(title = "Distribution of Target Share", x = "Target Share", y = "Count")

# Histogram: Distribution of yards per route run (YPRR)
p2 <- ggplot(master, aes(x = yprr)) +
  geom_histogram(binwidth = 0.1, fill = "darkorange", color = "white") +
  labs(title = "Distribution of YPRR", x = "Yards Per Route Run", y = "Count")

# Bar chart: Competition change distribution
p3 <- ggplot(master, aes(x = as.factor(competition_change))) +
  geom_bar(fill = "seagreen") +
  labs(title = "Competition Change", x = "Competition Change", y = "Count")

# Bar chart: Quarterback skill distribution
p4 <- ggplot(master, aes(x = as.factor(qb_skill))) +
  geom_bar(fill = "purple") +
  labs(title = "QB Skill", x = "QB Skill", y = "Count")

# Bar chart: Age dummy variable distribution
p5 <- ggplot(master, aes(x = as.factor(age_dummy))) +
  geom_bar(fill = "goldenrod") +
  labs(title = "Age Dummy", x = "Age Dummy", y = "Count")

# Correlation matrix for fantasy points and regressors ----
cor_vars <- master %>%
  dplyr::select(target_share, yprr, competition_change, qb_skill, age_2023, fantasy_points_2023) %>%
  mutate(across(everything(), as.numeric)) %>%
  na.omit()
cor_matrix <- cor(cor_vars, use = "complete.obs", method = "pearson")
corrplot::corrplot(cor_matrix, method = "color", type = "upper", order = "hclust",
                   addCoef.col = "black",
                   tl.col = "black", tl.srt = 45,
                   col = colorRampPalette(c("red", "white", "blue"))(200))

# Fit linear regression model to predict 2023 fantasy points ----
model <- lm(fantasy_points_2023 ~ target_share + yprr + competition_change + qb_skill + age_2023, data = master)
tab_model(model)

# Diagnostics: Assess model assumptions ----
# - Residuals vs fitted: test linearity
# - QQ-plot: test normality of residuals
# - Residuals vs leverage: check for outliers
# - Scale-location: check for heteroscedasticity
plot(model)

# Breusch-Pagan test for heteroscedasticity
bptest(model)

# Shapiro-Wilk test for normality of residuals
shapiro.test(resid(model))

# Variance Inflation Factor (VIF) for multicollinearity
vif(model)

# Validation: Test model on 2024 data using 2023 factors ----
Vfiltered_players <- read_csv("data/Vfiltered_players.csv")
Vftps_2023 <- read_csv("data/Vfantasy_points2024.csv")
Vage <- read_csv("data/Vage2024.csv")
Vyprr <- read_csv("data/Vyprr2023.csv")
Vcompetition_change <- read_csv("data/Vcomp_change2024.csv")
Vqb_skill <- read_csv("data/Vqb_skill2024.csv")
Vtarget_share <- read_csv("data/Vtarget_share2023.csv")

master_v <- Vfiltered_players %>%
  left_join(Vftps_2023, by = "player_name") %>%
  left_join(Vage, by = "player_name") %>%
  left_join(Vyprr, by = "player_name") %>%
  left_join(Vcompetition_change, by = "player_name") %>%
  left_join(Vqb_skill, by = "player_name") %>%
  left_join(Vtarget_share, by = "player_name")
master_v <- na.omit(master_v)

# Correlation matrix for validation set
cor_vars_v <- master_v %>%
  dplyr::select(target_share, yprr, comp_change, qb_skill, age, ftps_2024) %>%
  mutate(across(everything(), as.numeric)) %>%
  na.omit()
cor_matrix_v <- cor(cor_vars_v, use = "complete.obs", method = "pearson")
corrplot::corrplot(cor_matrix_v, method = "color", type = "upper", order = "hclust",
                   addCoef.col = "black",
                   tl.col = "black", tl.srt = 45,
                   col = colorRampPalette(c("red", "white", "blue"))(200))

# Prepare validation set for prediction
master_v$target_share <- as.numeric(master_v$target_share)
master_v <- master_v %>%
  rename(
    competition_change = comp_change,
    age_2023 = age
  )

# Predict 2024 fantasy points using the linear model
master_v$predicted_2024 <- predict(model, newdata = master_v)

# Calculate RMSE and R-squared for validation predictions ----
rmse <- sqrt(mean((master_v$ftps_2024 - master_v$predicted_2024)^2, na.rm = TRUE))
r2 <- cor(master_v$ftps_2024, master_v$predicted_2024, use = "complete.obs")^2
print(paste("Validation RMSE:", round(rmse, 2)))
print(paste("Validation R-squared:", round(r2, 3)))

# Plot residuals vs predicted values to diagnose model fit on validation set ----
master_v$residuals <- master_v$ftps_2024 - master_v$predicted_2024
p6 <- ggplot(master_v, aes(x = predicted_2024, y = residuals)) +
  geom_point(color = "blue", alpha = 0.6) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
  labs(
    title = "Residuals vs Predicted (Validation Set)",
    x = "Predicted 2024 Fantasy Points",
    y = "Residuals (Actual - Predicted)"
  )

# Identify top 10 outliers in validation predictions ----
order_indices <- order(abs(master_v$residuals), decreasing = TRUE)
top_outliers <- master_v[order_indices[1:10], ]
print(top_outliers[, c('player_name', 'ftps_2024', 'predicted_2024', 'residuals')])

# Fit robust regression model to reduce sensitivity to outliers ----
robust_model <- rlm(
  fantasy_points_2023 ~ target_share + yprr + competition_change + qb_skill + age_2023,
  data = master
)
summary(robust_model)
tab_model(robust_model)

# Plot residuals vs fitted values for robust regression ----
residuals_robust <- robust_model$resid
fitted_robust <- robust_model$fitted.values
plot(fitted_robust, residuals_robust,
     main = "Residuals vs Fitted (Robust Regression)",
     xlab = "Fitted values",
     ylab = "Residuals")
abline(h = 0, col = "red", lty = 2)

# Validate robust model on 2024 data ----
master_v$predicted_2024_robust <- predict(robust_model, newdata = master_v)
rmse_robust <- sqrt(mean((master_v$ftps_2024 - master_v$predicted_2024_robust)^2, na.rm = TRUE))
r2_robust <- cor(master_v$ftps_2024, master_v$predicted_2024_robust, use = "complete.obs")^2
print(paste("Robust Validation RMSE:", round(rmse_robust, 2)))
print(paste("Robust Validation R-squared:", round(r2_robust, 3)))

# Compare model predictions to expert and actual top 24 rankings ----

# Get top 24 predicted players for 2024
top24 <- master_v %>%
  arrange(desc(predicted_2024)) %>%
  slice(1:24) %>%
  dplyr::select(player_name, team, predicted_2024)
print(top24)

# Read in actual, expert, and model top 24 CSVs for comparison
actual_comp <- read_csv("data/actual_top24.csv")
expert_comp <- read_csv("data/expert_top24.csv")
model_comp <- read_csv("data/model_top24.csv")

# Standardize player names for comparison
expert_comp <- expert_comp %>%
  mutate(player_name = sub(" \\(.*\\)", "", player_name))
actual_comp <- actual_comp %>%
  mutate(player_name = sub(" \\(.*\\)", "", player_name))
model_comp <- model_comp %>%
  mutate(player_name = sub(" \\(.*\\)", "", player_name))

# Rename rank columns for clarity
colnames(actual_comp)[colnames(actual_comp) == "rank"] <- "actual_rank"
colnames(expert_comp)[colnames(expert_comp) == "rank"] <- "expert_rank"
colnames(model_comp)[colnames(model_comp) == "rank"]  <- "model_rank"

# Merge all rankings by player_name (full join to include all unique players)
comparison <- full_join(actual_comp, expert_comp, by = "player_name") %>%
  full_join(model_comp, by = "player_name")

# Assign rank 25 to missing values (players not in top 24)
max_rank <- 24
comparison <- comparison %>%
  mutate(
    actual_rank = ifelse(is.na(actual_rank), max_rank + 1, actual_rank),
    expert_rank = ifelse(is.na(expert_rank), max_rank + 1, expert_rank),
    model_rank  = ifelse(is.na(model_rank),  max_rank + 1, model_rank)
  )

# Calculate mean absolute rank error (MARE) for model and expert predictions ----
mare_model  <- mean(abs(comparison$model_rank  - comparison$actual_rank))
mare_expert <- mean(abs(comparison$expert_rank - comparison$actual_rank))
cat("Mean Absolute Rank Error (Model): ", round(mare_model, 3), "\n")
cat("Mean Absolute Rank Error (Expert): ", round(mare_expert, 3), "\n")

# Visualize top 12 actual finishers and compare to model/expert ranks ----
top12_actual <- actual_comp %>% filter(actual_rank <= 12)
comparison <- top12_actual %>%
  left_join(expert_comp, by = "player_name") %>%
  left_join(model_comp, by = "player_name")
# Assign rank 25 to missing values (not in expert/model top 24)
comparison <- comparison %>%
  mutate(
    expert_rank = ifelse(is.na(expert_rank), 25, expert_rank),
    model_rank  = ifelse(is.na(model_rank), 25, model_rank)
  )
# Add columns to flag "green" highlights for close matches
comparison <- comparison %>%
  mutate(
    model_green  = (model_rank <= 12) & (abs(model_rank - actual_rank) <= 5),
    expert_green = (expert_rank <= 12) & (abs(expert_rank - actual_rank) <= 5)
  )
# Select only columns needed for the comparison matrix
result <- comparison %>%
  dplyr::select(player_name, model_rank, expert_rank, actual_rank)

# Save the comparison matrix as an image with conditional formatting ----
png("results/comparison_matrix.png", width = 800, height = 600)
condformat(result) %>%
  rule_fill_discrete(
    columns = "model_rank",
    expression = (model_rank <= 12) & (abs(model_rank - actual_rank) <= 5),
    colours = c("TRUE" = "lightgreen")
  ) %>%
  rule_fill_discrete(
    columns = "expert_rank",
    expression = (expert_rank <= 12) & (abs(expert_rank - actual_rank) <= 5),
    colours = c("TRUE" = "lightgreen")
  )
dev.off()

# Saving Results ----

if (!dir.exists("results")) dir.create("results")

# Save all ggplot2 plots to the results folder
ggsave("results/hist_target_share.png", plot = p1, width = 6, height = 4, dpi = 300)
ggsave("results/hist_yprr.png", plot = p2, width = 6, height = 4, dpi = 300)
ggsave("results/bar_competition_change.png", plot = p3, width = 6, height = 4, dpi = 300)
ggsave("results/bar_qb_skill.png", plot = p4, width = 6, height = 4, dpi = 300)
ggsave("results/bar_age_dummy.png", plot = p5, width = 6, height = 4, dpi = 300)
ggsave("results/residuals_vs_predicted.png", plot = p6, width = 6, height = 4, dpi = 300)

# Save linear model diagnostic plots (base R) ----
png(paste(folder, "/results/linear_model_diagnostics.png", sep=""), width = 1200, height = 1200)
par(mfrow = c(2,2))
plot(model)
dev.off()

# Save residuals vs fitted plot for robust regression ----
png("results/robust_residuals_vs_fitted.png", width = 800, height = 600)
plot(fitted_robust, residuals_robust,
     main = "Residuals vs Fitted (Robust Regression)",
     xlab = "Fitted values",
     ylab = "Residuals")
abline(h = 0, col = "red", lty = 2)
dev.off()

# Save key tables as CSV files ----
write.csv(top24, "results/top24_predictions.csv", row.names = FALSE)
write.csv(top_outliers, "results/top10_outliers.csv", row.names = FALSE)
write.csv(result, "results/comparison_matrix.csv", row.names = FALSE)

# Save linear model summary to text file ----
sink("results/linear_model_summary.txt")
summary(model)
sink()

# Save robust model summary to text file ----
sink("results/robust_model_summary.txt")
summary(robust_model)
sink()

# Save validation and comparison metrics to text file ----
sink("results/validation_metrics.txt")
cat("Validation RMSE:", round(rmse, 2), "\n")
cat("Validation R-squared:", round(r2, 3), "\n")
cat("Robust Validation RMSE:", round(rmse_robust, 2), "\n")
cat("Robust Validation R-squared:", round(r2_robust, 3), "\n")
cat("Mean Absolute Rank Error (Model):", round(mare_model, 3), "\n")
cat("Mean Absolute Rank Error (Expert):", round(mare_expert, 3), "\n")
sink()

sink("results/mare_results.txt")
cat("Mean Absolute Rank Error (Model): ", round(mare_model, 3), "\n")
cat("Mean Absolute Rank Error (Expert): ", round(mare_expert, 3), "\n")
sink()





