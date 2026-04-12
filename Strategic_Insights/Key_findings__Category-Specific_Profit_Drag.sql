
/* Product Category Leakage Analysis: Revenue vs. Returns and Cancellations
   Granularity: One row per Product Category Dataform Logic (gold_layer.mart_product_leakage)
The following SQL (used SQLX in Dataform)  logic builds the golden layer mart.
*/
SELECT
  p.category,
 --1. GROSS REVENUE Total demand generated, regardless of whether the order was fulfilled.
   ROUND(SUM(oi.sale_price), 2) AS gross_revenue,

  /* 2. REALIZED REVENUE
     Revenue from orders safely banked or actively in progress.
     Note: BigQuery's SUM(IF(...)) could be used here, but standard 
     CASE WHEN is retained for universal SQL readability.
  */
  ROUND(
    SUM(
      CASE 
        WHEN oi.is_realized_revenue THEN oi.sale_price 
        ELSE 0 
      END
    ), 2
  ) AS net_revenue,

  /* 3. RETURN METRICS (Quality Indicators)
     Measures revenue lost specifically due to returned items.
  */
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

  /* 4. CANCELLATION METRICS (Friction Indicators)
     Measures revenue lost prior to fulfillment due to canceled orders.
  */
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

  /* 5. TOTAL LEAKAGE (The Ultimate Health Metric)
     Calculates the percentage of total potential revenue that was NOT kept.
     Formula: 100% - (Realized Revenue / Gross Revenue)
  */
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
