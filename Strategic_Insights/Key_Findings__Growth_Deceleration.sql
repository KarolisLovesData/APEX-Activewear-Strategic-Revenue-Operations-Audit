--Objective: Track company growth momentum across realized revenue and order volume.
--Quarter-over-Quarter (QoQ) Growth Analysis (Q1 2023 - Q4 2025)
--Filters: Excludes in-progress 2026 data to prevent sudden drops in order and revenue

WITH
  quarterly_metrics AS (
    SELECT
      EXTRACT(YEAR FROM created_at) AS order_year,
      EXTRACT(QUARTER FROM created_at) AS order_quarter,
      COUNT(DISTINCT order_id) AS total_orders,

      -- Enforce clean revenue: relies on the 'is_realized_revenue' flag
      -- to automatically exclude returns and cancellations.
      ROUND(SUM(CASE WHEN is_realized_revenue THEN sale_price ELSE 0 END), 2)
        AS realized_revenue
    FROM
      `apex-activewear.silver_layer.stg_order_items`
    WHERE
      EXTRACT(YEAR FROM created_at)
      < 2026  -- Isolate completed years for accurate trend analysis
    GROUP BY
      1, 2
  )
SELECT
  order_year,
  order_quarter,
  realized_revenue,
  -- Calculate Quarter-over-Quarter (QoQ) Revenue Growth (%)
  ROUND(
    (
      realized_revenue - LAG(realized_revenue)
        OVER (ORDER BY order_year, order_quarter))
      / NULLIF(
        LAG(realized_revenue) OVER (ORDER BY order_year, order_quarter), 0)
      * 100,
    2) AS qoq_revenue_growth_pct,
  total_orders,

  -- Calculate Quarter-over-Quarter (QoQ) Volume Growth (%)
  ROUND(
    (total_orders - LAG(total_orders) OVER (ORDER BY order_year, order_quarter))
      / NULLIF(LAG(total_orders) OVER (ORDER BY order_year, order_quarter), 0)
      * 100,
    2) AS qoq_volume_growth_pct
FROM
  quarterly_metrics
ORDER BY
  order_year, order_quarter;
