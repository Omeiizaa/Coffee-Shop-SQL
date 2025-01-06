CREATE TABLE transactions (
    transaction_id int, 
	transaction_date text,  
	transaction_time text, 
	transaction_qty int, 
	store_id int, 
	store_location text, 
	product_id int, 
	unit_price double, 
	product_category text, 
	product_type text, 
	product_detail text
);

LOAD DATA INFILE 'C:/Program Files/Documents/Coffee Shop Sales.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(transaction_id, 
transaction_date, 
transaction_time, 
transaction_qty, 
store_id, store_location, 
product_id, 
unit_price, 
product_category, 
product_type, 
product_detail);

SELECT *
FROM transactions;

DESCRIBE transactions;

-- disable safe mode
SET SQL_SAFE_UPDATES = 0;

-- DATA CLEANING

-- to change the date and time from "text" to "date" format
UPDATE transactions
SET transaction_date = STR_TO_DATE(transaction_date, '%m/%d/%Y');

ALTER TABLE transactions
MODIFY COLUMN transaction_date DATE;

UPDATE transactions
SET transaction_time = STR_TO_DATE(transaction_time, '%H:%i:%s');

ALTER TABLE transactions
MODIFY COLUMN transaction_time TIME;

DESCRIBE transactions;

-- Null values
SELECT COUNT(*) AS Missing_values
FROM transactions 
WHERE transaction_id IS NULL
OR transaction_qty IS NULL
OR store_location IS NULL
OR unit_price IS NULL
OR product_category IS NULL
OR product_type IS NULL;

-- Remove irrelevant column
ALTER TABLE transactions
DROP COLUMN product_detail;
-- View changes
SELECT *
FROM transactions;

-- DATA ANALYSIS

-- to check KPIs (Sales, Quantity Sold, and Orders)
SELECT
	CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000,1), 'K') AS total_sales,
    CONCAT(ROUND(SUM(transaction_qty)/1000,1), 'K')  AS total_qty_sold,
    CONCAT(ROUND(COUNT(transaction_id)/1000,1), 'K')  AS total_orders
FROM transactions;

-- Calculate the total sales per month
SELECT ROUND(SUM(unit_price * transaction_qty)) AS total_sales
FROM transactions;

-- Calculate the total sales for specific month (March)
SELECT 
	MONTH(transaction_date) AS month,
    ROUND(SUM(unit_price * transaction_qty)) AS total_sales
FROM transactions
WHERE 
	MONTH(transaction_date) IN (1,2,3,4,5,6) -- for momths of March, April and May
GROUP BY
	MONTH(transaction_date)
ORDER BY
	MONTH(transaction_date);

-- determine the increase/decresae in percentage between different months for sales
SELECT 
	MONTH(transaction_date) AS month,
    ROUND(SUM(unit_price * transaction_qty)) AS total_sales,
    (SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1)
    OVER(ORDER BY MONTH(transaction_date)))/LAG(SUM(unit_price * transaction_qty), 1)
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM
	transactions
WHERE
	MONTH(transaction_date) IN (1,2,3,4,5,6)
GROUP BY
	MONTH(transaction_date)
ORDER BY
	MONTH(transaction_date);

-- Calculate the total orders for each month (February was used for this example)
SELECT 
	MONTH(transaction_date) AS month,
	COUNT(transaction_id) AS total_orders
FROM transactions
WHERE
	MONTH(transaction_date) IN (1,2,3,4,5,6)
GROUP BY
	MONTH(transaction_date)
ORDER BY
	MONTH(transaction_date);

-- determine the increase/decresae in percentage between different months for orders
SELECT 
	MONTH(transaction_date) AS month,
    ROUND(COUNT(transaction_id)) AS total_orders,
    (COUNT(transaction_id) - LAG(COUNT(transaction_id), 1)
    OVER(ORDER BY MONTH(transaction_date)))/LAG(COUNT(transaction_id), 1)
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM
	transactions
WHERE
	MONTH(transaction_date) IN (1,2,3,4,5,6) -- for momths of March, April and May
GROUP BY
	MONTH(transaction_date)
ORDER BY
	MONTH(transaction_date);
    
-- calculate the total quantity sold for each month(January was used for this example)
SELECT SUM(transaction_qty) AS total_quantity_sold
FROM transactions
WHERE MONTH(transaction_date) = 1;

-- determine the increase/decresae in percentage between different months for quantity of item sold
SELECT 
	MONTH(transaction_date) AS month,
    ROUND(SUM(transaction_qty)) AS total_quantity_sold,
    (SUM(transaction_qty) - LAG(SUM(transaction_qty), 1)
    OVER(ORDER BY MONTH(transaction_date)))/LAG(SUM(transaction_qty), 1)
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM
	transactions
WHERE
	MONTH(transaction_date) IN (1,2,3,4,5,6) -- for momths of March, April and May
GROUP BY
	MONTH(transaction_date)
ORDER BY
	MONTH(transaction_date);
    
-- calculate saless by weekdays and weekends
 SELECT
	CASE WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN 'weekends'
    ELSE 'weekdays'
    END AS day_type,
    CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000,1), 'K') AS total_sales
FROM transactions
GROUP BY
	CASE WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN 'weekends'
    ELSE 'weekdays'
    END;    
			
-- monthly sales performance by store location 
SELECT
	store_location,
    CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000,2), 'K') AS total_sales
FROM transactions
GROUP BY store_location
ORDER BY SUM(unit_price * transaction_qty) DESC;


-- average sales month (February was used here) 
SELECT
	CONCAT(ROUND(AVG(total_sales)/1000,1),'K') AS avg_sales
FROM
	(
    SELECT SUM(transaction_qty * unit_price) AS total_sales
    FROM transactions
    WHERE MONTH (transaction_date) = 2
    GROUP BY transaction_date
    ) AS internal_query;

-- average sales by day (February was used here)
SELECT
	day_of_month,
    CASE
		WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
	END AS sales_status,
    total_sales
FROM (
	SELECT
		DAY(transaction_date) AS day_of_month,
		SUM(unit_price * transaction_qty) AS total_sales,
		AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
	FROM
		transactions
	WHERE
		MONTH(transaction_date) = 2
	GROUP BY
		DAY(transaction_date)
) AS sales_date
ORDER BY
	day_of_month;

-- sales by product categories (February was used here)
SELECT
	product_category,
    SUM(unit_price * transaction_qty) AS total_sales
FROM transactions
GROUP BY product_category
ORDER BY SUM(unit_price * transaction_qty) DESC;

-- sales by top 7 product type 
SELECT
	product_type, product_category,
    ROUND(SUM(unit_price * transaction_qty)) AS total_sales
FROM transactions
GROUP BY product_type, product_category
ORDER BY SUM(unit_price * transaction_qty) DESC
LIMIT 70;

-- sales by top 3 selling products by product categories (Coffee sales for the month of February was used here)
SELECT
	product_type,
    ROUND(SUM(unit_price * transaction_qty)) AS total_sales
FROM transactions
WHERE MONTH(transaction_date) = 2 AND product_category = 'Coffee'
GROUP BY product_type
ORDER BY SUM(unit_price * transaction_qty) DESC
LIMIT 3;

-- sales by specific days and hours
SELECT
	ROUND(SUM(unit_price * transaction_qty)) AS total_sales,
    SUM(transaction_qty) AS total_qty_sold,
    COUNT(*) AS total_orders
    FROM transactions
    WHERE MONTH(transaction_date) = 1 -- January
    AND DAYOFWEEK(transaction_date) = 1 -- Sunday
    AND HOUR(transaction_time) = 8; -- Time of the day
    
-- Orders by specific hours
    SELECT
	HOUR(transaction_time),
    ROUND(COUNT(transaction_id)) AS Orders
    FROM transactions
    GROUP BY HOUR(transaction_time)
    ORDER BY HOUR(transaction_time);
    
-- sales by days of the week   
SELECT 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END AS day_of_week,
    ROUND(COUNT(transaction_id), 1) AS Orders
FROM 
    transactions
GROUP BY 
    day_of_week
ORDER BY 
    FIELD(day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

