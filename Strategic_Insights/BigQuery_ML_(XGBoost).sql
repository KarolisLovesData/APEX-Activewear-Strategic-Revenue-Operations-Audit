/* ============================================================================
   CHURN PREDICTION PIPELINE
   Apex Activewear — BigQuery ML
   
   Execution order:
     1. Feature Engineering (Silver Layer)
     2. Model Training (XGBoost Classifier)
     3. Model Evaluation
     4. Batch Prediction
     5. Activation / Campaign Extraction (Gold Layer)
============================================================================ */


/* ============================================================================
   STEP 1: FEATURE ENGINEERING
   File: 01_user_churn_data_current.sql
   Architecture: Silver Layer / Feature Store
   Logic: Uses the absolute latest dataset date as the snapshot anchor for 
   live inference.
============================================================================ */

-- Dynamically set the anchors based on actual data bounds
DECLARE max_dataset_date TIMESTAMP DEFAULT (
  SELECT MAX(created_at) FROM `apex-activewear.silver_layer.stg_orders`
); -- Resolves to latest dataset timestamp

-- Anchors directly to the max date for current inference
DECLARE snapshot_date TIMESTAMP DEFAULT max_dataset_date;

CREATE OR REPLACE TABLE `apex-activewear.silver_layer.user_churn_data_current`
CLUSTER BY has_churned, total_order_count AS

WITH aggregated_order_items AS (
  SELECT 
    order_id,
    COALESCE(SUM(sale_price), 0) AS order_total,
    
    -- FIX: Prevent data leakage by only counting returns that physically happened BEFORE the snapshot date
    COUNT(CASE WHEN returned_at <= snapshot_date THEN returned_at END) AS order_returns,
    
   -- Upstream in aggregated_order_items
   COUNTIF(is_cancelled = true AND created_at <= snapshot_date) AS cancelled_orders
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
    MIN(CASE WHEN oh.order_created_at > snapshot_date THEN oh.order_created_at END) AS first_order_after_snapshot,

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
    -- Condition 1: They made NO purchases in the subsequent 180-day window. 
    -- Because they were active before the snapshot, extending 180 days past it guarantees >180 days of dormancy.
    WHEN first_order_after_snapshot IS NULL THEN TRUE 
    
    -- Condition 2: They did return, but the gap between their pre-snapshot order and their return order was 180+ days.
    WHEN DATE_DIFF(first_order_after_snapshot, last_order_before_snapshot, DAY) >= 180 THEN TRUE 
    
    ELSE FALSE 
  END AS has_churned
FROM user_lifecycle_stats
WHERE DATE_DIFF(snapshot_date, last_order_before_snapshot, DAY) < 180;


/* ============================================================================
   STEP 2: MODEL TRAINING
   File: 02_xgboost_churn_model.sql
   Description: Trains an XGBoost classifier in BigQuery ML to predict user churn.
   Optimization: Utilizes automated tuning for ROC AUC, balances class weights, 
   and enables global explanations for feature importance.
============================================================================ */

CREATE OR REPLACE MODEL `apex-activewear.silver_layer.xgboost_churn_model`
OPTIONS(
  model_type='BOOSTED_TREE_CLASSIFIER',
  input_label_cols=['has_churned'],
  auto_class_weights=TRUE,
  
  -- Hyperparameter Tuning Configuration
  num_trials=20,
  max_parallel_trials=2,
  hparam_tuning_objectives=['roc_auc'],
  
  -- Model Interpretability
  enable_global_explain=TRUE
) AS
SELECT
  -- All engineered features included for training
  days_to_value,
  total_order_count,
  first_order_value,
  avg_delivery_hours,
  total_returns,
  total_cancelled,
  total_historical_spend,
  recency_days,
  return_rate_pct,
  historical_aov,
  
  -- Target Label
  has_churned
FROM `apex-activewear.silver_layer.user_churn_data`;


/* ============================================================================
   STEP 3: MODEL EVALUATION
   File: 03_evaluate_churn_model.sql
   Description: Evaluates the performance of the XGBoost churn prediction model.
   Output: Returns core classification metrics and assigns a business-friendly 
   performance grade based on the ROC AUC score.
============================================================================ */

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
FROM eval_metrics;


/* ============================================================================
   STEP 4: BATCH PREDICTION
   File: 04_predict_user_churn.sql
   Description: Generates batch predictions for user churn probability using 
   the XGBoost model.
   Output: Returns the user_id, predicted churn status, and the exact 
   probability score to power targeted retention campaigns 
   (e.g., the SMS win-back sequence).
============================================================================ */

WITH churn_predictions AS (
  SELECT
    *
  FROM ML.PREDICT(
    MODEL `apex-activewear.silver_layer.xgboost_churn_model`,
    
    -- In a production environment (like Airflow or Dataform), this table would be 
    -- replaced by a 'current state' feature table updated daily, rather than the 
    -- 180-day historical training snapshot.
    TABLE `apex-activewear.silver_layer.user_churn_data` 
  )
)

SELECT
  user_id,
  predicted_has_churned AS is_churn_risk,
  
  -- Extract the probability specifically for the TRUE (churn) class
  ROUND((
    SELECT prob 
    FROM UNNEST(predicted_has_churned_probs) 
    WHERE label = TRUE
  ), 4) AS churn_probability,
  
  -- Include key financial features so the marketing team can prioritize high-value risks
  total_historical_spend,
  recency_days,
  historical_aov,
  total_order_count

FROM churn_predictions
ORDER BY churn_probability DESC;


/* ============================================================================
   STEP 5: ACTIVATION / CAMPAIGN EXTRACTION
   File: 05_prediction_results.sql
   Description: Extracts high-value churn risks for the targeted SMS win-back campaign.
   Architecture: Gold Layer / Activation
============================================================================ */

SELECT 
  user_id,
  churn_probability,
  total_historical_spend,
  dense_rank () over (order by total_historical_spend desc) as spend_rank,
  recency_days,
  total_order_count,
  dense_rank () over (order by total_order_count desc ) as orders_rank
  
FROM `apex-activewear.gold_layer.customer_churn_scores`
WHERE is_churn_risk = TRUE 
  AND churn_probability >= 0.75
ORDER BY total_historical_spend DESC;
