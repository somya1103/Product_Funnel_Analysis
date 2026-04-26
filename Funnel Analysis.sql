-- ─────────────────────────────────────────
-- M2.1  User-level funnel
--       (how many unique users reach each stage)
-- ─────────────────────────────────────────
WITH user_stages AS (
    SELECT
        user_id,
        MAX(event_type = 'view')     AS did_view,
        MAX(event_type = 'cart')     AS did_cart,
        MAX(event_type = 'purchase') AS did_purchase
    FROM events
    GROUP BY user_id
)
SELECT
    SUM(did_view)                                           AS viewers,
    SUM(did_cart)                                           AS carted,
    SUM(did_purchase)                                       AS purchasers,
    ROUND(SUM(did_cart)     * 100.0 / SUM(did_view), 2)    AS view_to_cart_pct,
    ROUND(SUM(did_purchase) * 100.0 / SUM(did_cart), 2)    AS cart_to_purchase_pct,
    ROUND(SUM(did_purchase) * 100.0 / SUM(did_view), 2)    AS overall_conversion_pct
FROM user_stages;


-- ─────────────────────────────────────────
-- M2.2  Session-level funnel + outcomes
--       (the more precise version — each session is one buying attempt)
-- ─────────────────────────────────────────
WITH session_stages AS (
    SELECT
        user_id,
        user_session,
        MAX(event_type = 'view')        AS did_view,
        MAX(event_type = 'cart')        AS did_cart,
        MAX(event_type = 'purchase')    AS did_purchase,
        MIN(event_time)                 AS session_start,
        MAX(event_time)                 AS session_end,
        COUNT(DISTINCT product_id)      AS products_interacted,
        COUNT(*)                        AS total_events
    FROM events
    GROUP BY user_id, user_session
),
session_with_outcome AS (
    SELECT *,
        CASE
            WHEN did_purchase = 1 THEN 'converted'
            WHEN did_cart     = 1 THEN 'abandoned_cart'
            ELSE                       'bounce_at_view'
        END                                                     AS session_outcome,
        TIMESTAMPDIFF(MINUTE, session_start, session_end)       AS session_duration_mins
    FROM session_stages
)
SELECT
    session_outcome,
    COUNT(*)                                                AS sessions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)     AS pct_of_sessions,
    ROUND(AVG(session_duration_mins), 1)                    AS avg_duration_mins,
    ROUND(AVG(products_interacted), 1)                      AS avg_products_touched,
    ROUND(AVG(total_events), 1)                             AS avg_events_in_session
FROM session_with_outcome
GROUP BY session_outcome
ORDER BY sessions DESC;


-- ─────────────────────────────────────────
-- M2.3  Time-to-convert analysis
--       (how long do users take from view → cart → purchase)
-- ─────────────────────────────────────────
WITH session_times AS (
    SELECT
        user_session,
        MIN(CASE WHEN event_type = 'view'     THEN event_time END) AS first_view,
        MIN(CASE WHEN event_type = 'cart'     THEN event_time END) AS first_cart,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS first_purchase
    FROM events
    GROUP BY user_session
    HAVING first_view IS NOT NULL
)
SELECT
    COUNT(*) AS converted_sessions,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, first_view, first_cart)),    1) AS avg_mins_view_to_cart,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, first_cart, first_purchase)), 1) AS avg_mins_cart_to_purchase,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, first_view, first_purchase)), 1) AS avg_mins_view_to_purchase,
    -- buckets: how fast do people convert?
    SUM(TIMESTAMPDIFF(MINUTE, first_view, first_purchase) < 5)     AS under_5_mins,
    SUM(TIMESTAMPDIFF(MINUTE, first_view, first_purchase) BETWEEN 5  AND 30)  AS btw_5_30_mins,
    SUM(TIMESTAMPDIFF(MINUTE, first_view, first_purchase) BETWEEN 30 AND 120) AS btw_30_120_mins,
    SUM(TIMESTAMPDIFF(MINUTE, first_view, first_purchase) > 120)   AS over_2_hrs
FROM session_times
WHERE first_cart IS NOT NULL AND first_purchase IS NOT NULL;


-- ─────────────────────────────────────────
-- M2.4  Funnel by hour of day
--       (when do users convert best? tells you when to run promotions)
-- ─────────────────────────────────────────
SELECT
    HOUR(event_time)                                            AS hour_of_day,
    SUM(event_type = 'view')                                    AS views,
    SUM(event_type = 'cart')                                    AS carts,
    SUM(event_type = 'purchase')                                AS purchases,
    ROUND(
        SUM(event_type = 'purchase') * 100.0
        / NULLIF(SUM(event_type = 'view'), 0), 2
    )                                                           AS conversion_rate_pct
FROM events
GROUP BY HOUR(event_time)
ORDER BY hour_of_day;


-- ─────────────────────────────────────────
-- M2.5  Cart abandonment — products most often
--       added to cart but never purchased
-- ─────────────────────────────────────────
WITH cart_events AS (
    SELECT product_id, user_session
    FROM events
    WHERE event_type = 'cart'
),
purchase_events AS (
    SELECT product_id, user_session
    FROM events
    WHERE event_type = 'purchase'
)
SELECT
    c.product_id,
    COUNT(*)                                                    AS times_carted,
    SUM(p.product_id IS NOT NULL)                               AS times_purchased,
    SUM(p.product_id IS     NULL)                               AS times_abandoned,
    ROUND(
        SUM(p.product_id IS NULL) * 100.0 / COUNT(*), 1
    )                                                           AS abandonment_rate_pct
FROM cart_events c
LEFT JOIN purchase_events p
    ON c.product_id   = p.product_id
   AND c.user_session = p.user_session
GROUP BY c.product_id
HAVING times_carted >= 5
ORDER BY abandonment_rate_pct DESC
LIMIT 20;