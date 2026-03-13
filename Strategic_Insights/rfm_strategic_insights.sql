
/* 1. Golden Table for RFM segments
  This standard BI query details segment size by customer count, 
  total value, and average user LTV.
*/
SELECT 
  rfm_segment,
  COUNT(user_id) AS number_of_users,
  ROUND(SUM(monetary_value), 2) AS total_segment_value,
  ROUND(SAFE_DIVIDE(SUM(monetary_value), COUNT(user_id)), 2) AS average_segment_user_LTV
FROM
  `apex-activewear.gold_layer.mart_rfm_segments`
GROUP BY
  rfm_segment
ORDER BY
  total_segment_value DESC;


/* 2. RFM Segments by Country Dimension
  This standard BI query adds a country dimension to the RFM segments 
  for geographic analysis and valuation.
*/
SELECT 
  u.country,
  rfm_segment,
  COUNT(user_id) AS number_of_users,
  ROUND(SUM(monetary_value), 2) AS total_segment_value,
  ROUND(SAFE_DIVIDE(SUM(monetary_value), COUNT(user_id)), 2) AS average_segment_user_LTV
FROM
  `apex-activewear.gold_layer.mart_rfm_segments`
  INNER JOIN `apex-activewear.silver_layer.stg_users` u USING(user_id)
GROUP BY
  country, rfm_segment
ORDER BY
  country;


/* 3. Core RFM Segmentation Model
  To create the clean and BI-ready queries above, this model was originally 
  built in Dataform. It has been translated here into standard BigQuery SQL.
*/
WITH
  rfm_base AS (
  SELECT
    user_id,
    -- Calculate Recency: Days since last order from a static anchor date.
    -- NOTE: In production, I would replace DATE('2026-01-19')[end of data] with CURRENT_DATE() 
    -- so segments update dynamically as time passes rather than slowly decaying.
    DATE_DIFF(DATE('2026-01-19'), DATE(last_order_at), DAY) AS recency_days, 
    lifetime_orders AS frequency,
    ROUND(lifetime_revenue, 2) AS monetary_value
  FROM
    `apex-activewear.silver_layer.int_user_lifecycle`
  WHERE
    lifetime_orders > 0
    AND first_order_at >= TIMESTAMP('2023-01-09')
    AND last_order_at <= TIMESTAMP('2026-01-19 23:59:59') 
  ),

  rfm_scores AS (
  SELECT
    *,
    -- RECENCY: Manual CASE statement allows for customized, precise recency segmentation rather than NTILE.
    CASE
      WHEN recency_days <= 30 THEN 5
      WHEN recency_days <= 90 THEN 4
      WHEN recency_days <= 120 THEN 3
      WHEN recency_days <= 365 THEN 2
      ELSE 1
    END AS r_score,

    -- FREQUENCY: Manual CASE statement ensures exact order counts are segmented correctly.
    CASE
      WHEN frequency = 1 THEN 1
      WHEN frequency = 2 THEN 2
      WHEN frequency = 3 THEN 3
      WHEN frequency = 4 THEN 4
      ELSE 5
    END AS f_score,

    -- MONETARY: Calculated ONLY on this filtered base.
    NTILE(5) OVER (ORDER BY monetary_value ASC) AS m_score
  FROM
    rfm_base 
  ),

  rfm_segments AS (
  SELECT
    *,
    -- SEGMENTATION: Assigning intuitive segment names to customers based on their combined scores.
    CASE
      WHEN r_score = 5 AND f_score = 5 AND m_score = 5 THEN 'Champions' 
      WHEN r_score >= 3 AND f_score >= 4 AND m_score >= 4 THEN 'Loyal Customers'
      WHEN r_score >= 4 AND f_score >= 2 AND m_score >= 2 THEN 'Potential Loyalists'
      WHEN r_score = 5 AND f_score = 1 THEN 'New Customers'
      WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'At Risk / Can't Lose'
      WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating / Lost'
      ELSE 'Needs Attention'
    END AS rfm_segment
  FROM
    rfm_scores 
  )

SELECT
  *
FROM
  rfm_segments;
