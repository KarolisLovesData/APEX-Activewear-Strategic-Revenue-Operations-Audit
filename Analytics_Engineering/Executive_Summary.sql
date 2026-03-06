--KPI SCORECARD: The High-Level Health Check
   
SELECT
  -- 1. Realized Revenue (Money actually kept)
  ROUND(SUM(CASE WHEN is_realized_revenue THEN sale_price ELSE 0 END), 2) AS realized_revenue,

  -- 2. Gross Margin % (Efficiency)
  ROUND(
    (SUM(CASE WHEN is_realized_revenue THEN gross_margin_amount ELSE 0 END) / 
     NULLIF(SUM(CASE WHEN is_realized_revenue THEN sale_price ELSE 0 END), 0)) * 100
  , 2) AS gross_margin_pct,

  -- 3. Average Order Value
  ROUND(
    SUM(CASE WHEN is_realized_revenue THEN sale_price ELSE 0 END) / 
    NULLIF(COUNT(DISTINCT CASE WHEN is_realized_revenue THEN order_id ELSE NULL END), 0)
  , 2) AS AOV,

  -- 4. Global Return Rate 
  -- Denominator includes 'Complete', 'Shipped', 'Processing', AND 'Returned'
  ROUND(
    (COUNTIF(is_returned) / 
     NULLIF(COUNTIF(is_realized_revenue OR is_returned), 0)) * 100
  , 2) AS return_rate_pct

FROM 
  `apex-activewear.silver_layer.stg_order_items`;


