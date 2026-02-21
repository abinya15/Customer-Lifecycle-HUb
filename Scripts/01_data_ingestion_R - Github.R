# 1. LIBRARIES
library(AzureStor)
library(tidyverse)

# ADLS Connection
account_url  <- "Insert URL"
account_key  <- "Insert Key"
container_nm <- "ravenstack"

endpoint <- storage_endpoint(account_url, key = account_key)
cont     <- adls_filesystem(endpoint, container_nm)

# 2.DATA INGESTION
files <- c("accounts"      = "ravenstack_accounts.csv", 
           "subscriptions" = "ravenstack_subscriptions.csv", 
           "usage"         = "ravenstack_feature_usage.csv", 
           "churn"         = "ravenstack_churn_events.csv",
           "tickets"       = "ravenstack_support_tickets.csv")

for (f in files) {
  storage_download(cont, src = paste0("bronze/", f), dest = f, overwrite = TRUE)
}

# Read all at once using a list for cleaner workspace management
data_list <- map(files, read.csv)

# 3. FEATURE ENGINEERING

# A. Finance Features
finance_features <- data_list$subscriptions %>%
  group_by(account_id) %>%
  summarise(total_mrr = sum(mrr_amount, na.rm = TRUE),
            total_arr = sum(arr_amount, na.rm = TRUE),
            active_subs = n_distinct(subscription_id), .groups = "drop")

# B. Usage Features
usage_features <- data_list$usage %>%
  left_join(data_list$subscriptions %>% select(subscription_id, account_id), by = "subscription_id") %>%
  arrange(account_id, usage_date) %>%
  group_by(account_id) %>%
  summarise(
    total_usage_events    = n(),
    avg_daily_usage       = mean(usage_count, na.rm = TRUE),
    total_errors          = sum(error_count, na.rm = TRUE),
    unique_features       = n_distinct(feature_name),
    # Usage velocity is an excellent predictor for your 0.62 AUC model
    usage_velocity        = sum(tail(usage_count, 10)) / (sum(head(usage_count, 10)) + 1),
    .groups = "drop"
  )

# C. Ticket Features
ticket_features <- data_list$tickets %>%
  group_by(account_id) %>%
  summarise(
    ticket_volume        = n(),
    avg_res_time_hrs     = mean(resolution_time_hours, na.rm = TRUE),
    high_priority_count  = sum(priority %in% c("High", "high", "Urgent", "urgent"), na.rm = TRUE),
    .groups = "drop"
  )

# 4. THE MASTER JOIN (Silver Layer Creation)
master_df <- list(data_list$accounts, finance_features, usage_features, ticket_features) %>%
  reduce(left_join, by = "account_id") %>%
  # Bring in Churn label
  left_join(data_list$churn %>% select(account_id, churn_date), by = "account_id") %>%
  mutate(
    is_churned = if_else(!is.na(churn_date), 1, 0),
    # Cleaning numeric NAs to 0 is vital for Random Forest stability
    across(where(is.numeric), ~replace_na(.x, 0))
  )

# 5. EXPORT TO ADLS SILVER
write.csv(master_df, "silver_customer_master.csv", row.names = FALSE)
storage_upload(cont, src = "silver_customer_master.csv", dest = "silver/silver_customer_master.csv")

message("Project Update: Silver layer successfully processed and uploaded to Azure.")
