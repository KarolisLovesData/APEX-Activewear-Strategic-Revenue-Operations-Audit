-- Predictive Churn Modeling: Feature Engineering & Label Generation
-- Constructs the training dataset using a 30-day snapshot to prevent data leakage.
-- Features are aggregated prior to the snapshot; the label evaluates if the user 
-- crossed the 180-day dormancy threshold during the subsequent 30-day window.

DECLARE snapshot_date TIMESTAMP DEFAULT TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);

CREATE OR REPLACE TABLE `apex-activewear.silver_layer.user_churn_data_v2` AS

-- CTE 1: Aggregate foundational transaction history and operational metrics
WITH all_orders AS (
  SELECT 
    u.user_id,
    u.created_at AS account_created_at,
    o.order_id,
    o.created_at AS order_created_at,
    DATE_DIFF(o.delivered_at, o.shipped_at, HOUR) AS delivery_hours,
    COALESCE(SUM(oi.sale_price), 0) AS order_total,
    -- Flag orders containing historically high-return product categories
    MAX(CASE WHEN p.category = 'Mens Alpine Outerwear' THEN 1 ELSE 0 END) AS is_high_risk_category,
    COUNT(oi.returned_at) AS order_returns,
    COUNTIF(oi.is_cancelled = true) AS cancelled_orders,
    -- Sequence orders to isolate initial purchase behavior
    ROW_NUMBER() OVER(PARTITION BY u.user_id ORDER BY o.created_at) AS order_sequence
  FROM `apex-activewear.silver_layer.stg_users` u
  JOIN `apex-activewear.silver_layer.stg_orders` o ON u.user_id = o.user_id
  LEFT JOIN `apex-activewear.silver_layer.stg_order_items` oi ON o.order_id = oi.order_id
  LEFT JOIN `apex-activewear.silver_layer.stg_products` p ON oi.product_id = p.product_id
  GROUP BY 1, 2, 3, 4, 5
),

-- CTE 2: Aggregate user profiles strictly prior to the snapshot date (Model Features)
snapshot_features AS (
  SELECT
    user_id,
    account_created_at,
    MAX(order_created_at) AS last_order_before_snapshot,
    MIN(order_created_at) AS first_order_date,
    COUNT(DISTINCT order_id) AS total_order_count,
    MAX(is_high_risk_category) AS bought_high_risk_gear,
    MAX(CASE WHEN order_sequence = 1 THEN order_total ELSE 0 END) AS first_order_value,
    ROUND(AVG(delivery_hours), 2) AS avg_delivery_hours,
    SUM(order_returns) AS total_returns,
    SUM(cancelled_orders) AS total_cancelled
  FROM all_orders
  WHERE order_created_at <= snapshot_date
  GROUP BY 1, 2
),

-- CTE 3: Capture the absolute latest order to determine the true current state
future_labels AS (
  SELECT 
    user_id, 
    MAX(order_created_at) AS absolute_last_order 
  FROM all_orders 
  GROUP BY 1
)

-- Final Assembly: Combine historical features with the calculated target label
SELECT
  f.user_id,
  ROUND(DATE_DIFF(f.first_order_date, f.account_created_at, HOUR)/24, 2) AS days_to_value,
  f.total_order_count,
  f.bought_high_risk_gear,
  f.first_order_value,
  f.avg_delivery_hours,
  f.total_returns,
  f.total_cancelled,
  -- Target Label: Evaluates if a user hit the 180-day dormancy mark exactly within the 30-day window
  CASE 
    WHEN DATE_DIFF(snapshot_date, f.last_order_before_snapshot, DAY) < 180 
    AND DATE_DIFF(CURRENT_TIMESTAMP(), l.absolute_last_order, DAY) >= 180 
    THEN TRUE 
    ELSE FALSE 
  END AS has_churned
FROM snapshot_features f
JOIN future_labels l ON f.user_id = l.user_id
-- Filter: Restrict training data to users active as of the snapshot date
WHERE DATE_DIFF(snapshot_date, f.last_order_before_snapshot, DAY) < 180;






-- Predictive Churn Modeling: Model Training & Hyperparameter Tuning
-- Trains an XGBoost classifier in BigQuery ML to predict user churn.
-- Utilizes automated tuning to optimize for ROC AUC, balances class weights, 
-- and enables global explanations for feature importance.

CREATE OR REPLACE MODEL `apex-activewear.silver_layer.xgboost_churn_model`
OPTIONS(
  model_type='BOOSTED_TREE_CLASSIFIER',
  input_label_cols=['has_churned'],
  auto_class_weights=TRUE,
  
  -- Hyperparameter Tuning Configuration
  num_trials=20,           -- Total number of combinations to evaluate
  max_parallel_trials=2,   -- Number of concurrent training trials
  hparam_tuning_objectives=['roc_auc'], 
  
  enable_global_explain=TRUE
) AS
SELECT
  -- Behavioral and Operational Features
  days_to_value,
  total_order_count,
  bought_high_risk_gear,
  first_order_value,
  avg_delivery_hours,
  total_returns,
  total_cancelled,
  
  -- Target Label
  has_churned
FROM `apex-activewear.silver_layer.user_churn_data_v2`;
