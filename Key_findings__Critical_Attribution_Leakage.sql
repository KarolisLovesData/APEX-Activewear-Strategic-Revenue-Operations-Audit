-- This query calculates total revenue we received via each traffic source and respective percentage

SELECT
  map.traffic_source,
  ROUND(SUM(oi.sale_price), 2) AS total_revenue,
  ROUND(100.0 * SUM(oi.sale_price) / SUM(SUM(oi.sale_price)) OVER (), 2)
    AS revenue_share_pct
FROM
  `apex-activewear.silver_layer.stg_order_items` oi
JOIN
  `apex-activewear.silver_layer.int_order_attribution` map
  ON oi.order_id = map.order_id
GROUP BY
  1
ORDER BY
  2 DESC;
