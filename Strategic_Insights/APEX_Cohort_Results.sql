/* This query was originally developed in SQLX within Google Cloud Dataform 
   and has been translated to standard BigQuery SQL.
   Standard Monthly Cohort Retention (Month 0-12) to track customer lifecycle and drop-off.
*/

WITH user_cohorts AS (
  -- 1. Define the Cohort: Find the first month a user made a successful purchase.
  SELECT
    user_id,
    DATE_TRUNC(DATE(MIN(created_at)), MONTH) AS cohort_month
  FROM
    `apex-activewear.silver_layer.stg_orders`
  WHERE
    status IN ('Complete', 'Shipped')
    /*ACQUISITION WINDOW: I cut off new cohort creation at 2025-01-09. 
      This ensures that even the very last cohort has a full 12-month "runway" 
      to mature before the dataset ends in early 2026 */
    AND created_at BETWEEN '2023-01-09' AND '2025-01-09'
  GROUP BY
    1
),

cohort_sizes AS (
  -- 2. Size the Cohort: Count the total number of unique users acquired in each baseline month.
  SELECT
    cohort_month,
    COUNT(user_id) AS initial_users
  FROM
    user_cohorts
  GROUP BY
    1
),

retention_data AS (
  -- 3. Track Activity: Calculate how many months after the initial cohort month the user returned to buy again.
  SELECT
    uc.cohort_month,
    DATE_DIFF(DATE_TRUNC(DATE(o.created_at), MONTH), uc.cohort_month, MONTH) AS month_number,
    COUNT(DISTINCT o.user_id) AS active_users
  FROM
    `apex-activewear.silver_layer.stg_orders` AS o
  JOIN
    user_cohorts AS uc
    ON o.user_id = uc.user_id
  WHERE
    o.status IN ('Complete', 'Shipped')
     /*OBSERVATION WINDOW: I extended tracking out to 2026-01-19.
       This gives the final Jan 2025 cohort exactly 12 months of observable history,
       preventing artificial drop-offs in the final months of the report.*/
    AND o.created_at <= '2026-01-19 23:59:59'       
  GROUP BY
    1,
    2
)

-- 4. Final Output: Calculate the actual retention rate percentage for months 0-12.
SELECT
  rd.cohort_month,
  cs.initial_users,
  rd.month_number,
  rd.active_users,
  -- SAFE_DIVIDE prevents divide-by-zero errors. Month 0 retention will always be 1.0000 (100%).
  ROUND(SAFE_DIVIDE(rd.active_users, cs.initial_users), 4) AS retention_rate
FROM
  retention_data AS rd
JOIN
  cohort_sizes AS cs
  ON rd.cohort_month = cs.cohort_month
WHERE
  -- Focus the mart strictly on the first year (12 months) of the customer lifecycle.
  rd.month_number BETWEEN 0 AND 12
ORDER BY
  rd.cohort_month DESC,
  rd.month_number ASC;
