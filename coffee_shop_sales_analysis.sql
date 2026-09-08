-- ============================================================
-- COFFEE SHOP SALES - SQL ANALYSIS
-- ============================================================
-- Project: Coffee Shop Sales Analysis
-- Database: MySQL
-- Focus: Data preparation, KPIs, month-over-month performance,
--        daily sales, store performance, product performance,
--        weekday/weekend patterns, and hourly sales trends
-- ============================================================


-- ============================================================
-- 1. DATA PREPARATION
-- ============================================================

-- Convert transaction_date from text to DATE
UPDATE cssales
SET transaction_date = REPLACE(transaction_date, '/', '-');

UPDATE cssales
SET transaction_date = STR_TO_DATE(transaction_date, '%d-%m-%Y');

ALTER TABLE cssales
MODIFY COLUMN transaction_date DATE;

-- Convert transaction_time from text to TIME
UPDATE cssales
SET transaction_time = STR_TO_DATE(transaction_time, '%H:%i:%s');

ALTER TABLE cssales
MODIFY COLUMN transaction_time TIME;


-- ============================================================
-- 2. MAY KPI ANALYSIS
-- ============================================================

-- Total sales for May
SELECT
    ROUND(SUM(transaction_qty * unit_price)) AS total_sales
FROM cssales
WHERE MONTH(transaction_date) = 5;

-- Total orders for May
SELECT
    COUNT(transaction_id) AS total_orders
FROM cssales
WHERE MONTH(transaction_date) = 5;

-- Total quantity sold for May
SELECT
    SUM(transaction_qty) AS total_quantity_sold
FROM cssales
WHERE MONTH(transaction_date) = 5;


-- ============================================================
-- 3. MONTH-OVER-MONTH PERFORMANCE
-- ============================================================

-- Sales growth from April to May
SELECT
    MONTH(transaction_date) AS month,
    ROUND(SUM(transaction_qty * unit_price)) AS total_sales,
    (
        SUM(transaction_qty * unit_price)
        - LAG(SUM(transaction_qty * unit_price), 1)
          OVER (ORDER BY MONTH(transaction_date))
    )
    / LAG(SUM(transaction_qty * unit_price), 1)
      OVER (ORDER BY MONTH(transaction_date)) * 100
    AS mom_sales_growth_pct
FROM cssales
WHERE MONTH(transaction_date) IN (4, 5)
GROUP BY MONTH(transaction_date)
ORDER BY month;

-- Order growth from April to May
SELECT
    MONTH(transaction_date) AS month,
    COUNT(transaction_id) AS total_orders,
    (
        COUNT(transaction_id)
        - LAG(COUNT(transaction_id), 1)
          OVER (ORDER BY MONTH(transaction_date))
    )
    / LAG(COUNT(transaction_id), 1)
      OVER (ORDER BY MONTH(transaction_date)) * 100
    AS mom_order_growth_pct
FROM cssales
WHERE MONTH(transaction_date) IN (4, 5)
GROUP BY MONTH(transaction_date)
ORDER BY month;

-- Quantity growth from April to May
SELECT
    MONTH(transaction_date) AS month,
    SUM(transaction_qty) AS total_quantity_sold,
    (
        SUM(transaction_qty)
        - LAG(SUM(transaction_qty), 1)
          OVER (ORDER BY MONTH(transaction_date))
    )
    / LAG(SUM(transaction_qty), 1)
      OVER (ORDER BY MONTH(transaction_date)) * 100
    AS mom_quantity_growth_pct
FROM cssales
WHERE MONTH(transaction_date) IN (4, 5)
GROUP BY MONTH(transaction_date)
ORDER BY month;


-- ============================================================
-- 4. SELECTED-DATE KPI ANALYSIS
-- ============================================================

-- Sales, orders, and quantity for a selected date
SELECT
    CONCAT(ROUND(SUM(transaction_qty * unit_price) / 1000, 1), 'k') AS total_sales,
    CONCAT(ROUND(COUNT(transaction_id) / 1000, 1), 'k') AS total_orders,
    CONCAT(ROUND(SUM(transaction_qty) / 1000, 1), 'k') AS total_quantity
FROM cssales
WHERE transaction_date = '2023-05-18';


-- ============================================================
-- 5. DAILY SALES ANALYSIS
-- ============================================================

-- Average daily sales for May
SELECT
    ROUND(AVG(total_sales), 2) AS avg_daily_sales
FROM (
    SELECT
        transaction_date,
        SUM(transaction_qty * unit_price) AS total_sales
    FROM cssales
    WHERE MONTH(transaction_date) = 5
    GROUP BY transaction_date
) AS daily_sales;

-- Daily sales for May
SELECT
    DAY(transaction_date) AS day_of_month,
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales
FROM cssales
WHERE MONTH(transaction_date) = 5
GROUP BY DAY(transaction_date)
ORDER BY day_of_month;

-- Compare each day's sales with the May daily average
SELECT
    day_of_month,
    CASE
        WHEN total_sales > avg_total_sales THEN 'Above'
        WHEN total_sales < avg_total_sales THEN 'Below'
        ELSE 'Equal'
    END AS sales_vs_average,
    total_sales,
    avg_total_sales
FROM (
    SELECT
        DAY(transaction_date) AS day_of_month,
        ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales,
        ROUND(AVG(SUM(transaction_qty * unit_price)) OVER (), 2) AS avg_total_sales
    FROM cssales
    WHERE MONTH(transaction_date) = 5
    GROUP BY DAY(transaction_date)
) AS daily_sales_comparison
ORDER BY day_of_month;


-- ============================================================
-- 6. WEEKDAY VS WEEKEND SALES
-- ============================================================

-- Compare May sales by week type
-- This preserves the original project logic.
SELECT
    CASE
        WHEN DAYOFWEEK(transaction_date) IN (6, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS week_type,
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales
FROM cssales
WHERE MONTH(transaction_date) = 5
GROUP BY week_type;


-- ============================================================
-- 7. STORE LOCATION PERFORMANCE
-- ============================================================

-- May sales by store location
SELECT
    store_location,
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales
FROM cssales
WHERE MONTH(transaction_date) = 5
GROUP BY store_location
ORDER BY total_sales DESC;


-- ============================================================
-- 8. PRODUCT PERFORMANCE
-- ============================================================

-- May sales by product category
SELECT
    product_category,
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales
FROM cssales
WHERE MONTH(transaction_date) = 5
GROUP BY product_category
ORDER BY total_sales DESC;

-- Top 10 product types by May sales
SELECT
    product_type,
    ROUND(SUM(transaction_qty * unit_price), 2) AS total_sales
FROM cssales
WHERE MONTH(transaction_date) = 5
GROUP BY product_type
ORDER BY total_sales DESC
LIMIT 10;


-- ============================================================
-- 9. DAY AND HOUR PERFORMANCE
-- ============================================================

-- KPIs for a selected weekday and hour in May
SELECT
    ROUND(SUM(transaction_qty * unit_price)) AS total_sales,
    COUNT(transaction_id) AS total_orders,
    SUM(transaction_qty) AS total_quantity
FROM cssales
WHERE DAYOFWEEK(transaction_date) = 3
  AND HOUR(transaction_time) = 8
  AND MONTH(transaction_date) = 5;

-- May sales by day of week
SELECT
    CASE
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        ELSE 'Sunday'
    END AS day_of_week,
    ROUND(SUM(transaction_qty * unit_price)) AS total_sales
FROM cssales
WHERE MONTH(transaction_date) = 5
GROUP BY day_of_week;

-- May sales by hour of day
SELECT
    HOUR(transaction_time) AS hour_of_day,
    ROUND(SUM(transaction_qty * unit_price)) AS total_sales
FROM cssales
WHERE MONTH(transaction_date) = 5
GROUP BY HOUR(transaction_time)
ORDER BY hour_of_day;
