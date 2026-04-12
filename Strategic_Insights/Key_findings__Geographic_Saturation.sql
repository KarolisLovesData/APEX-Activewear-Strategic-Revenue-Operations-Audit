/* This query calculates the geographical distribution of realized revenue and order volume by country. */
SELECT
  u.country,
  COUNT(DISTINCT oi.order_id) AS total_orders,
  ROUND(SUM(oi.sale_price), 2) AS country_revenue,
  
  --Calculate the country's revenue strictly relative to the global aggregate
  ROUND(
    SAFE_DIVIDE(
      SUM(oi.sale_price), 
      SUM(SUM(oi.sale_price)) OVER() 
    ) * 100, 
    2
  ) AS pct_of_total_revenue

FROM `apex-activewear.silver_layer.stg_order_items` AS oi
JOIN `apex-activewear.silver_layer.stg_users` AS u
  ON oi.user_id = u.user_id

--Filter exclusively for completed, non-returned transactions
WHERE oi.is_realized_revenue = TRUE

GROUP BY 1
ORDER BY total_orders DESC;
