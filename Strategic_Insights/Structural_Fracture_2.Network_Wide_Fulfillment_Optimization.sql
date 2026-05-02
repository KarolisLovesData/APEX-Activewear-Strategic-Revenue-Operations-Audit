/**
 * WAREHOUSE SLA & CAPACITY UTILIZATION
 * PURPOSE: Evaluates distribution center efficiency by mapping network load 
 * against internal processing speed and end-to-end delivery latency.
 * 
 * PORTFOLIO NOTE: Originally developed in SQLX (Google Cloud Dataform).
 */

SELECT
  dc.name AS distribution_center,

  -- Network Load: Percentage of total company volume handled by this facility
  ROUND(COUNT(o.order_id) / SUM(COUNT(o.order_id)) OVER () * 100, 1) AS volume_share_pct,

  -- Internal Friction: Average days spent processing inside the four walls of the warehouse
  ROUND(AVG(TIMESTAMP_DIFF(o.shipped_at, o.created_at, SECOND) / (24 * 60 * 60)), 2) AS avg_fulfillment_latency_days,

  -- Customer Experience: End-to-end cycle time (Order-to-Door)
  ROUND(AVG(TIMESTAMP_DIFF(o.delivered_at, o.created_at, SECOND) / (24 * 60 * 60)), 2) AS avg_ofct_days

FROM `apex-activewear.silver_layer.stg_orders` AS o
JOIN `apex-activewear.silver_layer.stg_distribution_centers` AS dc
  ON o.distribution_center_id = dc.id
WHERE o.status = 'Complete'
  -- Restrict scope to finalized cycles to ensure accurate SLA measurement
  AND o.shipped_at IS NOT NULL
  AND o.delivered_at IS NOT NULL
GROUP BY 1
ORDER BY volume_share_pct DESC;


/**
 * GLOBAL LOGISTICS BOTTLENECK ANALYSIS
 * PURPOSE: Quantifies system-wide warehouse friction and models the 
 * projected improvement to customer delivery times if strict processing SLAs are enforced.
 */

SELECT
  -- Processing Latency: The current operational baseline
  ROUND(AVG(TIMESTAMP_DIFF(shipped_at, created_at, SECOND) / (24 * 60 * 60)), 2) AS avg_fulfillment_latency_days,

  -- Total Delivery Cycle: The current baseline customer experience
  ROUND(AVG(TIMESTAMP_DIFF(delivered_at, created_at, SECOND) / (24 * 60 * 60)), 2) AS avg_ofct_days,

  -- Warehouse Drag: Percentage of the total delivery timeline wasted sitting on warehouse shelves
  ROUND(
    AVG(TIMESTAMP_DIFF(shipped_at, created_at, SECOND)) / 
    AVG(TIMESTAMP_DIFF(delivered_at, created_at, SECOND)) * 100, 1
  ) AS warehouse_share_of_total_time_pct,

  -- Target State ROI: Modeled customer delivery time if warehouse processing is optimized to exactly 24 hours
  ROUND(
    (AVG(TIMESTAMP_DIFF(delivered_at, created_at, SECOND) / (24 * 60 * 60))) - 
    (AVG(TIMESTAMP_DIFF(shipped_at, created_at, SECOND) / (24 * 60 * 60)) - 1.0), 2
  ) AS projected_ofct_after_fix

FROM `apex-activewear.silver_layer.stg_orders`
WHERE status = 'Complete'
  -- Exclude inflight orders to prevent partial data from skewing the baseline averages
  AND shipped_at IS NOT NULL
  AND delivered_at IS NOT NULL;
