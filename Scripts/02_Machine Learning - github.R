# 1. LIBRARIES & CREDENTIALS
library(AzureStor)
library(tidymodels)
library(themis)      
library(tidyverse)
library(ranger)      
library(vip)         

# Azure Connection
account_url <- "Insert URL"
account_key <- "Insert key"
container_name <- "ravenstack"

bl_endp <- storage_endpoint(account_url, key = account_key)
cont <- adls_filesystem(bl_endp, container_name)

# 2. DATA INGESTION & PREP
storage_download(cont, src = "silver/silver_customer_master.csv", dest = "silver_customer_master.csv", overwrite = TRUE)
final_training_data <- read.csv("silver_customer_master.csv")
final_training_data$is_churned <- as.factor(final_training_data$is_churned)

# 3. SPLITTING (75/25)
set.seed(123)
data_split <- initial_split(final_training_data, prop = 0.75, strata = is_churned)
train_data <- training(data_split)
test_data  <- testing(data_split)

# 4. RECIPE & WORKFLOW
# Added dummy encoding for categorical columns (plan_tier, industry)
churn_recipe <- recipe(is_churned ~ usage_velocity + total_errors + ticket_volume + 
                         avg_daily_usage + total_usage_events + unique_features + 
                         high_priority_count + plan_tier + industry + is_trial + 
                         active_subs + seats + total_mrr + total_arr, 
                       data = train_data) %>%
  step_downsample(is_churned) %>%
  step_dummy(all_nominal_predictors())

rf_spec <- rand_forest(trees = 500) %>%
  set_engine("ranger", importance = "impurity") %>%
  set_mode("classification")

churn_wf <- workflow() %>%
  add_recipe(churn_recipe) %>%
  add_model(rf_spec)

# 5. FIT THE MODEL
set.seed(123)
balanced_fit <- fit(churn_wf, data = train_data)

# --- VISUAL 1: VARIABLE IMPORTANCE BAR GRAPH ---
# Shows which factors (Usage vs Finance) drive churn the most
balanced_fit %>%
  extract_fit_parsnip() %>%
  vip(num_features = 10, geom = "col", fill = "#2c3e50") +
  theme_minimal() +
  labs(title = "Top 10 Behavioral & Financial Drivers of Churn")

# 6. EVALUATION ON TEST DATA
results <- test_data %>%
  bind_cols(predict(balanced_fit, test_data)) %>%
  bind_cols(predict(balanced_fit, test_data, type = "prob"))

# --- VISUAL 2: CONFUSION MATRIX HEATMAP ---
# Shows True Positives (88) vs False Positives (62)
results %>%
  conf_mat(truth = is_churned, estimate = .pred_class) %>%
  autoplot(type = "heatmap") +
  labs(title = "Confusion Matrix: Balanced Model Performance")

# --- VISUAL 3: ROC AUC CURVE ---
# Visual proof of the model's 0.62 predictive power
results %>%
  roc_curve(truth = is_churned, .pred_1, event_level = "second") %>%
  autoplot() +
  theme_minimal() +
  labs(title = "ROC Curve: Predictive Power",
       subtitle = "Model's ability to distinguish Stayers from Churners")

# 7. EXPORT GOLD LAYER & TOP 10
# (Your existing export logic remains here)
production_gold_data <- final_training_data %>%
  bind_cols(predict(balanced_fit, final_training_data)) %>%
  bind_cols(predict(balanced_fit, final_training_data, type = "prob")) %>%
  rename(predicted_churn = .pred_class, churn_probability = .pred_1)

write.csv(production_gold_data, "gold_full_company_churn_risk.csv", row.names = FALSE)
storage_upload(cont, src = "gold_full_company_churn_risk.csv", dest = "gold/gold_full_company_churn_risk.csv")

