/*
===============================================================================
Part-to-Whole Analysis
===============================================================================
Purpose:
    - To compare performance or metrics across dimensions or time periods.
    - To evaluate differences between categories.
    - Useful for A/B testing or regional comparisons.
*/

-- Which categories contribute the most to overall sales?
WITH category_sales AS( 
    SELECT 
        p.category,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_products p
        ON p.product_key = s.product_key
    GROUP BY p.category
)
SELECT 
    *,
    SUM(total_sales) OVER() AS overall_sales,
    ROUND(CAST(total_sales AS FLOAT) * 100 / SUM(total_sales) OVER(), 2) AS percent_contribution
FROM category_sales
ORDER BY total_sales DESC

/*
===============================================================================
Data Segmentation Analysis
===============================================================================
Purpose:
    - To group data into meaningful categories for targeted insights.
    - For customer segmentation, product categorization, or regional analysis.
*/

--Segment products into cost ranges and 
--count how many products fall into each segment
WITH product_segments AS (
    SELECT
        product_key,
        product_name,
        cost,
        CASE 
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT 
    cost_range,
    COUNT(*) AS total_products
FROM product_segments
GROUP BY cost_range 
ORDER BY total_products DESC

/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than €5,000.
	- Regular: Customers with at least 12 months of history but spending €5,000 or less.
	- New: Customers with a lifespan less than 12 months.
And find the total number of customers by each group
*/
WITH customer_loyalty AS(
    SELECT 
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        SUM(s.sales_amount) AS total_sales,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order,
        DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS duration
    FROM gold.fact_sales s
    LEFT JOIN gold.dim_customers c 
        ON c.customer_key = s.customer_key
    GROUP BY CONCAT(c.first_name, ' ', c.last_name)
)
SELECT 
    customer_segment,
    COUNT(*) AS total_customers
FROM(
    SELECT 
        *,
        CASE 
            WHEN duration >= 12 AND total_sales > 5000 THEN 'VIP'
            WHEN duration >= 12 AND total_sales <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_loyalty
)t
GROUP BY customer_segment
ORDER BY total_customers DESC