# Customer-Lifecycle-HUb

<img width="2653" height="960" alt="image" src="https://github.com/user-attachments/assets/12c4f3f4-eeb5-462f-9da8-14725df5656e" />


# Predictive Churn & Revenue Expansion Hub
## An End-to-End Data Science Solution for SaaS Lifecycle Management

## 📌 Executive Summary
This project addresses the dual challenge of customer retention and revenue growth in a subscription-based business model. By leveraging a Random Forest model built in R, I identified a $9M MRR risk and transformed these insights into a three-layered Power BI suite. The solution moves beyond static reporting to provide a proactive "diagnostic" tool for Support and Sales teams.

## 🏗️ Technical Architecture
The pipeline is designed for scalability and security, utilizing a decoupled architecture:

### Data Source: 
Telemetry and financial data ingested securely from Azure Storage.

### Modeling (R): 
Feature engineering, normalization of behavioral drivers, and Random Forest classification.

### Security: 
Implementation of Environment Variables (.Renviron) to manage sensitive API keys, ensuring no secrets are exposed in the repository.

### Gold Layer: 
A refined, optimized dataset designed for high-performance DAX calculations.

## 📊 Dashboard Breakdown

### 1. Executive Risk (The "What")
Goal: High-level visibility into total financial exposure.

Key Insight: Identified that Usage Velocity is the primary leading indicator of churn.

Visuals: MRR at Risk cards, ROC Curve, and Relative Behavioral Driver weights.

<img width="1387" height="742" alt="Executive Insights" src="https://github.com/user-attachments/assets/d4039c25-76fa-4313-8241-154c81431c4c" />


### 2. Support Integrity (The "Why")
Goal: Identify operational friction causing churn.

Key Insight: Discovered a correlation between 56-hour Resolution Times and high churn probability.

Visuals: SLA Breach Rate, First Response Time (FRT), and Friction Score vs. Risk scatter plots.

<img width="1322" height="740" alt="Support Integrity" src="https://github.com/user-attachments/assets/83fbf69a-a1c0-4aab-b3f6-81f0256fe881" />


### 3. Revenue Expansion (The "Opportunity")
Goal: Offensive growth strategy.

Key Insight: Uncovered $43K in immediate expansion opportunity by targeting healthy accounts nearing seat capacity.

Visuals: Upsell Quadrant (Health vs. Velocity) and Seat-to-Expansion Ratios.
Open Dashboard: Open dashboard/Customer_Lifecycle_Hub.pbix in Power BI Desktop.

<img width="1322" height="740" alt="Revenue   Expansion" src="https://github.com/user-attachments/assets/b8828e1f-34b5-4aa4-9741-38d97c9f2d83" />


## 🧠 Lessons Learned
Security First: Transitioned from hardcoded credentials to professional secret management using environment variables.

Operational Alignment: Learned that predictive models are only as good as the operational "fixes" (like improving ART) they inspire.
