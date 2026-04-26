-- ─────────────────────────────────────────
-- M5.1  Define cohorts by first purchase month
-- ─────────────────────────────────────────
WITH first_purchase AS (
    SELECT
        user_id,
        DATE_FORMAT(MIN(event_time), '%Y-%m-01') AS cohort_month
    FROM events
    WHERE event_type = 'purchase'
    GROUP BY user_id
),


-- ─────────────────────────────────────────
-- M5.2  Tag every subsequent purchase with
--       months since first purchase
-- ─────────────────────────────────────────
user_activity AS (
    SELECT
        e.user_id,
        fp.cohort_month,
        DATE_FORMAT(e.event_time, '%Y-%m-01')       AS activity_month,
        TIMESTAMPDIFF(
            MONTH,
            fp.cohort_month,
            DATE_FORMAT(e.event_time, '%Y-%m-01')
        )                                           AS months_since_first
    FROM events e
    JOIN first_purchase fp ON e.user_id = fp.user_id
    WHERE e.event_type = 'purchase'
),


-- ─────────────────────────────────────────
-- M5.3  Cohort size (month 0 users)
-- ─────────────────────────────────────────
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_users
    FROM first_purchase
    GROUP BY cohort_month
)


-- ─────────────────────────────────────────
-- M5.4  Final retention heatmap output
-- ─────────────────────────────────────────
SELECT
    ua.cohort_month,
    cs.cohort_users,
    ua.months_since_first,
    COUNT(DISTINCT ua.user_id)                      AS retained_users,
    ROUND(
        COUNT(DISTINCT ua.user_id) * 100.0
        / cs.cohort_users, 1
    )                                               AS retention_pct
FROM user_activity ua
JOIN cohort_size cs ON ua.cohort_month = cs.cohort_month
GROUP BY ua.cohort_month, cs.cohort_users, ua.months_since_first
ORDER BY ua.cohort_month, ua.months_since_first;


-- ─────────────────────────────────────────
-- M5.5  Average retention curve across all cohorts
--       (one clean number per month offset)
-- ─────────────────────────────────────────
WITH first_purchase AS (
    SELECT user_id,
           DATE_FORMAT(MIN(event_time), '%Y-%m-01') AS cohort_month
    FROM events
    WHERE event_type = 'purchase'
    GROUP BY user_id
),
user_activity AS (
    SELECT
        e.user_id,
        fp.cohort_month,
        TIMESTAMPDIFF(
            MONTH,
            fp.cohort_month,
            DATE_FORMAT(e.event_time, '%Y-%m-01')
        ) AS months_since_first
    FROM events e
    JOIN first_purchase fp ON e.user_id = fp.user_id
    WHERE e.event_type = 'purchase'
),
cohort_size AS (
    SELECT cohort_month, COUNT(DISTINCT user_id) AS cohort_users
    FROM first_purchase
    GROUP BY cohort_month
),
retention_data AS (
    SELECT
        ua.cohort_month,
        cs.cohort_users,
        ua.months_since_first,
        COUNT(DISTINCT ua.user_id) AS retained_users
    FROM user_activity ua
    JOIN cohort_size cs ON ua.cohort_month = cs.cohort_month
    GROUP BY ua.cohort_month, cs.cohort_users, ua.months_since_first
)
SELECT
    months_since_first,
    SUM(retained_users)                             AS total_retained,
    SUM(cohort_users)                               AS total_cohort_size,
    ROUND(
        SUM(retained_users) * 100.0 / SUM(cohort_users), 1
    )                                               AS avg_retention_pct
FROM retention_data
GROUP BY months_since_first
ORDER BY months_since_first;


-- ─────────────────────────────────────────
-- M5.6  Days between repeat purchases
--       (purchase frequency / purchase cycle)
-- ─────────────────────────────────────────
WITH purchase_history AS (
    SELECT
        user_id,
        event_time,
        LAG(event_time) OVER (
            PARTITION BY user_id ORDER BY event_time
        ) AS prev_purchase_time
    FROM events
    WHERE event_type = 'purchase'
)
SELECT
    DATEDIFF(event_time, prev_purchase_time)        AS days_between_purchases,
    COUNT(*)                                        AS occurrences
FROM purchase_history
WHERE prev_purchase_time IS NOT NULL
GROUP BY days_between_purchases
ORDER BY days_between_purchases
LIMIT 30;


