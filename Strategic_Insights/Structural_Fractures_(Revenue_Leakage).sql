--Objective: Evaluate attribution integrity by comparing top-of-funnel intent to bottom-of-funnel conversions.
--Funnel Visibility Gap & Anomaly Detection (View -> Cart -> Purchase)
--Highlight: Identifies traffic sources showing purchase volume without upstream intent signals.

WITH Funnel_Top AS (
  -- Capture top-of-funnel intent signals
  SELECT
    traffic_source, 
    COUNTIF(event_type = 'product') AS product_views,
    COUNTIF(event_type = 'cart') AS add_to_carts
  FROM 
    `apex-activewear.silver_layer.stg_online_events`
  GROUP BY 
    traffic_source
),

Purchases_Bottom AS (
  -- Isolate bottom-of-funnel conversions via intermediate attribution
  SELECT
    traffic_source,
    COUNT(order_id) AS purchases
  FROM 
    `apex-activewear.silver_layer.int_order_attribution`
  GROUP BY 
    traffic_source
)

SELECT
  p.traffic_source,
  COALESCE(f.product_views, 0) AS product_views,
  COALESCE(f.add_to_carts, 0) AS add_to_carts,
  p.purchases,

  -- Calculate View-to-Purchase Conversion Rate (%)
  ROUND(SAFE_DIVIDE(p.purchases, f.product_views), 2) AS view_to_purchase_rate,

  -- Flag pipeline anomalies: identifies 'Ghost Orders' (purchases without views)
  -- or suspiciously high conversion rates indicating broken data capture.
  CASE
    WHEN p.purchases > 0 AND COALESCE(f.product_views, 0) = 0 THEN 'CRITICAL: Broken Tracking'
    WHEN SAFE_DIVIDE(p.purchases, f.product_views) > 0.10 THEN 'Suspiciously High'
    ELSE 'Normal'
  END AS tracking_status

FROM 
  Purchases_Bottom p
LEFT JOIN 
  Funnel_Top f 
  USING(traffic_source)
ORDER BY 
  purchases DESC;
