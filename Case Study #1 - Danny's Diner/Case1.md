## 1. What is the total amount each customer spent at the restaurant?
| Customer_id | Total_sales |
|-------------|-------------|
| A           | 76          |
| B           | 74          |
| C           | 36          |
```sql
SELECT s.customer_id, SUM(m.price) AS total_sales
FROM Menu m
JOIN Sales s
  ON m.product_id = s.product_id
GROUP BY s.customer_id;


