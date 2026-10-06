Create database walmart;




-- =====================================================================
-- 2. DATA CLEANING & VALIDATION
-- =====================================================================

-- 1. Check Total Records
SELECT COUNT(*) AS total_records FROM walmart.sales;

-- 2. Check Duplicate Invoice IDs
SELECT invoice_id, COUNT(*) AS total
FROM walmart.sales
GROUP BY invoice_id
HAVING COUNT(*) > 1;

-- 3. Check NULL Values
SELECT
    SUM(invoice_id IS NULL) AS invoice_id,
    SUM(branch IS NULL) AS branch,
    SUM(city IS NULL) AS city,
    SUM(customer_type IS NULL) AS customer_type,
    SUM(gender IS NULL) AS gender,
    SUM(product_line IS NULL) AS product_line,
    SUM(unit_price IS NULL) AS unit_price,
    SUM(quantity IS NULL) AS quantity,
    SUM(vat IS NULL) AS vat,
    SUM(total IS NULL) AS total,
    SUM(date IS NULL) AS sale_date,
    SUM(time IS NULL) AS sale_time,
    SUM(payment IS NULL) AS payment,
    SUM(cogs IS NULL) AS cogs,
    SUM(gross_margin_pct IS NULL) AS gross_margin_pct,
    SUM(gross_income IS NULL) AS gross_income,
    SUM(rating IS NULL) AS rating
FROM walmart.sales;

-- 4. Check Blank Values
SELECT *
FROM walmart.sales
WHERE TRIM(city) = ''
   OR TRIM(branch) = ''
   OR TRIM(customer_type) = ''
   OR TRIM(product_line) = ''
   OR TRIM(payment) = '';

-- 5. Remove Extra Spaces
UPDATE walmart.sales
SET
    city = TRIM(city),
    branch = TRIM(branch),
    customer_type = TRIM(customer_type),
    gender = TRIM(gender),
    product_line = TRIM(product_line),
    payment = TRIM(payment);

-- 6. Verify Data Types
DESCRIBE walmart.sales;

-- 7. Validate Quantity
UPDATE walmart.sales SET quantity = 14 WHERE invoice_id = '102-06-2002';

SELECT * FROM walmart.sales WHERE quantity <= 0;

-- 8. Validate Unit Price
SELECT * FROM walmart.sales WHERE unit_price <= 0;


-- =====================================================================
-- 3. FEATURE ENGINEERING
-- =====================================================================

-- 1. Add and populate time_of_day
ALTER TABLE walmart.sales ADD COLUMN time_of_day VARCHAR(20) AFTER time;

UPDATE walmart.sales
SET time_of_day = (
    CASE 
        WHEN `time` BETWEEN '00:00:00' AND '12:00:00' THEN 'Morning'
        WHEN `time` BETWEEN '12:01:00' AND '16:00:00' THEN 'Afternoon'
        ELSE 'Evening' 
    END
);

-- 2. Add state column (if applicable to dataset layout)
ALTER TABLE walmart.sales ADD COLUMN state VARCHAR(200) AFTER city;

-- 3. Add and populate day_name
ALTER TABLE walmart.sales ADD COLUMN day_name VARCHAR(10) AFTER date;

UPDATE walmart.sales
SET day_name = DAYNAME(date);

-- 4. Add and populate month_name
ALTER TABLE walmart.sales ADD COLUMN month_name VARCHAR(10) AFTER day_name;

UPDATE walmart.sales
SET month_name = MONTHNAME(date);


-- =====================================================================
-- 4. EXPLORATORY DATA ANALYSIS (EDA)
-- =====================================================================

-- ---------------------------------------------------------------------
--  Questions
-- ---------------------------------------------------------------------
-- 1. How many distinct cities are present in the dataset?
SELECT COUNT(DISTINCT city) AS distinct_cities FROM walmart.sales;

-- 2. In which city is each branch situated?
SELECT DISTINCT branch, city FROM walmart.sales;


-- ---------------------------------------------------------------------
-- Product Analysis
-- ---------------------------------------------------------------------
-- 1. How many distinct product lines are there in the dataset?
SELECT COUNT(DISTINCT product_line) FROM walmart.sales;

-- 2. What is the most common payment method?
SELECT payment, COUNT(payment) AS common_payment_method 
FROM walmart.sales 
GROUP BY payment 
ORDER BY common_payment_method DESC 
LIMIT 1;

-- 3. What is the most selling product line?
SELECT product_line, COUNT(product_line) AS most_selling_product
FROM walmart.sales 
GROUP BY product_line 
ORDER BY most_selling_product DESC 
LIMIT 1;

-- 4. What is the total revenue by month?
SELECT month_name, SUM(total) AS total_revenue
FROM walmart.sales 
GROUP BY month_name 
ORDER BY total_revenue DESC;

-- 5. Which month recorded the highest Cost of Goods Sold (COGS)?
SELECT month_name, SUM(cogs) AS total_cogs
FROM walmart.sales 
GROUP BY month_name 
ORDER BY total_cogs DESC;

-- 6. Which product line generated the highest revenue?
SELECT product_line, SUM(total) AS total_revenue
FROM walmart.sales 
GROUP BY product_line 
ORDER BY total_revenue DESC 
LIMIT 1;

-- 7. Which city has the highest revenue?
SELECT city, SUM(total) AS total_revenue
FROM walmart.sales 
GROUP BY city 
ORDER BY total_revenue DESC 
LIMIT 1;

-- 8. Which product line incurred the highest GST (VAT)?
SELECT product_line, SUM(vat) AS total_vat 
FROM walmart.sales 
GROUP BY product_line 
ORDER BY total_vat DESC 
LIMIT 1;

-- 9. Retrieve each product line and add a column product_category indicating 'Good' or 'Bad' based on average sales.
ALTER TABLE walmart.sales ADD COLUMN product_category VARCHAR(20);

SET @avg_total = (SELECT AVG(total) FROM walmart.sales);

UPDATE walmart.sales
SET product_category = CASE
    WHEN total >= @avg_total THEN 'Good'
    ELSE 'Bad'
END;

-- 10. Which branch sold more products than the average products sold?
SELECT branch, SUM(quantity) AS quantity
FROM walmart.sales
GROUP BY branch 
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM walmart.sales) 
ORDER BY quantity DESC 
LIMIT 1;

-- 11. What is the most common product line by gender?
SELECT gender, product_line, COUNT(gender) AS total_count
FROM walmart.sales 
GROUP BY gender, product_line 
ORDER BY total_count DESC;

-- 12. What is the average rating of each product line?
SELECT product_line, ROUND(AVG(rating), 2) AS average_rating
FROM walmart.sales 
GROUP BY product_line 
ORDER BY average_rating DESC;


-- ---------------------------------------------------------------------
-- Advanced SQL Analysis & Window Functions
-- ---------------------------------------------------------------------

-- 1. Which products contribute to 80% of total revenue? (Pareto Analysis)
WITH sales_cte AS (
    SELECT
        product_line,
        SUM(total) AS revenue
    FROM walmart.sales
    GROUP BY product_line
),
pareto AS (
    SELECT *,
        SUM(revenue) OVER(ORDER BY revenue DESC) AS running_sales,
        SUM(revenue) OVER() AS total_sales
    FROM sales_cte
)
SELECT *,
    ROUND((running_sales / total_sales) * 100, 2) AS cumulative_percentage
FROM pareto
WHERE (running_sales / total_sales) <= 0.80;

-- 2. Rank Products by Revenue within each City/State
SELECT
    city,
    product_line,
    SUM(total) AS revenue,
    RANK() OVER(
        PARTITION BY city
        ORDER BY SUM(total) DESC
    ) AS product_rank
FROM walmart.sales
GROUP BY city, product_line;

-- 3. Month-over-Month Sales Growth
WITH monthly_sales AS (
    SELECT
        MONTH(date) AS month_no,
        MONTHNAME(date) AS month_name,
        SUM(total) AS sales
    FROM walmart.sales
    GROUP BY MONTH(date), MONTHNAME(date)
)
SELECT *,
    LAG(sales) OVER(ORDER BY month_no) AS previous_month,
    ROUND(((sales - LAG(sales) OVER(ORDER BY month_no)) / LAG(sales) OVER(ORDER BY month_no)) * 100, 2) AS growth_percentage
FROM monthly_sales;

-- 4. Top 3 Products in Every Branch
WITH product_sales AS (
    SELECT
        branch,
        product_line,
        SUM(total) AS sales,
        DENSE_RANK() OVER (
            PARTITION BY branch
            ORDER BY SUM(total) DESC
        ) AS rnk
    FROM walmart.sales
    GROUP BY branch, product_line
)
SELECT *
FROM product_sales
WHERE rnk <= 3;

-- 5. Which Payment Method Generates Highest Revenue?
SELECT
    payment,
    COUNT(*) AS total_orders,
    SUM(total) AS revenue,
    AVG(total) AS average_bill
FROM walmart.sales
GROUP BY payment
ORDER BY revenue DESC;

-- 6. Sales Contribution by City
SELECT
    city,
    SUM(total) AS sales,
    ROUND(SUM(total) * 100 / (SELECT SUM(total) FROM walmart.sales), 2) AS contribution_percentage
FROM walmart.sales
GROUP BY city
ORDER BY sales DESC;

-- 7. Which Day Generates Maximum Revenue?
SELECT
    day_name,
    SUM(total) AS revenue,
    RANK() OVER(ORDER BY SUM(total) DESC) AS rnk
FROM walmart.sales
GROUP BY day_name;

-- 8. Best Selling Product by Quantity
SELECT 
    product_line,
    SUM(quantity) AS qty,
    DENSE_RANK() OVER(ORDER BY SUM(quantity) DESC) AS rnk
FROM walmart.sales
GROUP BY product_line;


-- ---------------------------------------------------------------------
-- Sales Analysis (Time & Transactions)
-- ---------------------------------------------------------------------

-- 1. Number of sales made in each time of the day per weekday
SELECT 
    day_name,
    time_of_day,
    COUNT(invoice_id) AS total_sales
FROM walmart.sales
WHERE day_name NOT IN ('Saturday', 'Sunday')
GROUP BY day_name, time_of_day
ORDER BY total_sales DESC;

-- 2. Identify the customer type that generates the highest revenue.
SELECT customer_type, SUM(total) AS total_sales
FROM walmart.sales 
GROUP BY customer_type 
ORDER BY total_sales DESC 
LIMIT 1;

-- 3. Which city has the largest tax percent / VAT?
SELECT city, SUM(vat) AS total_vat
FROM walmart.sales 
GROUP BY city 
ORDER BY total_vat DESC 
LIMIT 1;

-- 4. Which customer type pays the most in VAT?
SELECT customer_type, SUM(vat) AS total_vat
FROM walmart.sales 
GROUP BY customer_type 
ORDER BY total_vat DESC 
LIMIT 1;


-- ---------------------------------------------------------------------
-- Customer Analysis
-- ---------------------------------------------------------------------

-- 1. How many unique customer types does the data have?
SELECT COUNT(DISTINCT customer_type) FROM walmart.sales;

-- 2. How many unique payment methods does the data have?
SELECT COUNT(DISTINCT payment) FROM walmart.sales;

-- 3. Which is the most common customer type?
SELECT customer_type, COUNT(customer_type) AS common_customer
FROM walmart.sales 
GROUP BY customer_type 
ORDER BY common_customer DESC 
LIMIT 1;

-- 4. Which customer type buys the most (by total sales)?
SELECT customer_type, SUM(total) AS total_sales
FROM walmart.sales 
GROUP BY customer_type 
ORDER BY total_sales DESC 
LIMIT 1;

-- 5. What is the gender of most of the customers?
SELECT gender, COUNT(*) AS all_genders 
FROM walmart.sales 
GROUP BY gender 
ORDER BY all_genders DESC 
LIMIT 1;

-- 6. What is the gender distribution per branch?
SELECT branch, gender, COUNT(gender) AS gender_distribution
FROM walmart.sales 
GROUP BY branch, gender 
ORDER BY branch;

-- 7. Which time of the day do customers give most ratings?
SELECT time_of_day, AVG(rating) AS average_rating
FROM walmart.sales 
GROUP BY time_of_day 
ORDER BY average_rating DESC 
LIMIT 1;

-- 8. Which time of the day do customers give most ratings per branch?
SELECT branch, time_of_day, AVG(rating) AS average_rating
FROM walmart.sales 
GROUP BY branch, time_of_day 
ORDER BY average_rating DESC;

-- 9. Which day of the week has the best average ratings?
SELECT day_name, AVG(rating) AS average_rating
FROM walmart.sales 
GROUP BY day_name 
ORDER BY average_rating DESC 
LIMIT 1;

-- 10. Which day of the week has the best average ratings per branch?
SELECT branch, day_name, AVG(rating) AS average_rating
FROM walmart.sales 
GROUP BY branch, day_name 
ORDER BY average_rating DESC;

select * from walmart.sales;

