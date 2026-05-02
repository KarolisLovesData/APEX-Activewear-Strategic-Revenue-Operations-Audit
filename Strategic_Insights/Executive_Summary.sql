/**
 * KPI SCORECARD: EXECUTIVE HEALTH CHECK
 * PURPOSE: Extracts core financial performance metrics (Revenue, Profit, Margin, AOV, Returns) 
 * into a single, high-level executive view.
 * 
 * PORTFOLIO NOTE: Relies on pre-calculated boolean flags (e.g., is_realized_revenue) 
 * pushed upstream to the Silver staging layer to ensure enterprise-wide metric consistency.
 */

SELECT 
  -- Banked Cash: Total top-line sales safely retained after all returns and cancellations.
  ROUND(SUM(CASE WHEN is_realized_revenue THEN sale_price ELSE 0 END), 2) AS realized_revenue,

  -- Net Bottom Line: Absolute profit generated exclusively from retained, successful orders.
  ROUND(SUM(CASE WHEN is_realized_revenue THEN gross_margin_amount ELSE 0 END), 2) AS realized_profit, 

  -- Profitability Index: The percentage of realized revenue that translates directly to gross profit.
  ROUND(
    (SUM(CASE WHEN is_realized_revenue THEN gross_margin_amount ELSE 0 END) / 
     NULLIF(SUM(CASE WHEN is_realized_revenue THEN sale_price ELSE 0 END), 0)) * 100
  , 2) AS gross_margin_pct,

  -- Basket Size (AOV): The average monetary value of a successful, non-cancelled checkout.
  ROUND(
    SUM(CASE WHEN is_realized_revenue THEN sale_price ELSE 0 END) /      
    NULLIF(COUNT(DISTINCT CASE WHEN is_realized_revenue THEN order_id ELSE NULL END), 0)     
  , 2) AS avg_order_value,

  -- Quality & Friction: The percentage of successfully delivered items that were ultimately returned.
  ROUND(
    (COUNTIF(is_returned) / 
     NULLIF(COUNTIF(is_realized_revenue OR is_returned), 0)) * 100
  , 2) AS return_rate_pct

FROM `apex-activewear.silver_layer.stg_order_items`;
