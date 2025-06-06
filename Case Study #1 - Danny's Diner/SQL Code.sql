
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- Calculate the total spending per customer by joining price from the menu table
SELECT
	customer_id,
    SUM(price) AS total_spent
FROM dannys_diner.sales
LEFT JOIN dannys_diner.menu USING (product_id)
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
-- Count distinct visit dates for each customer
SELECT 
	customer_id,
	COUNT(DISTINCT order_date) AS visit_days
FROM dannys_diner.sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
-- Get the first purchased product per customer by using dense_rank and row_number
-- Sort by order_date and product_id to ensure consistent results
SELECT customer_id, product_name 
FROM (
	SELECT 
		customer_id,
		product_name,
		DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rk,
		ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, product_id ASC) AS id
	FROM dannys_diner.sales
	LEFT JOIN dannys_diner.menu USING(product_id)
) cte
WHERE rk = 1 AND id = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- Count how many times each item was purchased (not distinct customers)
-- Use LEFT JOIN to include items that were never purchased
-- Use CASE WHEN to replace nulls with 0
SELECT 
	product_name,
	CASE WHEN sales_unit > 0 THEN sales_unit ELSE 0 END AS sales_unit
FROM menu
LEFT JOIN (
	SELECT 
		product_id,
		COUNT(customer_id) AS sales_unit
	FROM sales
	GROUP BY product_id
) units_table USING (product_id);

-- 5. Which item was the most popular for each customer?
-- For each customer, count how many times they purchased each item
-- Use DENSE_RANK to get the most purchased item(s) per customer
-- Exclude customers who made no purchases
WITH rk_table AS (
	SELECT 
		customer_id,
		product_id,
		product_name,
		COUNT(product_id) AS cnt,
		DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) AS rk
	FROM sales
	LEFT JOIN menu USING(product_id)
	GROUP BY customer_id, product_id, product_name
)
SELECT customer_id, product_name, cnt
FROM rk_table
WHERE rk = 1;

-- 6. Which item was purchased first by the customer after they became a member?
-- Filter orders after join_date and find the first one using DENSE_RANK
WITH times_table AS (
	SELECT 
		customer_id,
		product_name,
		DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS times
	FROM sales
	LEFT JOIN members USING (customer_id)
	LEFT JOIN menu USING(product_id)
	WHERE order_date >= join_date
)
SELECT customer_id, product_name
FROM times_table
WHERE times = 1;

-- 7. Which item was purchased just before the customer became a member?
-- Get the last purchase before the join date using ROW_NUMBER (ordered descending)
-- Handle case where customer bought multiple items on same day
WITH times_table AS (
	SELECT 
		customer_id,
		product_name,
		ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC, product_id DESC) AS times
	FROM sales
	LEFT JOIN members USING (customer_id)
	LEFT JOIN menu USING(product_id)
	WHERE order_date < join_date
)
SELECT customer_id, product_name
FROM times_table
WHERE times = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
-- Count how many items they bought and total amount before join date
-- No need to remove duplicates
SELECT 
	customer_id,
	COUNT(product_id) AS items_units,
    SUM(price) AS total_amount
FROM sales
LEFT JOIN menu USING (product_id)
LEFT JOIN members USING (customer_id)
WHERE order_date < join_date
GROUP BY customer_id
ORDER BY customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- Option 1: add multiplier in menu table
-- Option 2: use CASE WHEN in SQL (chosen here due to small dataset)
-- Sushi = product_id 1, gets 20 points per dollar
SELECT 
	customer_id,
	SUM(CASE 
			WHEN product_id = 1 THEN price * 20 
			ELSE price * 10 
		END) AS points
FROM sales
LEFT JOIN menu USING (product_id)
GROUP BY customer_id
ORDER BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- Join join_date and define a 7-day bonus period using CASE WHEN
-- Bonus period: join_date to join_date + 6 days → 2x points for all items
-- After that: sushi = 2x, others = 1x
SELECT 
	customer_id,
	SUM(CASE 
			WHEN order_date BETWEEN join_date AND join_date + INTERVAL '6 days' THEN price * 20
			WHEN product_id = 1 THEN price * 20
			ELSE price * 10 
		END) AS points
FROM sales
LEFT JOIN members USING (customer_id)
LEFT JOIN menu USING(product_id)
GROUP BY customer_id;
