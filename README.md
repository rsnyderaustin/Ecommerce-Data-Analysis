# Table of Contents
* [Database Schema](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/blob/main/README.md#database-schema)
* [SQL Queries and Visualizations: Business Questions and Analysis](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/tree/main?tab=readme-ov-file#sales-analysis)
* [Database Setup Notes](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/blob/main/README.md#database-setup-notes)

# Project Description
The purpose of this project is to display my skills in addressing business questions with SQL query writing and data visualizations. 

For hosting, managing, and querying the dataset, I hosted a PostgreSQL server on my local machine, and managed the database with a mix of the command line tool 'psql' and software DBeaver.

The dataset originates from the Brazilian e-commerce company Olist, and is made publicly available through the website Kaggle.

Data source: 

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist

# Database Schema
![Olist Diagram](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/assets/114520816/2e1c568f-cbf7-4c37-bbf7-736162f19681)

# Business Questions and Analysis
### What does the general sales performance and revenue look like by marketing origin?

![825E991C-BF1B-496F-A1EB-5B97518DC7B4](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/assets/114520816/aa334095-80ac-48a8-b34a-c03a41d34337)

```
WITH seller_origin AS (
	SELECT DISTINCT ql.mql_id, ql.origin, cd.seller_id as seller_id
	FROM qualified_leads ql
	LEFT JOIN closed_deals cd
		ON ql.mql_id = cd.mql_id
	WHERE origin != ''
),
closes_data AS (
	SELECT origin, COUNT(seller_id) as num_deal_closes, 
		ROUND(COUNT(seller_id) * 1.0 / COUNT(origin), 4) as portion_deals_closed 
	FROM seller_origin
	GROUP BY origin
),
revenue_data AS (
	SELECT so.origin, COUNT(so.seller_id) as num_closes, SUM(oi.price) as total_revenue, 
		(SUM(oi.price) * 1.0 / COUNT(so.seller_id)) as average_revenue_per_deal
	FROM seller_origin so
	LEFT JOIN order_items oi
		ON so.seller_id = oi.seller_id
	GROUP BY so.origin
)
SELECT cd.origin, cd.num_deal_closes, cd.portion_deals_closed, rd.total_revenue,
	rd.average_revenue_per_deal
FROM closes_data cd
INNER JOIN revenue_data rd
ON cd.origin = rd.origin
```

### We've recently shifted our strategy for targeting potential sellers through organic search. How has our percent of deals closed from organic search changed over time?

![EC21F402-07D9-463C-8703-9B3B2F2B6661](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/assets/114520816/6eb0b1e4-0f1a-4f59-9c9a-00a125c8a3fd)

```
WITH seller_origin AS (
	SELECT DISTINCT ql.mql_id, TO_CHAR(ql.first_contact_date, 'YYYY-MM') AS first_contact, 
	ql.first_contact_date, cd.seller_id as seller_id, 
	TO_CHAR(cd.won_date, 'YYYY-mm') as won_date
	FROM qualified_leads ql
	LEFT JOIN closed_deals cd
		ON ql.mql_id = cd.mql_id
	WHERE origin = 'organic_search'
)
SELECT first_contact, COUNT(won_date) as num_closes, COUNT(mql_id) as num_solicitations, 
COUNT(won_date) * 1.0 / COUNT(mql_id) as portion_closed
FROM seller_origin
GROUP BY first_contact
ORDER BY first_contact DESC
```
### What is the relationship between deviation from the estimated order delivery date and customer order review?

**Note that a negative delivery delay indicates that the order was delivered before the estimated delivery date, and a positive delay indicates that the order was delivered after the estimated delivery date.**

![E8B2F2BC-4C51-4451-928C-D34F2E17F327](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/assets/114520816/608fbcc8-04ed-4e81-ba93-62151881dc83)

```
WITH delivery_delay AS (
	SELECT reviews.order_id, o.order_estimated_delivery_date, 
	o.order_delivered_customer_date,
	ROUND(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 60, 2)
	as delivery_delay_minutes,
	reviews.review_score
	FROM order_reviews reviews
	INNER JOIN orders o
		ON reviews.order_id = o.order_id
)
SELECT FLOOR(delivery_delay_minutes / 1000) * 1000 AS delivery_delay_minutes,
ROUND(AVG(review_score), 2) as avg_review_score, COUNT(delivery_delay_minutes) as num_deliveries
FROM delivery_delay
GROUP BY FLOOR(delivery_delay_minutes / 1000)
HAVING COUNT(delivery_delay_minutes) > 5
```

### What is the average time to close a deal for each of our sales representatives?

![967DC356-2FCE-42DD-BB04-C7E78DA26760_1_201_a](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/assets/114520816/7075f07d-8b86-4864-9f5d-60484109eb74)

```
WITH time_to_close AS (
	SELECT cd.sr_id, COUNT(cd.sr_id) OVER(PARTITION BY sr_id) as num_closes, (cd.won_date - ql.first_contact_date) as days_to_close
	FROM closed_deals cd 
	INNER JOIN qualified_leads ql
		ON cd.mql_id = ql.mql_id)
SELECT sitn.first_name, sitn.last_name, ttc.num_closes, ROUND(AVG(ttc.days_to_close), 2) as avg_days_to_close
FROM time_to_close ttc
INNER JOIN sales_id_to_name sitn 
	ON ttc.sr_id = sitn.sales_id
GROUP BY sitn.first_name, sitn.last_name, ttc.num_closes
HAVING ttc.num_closes > 5
```

### What is the percent of soliciations closed for each type of marketing origin?

![8D8DC1C6-0700-42B0-B497-BA7B771CE060_1_201_a](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/assets/114520816/5adeff1f-df87-42bf-a2aa-d5d4707f730b)

```
SELECT ql.origin, ROUND(100 * (COUNT(cd.mql_id) * 1.0 / COUNT(ql.mql_id)), 2) percent_closed
FROM qualified_leads ql
LEFT JOIN closed_deals cd
	ON ql.mql_id = cd.mql_id
WHERE ql.origin NOT IN ('', 'unknown')
GROUP BY ql.origin
```

### What is the revenue generated from closed deals, and number of closed deals for each type of marketing origin?

![4DA2614E-9631-45A7-9D47-268C2B95F7A6](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/assets/114520816/5e1ebb1b-eb6f-41f3-b7fa-cccf9827e395)

```
WITH closed_deals_origin AS (
	SELECT cd.seller_id, ql.origin
	FROM closed_deals cd
	INNER JOIN qualified_leads ql
	ON cd.mql_id = ql.mql_id
)
SELECT cdo.origin, COUNT(cdo.seller_id) as num_closes, SUM(price) as total_revenue
FROM closed_deals_origin cdo
INNER JOIN order_items oi
ON cdo.seller_id = oi.seller_id
WHERE cdo.origin NOT IN ('', 'unknown', 'other')
GROUP BY cdo.origin
```

### What are the top 5 item categories by revenue?
```
SELECT p.product_category_name_english as category_name, SUM(oi.price) as total_revenue
FROM order_items oi
LEFT JOIN products p
	ON oi.product_id = p.product_id
WHERE p.product_category_name_english IS NOT NULL
GROUP BY p.product_category_name_english 
ORDER BY total_revenue desc 
-- Limit can be used here as a convenience (as opposed to rank or row_number
-- which would require a subquery or cte) as it's highly unlikely that we'll
-- encounter a tie in total_revenue
LIMIT 5
```
### For each of the top 5 categories by revenue, what are their monthly sales totals?
```
WITH top_5_revenue AS (
	SELECT p.product_category_name_english as category_name, SUM(oi.price) as total_revenue
	FROM order_items oi
	LEFT JOIN products p
		ON oi.product_id = p.product_id
	WHERE p.product_category_name_english IS NOT NULL
	GROUP BY p.product_category_name_english 
	ORDER BY total_revenue desc 
	-- Limit can be used here as a convenience (as opposed to rank or row_number which would require a subquery or cte) 
	-- as it's highly unlikely that we'll encounter a tie in total_revenue
	LIMIT 5
)
SELECT p.product_category_name_english as category_name, 
	TO_CHAR(o.order_purchase_timestamp::date, 'YYYY-mm') as year_month_purchased, SUM(oi.price) as total_revenue
FROM orders o
INNER JOIN order_items oi
	ON o.order_id = oi.order_id
INNER JOIN products p
	ON oi.product_id = p.product_id
WHERE p.product_category_name_english IN (SELECT category_name FROM top_5_revenue)
GROUP BY category_name, year_month_purchased
ORDER BY year_month_purchased DESC, category_name DESC
```


# Database Setup Notes
### Customer Id Key Oddity
One oddity to note is the relationship of 'customer_id' and 'customer_unique_id' in the customers table shown specifically below. 

![odd_olist_relationship](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/assets/114520816/7624d5ce-1d73-4a10-8588-a1a08f721406)

In the 'orders' table, both a unique order_id and a unique customer_id are generated for each order, rather than using 'customer_id' as a foreign key relating to the 'customers' table. So, in the 'customers' table, there can be many 'customer_id's for each primary key 'customer_unique_id'. The implication of this relationship is that to analyze data based on individual customer data, the 'customer_id' column of any table has to be joined with and replaced by 'customer_unique_id'. This normally will just add a subquery or CTE.

---
### Determining Key Relationships
To determine one-to-one, many-to-one, etc relationships, queries such as the one below can display whether a table has multiple instances of a foreign key for the key relationship that we're interested in.
```
SELECT o.order_id AS primary_key, COUNT(r.order_id) AS num_foriegn_keys
FROM orders o
INNER JOIN order_reviews r
	ON o.order_id = r.order_id
GROUP BY o.order_id 
HAVING COUNT(r.order_id) > 1
LIMIT 5
```

---
### Translate Product Category Names from Spanish to English
The original dataset has a separatable table for translating the Spanish 'product_category_name' in the 'products' table to English. The query below joins the two tables, replacing the Spanish 'product_category_name' column with the English translations. The resulting table then replaces the original 'products' table.
```
SELECT distinct p.product_id, pcnt.product_category_name_english, p.product_photos_qty, p.product_weight_g,
p.product_length_cm, p.product_height_cm, p.product_width_cm
FROM public.product_category_name_translation pcnt 
INNER JOIN public.products p
	ON 
