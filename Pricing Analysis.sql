-- M3.1a — find price band thresholds (MySQL-compatible)
SELECT
    MAX(CASE WHEN pct_rank <= 0.33 THEN price END) AS low_upper_bound,
    MAX(CASE WHEN pct_rank <= 0.66 THEN price END) AS mid_upper_bound
FROM (
    SELECT
        price,
        PERCENT_RANK() OVER (ORDER BY price) AS pct_rank
    FROM events
    WHERE event_type = 'view'
) t;
-- note these two values — use them in M3.1b below


-- M3.1b — conversion rate by price band
--         replace 15.00 and 65.00 with your actual thresholds from M3.1a
WITH product_events AS (
    SELECT
        product_id,
        price,
        event_type,
        CASE
            WHEN price <= 15.00  THEN 'Low'
            WHEN price <= 65.00  THEN 'Medium'
            ELSE                      'High'
        END AS price_band
    FROM events
)
SELECT
    price_band,
    ROUND(MIN(price), 2)                            AS min_price,
    ROUND(MAX(price), 2)                            AS max_price,
    SUM(event_type = 'view')                        AS views,
    SUM(event_type = 'cart')                        AS carts,
    SUM(event_type = 'purchase')                    AS purchases,
    ROUND(
        SUM(event_type = 'purchase') * 100.0
        / NULLIF(SUM(event_type = 'view'), 0), 2
    )                                               AS view_to_purchase_pct,
    ROUND(
        SUM(event_type = 'cart') * 100.0
        / NULLIF(SUM(event_type = 'view'), 0), 2
    )                                               AS view_to_cart_pct,
    ROUND(
        SUM(event_type = 'purchase') * 100.0
        / NULLIF(SUM(event_type = 'cart'), 0), 2
    )                                               AS cart_to_purchase_pct
FROM product_events
GROUP BY price_band
ORDER BY FIELD(price_band, 'Low', 'Medium', 'High');

SELECT
    price_band,
    ROUND(MIN(price), 2)                                AS min_price,
    ROUND(MAX(price), 2)                                AS max_price,
    SUM(event_type = 'view')                            AS views,
    SUM(event_type = 'cart')                            AS carts,
    SUM(event_type = 'purchase')                        AS purchases,
    ROUND(
        SUM(event_type = 'cart') * 100.0
        / NULLIF(SUM(event_type = 'view'), 0), 2
    )                                                   AS view_to_cart_pct,
    ROUND(
        SUM(event_type = 'purchase') * 100.0
        / NULLIF(SUM(event_type = 'view'), 0), 2
    )                                                   AS view_to_purchase_pct,
    ROUND(
        LEAST(
            SUM(event_type = 'purchase') * 100.0
            / NULLIF(SUM(event_type = 'cart'), 0),
        100)
    , 2)                                                AS cart_to_purchase_pct
FROM (
    SELECT
        event_type,
        price,
        CASE
            WHEN price <= 15  THEN '1_Low ($0-15)'
            WHEN price <= 65  THEN '2_Medium ($15-65)'
            ELSE                   '3_High ($65+)'
        END AS price_band
    FROM events
) t
GROUP BY price_band
ORDER BY price_band;


-- ─────────────────────────────────────────
-- M3.2  Average order value by category
-- ─────────────────────────────────────────
SELECT
    category_code,
    COUNT(*)                        AS purchases,
    ROUND(SUM(price), 2)            AS total_revenue,
    ROUND(AVG(price), 2)            AS avg_order_value,
    ROUND(MIN(price), 2)            AS min_price,
    ROUND(MAX(price), 2)            AS max_price
FROM events
WHERE event_type = 'purchase'
  AND category_code IS NOT NULL
  AND TRIM(category_code) != ''
GROUP BY category_code
HAVING purchases >= 10
ORDER BY avg_order_value DESC
LIMIT 15;


-- ─────────────────────────────────────────
-- M3.3  Price elasticity proxy
--       (revenue by price decile — does revenue peak at a middle decile?)
-- ─────────────────────────────────────────
SELECT
    price_decile,
    ROUND(MIN(price), 2)            AS decile_min,
    ROUND(MAX(price), 2)            AS decile_max,
    COUNT(*)                        AS purchases,
    ROUND(SUM(price), 2)            AS total_revenue,
    ROUND(AVG(price), 2)            AS avg_price
FROM (
    SELECT
        price,
        NTILE(10) OVER (ORDER BY price) AS price_decile
    FROM events
    WHERE event_type = 'purchase'
) t
GROUP BY price_decile
ORDER BY price_decile;


-- ─────────────────────────────────────────
-- M3.4  High-value vs low-value buyer behaviour
--       (do expensive buyers browse differently?)
-- ─────────────────────────────────────────
WITH buyer_value AS (
    SELECT
        user_id,
        SUM(price)                  AS total_spent,
        COUNT(*)                    AS total_purchases,
        ROUND(AVG(price), 2)        AS avg_order_value
    FROM events
    WHERE event_type = 'purchase'
    GROUP BY user_id
),
buyer_segments AS (
    SELECT
        user_id,
        total_spent,
        avg_order_value,
        NTILE(3) OVER (ORDER BY total_spent) AS spend_tier
    FROM buyer_value
)
SELECT
    CASE spend_tier
        WHEN 1 THEN 'Low spender'
        WHEN 2 THEN 'Mid spender'
        WHEN 3 THEN 'High spender'
    END                                     AS segment,
    COUNT(*)                                AS users,
    ROUND(AVG(b.total_spent), 2)            AS avg_total_spent,
    ROUND(AVG(b.avg_order_value), 2)        AS avg_order_value,
    ROUND(AVG(e.view_count), 1)             AS avg_views_per_user,
    ROUND(AVG(e.session_count), 1)          AS avg_sessions_per_user
FROM buyer_segments b
JOIN (
    SELECT
        user_id,
        SUM(event_type = 'view')            AS view_count,
        COUNT(DISTINCT user_session)        AS session_count
    FROM events
    GROUP BY user_id
) e ON b.user_id = e.user_id
GROUP BY spend_tier
ORDER BY spend_tier;