USE ecommerce_analytics;

-- ─────────────────────────────────────────
-- M1.1  Row count + event distribution
-- ─────────────────────────────────────────
SELECT
    event_type,
    COUNT(*)                                                    AS event_count,
    COUNT(DISTINCT user_id)                                     AS unique_users,
    COUNT(DISTINCT user_session)                                AS unique_sessions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)         AS pct_of_total
FROM events
GROUP BY event_type
ORDER BY event_count DESC;


-- ─────────────────────────────────────────
-- M1.2  Daily event volume (spot data gaps)
-- ─────────────────────────────────────────
SELECT
    DATE(event_time)            AS event_date,
    COUNT(*)                    AS total_events,
    SUM(event_type = 'view')    AS views,
    SUM(event_type = 'cart')    AS carts,
    SUM(event_type = 'purchase') AS purchases
FROM events
GROUP BY DATE(event_time)
ORDER BY event_date;


-- ─────────────────────────────────────────
-- M1.3  Price distribution by event type
-- ─────────────────────────────────────────
WITH stats AS (
    SELECT
        event_type,
        MIN(price) AS min_price,
        MAX(price) AS max_price,
        AVG(price) AS avg_price,
        STDDEV(price) AS std_price
    FROM events
    GROUP BY event_type
),

median_calc AS (
    SELECT
        event_type,
        AVG(price_val) AS median_price
    FROM (
        SELECT
            event_type,
            price AS price_val,
            ROW_NUMBER() OVER (PARTITION BY event_type ORDER BY price) AS rn,
            COUNT(*) OVER (PARTITION BY event_type) AS total
        FROM events
    ) t
    WHERE rn IN (FLOOR((total + 1) / 2), CEIL((total + 1) / 2))
    GROUP BY event_type
)

SELECT 
    s.event_type,
    ROUND(s.min_price, 2),
    ROUND(s.max_price, 2),
    ROUND(s.avg_price, 2),
    ROUND(s.std_price, 2),
    ROUND(m.median_price, 2)
FROM stats s
JOIN median_calc m 
ON s.event_type = m.event_type;


-- ─────────────────────────────────────────
-- M1.4  Null + empty value audit
-- ─────────────────────────────────────────
SELECT
    SUM(event_time   IS NULL)                   AS null_event_time,
    SUM(event_type   IS NULL)                   AS null_event_type,
    SUM(product_id   IS NULL)                   AS null_product_id,
    SUM(price        IS NULL OR price = 0)      AS null_zero_price,
    SUM(user_id      IS NULL)                   AS null_user_id,
    SUM(user_session IS NULL OR
        TRIM(user_session) = '')                AS null_empty_session,
    SUM(category_code IS NULL OR
        TRIM(category_code) = '')               AS null_empty_category,
    SUM(brand IS NULL OR
        TRIM(brand) = '')                       AS null_empty_brand,
    COUNT(*)                                    AS total_rows
FROM events;


-- ─────────────────────────────────────────
-- M1.5  Sessions per user distribution
--       (shows if data is user-heavy or session-heavy)
-- ─────────────────────────────────────────
SELECT
    sessions_per_user,
    COUNT(*)                                        AS user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM (
    SELECT
        user_id,
        COUNT(DISTINCT user_session) AS sessions_per_user
    FROM events
    GROUP BY user_id
) t
GROUP BY sessions_per_user
ORDER BY sessions_per_user;


-- ─────────────────────────────────────────
-- M1.6  Top 10 brands by purchase volume
-- ─────────────────────────────────────────
SELECT
    brand,
    COUNT(*)                        AS purchase_events,
    ROUND(SUM(price), 2)            AS total_revenue,
    ROUND(AVG(price), 2)            AS avg_order_value
FROM events
WHERE event_type = 'purchase'
  AND brand IS NOT NULL
  AND TRIM(brand) != ''
GROUP BY brand
ORDER BY purchase_events DESC
LIMIT 10;