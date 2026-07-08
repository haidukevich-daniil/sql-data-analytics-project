/*
===============================================================================
Ranking Analysis
===============================================================================
Purpose:
    - To rank items (e.g., products, customers) based on performance or other metrics.
    - To identify top performers or laggards.
*/

-- Which 5 products Generating the Highest Revenue?
SELECT TOP 5
    p.product_name,
    SUM(s.sales_amount) AS total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
    ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- Using Window Functions
SELECT *
FROM(
    SELECT
        p.product_name,
        SUM(s.sales_amount) AS total_revenue,
        RANK() OVER(ORDER BY SUM(s.sales_amount) DESC) AS product_rank
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p
        ON p.product_key = s.product_key
    GROUP BY p.product_name
)t
WHERE product_rank <= 5;

-- What are the 5 worst-performing products in terms of sales?
SELECT TOP 5
    p.product_name,
    SUM(s.sales_amount) AS total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_products p
    ON p.product_key = s.product_key
GROUP BY p.product_name
ORDER BY total_revenue;

-- Find the top 10 customers who have generated the highest revenue
SELECT TOP 10
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(s.sales_amount) AS total_revenue
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
    ON c.customer_key = s.customer_key
GROUP BY    
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_revenue DESC;

-- The 3 customers with the fewest orders placed
SELECT TOP 3
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(*) AS total_orders
FROM gold.fact_sales s
LEFT JOIN gold.dim_customers c
    ON c.customer_key = s.customer_key
GROUP BY    
    c.customer_key,
    c.first_name,
    c.last_name
ORDER BY total_orders;