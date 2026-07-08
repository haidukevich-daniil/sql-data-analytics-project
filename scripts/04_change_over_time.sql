/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.
*/

-- Analyse sales performance over time
SELECT 
    DATETRUNC(MONTH, order_date) AS order_date,
    COUNT(DISTINCT customer_key) AS total_customers,
    COUNT(*) AS total_orders,
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE MONTH(order_date) IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY DATETRUNC(MONTH, order_date);

-- FORMAT()
SELECT 
    FORMAT(order_date, 'yyyy-MMM') AS order_date,
    COUNT(DISTINCT customer_key) AS total_customers,
    COUNT(*) AS total_orders,
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE MONTH(order_date) IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM');

/*
===============================================================================
Cumulative Analysis
===============================================================================
Purpose:
    - To calculate running totals or moving averages for key metrics.
    - To track performance over time cumulatively.
    - Useful for growth analysis or identifying long-term trends.
*/

-- Calculate the total sales per month 
-- and the running total of sales over time 
SELECT 
    *,
    SUM(total_sales) OVER(PARTITION BY DATEPART(QUARTER, order_month) ORDER BY order_month) AS running_total_sales_per_quater,
    SUM(total_sales) OVER(ORDER BY order_month) AS running_total_sales
FROM(
SELECT 
    DATETRUNC(MONTH, order_date) AS order_month,
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales
WHERE MONTH(order_date) IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
)t

/*
===============================================================================
Performance Analysis (Year-over-Year, Month-over-Month)
===============================================================================
Purpose:
    - To measure the performance of products, customers, or regions over time.
    - For benchmarking and identifying high-performing entities.
    - To track yearly trends and growth.
*/

--Analyze the yearly performance of products by comparing their sales 
--to both the average sales performance of the product and the previous year's sales
WITH yearly_product_sales AS(
    SELECT 
        YEAR(s.order_date) AS order_year,
        p.product_name,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p
        ON p.product_key = s.product_key
    WHERE order_date IS NOT NULL
    GROUP BY 
        YEAR(s.order_date),
        p.product_name
)
SELECT 
    *,
    AVG(total_sales) OVER (PARTITION BY product_name) AS avg_sales,
    total_sales - AVG(total_sales) OVER (PARTITION BY product_name) AS diff_avg,
    CASE 
        WHEN total_sales - AVG(total_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above avg'
        WHEN total_sales - AVG(total_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below avg'
        ELSE 'Avg'
    END AS avg_change,
    total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_sum,
    CASE 
        WHEN total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
        WHEN total_sales - LAG(total_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease' 
        ELSE 'No Change'
    END sum_change
FROM yearly_product_sales
ORDER BY 
    product_name,
    order_year