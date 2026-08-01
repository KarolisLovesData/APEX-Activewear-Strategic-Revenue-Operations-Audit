# APEX-Activewear-Strategic-Revenue-Operations-Audit

* **The Data Pipeline:** `Batch Ingestion (GCP Cloud Shell)` ➔ `Data Warehouse (BigQuery)` ➔ `Medallion Architecture (Cloud Dataform SQLX)`
* **The Pipeline Outputs (Driven by the Gold/Silver Layers):**
  * 📊 **Strategic Business Insights** (Revenue diagnostics & RFM segmentation)
  * 🧠 **Predictive Modeling** (`BigQuery ML` XGBoost churn intercept)
  * 🤖 **Governed AI Serving** (RAG Text-to-SQL via `Python`, `Google GenAI SDK`, & `JSON Semantic Layer`)

## Table of Contents
* [Executive Summary & Business Impact](#executive-summary)
* [Key Findings: The "Profit Paradox"](#key-findings)
* [I. Structural Fractures (Revenue Leakage)](#structural-fractures)
  * [1. Critical Attribution Leakage (The "Dark Traffic" Crisis)](#attribution-leakage)
  * [2. Network-Wide Fulfillment Optimization](#fulfillment-optimization)
* [II. Dormant Opportunities (Value Unlocks)](#dormant-opportunities)
  * [1. The "First Order" Multiplier (LTV Optimization)](#first-order-multiplier)
  * [2. RFM Strategic Insight: Reclaiming & Scaling](#rfm-insight)
  * [3. Predictive AI: The "Sleeping Giant" Intercept](#predictive-ai)
* [III. AI-Powered Semantic Layer & BI Governance](#ai-governance)
* [🛠️ Analytics Engineering & Data Architecture](#analytics-engineering)
  * [Data Scope & ERD](#data-scope)
  * [Medallion Pipeline & Guardrails](#tech-implementation)

---

# <a id="executive-summary"></a>Executive Summary & Business Impact

**APEX Activewear** is a simulated e-commerce dataset scaled to **$48.85M in realized lifetime revenue** (net of returns and cancellations) across North America, built on over **436K+** processed orders, a **$148 AOV**, and a **53.9% Gross Margin**.

**The Business Problem:** Top-line growth decelerated from 344% YoY to just 9.8%, exposing structural revenue leakage. A diagnostic audit of the revenue engine revealed four systemic risks obscuring profitability. **[Access SQL Queries](Strategic_Insights/Executive_Summary.sql)**

**Key Deliverables & Identified ROI:**
* **$34.3M Attribution Recovery:** Diagnosed mid-funnel session breaks misattributing 68% of revenue to "Direct" traffic.
* **$33.3M Retention Target:** Deployed RFM segmentation to isolate dormant "Sleeping Giant" users globally.
* **Predictive Churn Automation:** Built an early-warning ML model identifying users 30 days before they churn.
* **21% Fulfillment Speed Gain:** Proposed a 'Clean Flow' protocol to cut delivery lag from 5.1 to 4.1 days.

---

# <a id="key-findings"></a>Key Findings: The "Profit Paradox"

* **Growth Deceleration:** Momentum dropped from a peak of **344%** (Q2 2023) to **9.8%** (Q4 2025). Future revenue gains must come from maximizing Lifetime Value (LTV) rather than net-new acquisition. 🔗 **[Access SQL Queries](Strategic_Insights/Key_Findings__Growth_Deceleration.sql)**
  <img src="./Visuals/APEX Growth.png" alt="APEX Growth" width="600">

* **Critical Attribution Leakage:** We are "flying blind" on **68.3%** of total revenue. Untraceable mid-funnel breaks are starving ad algorithms and inflating Customer Acquisition Cost (CAC). 🔗 **[Access SQL Queries](Strategic_Insights/Key_findings__Critical_Attribution_Leakage.sql)**
  <img src="./Visuals/Revenue_by_traffic_source.png" alt="Revenue by traffic source" width="600">

* **Category-Specific Profit Drag:** Men's Alpine Outerwear incurs **$3.2M** in return losses. A **~24% total loss rate** across top categories means one-quarter of operational effort generates zero realized revenue. 🔗 **[Access SQL Queries](Strategic_Insights/Key_findings__Category-Specific_Profit_Drag.sql)**
  <img src="./Visuals/APEX_product_leakage.png" alt="Product leakage" width="600">

* **Systemic Retention Risk:** RFM segmentation reveals **$33.3M** in lifetime revenue is trapped globally in the dormant "At Risk / Can't Lose" segment. 🔗 **[Access SQL Queries](Strategic_Insights/Key_findings__Geographic_Saturation.sql)**

**The Strategic Pivot:** The data confirms APEX must transition to a value-driven model by fixing **Structural Fractures** (Logistics & Attribution) and unlocking **Dormant Opportunities** (LTV & Predictive Churn).

---

# <a id="structural-fractures"></a>I. Structural Fractures (Revenue Leakage)

### <a id="attribution-leakage"></a>1. Critical Attribution Leakage (The "Dark Traffic" Crisis)
**Stakeholder:** CMO & Data Engineering Lead | **Priority:** 🔴 CRITICAL

* **Insight:** Genuine users don't "teleport" to checkout. The complete absence of funnel history for 225k+ orders proves mid-session tracking breaks are creating "dark traffic," starving paid ad algorithms of conversion data and artificially inflating our CAC. 🔗 **[Access SQL Queries](Strategic_Insights/Structural_Fractures_(Revenue_Leakage).sql)**
* **Action:** Execute an immediate Tech Audit on the "Session-Break Triad" (whitelist payment gateways, verify cross-domain cookies, audit 301 redirect UTMs).
* **Impact:** Re-attribute **~$34.3M** to its true source, allowing marketing to scale budgets based on True ROAS.

<img src="Visuals/Impossible_funnel.png" alt="Impossible funnel" width="600">

### <a id="fulfillment-optimization"></a>2. Network-Wide Fulfillment Optimization
**Stakeholder:** COO & Supply Chain Lead | **Priority:** 🟠 HIGH

* **Insight:** Inbound returns are actively cannibalizing outbound sales capacity. Distribution centers are prioritizing inventory restocking over revenue capture, creating a universal 2.1-day fulfillment lag. 🔗 **[Access SQL Queries](Strategic_Insights/Structural_Fracture_2.Network_Wide_Fulfillment_Optimization.sql)**
* **Action:** Implement a **'Clean Flow' SOP**, a strict operational decoupling mandating all outbound orders clear in <24 hours before labor shifts to returns. Launch a 4-week pilot in Reno, NV.
* **Impact:** Compresses total fulfillment cycle time from 5.1 to 4.1 days (a **21%** speed gain) without requiring carrier shipping upgrades.

<img src="Visuals/APEX_fulfillment.png" alt="Fulfillment delays" width="600">

---

# <a id="dormant-opportunities"></a>II. Dormant Opportunities (Value Unlocks)

### <a id="first-order-multiplier"></a>1. The "First Order" Multiplier (LTV Optimization)
**Stakeholder:** Head of Growth | **Priority:** 🟠 HIGH

* **Insight:** Customer retention degrades structurally over time, but **First Order Value is a massive predictor of lifetime worth**. Customers starting with a basket >$90 generate a **56% lift in LTV**, yet share the exact same churn curve as low-value buyers. 🔗 **[Access SQL Queries](Strategic_Insights/The_First_Order_Multiplier.sql)**
* **Action:** Transition from flat discounts to **Tiered Thresholds** (e.g., "Save $20 on Orders >$100") to force users to self-select into the High-Value tier on Day 1.
* **Impact:** Unlocks **$185 incremental LTV** per user. Nudging just 1,000 baseline users across this threshold generates $185,000 in risk-free revenue.

<img src="Visuals/LTVs.png" alt="LTV curves" width="600">

### <a id="rfm-insight"></a>2. RFM Strategic Insight: Reclaiming & Scaling
**Stakeholder:** Head of Retention | **Global Revenue Impact:** ~$39M

Dividing our 122k+ user base into actionable RFM (Recency, Frequency, Monetary) cohorts isolates three segments requiring distinct interventions. 🔗 **[Access SQL Queries](Strategic_Insights/rfm_strategic_insights.sql)**

<img src="Visuals/APEX_RFM.png" alt="RFM Segments" width="600">

* **A. The "Sleeping Giant" (Reactivation):** $33.3M is dormant. Deploy an SMS-first "Pending Credit" sequence utilizing loss aversion to reclaim ~$3.33M at a conservative 10% win-back rate.
* **B. The "Tipping Point" (Upsell):** 10,996 active users haven't reached the "Loyal" tier. Deploy targeted bundle offers to inflate AOV, migrating 20% of this group to generate ~$1.1M in incremental LTV.
* **C. Cloning the Champions (Acquisition):** Merge 122 international "Champions" with "Loyal Customers" to build a statistically stable seed audience, providing ad pixels the critical mass needed to clone high-value users.

### <a id="predictive-ai"></a> 🧠 3. Predictive AI: The "Sleeping Giant" Intercept
Conversation with Gemini
how can I query tables in GCP bucket using SQL? via BigQuery federated query or external query ?

Here is how BigQuery concepts map to querying Cloud Storage (GCS) files using SQL:

To query tables or files directly in a GCP Cloud Storage bucket, you use an External Table (or BigLake Table), NOT a Federated Query/EXTERNAL_QUERY.  
Google

Why the distinction matters:
External Tables / BigLake Tables (Use for GCS): Used to query object storage like Google Cloud Storage (GCS) containing CSV, Parquet, ORC, Avro, or JSON files directly where they lie. You query them like normal SQL tables (SELECT * FROM my_dataset.my_gcs_table).  
Google

Federated Queries / EXTERNAL_QUERY (Use for RDBMS): Used specifically to execute SQL directly on external operational databases like Cloud SQL (PostgreSQL, MySQL), Cloud Spanner, or AlloyDB using the EXTERNAL_QUERY() function.  
OneUptime

How to Query GCS Files via SQL in BigQuery
You have three standard options depending on your setup:

Option 1: Create a Permanent External Table (Best Practice)
Create an external table pointing to your GCS file path(s). You can do this in SQL via BigQuery Studio:

SQL
CREATE OR REPLACE EXTERNAL TABLE `my_project.my_dataset.my_gcs_table`
OPTIONS (
  format = 'PARQUET', -- Can also be 'CSV', 'JSON', 'AVRO', 'ORC'
  uris = ['gs://my-bucket/folder/*.parquet']
);
Once created, query it with standard BigQuery SQL:

SQL
SELECT * 
FROM `my_project.my_dataset.my_gcs_table`
WHERE created_date >= '2026-01-01';
Option 2: Create a BigLake Table (Best for Security & Governance)
If you need row/column-level access control or fine-grained IAM governance over GCS data, use BigLake tables. BigLake wraps around GCS external tables using a Cloud Resource connection:

SQL
CREATE OR REPLACE EXTERNAL TABLE `my_project.my_dataset.my_biglake_table`
WITH CONNECTION `projects/my_project/locations/us/connections/gcs-connection`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://my-bucket/data/*.parquet']
);
Option 3: Query directly via bq CLI (Quick Ad-hoc Queries)
If you don't want to save a table schema in BigQuery and just need a quick ad-hoc SQL query from the command line:

Bash
bq query \
  --use_legacy_sql=false \
  'SELECT * FROM `my_project.my_dataset.my_temp_table` LIMIT 10'
(Alternatively, you can define temporary tables inline using the BigQuery API or Python SDK).

Important Things to Consider
Format: Parquet and ORC perform significantly faster than CSV or JSON because they are columnar and support predicate pushdown.

Costs & Performance: External queries on GCS don't cache results by default and are generally slower than native BigQuery storage tables. If you plan to query this dataset frequently, consider executing a CREATE TABLE ... AS SELECT to load it directly into BigQuery native storage.  
Google Cloud Documentation

Permissions: Ensure the BigQuery Service Account or user running the query has Storage Object Viewer (roles/storage.objectViewer) on the target GCS bucket.

create or replace external table apex_activewear_portfolio.user_churn_data

options(

  format = "CSV",

  uri = ["gs://apex_activewear_portfolio/user_churn_data.csv"]

)



gs://apex_activewear_portfolio/user_churn_data.csv = uri it is not connecting

The issue is a syntax error in your DDL statement: BigQuery expects the option key to be uris (plural), not uri.

Here is the corrected SQL statement:

SQL
CREATE OR REPLACE EXTERNAL TABLE apex_activewear_portfolio.user_churn_data
OPTIONS (
  format = 'CSV',
  uris = ['gs://apex_activewear_portfolio/user_churn_data.csv'],
  skip_leading_rows = 1, -- Set to 1 if your CSV has a header row
  autodetect = TRUE       -- Automatically infers the schema from the CSV
);
Common Checklist If You Still Experience Issues
If updating to uris does not resolve the connectivity error, verify the following:

Bucket Path & File Existence: Ensure the object path gs://apex_activewear_portfolio/user_churn_data.csv is exact (case-sensitive) and exists in Google Cloud Storage.

IAM Permissions: The principal running the query needs the Storage Object Viewer (roles/storage.objectViewer) role on the apex_activewear_portfolio bucket (or at least on the specific CSV file).

CSV Formatting Flags: If your CSV contains embedded line breaks or quotes, you may need to pass additional options:

SQL
allow_quoted_newlines = TRUE,
ignore_unknown_values = TRUE
Not found: Dataset cloud-etl-500119:apex_activewear_portfolio was not found in location US

Not found: Dataset cloud-etl-500119:apex_activewear_portfolio was not found in location US

That error occurs because BigQuery requires the destination dataset (apex_activewear_portfolio) to already exist in your GCP project before you can create tables inside it. It doesn't auto-create datasets when running a CREATE TABLE statement.

Here are the two ways to fix this:

Fix 1: Create the Dataset via SQL First
Run a CREATE SCHEMA (or CREATE DATASET) DDL statement in BigQuery Studio to create the dataset in the US region, then run your table creation DDL:

SQL
-- 1. Create the dataset
CREATE SCHEMA IF NOT EXISTS `cloud-etl-500119.apex_activewear_portfolio`
OPTIONS (
  location = 'US'
);

-- 2. Create the external table
CREATE OR REPLACE EXTERNAL TABLE `cloud-etl-500119.apex_activewear_portfolio.user_churn_data`
OPTIONS (
  format = 'CSV',
  uris = ['gs://apex_activewear_portfolio/user_churn_data.csv'],
  skip_leading_rows = 1,
  autodetect = TRUE
);
Fix 2: Create the Dataset via bq CLI
If you prefer using the command line or terminal, create the dataset using the Google Cloud SDK:

Bash
bq --location=US mk --dataset cloud-etl-500119:apex_activewear_portfolio
Key Things to Watch For
Region Matching: Ensure your GCS bucket (gs://apex_activewear_portfolio) is also located in the US multi-region (or a US single region). BigQuery datasets and GCS buckets must be in compatible locations to perform external queries.

Fully Qualified Names: It is good practice to include the project ID explicitly in DDL statements (cloud-etl-500119.apex_activewear_portfolio.user_churn_data) to prevent queries from defaulting to the wrong active project.

/*

  Description: Constructs the feature engineering dataset for predictive churn modeling.

  Architecture: Silver Layer / Feature Store

  Logic: Uses a 180-day historical snapshot to prevent data leakage. Features are aggregated

  prior to the snapshot; the target label evaluates if the user crossed a 180-day dormancy

  threshold during the subsequent 180-day window.

*/



-- Dynamically set the anchors based on actual data bounds

DECLARE max_dataset_date TIMESTAMP DEFAULT (

  SELECT MAX(created_at) FROM `apex-activewear.silver_layer.stg_orders`

);

DECLARE snapshot_date TIMESTAMP DEFAULT TIMESTAMP_SUB(max_dataset_date, INTERVAL 180 DAY);



CREATE OR REPLACE TABLE `apex-activewear.silver_layer.user_churn_data`

CLUSTER BY has_churned, total_order_count AS



WITH aggregated_order_items AS (

  SELECT

    order_id,

    COALESCE(SUM(sale_price), 0) AS order_total,

   

    -- FIX: Prevent data leakage by only counting returns that physically happened BEFORE the snapshot date

    COUNT(CASE WHEN returned_at <= snapshot_date THEN returned_at END) AS order_returns,

   

    COUNTIF(is_cancelled = true) AS cancelled_orders

  FROM `apex-activewear.silver_layer.stg_order_items`

  GROUP BY 1

),



user_order_history AS (

  SELECT

    o.user_id,

    o.created_at AS order_created_at,

    DATE_DIFF(o.delivered_at, o.shipped_at, HOUR) AS delivery_hours,

    ai.order_total,

    ai.order_returns,

    ai.cancelled_orders

  FROM `apex-activewear.silver_layer.stg_orders` o

  JOIN aggregated_order_items ai ON o.order_id = ai.order_id

),



user_first_orders AS (

  SELECT

    user_id,

    MIN(order_created_at) AS first_order_timestamp_marker

  FROM user_order_history

  GROUP BY 1

),



user_lifecycle_stats AS (

  SELECT

    u.user_id,

    u.created_at AS account_created_at,

    fo.first_order_timestamp_marker,

   

    -- Absolute State Operational Anchors

    MAX(oh.order_created_at) AS absolute_last_order,

    MIN(oh.order_created_at) AS first_order_date,



    -- Windowed Training Features (Strictly bound to historical snapshot)

    MAX(CASE WHEN oh.order_created_at <= snapshot_date THEN oh.order_created_at END) AS last_order_before_snapshot,

    COUNT(DISTINCT CASE WHEN oh.order_created_at <= snapshot_date THEN oh.order_created_at END) AS total_order_count,

    SUM(CASE WHEN oh.order_created_at <= snapshot_date THEN oh.order_returns ELSE 0 END) AS total_returns,

    SUM(CASE WHEN oh.order_created_at <= snapshot_date THEN oh.cancelled_orders ELSE 0 END) AS total_cancelled,

    ROUND(AVG(CASE WHEN oh.order_created_at <= snapshot_date THEN oh.delivery_hours END), 2) AS avg_delivery_hours,

    SUM(CASE WHEN oh.order_created_at <= snapshot_date THEN oh.order_total ELSE 0 END) AS total_historical_spend,

   

    -- Target Metric

    MAX(CASE WHEN oh.order_created_at = fo.first_order_timestamp_marker THEN oh.order_total ELSE 0 END) AS first_order_value

  FROM `apex-activewear.silver_layer.stg_users` u

  LEFT JOIN user_first_orders fo ON u.user_id = fo.user_id

  LEFT JOIN user_order_history oh ON u.user_id = oh.user_id

  GROUP BY 1, 2, 3

)



SELECT

  user_id,

  ROUND(DATE_DIFF(first_order_date, account_created_at, HOUR)/24, 2) AS days_to_value,

  COALESCE(total_order_count, 0) AS total_order_count,

  COALESCE(first_order_value, 0) AS first_order_value,

  COALESCE(avg_delivery_hours, 0) AS avg_delivery_hours,

  COALESCE(total_returns, 0) AS total_returns,

  COALESCE(total_cancelled, 0) AS total_cancelled,

 

  -- Behavioral Signals

  ROUND(COALESCE(total_historical_spend, 0), 2) AS total_historical_spend,

  DATE_DIFF(snapshot_date, last_order_before_snapshot, DAY) AS recency_days,

  ROUND(SAFE_DIVIDE(total_returns, total_order_count), 4) AS return_rate_pct,

  ROUND(SAFE_DIVIDE(total_historical_spend, total_order_count), 2) AS historical_aov,

 

  -- Target Churn Label Output

  CASE

    WHEN DATE_DIFF(snapshot_date, last_order_before_snapshot, DAY) < 180

     AND DATE_DIFF(max_dataset_date, absolute_last_order, DAY) >= 180

    THEN TRUE

    ELSE FALSE

  END AS has_churned

FROM user_lifecycle_stats

WHERE DATE_DIFF(snapshot_date, last_order_before_snapshot, DAY) < 180; find the logical error in the cxase when statement

There are two distinct logical errors in your has_churned CASE WHEN statement: one is a structural redundancy, and the other is a critical business logic flaw that will corrupt your predictive target by creating false negatives.

Here is the breakdown of the errors and how to fix them.

1. The "Resurrection" Trap (Critical Business Logic Flaw)
Your comment states that the label evaluates if a user crossed a 180-day dormancy threshold during the subsequent window. However, your logic evaluates the gap between their absolute final order and the end of the dataset:

SQL
AND DATE_DIFF(max_dataset_date, absolute_last_order, DAY) >= 180 
Why this fails:
This logic incorrectly assumes that a user's absolute_last_order is the only thing that dictates churn. It completely misses "resurrected" users—people who crossed the 180-day dormancy threshold but eventually made a purchase right before the end of the dataset.

Example Scenario: A user's last_order_before_snapshot is 30 days before the snapshot. They go completely dormant. On day 160 of the future evaluation window, they finally make a purchase.

The Reality: The gap between their orders is 190 days (30 pre-snapshot + 160 post-snapshot). They did cross the 180-day dormancy threshold. They churned and resurrected.

Your Code's Output: Because they ordered on day 160 of the future window, their absolute_last_order updates to that date. The gap between day 160 and the end of the dataset (day 180) is 20 days. Since 20 >= 180 is FALSE, your code labels them as has_churned = FALSE.

2. The Redundant Condition (Structural Flaw)
The first half of your CASE WHEN statement is completely redundant:

SQL
WHEN DATE_DIFF(snapshot_date, last_order_before_snapshot, DAY) < 180 
Because you have a WHERE clause at the very end of your query (WHERE DATE_DIFF(snapshot_date, last_order_before_snapshot, DAY) < 180;), your final SELECT statement is already strictly filtered down to active users. The CASE WHEN will never process a row where this condition is false, making the check obsolete.

How to Fix the Logic
To accurately determine if a user crossed a 180-day dormancy threshold during the evaluation window, you need to measure the gap between their last_order_before_snapshot and their first order AFTER the snapshot, not their absolute last order.

Step 1: Add a new feature anchor in your user_lifecycle_stats CTE:
Capture the timestamp of their very first order in the evaluation window.

SQL
-- Add this line to the user_lifecycle_stats CTE
MIN(CASE WHEN oh.order_created_at > snapshot_date THEN oh.order_created_at END) AS first_order_after_snapshot,
Step 2: Rewrite the CASE WHEN target label:
Remove the redundant condition and evaluate the actual gap.

SQL
-- Target Churn Label Output
CASE 
  -- Condition 1: They made NO purchases in the subsequent 180-day window. 
  -- Because they were active before the snapshot, extending 180 days past it guarantees >180 days of dormancy.
  WHEN first_order_after_snapshot IS NULL THEN TRUE 
  
  -- Condition 2: They did return, but the gap between their pre-snapshot order and their return order was 180+ days.
  WHEN DATE_DIFF(first_order_after_snapshot, last_order_before_snapshot, DAY) >= 180 THEN TRUE 
  
  ELSE FALSE 
END AS has_churned
SPX10K what is it ?

Depending on the context, SPX10K typically refers to one of two completely different concepts:

1. S&P 500 Index Milestone (Traditional Finance)
In macroeconomics and equity markets, SPX 10K is a long-term psychological and numerical milestone representing the S&P 500 Index (SPX) reaching 10,000 points. Analysts, institutional strategists, and macro commentators use the term when modeling the structural earnings growth, secular bull market trajectory, or inflationary timeline required for the benchmark index to cross from current valuations up to the 10,000 threshold.

2. Cryptocurrency Tokens (Web3 & DeFi)
In the digital asset space, SPX10K refers to speculative cryptocurrency tokens or community-driven projects (frequently traded on decentralized exchanges such as Aerodrome on the Base network). These assets typically circulate during high-beta altcoin or narrative-driven market cycles, often playing on traditional stock market terminology or derivative meme culture.

Are you tracking SPX10K as a long-term macro target for the S&P 500, or are you looking at a specific crypto asset?

/*

  Description: Evaluates the performance of the XGBoost churn prediction model.

  Architecture: Gold Layer / Analytics

  Output: Returns core classification metrics and assigns a business-friendly

  performance grade based on the ROC AUC score.

*/



WITH eval_metrics AS (

  SELECT

    ROUND(roc_auc, 4) AS roc_auc,

    ROUND(accuracy, 4) AS accuracy,

    ROUND(precision, 4) AS precision,

    ROUND(recall, 4) AS recall,

    ROUND(f1_score, 4) AS f1_score,

    ROUND(log_loss, 4) AS log_loss

  FROM ML.EVALUATE(

    MODEL `apex-activewear.silver_layer.xgboost_churn_model`

  )

)



SELECT

  *,

  -- Translate statistical performance into a business-readable grade

  CASE

    WHEN roc_auc >= 0.90 THEN 'Excellent (Highly Predictive)'

    WHEN roc_auc >= 0.80 THEN 'Good (Reliable for Production)'

    WHEN roc_auc >= 0.70 THEN 'Fair (Needs Feature Tuning)'

    ELSE 'Poor (Barely Better Than Random)'

  END AS model_performance_grade

FROM eval_metrics; Row roc_auc accuracy precision recall f1_score log_loss model_performance_grade

1 0.8868 0.781 0.945 0.7583 0.8414 0.4329 Good (Reliable for Production) these are the results we need to go back to editing the github part do you still have it ?

Those are fantastic results. An ROC AUC of 0.8868 is a very strong signal, but that 0.945 precision is the real highlight here. In a business context, that means when your model flags a user as a churn risk, it is correct 94.5% of the time. If APEX Activewear is handing out retention discounts, this model ensures you aren't wasting money on users who were going to stay anyway.

Since this is a fresh session window, I don't have the exact text of your previous README draft loaded in my immediate memory, but I have all the context for the APEX Activewear Medallion architecture.

Here is the formatted Markdown block for these specific results, ready to be dropped straight into your GitHub repository:

Markdown
### 📊 Model Performance & Evaluation

The XGBoost churn prediction model was evaluated using a 180-day historical holdout dataset to prevent data leakage. The model achieved a **Good (Reliable for Production)** grade, heavily indexing on precision to ensure targeted retention campaigns are highly efficient.

| Metric | Score | Business Interpretation |
| :--- | :--- | :--- |
| **ROC AUC** | `0.8868` | Strong capability to distinguish between churning and retained users. |
| **Precision** | `0.9450` | Highly efficient; when churn is predicted, it is correct 94.5% of the time. |
| **Recall** | `0.7583` | Successfully identifies ~76% of all actual churned users. |
| **F1 Score** | `0.8414` | Solid balance between precision and recall. |
| **Accuracy** | `0.7810` | Overall predictive correctness across the dataset. |
| **Log Loss** | `0.4329` | Indicates confident probability predictions. |
Do you want to paste the current draft of your README in here so we can weave this in naturally, or are there other sections we need to build out first?

### <a id="predictive-ai"></a> 🧠 3. Predictive AI: The "Sleeping Giant" Intercept

**Stakeholder:** Head of Retention 



* **Insight:** RFM is inherently reactive. To pivot to preemptive intervention, I engineered a `BOOSTED_TREE_CLASSIFIER` directly in the Silver layer using BigQuery ML to identify high-risk users *before* they churn. 🔗 **[Access SQL Queries](Strategic_Insights/BigQuery_ML_(XGBoost).sql)**

* **Action:** Constructed a 180-day historical SQL snapshot for feature engineering (Frequency, Return Rates, Delivery Latency) to prevent data leakage and isolate predictive behavioral signals (e.g., fast Time-to-Value correlations with high returns). Automated hyperparameter tuning optimized the model for ROC AUC while automatically balancing class weights.

* **Impact:** Achieved a **[XX.X] ROC AUC score**, proving strong predictive validity. This pipeline dynamically generates a **"Live Risk List,"** allowing marketing to trigger targeted SMS win-back credits precisely during the critical pre-churn window. this is how it currently looks like, the repo is targeted a data analyst or analytics engineering position so we should not be too scientific about this, and it should be really business outcome focused . return .md markdown format text

Your Markdown file is ready

MD icon
apex_predictive_ai_section
 MD 
Open
Here is the revised text designed for your README. It explicitly connects the technical output (precision) to the business value (protecting profit margins), removing academic language in favor of a clear, impact-driven narrative.


### <a id="predictive-ai"></a> 🧠 3. Predictive AI: The "Sleeping Giant" Intercept
**Stakeholder:** Head of Retention 

* **Insight:** RFM segmentation is inherently reactive. To pivot to preemptive intervention, I engineered a `BOOSTED_TREE_CLASSIFIER` directly in the Silver layer using BigQuery ML to identify high-risk users *before* they churn. 🔗 **[Access SQL Queries](Strategic_Insights/BigQuery_ML_(XGBoost).sql)**
* **Action:** Constructed a 180-day historical SQL snapshot for feature engineering (Frequency, Return Rates, Delivery Latency) to prevent data leakage and isolate predictive behavioral signals. Automated hyperparameter tuning optimized the model for ROC AUC while automatically balancing class weights.
* **Impact:** Delivered an **0.88 ROC AUC** with a standout **94.5% Precision rate**. Through compelling data storytelling, I demonstrated that this high precision ensures promotional efficiency—flagged users are genuine flight risks 94.5% of the time. The pipeline dynamically generates a **"Live Risk List,"** allowing marketing to trigger targeted SMS win-back credits without wasting margin on users who were naturally going to stay.



Gemini is AI and can make mistakes.

### <a id="predictive-ai"></a> 🧠 3. Predictive AI: The "Sleeping Giant" Intercept
**Stakeholder:** Head of Retention 

* **Insight:** RFM segmentation is inherently reactive. To pivot to preemptive intervention, I engineered a `BOOSTED_TREE_CLASSIFIER` directly in the Silver layer using BigQuery ML to identify high-risk users *before* they churn. 🔗 **[Access SQL Queries](Strategic_Insights/BigQuery_ML_(XGBoost).sql)**
* **Action:** Constructed a 180-day historical SQL snapshot for feature engineering (Frequency, Return Rates, Delivery Latency) to prevent data leakage and isolate predictive behavioral signals. Automated hyperparameter tuning optimized the model for ROC AUC while automatically balancing class weights.
* **Impact:** Delivered an **0.88 ROC AUC** with a standout **94.5% Precision rate**. Through compelling data storytelling, I demonstrated that this high precision ensures promotional efficiency—flagged users are genuine flight risks 94.5% of the time. The pipeline dynamically generates a **"Live Risk List,"** allowing marketing to trigger targeted SMS win-back credits without wasting margin on users who were naturally going to stay.
---

### <a id="ai-governance"></a>III. AI-Powered Semantic Layer & BI Governance

**Target:** Stakeholder Self-Service & Metric Standardization 

* **The Bottleneck:** Out-of-the-box LLMs inherently hallucinate business logic. Without guardrails, they blindly query raw tables, missing critical context like "Ghost Revenue" filters or our 24% return rate.
* **The Architecture:** Engineered a custom **Retrieval-Augmented Generation (RAG) Governance CLI** that intercepts stakeholder natural-language questions and binds the AI strictly to our validated Dataform pipeline logic.
* **Technical Execution:** Built a Python engine to dynamically parse BigQuery schemas and `Dataform Assertions` into a structured JSON dictionary. The LLM is prompt-restricted exclusively to the `gold_layer`, ensuring it outputs clean, compliant BigQuery Standard SQL.
* **Business Impact:** **"Zero-Hallucination" self-serve analytics.** Stakeholders can now query the warehouse in plain English with mathematical certainty that the generated SQL perfectly matches the CFO's definition of realized revenue.
#### *A sample governed query:*

<img src="./Visuals/rag_cli_demo.gif" alt="RAG CLI Demo" width="800">

#### *Ground Truth Verification: Executing the Governed Query in BigQuery*

<img src="Visuals/bigquery_governance_validation.png" alt="BigQuery Execution Verification" width="800">

---

# <a id="analytics-engineering"></a>🛠️ Analytics Engineering & Data Architecture

To perform this audit, I architected a scalable Medallion pipeline to act as a "source of truth," connecting the entire customer lifecycle—from the initial website visit to the final delivery and potential return.

### <a id="data-scope"></a>Data Scope & ERD
* **Volume:** **1.33M** online events, **436K+** orders, **122K+** unique users, and integration across **11** distribution centers.
* **Staging Schema:** The ERD below represents the foundational `stg_` nodes.

<img src="./Visuals/apex_activewear_erd.png" alt="Apex Activewear ERD" width="800">

### <a id="tech-implementation"></a>Medallion Pipeline & Guardrails
Enforced a strict `stg_` ➔ `int_` ➔ `mart_` DAG progression using **Cloud Dataform**, centralizing business logic in the Silver layer to eliminate downstream metric drift.

<img src="Visuals/APEX_Activewear Data_Lineage.png" alt="DAG" width="600">

* **Scalable Architecture:** Designed to scale from 300MB to petabyte volume without structural redesign. Partitioned tables by `TIMESTAMP_TRUNC` to manage high-cardinality data and clustered on low-cardinality IDs to prevent block fragmentation.
* **Event-Driven Ingestion:** Deployed GCS-triggered Cloud Functions for landing files, with centralized source declarations via Dataform JS configs (`bronze_sources.js`) to insulate against upstream schema breaks.
* **Defensive Modeling:**
  * **Circuit Breakers:** Built a "Dark Traffic" alert halting updates if `Direct` traffic exceeds 20% of revenue. Enforced null checks on primary keys.
  * **Temporal Locks:** Validated chronological integrity (`created_at` ➔ `shipped_at` ➔ `delivered_at`) using `COALESCE` and `GREATEST` to handle nulls and protect financial averages.
  * **Financial Integrity:** Locked `is_realized_revenue` to valid business statuses and implemented defensive casting for bulletproof downstream joins.
* **Anomaly Handling:** Instead of filtering edge cases in Staging (e.g., carrier "Return to Sender" events), I engineered a `has_timeline_anomaly` boolean flag in the Silver layer. This preserves raw data for logistics QA while allowing Gold layer LTV models to cleanly bypass bad records.
