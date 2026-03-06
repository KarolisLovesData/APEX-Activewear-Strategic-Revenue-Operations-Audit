/* The query calculates realized revenue growth QoQ.
  The analysis period covers Q1 2023 through Q4 2025. 
  Data from 2026 onwards is currently in a 'collection phase' 
  and was omitted from growth calculations to prevent skewing findings.
*/

WITH annual_counts AS (
  SELECT
    EXTRACT(YEAR FROM created_at) AS year,
    EXTRACT(QUARTER FROM created_at) AS quarter,
    COUNT(DISTINCT order_id) AS total_orders,
    
    -- leveraging the centralized business logic from Staging table (no returns or cancellations in realized_revenue)
    ROUND(SUM(CASE WHEN is_realized_revenue THEN sale_price ELSE 0 END), 2) AS realized_revenue

  FROM 
    `apex-activewear.silver_layer.stg_order_items`
  WHERE 
    EXTRACT(YEAR FROM created_at) < 2026 -- filtered out the beginning of 2026 to avoid skewed findings 
  GROUP BY 
    1, 2
)

SELECT
  year,
  quarter,
  realized_revenue,
  total_orders,
  ROUND(
    (total_orders - LAG(total_orders) OVER (ORDER BY year, quarter))
      / NULLIF(LAG(total_orders) OVER (ORDER BY year, quarter), 0)
      * 100, 2) AS QoQ_growth_pct
FROM 
  annual_counts
ORDER BY 
  year, quarter;
