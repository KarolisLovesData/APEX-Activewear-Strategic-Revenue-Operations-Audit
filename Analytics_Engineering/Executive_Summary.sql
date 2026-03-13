-- KPI Scorecard: High-Level Business Health Check
-- Objective: Extracts core financial metrics (Revenue, Realized Profit, Profit Margin, AOV, Returns) 
-- Dependency: Relies on pre-calculated boolean flags from the silver staging layer.




SELECT
  -- 1. Realized Revenue: Total sales volume minus returns and cancellations
  ROUND(SUM(CASE WHEN is_realized_revenue THEN sale_price ELSE 0 END), 2) AS realized_revenue,

  -- 2. Realized Profit: Absolute profit after accounting for restated return events
  ROUND(SUM(CASE WHEN is_realized_revenue THEN gross_margin_amount ELSE 0 END), 2) AS realized_profit, -- Reflects net truth; fluctuates as returns are backfilled.

  -- 3. Gross Margin (%): Profitability index on successfully retained revenue
  ROUND(
    (SUM(CASE WHEN is_realized_revenue THEN gross_margin_amount ELSE 0 END) / 
     NULLIF(SUM(CASE WHEN is_realized_revenue THEN sale_price ELSE 0 END), 0)) * 100
  , 2) AS gross_margin_pct,

  -- 4. Average Order Value (AOV): Average basket size for successful conversions
  ROUND(
    SUM(CASE WHEN is_realized_revenue THEN sale_price ELSE 0 END) /      --ELSE 0 does not affect the SUM result 
    NULLIF(COUNT(DISTINCT CASE WHEN is_realized_revenue THEN order_id ELSE NULL END), 0)     --ELSE NULL was added as COUNT ignores NULLS but does count 0 
  , 2) AS avg_order_value,

  -- 5. Global Return Rate (%): Ratio of returned items to all valid (non-cancelled) items
  ROUND(
    (COUNTIF(is_returned) / 
     NULLIF(COUNTIF(is_realized_revenue OR is_returned), 0)) * 100
  , 2) AS return_rate_pct

FROM 
  `apex-activewear.silver_layer.stg_order_items`;





