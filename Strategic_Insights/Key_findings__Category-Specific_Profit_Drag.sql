/**
 * PRODUCT CATEGORY REVENUE LEAKAGE (GOLD MART)
 * PURPOSE: Identifies catalog underperformers by tracking how much gross demand 
 * actually converts to banked revenue vs. bleeding out through returns and cancellations.
 * 
 * PORTFOLIO NOTE: Originally deployed as a Google Cloud Dataform (SQLX) model.
 */

SELECT
  p.category,
  
  -- Top-Line Demand: Total sales value generated before any post-purchase friction occurs.
  ROUND(SUM(oi.sale_price), 2) AS gross_revenue,

  -- Banked Cash (Net Revenue): Safe, realized revenue from completed or healthy in-flight orders.
  ROUND(
    SUM(
      CASE 
        WHEN oi.is_realized_revenue THEN oi.sale_price 
        ELSE 0 
      END
    ), 2
  ) AS net_revenue,

  -- Product Quality Indicators: Revenue lost specifically to post-purchase returns. 
  -- High rates here signal poor fit, product defects, or misleading catalog descriptions.
  ROUND(
    SUM(
      CASE 
        WHEN oi.is_returned THEN oi.sale_price 
        ELSE 0 
      END
    ), 2
  ) AS return_loss,
  
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN oi.is_returned THEN oi.sale_price ELSE 0 END), 
      SUM(oi.sale_price)
    ) * 100, 2
  ) AS return_rate_pct,

  -- Pre-Fulfillment Friction: Revenue lost before the item ever leaves the warehouse. 
  -- High rates here signal buyer remorse, payment failures, or intolerable shipping delays.
  ROUND(
    SUM(
      CASE 
        WHEN oi.is_cancelled THEN oi.sale_price 
        ELSE 0 
      END
    ), 2
  ) AS cancel_loss,
  
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN oi.is_cancelled THEN oi.sale_price ELSE 0 END), 
      SUM(oi.sale_price)
    ) * 100, 2
  ) AS cancel_rate_pct,

  -- The Total "Bleed" Rate: The ultimate category health metric. 
  -- Represents the percentage of total potential revenue that failed to materialize.
  ROUND(
    (
      1 - SAFE_DIVIDE(
        SUM(CASE WHEN oi.is_realized_revenue THEN oi.sale_price ELSE 0 END), 
        SUM(oi.sale_price)
      )
    ) * 100, 2
  ) AS total_loss_pct

FROM `apex-activewear.silver_layer.stg_order_items` AS oi
INNER JOIN `apex-activewear.silver_layer.stg_products` AS p
  ON oi.product_id = p.product_id
GROUP BY 1
ORDER BY total_loss_pct DESC;
