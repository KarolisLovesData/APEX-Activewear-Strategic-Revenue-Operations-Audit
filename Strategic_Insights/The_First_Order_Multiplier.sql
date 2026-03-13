/* STRATEGIC AUDIT: II. Dormant Opportunities (Value Unlocks) 
  1. The "First Order" Multiplier (LTV Optimization)

  Note: The underlying construction models were originally developed in SQLX 
  within Google Cloud Dataform and have been translated here to standard BigQuery SQL.
*/

/* -------------------------------------------------------------------------
   REPORTING: First Basket Value vs. 12-Month LTV
   This query returns AVG first basket value, # of customers, and AVG 12-month LTV 
   of high first-time baskets vs. low first-time baskets.
------------------------------------------------------------------------- */
SELECT
  customer_segment,
  COUNT(DISTINCT user_id) AS total_customers,
  ROUND(AVG(first_basket_size), 2) AS avg_first_basket,
  ROUND(AVG(ltv_12_months), 2) AS avg_12_month_ltv
FROM
  `apex-activewear.gold_layer.mart_ltv_12m_segmentation`
GROUP BY
  1
ORDER BY
  avg_12_month_ltv DESC;


/* -------------------------------------------------------------------------
   DATA MODEL: LTV Prediction (12-Month Revenue)
   This query constructs the mart for strict 12-Month Revenue segmentation.
------------------------------------------------------------------------- */
WITH first_orders AS (
  SELECT
    user_id,
    order_id,
    created_at AS first_order_date
  FROM 
    `apex-activewear.silver_layer.stg_orders`
  WHERE 
    status IN ('Complete', 'Shipped')
    AND created_at >= '2023-01-09' 
    AND created_at <= '2025-01-09'
  QUALIFY 
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at ASC) = 1
),

first_order_value AS (
  SELECT
    fo.user_id,
    fo.first_order_date,
    SUM(oi.sale_price) AS first_basket_size
  FROM 
    first_orders AS fo
  JOIN 
    `apex-activewear.silver_layer.stg_order_items` AS oi 
    ON fo.order_id = oi.order_id
  GROUP BY 
    1, 2
),

ltv_12m_data AS (
  SELECT
    fo.user_id,
    SUM(oi.sale_price) AS ltv_12_months
  FROM 
    `apex-activewear.silver_layer.stg_order_items` AS oi
  JOIN 
    first_orders AS fo 
    ON oi.user_id = fo.user_id
  WHERE 
    oi.status = 'Complete' 
    AND DATE(oi.created_at) >= DATE(fo.first_order_date)
    AND DATE(oi.created_at) <= DATE_ADD(DATE(fo.first_order_date), INTERVAL 1 YEAR)
  GROUP BY 
    1
)

SELECT
  fov.user_id,
  fov.first_basket_size,
  COALESCE(lt.ltv_12_months, fov.first_basket_size) AS ltv_12_months,
  CASE 
    WHEN fov.first_basket_size > 90 THEN 'High Value (> $90)' 
    ELSE 'Low Value (<= $90)' 
  END AS customer_segment
FROM
  first_order_value AS fov
LEFT JOIN
  ltv_12m_data AS lt 
  ON fov.user_id = lt.user_id;


/* -------------------------------------------------------------------------
   REPORTING: Segmented Retention 
   This query compares retention rates of High Value (>$90) vs. Low Value (<$90) cohorts.
------------------------------------------------------------------------- */
SELECT 
  * FROM 
  `apex-activewear.gold_layer.mart_segmented_retention` 
ORDER BY 
  1, 2;


/* -------------------------------------------------------------------------
   DATA MODEL: Segmented Retention Curve
   This query constructs the mart comparing the retention curves of High vs Low value segments.
------------------------------------------------------------------------- */
WITH First_Orders AS (
  SELECT
    user_id,
    order_id,
    created_at AS first_order_date
  FROM
    `apex-activewear.silver_layer.stg_orders`
  WHERE
    status IN ('Complete', 'Shipped')
  QUALIFY
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at ASC) = 1 
),

User_Segments AS (
  SELECT
    fo.user_id,
    fo.first_order_date,
    CASE
      WHEN SUM(oi.sale_price) > 90 THEN 'High Value (>$90)'
      ELSE 'Low Value (<$90)'
    END AS segment
  FROM
    First_Orders fo
  JOIN
    `apex-activewear.silver_layer.stg_order_items` oi
    ON fo.order_id = oi.order_id
  GROUP BY
    1, 2 
),

Segment_Sizes AS (
  SELECT
    segment,
    COUNT(user_id) AS initial_users
  FROM
    User_Segments
  GROUP BY
    1 
),

Retention_Activity AS (
  SELECT
    us.segment,
    DATE_DIFF(DATE(o.created_at), DATE(us.first_order_date), MONTH) AS month_number,
    COUNT(DISTINCT o.user_id) AS active_users
  FROM
    User_Segments us
  JOIN
    `apex-activewear.silver_layer.stg_orders` o
    ON us.user_id = o.user_id
  WHERE
    o.status IN ('Complete', 'Shipped')
    AND o.created_at >= us.first_order_date
  GROUP BY
    1, 2 
)

SELECT
  ra.segment,
  ra.month_number,
  ss.initial_users,
  ra.active_users,
  ROUND((ra.active_users / ss.initial_users) * 100, 2) AS retention_rate_pct
FROM
  Retention_Activity ra
JOIN
  Segment_Sizes ss
  ON ra.segment = ss.segment
WHERE
  ra.month_number BETWEEN 0 AND 12;
