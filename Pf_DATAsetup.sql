CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;

CREATE TABLE events (
    event_time      DATETIME,
    event_type      VARCHAR(10),
    product_id      INT,
    category_id     BIGINT,
    category_code   VARCHAR(100),
    brand           VARCHAR(50),
    price           DECIMAL(10, 2),
    user_id         INT,
    user_session    VARCHAR(50)
);
SHOW VARIABLES LIKE 'secure_file_priv';

USE ecommerce_analytics;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ecommerce_combined.csv'
INTO TABLE events
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(event_time, event_type, product_id, category_id, category_code, brand, price, user_id, user_session);


select * from events;


-- CREATING INDEX
CREATE INDEX idx_event_type  ON events (event_type);

-- session-level funnel analysis joins on this
CREATE INDEX idx_session     ON events (user_session);

-- cohort analysis groups by user
CREATE INDEX idx_user        ON events (user_id);

-- category analysis
CREATE INDEX idx_category    ON events (category_code);

-- time-based analysis
CREATE INDEX idx_time        ON events (event_time);


-- DATA VALIDATION 

USE ecommerce_analytics;

-- 1. total rows — should be 200,000
SELECT COUNT(*) AS total_rows FROM events;

-- 2. event type distribution — should show view, cart, purchase
SELECT event_type, COUNT(*) AS cnt,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM events
GROUP BY event_type;

-- 3. date range — should be within Oct 2019
SELECT MIN(event_time) AS earliest, MAX(event_time) AS latest FROM events;

-- 4. null check — all should be 0
SELECT
    SUM(event_time    IS NULL) AS null_event_time,
    SUM(event_type    IS NULL) AS null_event_type,
    SUM(product_id    IS NULL) AS null_product_id,
    SUM(price         IS NULL) AS null_price,
    SUM(user_id       IS NULL) AS null_user_id,
    SUM(user_session  IS NULL) AS null_session
FROM events;

-- 5. price sanity check — min should be > 0, max should be reasonable
SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    ROUND(AVG(price), 2) AS avg_price
FROM events
WHERE event_type = 'purchase';

-- 6. unique counts — rough sense of scale
SELECT
    COUNT(DISTINCT user_id)      AS unique_users,
    COUNT(DISTINCT product_id)   AS unique_products,
    COUNT(DISTINCT user_session) AS unique_sessions,
    COUNT(DISTINCT category_code) AS unique_categories
FROM events;

-- 7. top 5 categories by volume
SELECT category_code, COUNT(*) AS events
FROM events
WHERE category_code IS NOT NULL AND category_code != ''
GROUP BY category_code
ORDER BY events DESC
LIMIT 5;


