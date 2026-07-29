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
