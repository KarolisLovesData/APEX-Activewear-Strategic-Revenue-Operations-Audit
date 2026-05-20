-- Predictive Churn Modeling: Feature Engineering & Label Generation
-- Constructs the training dataset using a 30-day snapshot to prevent data leakage.
-- Features are aggregated prior to the snapshot; the label evaluates if the user 
-- crossed the 180-day dormancy threshold during the subsequent 30-day window.


DECLARE snapshot_date TIMESTAMP DEFAULT TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);

CREATE OR REPLACE TABLE `apex-activewear.silver_layer.user_churn_data` 
CLUSTER BY has_churned, total_order_count AS

-- CTE 1: Isolate high-risk product keys to avoid joining the full product catalog later
WITH high_risk_products AS (
  SELECT product_id 
  FROM `apex-activewear.silver_layer.stg_products` 
  WHERE category = 'Mens Alpine Outerwear'
),

-- CTE 2: Pre-aggregate item-level rows to the order level
aggregated_order_items AS (
  SELECT 
    oi.order_id,
    COALESCE(SUM(oi.sale_price), 0) AS order_total,
    COUNT(oi.returned_at) AS order_returns,
    COUNTIF(oi.is_cancelled = true) AS cancelled_orders,
    MAX(CASE WHEN hr.product_id IS NOT NULL THEN 1 ELSE 0 END) AS is_high_risk_category
  FROM `apex-activewear.silver_layer.stg_order_items` oi
  LEFT JOIN high_risk_products hr ON oi.product_id = hr.product_id
  GROUP BY 1
),

-- CTE 3: Map clean order records to user keys
user_order_history AS (
  SELECT 
    o.user_id,
    o.created_at AS order_created_at,
    DATE_DIFF(o.delivered_at, o.shipped_at, HOUR) AS delivery_hours,
    ai.order_total,
    ai.is_high_risk_category,
    ai.order_returns,
    ai.cancelled_orders
  FROM `apex-activewear.silver_layer.stg_orders` o
  JOIN aggregated_order_items ai ON o.order_id = ai.order_id
),

-- CTE 4: Isolate user account foundation metadata along with their first purchase timestamp
user_base_profiles AS (
  SELECT 
    user_id, 
    created_at AS account_created_at, 
    MIN(created_at) OVER(PARTITION BY user_id) AS first_order_timestamp_marker 
  FROM `apex-activewear.silver_layer.stg_users`
),

-- CTE 5: Consolidate historical features and target markers in a single execution pass
user_lifecycle_stats AS (
  SELECT
    u.user_id,
    u.account_created_at,
    
    -- Boundary Markers
    MAX(oh.order_created_at) AS absolute_last_order,
    MIN(oh.order_created_at) AS first_order_date,

    -- Conditional Features (Historical Snapshot)
    MAX(CASE WHEN oh.order_created_at <= snapshot_date THEN oh.order_created_at END) AS last_order_before_snapshot,
    COUNT(DISTINCT CASE WHEN oh.order_created_at <= snapshot_date THEN oh.order_created_at END) AS total_order_count,
    MAX(CASE WHEN oh.order_created_at <= snapshot_date THEN oh.is_high_risk_category END) AS bought_high_risk_gear,
    SUM(CASE WHEN oh.order_created_at <= snapshot_date THEN oh.order_returns END) AS total_returns,
    SUM(CASE WHEN oh.order_created_at <= snapshot_date THEN oh.cancelled_orders END) AS total_cancelled,
    ROUND(AVG(CASE WHEN oh.order_created_at <= snapshot_date THEN oh.delivery_hours END), 2) AS avg_delivery_hours,
    
    -- Target Metric evaluated against the initial timestamp marker
    MAX(CASE WHEN oh.order_created_at = u.first_order_timestamp_marker THEN oh.order_total ELSE 0 END) AS first_order_value

  FROM user_base_profiles u
  LEFT JOIN user_order_history oh ON u.user_id = oh.user_id
  GROUP BY u.user_id, u.account_created_at, u.first_order_timestamp_marker
)

-- Final Assembly Layer: Calculate data labels and filter data bounds
SELECT
  user_id,
  ROUND(DATE_DIFF(first_order_date, account_created_at, HOUR)/24, 2) AS days_to_value,
  COALESCE(total_order_count, 0) AS total_order_count,
  COALESCE(bought_high_risk_gear, 0) AS bought_high_risk_gear,
  COALESCE(first_order_value, 0) AS first_order_value,
  COALESCE(avg_delivery_hours, 0) AS avg_delivery_hours,
  COALESCE(total_returns, 0) AS total_returns,
  COALESCE(total_cancelled, 0) AS total_cancelled,
  
  CASE 
    WHEN DATE_DIFF(snapshot_date, last_order_before_snapshot, DAY) < 180 
    AND DATE_DIFF(CURRENT_TIMESTAMP(), absolute_last_order, DAY) >= 180 
    THEN TRUE 
    ELSE FALSE 
  END AS has_churned
FROM user_lifecycle_stats
WHERE DATE_DIFF(snapshot_date, last_order_before_snapshot, DAY) < 180;
