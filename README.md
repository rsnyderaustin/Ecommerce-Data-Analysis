# Table of Contents
* [Database Schema](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/blob/main/README.md#database-schema)
* [SQL Queries and Visualizations: Sales Representative Performance Analysis](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/tree/main?tab=readme-ov-file#sales-analysis)
* SQL Queries and Visualizations: Products and Sellers Analysis
* Visualizations: Products and Sellers Analysis
* [Database Setup Notes](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/blob/main/README.md#database-setup-notes)

Data source: 

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist

# Project Description
The purpose of this project is to display my skills in answering business questions through SQL query writing and data visualizations. The dataset originates from the Brazilian e-commerce company Olist, and is made publicly available through the website Kaggle. For hosting, managing, and querying the dataset, I hosted a PostgreSQL server on my local machine, and managed the database with a mix of the command line tool 'psql' and software DBeaver.

# Database Schema
![Olist Diagram](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/assets/114520816/2e1c568f-cbf7-4c37-bbf7-736162f19681)

# Business Questions and Analysis
## Sales Representatives (SR) Performance Analysis
### What is the average time to close a deal for each of our sales representatives?
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
```
SELECT ql.origin, ROUND(100 * (COUNT(cd.mql_id) * 1.0 / COUNT(ql.mql_id)), 2) percent_closed
FROM qualified_leads ql
LEFT JOIN closed_deals cd
	ON ql.mql_id = cd.mql_id
WHERE ql.origin NOT IN ('', 'unknown')
GROUP BY ql.origin
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
-- Limit can be used here as a convenience (as opposed to rank or row_number which would require a subquery or cte) 
-- as it's highly unlikely that we'll encounter a tie in total_revenue
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
