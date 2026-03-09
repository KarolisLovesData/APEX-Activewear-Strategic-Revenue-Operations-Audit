/* KPI: Funnel Visibility Gap & Anomaly Detection
  Goal: Compare funnel depth (View -> Cart -> Purchase).
  Highlight: Identifies traffic sources (e.g., 'Direct' and '(Unattributed)') 
             showing purchase volume without upstream intent signals.
*/

WITH Funnel_Top AS (
  -- 1. Aggregate top-of-funnel intent signals (Views and Carts) from staging events
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
  -- 2. Aggregate bottom-of-funnel conversions (Distinct Orders) from intermediate attribution
  SELECT
    traffic_source,
    COUNT(order_id) AS purchases
  FROM 
    `apex-activewear.silver_layer.int_order_attribution`
  GROUP BY 
    traffic_source
)

-- 3. Join top and bottom funnel metrics to evaluate attribution integrity
SELECT
  p.traffic_source,
  COALESCE(f.product_views, 0) AS product_views,
  COALESCE(f.add_to_carts, 0) AS add_to_carts,
  p.purchases,

  -- 4. Calculate Conversion Rate (safely handling division by zero)
  ROUND(SAFE_DIVIDE(p.purchases, f.product_views), 2) AS view_to_purchase_rate,

  -- 5. Flag Anomalies based on expected funnel behavior
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
