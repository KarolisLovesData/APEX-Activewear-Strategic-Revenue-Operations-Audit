/* These queries were originally developed in SQLX within Google Cloud Dataform 
  and has been translated to standard BigQuery SQL.
  This query tracks volume share and latency SLAs per distribution center.
*/

SELECT
  dc.name AS distribution_center,

  -- 1. Volume Share: Calculates the percentage of total completed orders handled by each specific DC.
  ROUND(
    COUNT(o.order_id) / SUM(COUNT(o.order_id)) OVER () * 100, 1
  ) AS volume_share_pct,

  -- 2. Avg Fulfillment Latency: Measures the time spent inside the warehouse (creation to shipment).
  ROUND(
    AVG(TIMESTAMP_DIFF(o.shipped_at, o.created_at, SECOND) / (24 * 60 * 60)), 2
  ) AS avg_fulfillment_latency_days,

  -- 3. Avg Total Delivery Time (OFCT): Measures the end-to-end customer experience (creation to final delivery).
  ROUND(
    AVG(TIMESTAMP_DIFF(o.delivered_at, o.created_at, SECOND) / (24 * 60 * 60)), 2
  ) AS avg_ofct_days

FROM
  `apex-activewear.silver_layer.stg_orders` AS o
JOIN
  `apex-activewear.silver_layer.stg_distribution_centers` AS dc
  ON o.distribution_center_id = dc.id
WHERE
  o.status = 'Complete'
  -- Filter to ensure we only include fully processed orders for accurate performance metrics.
  AND o.shipped_at IS NOT NULL
  AND o.delivered_at IS NOT NULL
GROUP BY
  1
ORDER BY
  volume_share_pct DESC;


/* 
  This query Highlights global warehouse "drag" and projected delivery time improvements.
*/

SELECT
  -- 1. Fulfillment Latency (The Bottleneck): Global average days from order creation to shipment.
  ROUND(
    AVG(TIMESTAMP_DIFF(shipped_at, created_at, SECOND) / (24 * 60 * 60)), 2
  ) AS avg_fulfillment_latency_days,

  -- 2. Average OFCT (Order Fulfillment Cycle Time): Global average days from creation to final delivery.
  ROUND(
    AVG(TIMESTAMP_DIFF(delivered_at, created_at, SECOND) / (24 * 60 * 60)), 2
  ) AS avg_ofct_days,

  -- 3. The "Drag": The percentage of total delivery time that the package spends sitting in the warehouse.
  ROUND(
    AVG(TIMESTAMP_DIFF(shipped_at, created_at, SECOND)) / 
    AVG(TIMESTAMP_DIFF(delivered_at, created_at, SECOND)) * 100, 1
  ) AS warehouse_share_of_total_time_pct,

  -- 4. The "Opportunity": Projected total delivery time (OFCT) if we optimized fulfillment latency down to exactly 1 day.
  ROUND(
    (AVG(TIMESTAMP_DIFF(delivered_at, created_at, SECOND) / (24 * 60 * 60))) - 
    (AVG(TIMESTAMP_DIFF(shipped_at, created_at, SECOND) / (24 * 60 * 60)) - 1.0), 2
  ) AS projected_ofct_after_fix

FROM
  `apex-activewear.silver_layer.stg_orders`
WHERE
  status = 'Complete'
  -- Exclude active orders to ensure averages are based on completed delivery cycles.
  AND shipped_at IS NOT NULL
  AND delivered_at IS NOT NULL;
