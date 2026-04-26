-- ─────────────────────────────────────────
-- M6.1  Calculate raw RFM values per user
-- ─────────────────────────────────────────
WITH rfm_raw AS (
    SELECT
        user_id,
        MAX(event_time)                             AS last_purchase_date,
        COUNT(*)                                    AS frequency,
        ROUND(SUM(price), 2)                        AS monetary,
        DATEDIFF(
            (SELECT MAX(event_time) FROM events),
            MAX(event_time)
        )                                           AS recency_days
    FROM events
    WHERE event_type = 'purchase'
    GROUP BY user_id
),


-- ─────────────────────────────────────────
-- M6.2  Score each dimension 1–5
--       Recency: lower days = higher score
--       Frequency & Monetary: higher = higher score
-- ─────────────────────────────────────────
rfm_scores AS (
    SELECT
        user_id,
        recency_days,
        frequency,
        monetary,
        -- recency: recent buyers get score 5
        NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,
        -- NOTE: recency ASC because fewer days = better
        -- but NTILE assigns 1 to first group (lowest days = score 1)
        -- so we flip it:
        6 - NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score_fixed,
        NTILE(5) OVER (ORDER BY frequency ASC)          AS f_score,
        NTILE(5) OVER (ORDER BY monetary  ASC)          AS m_score
    FROM rfm_raw
),


-- ─────────────────────────────────────────
-- M6.3  Assign segment labels
-- ─────────────────────────────────────────
rfm_segments AS (
    SELECT
        user_id,
        recency_days,
        frequency,
        monetary,
        r_score_fixed AS r,
        f_score       AS f,
        m_score       AS m,
        CONCAT(r_score_fixed, f_score, m_score)     AS rfm_cell,
        CASE
            WHEN r_score_fixed >= 4 AND f_score >= 4
                THEN 'Champions'
            WHEN r_score_fixed >= 3 AND f_score >= 3
                THEN 'Loyal customers'
            WHEN r_score_fixed >= 4 AND f_score <= 2
                THEN 'New customers'
            WHEN r_score_fixed >= 3 AND f_score <= 2
                THEN 'Potential loyalists'
            WHEN r_score_fixed <= 2 AND f_score >= 3
                THEN 'At-risk'
            WHEN r_score_fixed <= 2 AND f_score >= 4
                THEN 'Cannot lose them'
            WHEN r_score_fixed <= 2 AND f_score <= 2
                THEN 'Lost'
            ELSE 'Needs attention'
        END                                         AS segment
    FROM rfm_scores
)


-- ─────────────────────────────────────────
-- M6.4  Segment summary
-- ─────────────────────────────────────────
SELECT
    segment,
    COUNT(*)                                        AS user_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_users,
    ROUND(AVG(recency_days), 0)                     AS avg_recency_days,
    ROUND(AVG(frequency), 1)                        AS avg_purchases,
    ROUND(AVG(monetary), 2)                         AS avg_revenue_per_user,
    ROUND(SUM(monetary), 2)                         AS total_segment_revenue
FROM rfm_segments
GROUP BY segment
ORDER BY avg_revenue_per_user DESC;


-- ─────────────────────────────────────────
-- M6.5  Champions vs Lost — behaviour comparison
--       (the most compelling contrast for your write-up)
-- ─────────────────────────────────────────
WITH rfm_raw AS (
    SELECT
        user_id,
        MAX(event_time)                             AS last_purchase_date,
        COUNT(*)                                    AS frequency,
        ROUND(SUM(price), 2)                        AS monetary,
        DATEDIFF(
            (SELECT MAX(event_time) FROM events),
            MAX(event_time)
        )                                           AS recency_days
    FROM events
    WHERE event_type = 'purchase'
    GROUP BY user_id
),
rfm_scores AS (
    SELECT *,
        6 - NTILE(5) OVER (ORDER BY recency_days ASC)  AS r,
        NTILE(5) OVER (ORDER BY frequency ASC)         AS f,
        NTILE(5) OVER (ORDER BY monetary  ASC)         AS m
    FROM rfm_raw
),
rfm_segments AS (
    SELECT *,
        CASE
            WHEN r >= 4 AND f >= 4  THEN 'Champions'
            WHEN r <= 2 AND f <= 2  THEN 'Lost'
            ELSE NULL
        END AS segment
    FROM rfm_scores
)
SELECT
    s.segment,
    COUNT(DISTINCT s.user_id)                       AS users,
    ROUND(AVG(s.monetary), 2)                       AS avg_revenue,
    ROUND(AVG(s.frequency), 1)                      AS avg_orders,
    ROUND(AVG(s.recency_days), 0)                   AS avg_days_since_purchase,
    ROUND(AVG(e.view_count), 0)                     AS avg_views,
    ROUND(AVG(e.session_count), 1)                  AS avg_sessions
FROM rfm_segments s
JOIN (
    SELECT
        user_id,
        SUM(event_type = 'view')                    AS view_count,
        COUNT(DISTINCT user_session)                AS session_count
    FROM events
    GROUP BY user_id
) e ON s.user_id = e.user_id
WHERE s.segment IS NOT NULL
GROUP BY s.segment;