-- USE coffeeStore DATABASE =========================================================
-- 1. Sales Performance Analysis ====================================================
-- <1.1> Revenue by Store -----------------------------------------------------------
SELECT 
    so.outlet_id AS store,
	COUNT(transaction_id) AS number_of_transactions,
    ROUND(SUM(sr.line_item_amount)::NUMERIC, 2) AS total_revenue,
	ROUND(AVG(sr.line_item_amount)::NUMERIC, 2) AS avg_transaction_revenue
FROM SalesReceipt AS sr
JOIN Outlets AS so 
	ON sr.outlet_id = so.outlet_id
GROUP BY so.outlet_id
ORDER BY total_revenue DESC;

-- Get percentage of number of trasactions and revenue
WITH sales_by_store_cte AS (
	SELECT 
	    so.outlet_id AS store,
		COUNT(transaction_id) AS number_of_transactions,
	    ROUND(SUM(sr.line_item_amount)::NUMERIC, 2) AS total_revenue
	FROM SalesReceipt AS sr
	JOIN Outlets AS so 
		ON sr.outlet_id = so.outlet_id
	GROUP BY so.outlet_id
),
sales_by_store_total_cte AS (
	SELECT
		store,
		number_of_transactions,
		SUM(number_of_transactions) OVER() AS total_transactions,
		total_revenue,
		SUM(total_revenue) OVER() AS overall_total_revenue
	FROM sales_by_store_cte
)
SELECT
	store,
	number_of_transactions,
	ROUND((number_of_transactions / total_transactions)* 100, 2) AS percentage_of_trasactions,
	total_revenue,
	ROUND((total_revenue / overall_total_revenue) * 100, 2) AS percentage_of_overall_total_revenue
FROM sales_by_store_total_cte
ORDER BY total_revenue DESC;



-- <1.2> Sales Volume by Product -------------------------------------------------------------
SELECT 
    p.product AS product_name,
    SUM(sr.quantity) AS total_sales_volume
FROM SalesReceipt AS sr
JOIN Products AS p 
	ON sr.product_id = p.product_id
GROUP BY p.product
ORDER BY total_sales_volume DESC;

-- Rank values -----------------------
WITH sales_volumes AS (
	SELECT 
	    p.product AS product_name,
	    SUM(sr.quantity) AS total_quantity_sold
	FROM SalesReceipt AS sr
	JOIN Products AS p 
		ON sr.product_id = p.product_id
	GROUP BY p.product
),
sales_volumes_rank AS (
	SELECT 
		product_name, 
		total_quantity_sold,
		RANK() OVER(ORDER BY total_quantity_sold DESC) AS sales_rank_top,
		RANK() OVER(ORDER BY total_quantity_sold ASC) AS sales_rank_bottom
	FROM sales_volumes
)
SELECT 
	product_name,
	total_quantity_sold,
	CASE 
		WHEN total_quantity_sold >= 1506 THEN 'Top'
		ELSE 'Bottom'
	END AS product_position
FROM sales_volumes_rank
WHERE sales_rank_top < 6 OR sales_rank_bottom < 6
ORDER BY total_quantity_sold DESC;


-- Top products details ------------------------
SELECT 
	product,
	product_group,
	product_category,
	product_type,
	current_wholesale_price,
	current_retail_price
FROM Products
WHERE product IN ('Earl Grey Rg', 'Dark Chocolate Lg', 'Latte', 'Morning Sunrise Chai Rg', 'Ethiopia Rg');

-- Bottom product details ---------------------
SELECT 
	product,
	product_group,
	product_category,
	product_type,
	current_wholesale_price,
	current_retail_price
FROM Products
WHERE product IN (
'Guatemalan Sustainably Grown', 
'Serenity Green Tea', 
'Earl Grey', 
'Primo Espresso Roast', 
'Peppermint',
'Spicy Eye Opener Chai',
'Dark chocolate'
);



-- <1.3> Weekly Sales Trend --------------------------------------------------------------------
SELECT 
    TO_CHAR(transaction_date, 'FMDay') AS weekday_name,
	EXTRACT(DOW FROM transaction_date) AS weekday_number,
	COUNT(TO_CHAR(transaction_date, 'FMDay')) AS number_of_weekly_transactions,
	ROUND(AVG(line_item_amount)::NUMERIC, 2) AS avg_weekly_revenue,
    ROUND(SUM(line_item_amount)::NUMERIC, 2) AS total_weekly_revenue
FROM SalesReceipt
GROUP BY TO_CHAR(transaction_date, 'FMDay'), EXTRACT(DOW FROM transaction_date)
ORDER BY weekday_number;

-- Rank weekly revenue
WITH weekly_revenue AS (
	SELECT 
	    TO_CHAR(transaction_date, 'FMDay') AS weekday_name,
		EXTRACT(DOW FROM transaction_date) AS weekday_number,
		COUNT(TO_CHAR(transaction_date, 'FMDay')) AS number_of_transactions,
		ROUND(AVG(line_item_amount)::NUMERIC, 2) AS avg_weekly_revenue,
	    ROUND(SUM(line_item_amount)::NUMERIC, 2) AS total_weekly_revenue
	FROM SalesReceipt
	GROUP BY TO_CHAR(transaction_date, 'FMDay'), EXTRACT(DOW FROM transaction_date)
	ORDER BY weekday_number
)
SELECT 
	weekday_name,
	weekday_number,
	number_of_transactions,
	avg_weekly_revenue,
	total_weekly_revenue,
	RANK() OVER(ORDER BY weekly_revenue DESC) AS weekday_revenue_rank
FROM weekly_revenue
ORDER BY weekday_number;



-- 2. Product Performance Analysis ===============================================================
-- <2.1> Best-Selling Product Category in Each Sales Outlet --------------------------
WITH CategorySales AS (
    SELECT 
        sr.outlet_id,
        p.product_category,
        SUM(sr.quantity) AS total_quantity_sold,
		SUM(sr.line_item_amount) AS total_revenue
    FROM SalesReceipt AS sr
    JOIN Products AS p 
		ON sr.product_id = p.product_id
    GROUP BY sr.outlet_id, p.product_category
),
BestSellingCategories AS (
    SELECT 
        cs.outlet_id,
        cs.product_category,
        cs.total_quantity_sold,
        cs.total_revenue,
        RANK() OVER (PARTITION BY cs.outlet_id ORDER BY cs.total_quantity_sold DESC) AS product_category_rank
    FROM CategorySales AS cs
)
SELECT 
    bsc.outlet_id,
    o.city AS store_city,
    bsc.product_category AS best_selling_category,
    bsc.total_quantity_sold,
    ROUND(bsc.total_revenue::NUMERIC, 2) AS total_revenue
FROM BestSellingCategories AS bsc
JOIN Outlets AS o 
	ON bsc.outlet_id = o.outlet_id
WHERE 
	 -- bsc.product_category_rank = 1  -- (Best selling product category by outlet)
    bsc.product_category_rank < 5  -- (Top 5 Selling product category by outlet)
-- ORDER BY total_revenue DESC;
ORDER BY o.outlet_id, total_revenue DESC;



-- <2.2> Best-Selling Products in Each Sales Outlet --------
WITH ProductSales AS (
    SELECT 
        sr.outlet_id,
        sr.product_id,
        SUM(sr.quantity) AS total_quantity_sold,
        SUM(sr.line_item_amount) AS total_revenue
    FROM SalesReceipt sr
    GROUP BY sr.outlet_id,  sr.product_id
),
BestSellingProducts AS (
    SELECT 
        ps.outlet_id,
        ps.product_id,
        ps.total_quantity_sold,
        ps.total_revenue,
        RANK() OVER (PARTITION BY ps.outlet_id ORDER BY ps.total_quantity_sold DESC) AS sales_rank
    FROM ProductSales AS ps
)
SELECT 
    bsp.outlet_id,
    o.city AS store_city,
    p.product AS product_name,
    bsp.total_quantity_sold,
    ROUND(bsp.total_revenue::NUMERIC, 2) AS total_revenue
FROM BestSellingProducts AS bsp
JOIN Products AS p 
	ON bsp.product_id = p.product_id
JOIN Outlets AS o 
	ON bsp.outlet_id = o.outlet_id
WHERE 
    bsp.sales_rank = 1     -- (best selling products by outlet)
   -- bsp.sales_rank <= 5  -- (Top 5 best selling products by outlet)
--ORDER BY bsp.outlet_id;


-- <2.3> Product with the Least and Most Wastage -----------------------
WITH ProductWaste AS (
    SELECT 
        i.product_id,
        p.product,
        AVG(i.percentage_waste) AS avg_waste_percentage
    FROM Inventory AS i
    JOIN Products AS p
		ON i.product_id = p.product_id
    GROUP BY i.product_id, p.product
),
LeastWasteProduct AS (
    SELECT 
        pw.product_id,
        pw.product,
        pw.avg_waste_percentage,
        RANK() OVER (ORDER BY pw.avg_waste_percentage ASC) AS waste_rank
    FROM ProductWaste AS pw
)
SELECT 
    lwp.product AS product_name,
    ROUND(lwp.avg_waste_percentage::NUMERIC, 2) AS avg_waste_percentage,
	CASE lwp.waste_rank
		WHEN 1 THEN 'Least wastage'
		WHEN 5 THEN 'Most Wastage'
		ELSE 'Others'
	END AS category
FROM LeastWasteProduct  AS lwp
WHERE 
	lwp.waste_rank = 1 OR lwp.waste_rank = 5;


-- By outlet 
WITH WasteSummary AS (
	SELECT 
		i.outlet_id,
		p.product,
		SUM(i.waste) AS total_waste,
		AVG(i.percentage_waste) AS avg_percentage_waste
	FROM Products AS p
	JOIN Inventory AS i
		ON p.product_id = i.product_id
	GROUP BY i.outlet_id, p.product
),
LeastWasteProduct AS (
	SELECT 
		ws.outlet_id,
		ws.product,
		ws.total_waste,
		ws.avg_percentage_waste,
		RANK() OVER(PARTITION BY outlet_id ORDER BY avg_percentage_waste ASC) AS waste_rank
	FROM WasteSummary AS ws
)
SELECT 
	lwp.outlet_id,
	lwp.product,
	lwp.total_waste,
	ROUND(lwp.avg_percentage_waste::NUMERIC, 2) AS avg_percentage_waste,
	CASE lwp.waste_rank
		WHEN 1 THEN 'Least wastage'
		WHEN 5 THEN 'Most Wastage'
		ELSE 'Others'
	END AS category
FROM LeastWasteProduct AS lwp
WHERE lwp.waste_rank = 1 OR lwp.waste_rank = 5;



-- 3. Operational efficiency Analysis ====================================================
-- <3.1> Sales Per Employee --------------------------------------------------------------
SELECT 
	CONCAT(s.first_name, ' ', s.last_name) AS employee_name,
    s.position,
    ROUND(SUM(sr.line_item_amount)::NUMERIC, 2) AS total_sales,
    COUNT(DISTINCT sr.transaction_id) AS number_of_transactions,
    ROUND((SUM(sr.line_item_amount) / COUNT(sr.transaction_id))::NUMERIC, 2) AS sales_per_transaction
FROM SalesReceipt AS sr
JOIN Staffs AS s 
	ON sr.staff_id = s.staff_id
GROUP BY s.staff_id, s.position 
ORDER BY total_sales DESC;

-- Descriptive summary of staff sales per transaction --------------------
SELECT 
	COUNT(*) AS number_of_staff,
	MIN(sales_per_transaction) AS minimum_value,
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sales_per_transaction) AS Q1_value,
	ROUND(AVG(sales_per_transaction), 2) AS average_value,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales_per_transaction) AS median_value,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sales_per_transaction) AS Q3_value,
	MAX(sales_per_transaction) AS maximum_value
FROM (
	SELECT 
		CONCAT(s.first_name, ' ', s.last_name) AS employee_name,
	    s.position,
	    ROUND(SUM(sr.line_item_amount)::NUMERIC, 2) AS total_sales,
	    COUNT(DISTINCT sr.transaction_id) AS number_of_transactions,
	    ROUND((SUM(sr.line_item_amount) / COUNT(sr.transaction_id))::NUMERIC, 2) AS sales_per_transaction
	FROM SalesReceipt AS sr
	JOIN Staffs AS s 
		ON sr.staff_id = s.staff_id
	GROUP BY s.staff_id, s.position 
);



-- <3.2> Potential Revenue Lost Due to Wastage by Store ID ----------------------------------
SELECT 
    i.outlet_id,
    o.city AS store_city,
	SUM(i.quantity_sold) AS total_quantity_sold,
	SUM(i.waste) AS total_waste,
	SUM(i.quantity_sold * p.current_retail_price) AS revenue,
    SUM(i.waste * p.current_retail_price) AS potential_revenue_lost
FROM Inventory AS i
JOIN Products AS p 
	ON i.product_id = p.product_id
JOIN Outlets AS o
	ON i.outlet_id = o.outlet_id
GROUP BY i.outlet_id, o.city
ORDER BY potential_revenue_lost DESC;


-- 4. Customer Behavior Analysis ========================================================
-- <4.1> Average Transaction Value by Customer -------------------------------------
SELECT 
    c.customer_id,
    c.name,
    ROUND(AVG(sr.line_item_amount)::NUMERIC, 2) AS average_transaction_value
FROM SalesReceipt AS sr
JOIN Customers AS c 
	ON sr.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY average_transaction_value DESC;

-- Descriptive summary of the average transaction value.
SELECT 
	COUNT(*) AS number_of_customers,
	MIN(average_transaction_value) AS minimum_value,
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY average_transaction_value) AS Q1_value,
	ROUND(AVG(average_transaction_value), 2) AS average_value,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY average_transaction_value) AS median_value,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY average_transaction_value) AS Q3_value,
	MAX(average_transaction_value) AS maximum_value
FROM (
	SELECT 
	    c.customer_id,
	    c.name,
	    ROUND(AVG(sr.line_item_amount)::NUMERIC, 2) AS average_transaction_value
	FROM SalesReceipt AS sr
	JOIN Customers AS c 
		ON sr.customer_id = c.customer_id
	GROUP BY c.customer_id, c.name
	ORDER BY average_transaction_value DESC
);



-- <4.2> Popular Purchase Combination by Customers ---------
WITH CustomerPurchases AS (
    SELECT 
        sr.customer_id,
        sr.customer_transaction_id,
        STRING_AGG(p.product, ', ') AS purchase_combination
    FROM SalesReceipt AS sr
    JOIN Products AS p 
		ON sr.product_id = p.product_id
    GROUP BY  sr.customer_id, sr.customer_transaction_id 
),
CombinationFrequency AS (
    SELECT purchase_combination, COUNT(*) AS frequency
    FROM CustomerPurchases
    GROUP BY purchase_combination
)
SELECT purchase_combination, frequency
FROM CombinationFrequency
ORDER BY frequency DESC
-- LIMIT 1; -- Most popular purchased products
LIMIT 5; -- Top 5 most popular purchased products

SELECT 
	product,
	product_group,
	product_category,
	product_type,
	current_wholesale_price,
	current_retail_price
FROM Products
WHERE product IN (
'Earl Grey Rg', 
'Dark chocolate Lg', 
'Jamaican Coffee River Lg', 
'Sustainably Grown Organic Lg', 
'Our Old Time Diner Blend Rg'
);



-- <4.3> Frequency of Daily Visit by Customers -------------------------
SELECT 
    c.customer_id,
	c.name,
    sr.transaction_date, 
    COUNT(DISTINCT sr.customer_transaction_id) AS daily_visit_frequency
FROM SalesReceipt AS sr
JOIN Customers AS c 
	ON sr.customer_id = c.customer_id
GROUP BY c.customer_id, sr.transaction_date
ORDER BY  daily_visit_frequency DESC;

-- Descriptive summary of daily visit frequency
SELECT 
	MIN(daily_visit_frequency) AS minimum,
	PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY daily_visit_frequency) AS Q1,
	ROUND(AVG(daily_visit_frequency), 2) AS average,
	PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY daily_visit_frequency) AS median,
	PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY daily_visit_frequency) AS Q3,
	MAX(daily_visit_frequency) AS maximum,
	MODE() WITHIN GROUP (ORDER BY daily_visit_frequency) AS mode -- most frequently occurring visit frequency
FROM (
	SELECT 
	    c.customer_id,
		c.name,
	    sr.transaction_date, 
	    COUNT(DISTINCT sr.customer_transaction_id) AS daily_visit_frequency
	FROM SalesReceipt AS sr
	JOIN Customers AS c 
		ON sr.customer_id = c.customer_id
	GROUP BY c.customer_id, sr.transaction_date
	ORDER BY  daily_visit_frequency DESC
);
	