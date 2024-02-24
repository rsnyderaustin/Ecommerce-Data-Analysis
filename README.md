# Table of Contents
* [Database Schema and Setup](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/tree/main?tab=readme-ov-file#database-setup)
* [SQL Queries and Visualizations: Sales Representative Performance Analysis](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/tree/main?tab=readme-ov-file#sales-analysis)
* SQL Queries and Visualizations: Products and Sellers Analysis
* Visualizations: Products and Sellers Analysis

Data source: 

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist

# Database Schema and Setup
![Olist Diagram](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/assets/114520816/2e1c568f-cbf7-4c37-bbf7-736162f19681)

---

One oddity to note is the relationship of 'customer_id' and 'customer_unique_id' in the customers table shown specifically below. 

![odd_olist_relationship](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/assets/114520816/7624d5ce-1d73-4a10-8588-a1a08f721406)

In the 'orders' table, both a unique order_id and a unique customer_id are generated for each order, rather than using 'customer_id' as a foreign key relating to the 'customers' table. Instead, in the 'customers' table, there can be many 'customer_id's for each 'customer_unique_id', with 'customer_unique_id' serving as the primary key. The implication of this relationship is that to analyze data requiring unique customers, the 'customer_id' column has to be joined with and replaced by 'customer_unique_id'. This normally will just add a subquery or CTE.

---
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
The original dataset has a separatable table for translating the Spanish 'product_category_name' in the 'products' table to English. The query below joins the two tables, replacing the Spanish 'product_category_name' column with the English translations. The resulting table then replaces the original 'products' table.

### Translate 'product' table product names from Spanish to English
```
SELECT distinct p.product_id, pcnt.product_category_name_english, p.product_photos_qty, p.product_weight_g,
p.product_length_cm, p.product_height_cm, p.product_width_cm
FROM public.product_category_name_translation pcnt 
INNER JOIN public.products p
	ON pcnt.product_category_name = p.product_category_name
```

### Database Schema


# Business Questions and Analysis
## Sales Representatives (SR) Performance Analysis
### What is the total revenue generated for each of our SRs?
```
SELECT cd.sr_id sr_id, cd.business_segment, SUM(oi.price)
FROM order_items oi
LEFT JOIN closed_deals cd
	ON oi.seller_id = cd.seller_id
GROUP BY cd.sr_id, cd.business_segment
```
### For every month, who are our top three SRs by number of closed deals?
```
WITH qualified_leads_y_m AS (
	SELECT mql_id, TO_CHAR(TO_DATE(ql.first_contact_date, 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM') as first_contact_date
	FROM qualified_leads ql 
),
sr_ranks as (
SELECT ql.first_contact_date,
	RANK() OVER (PARTITION BY ql.first_contact_date 
		ORDER BY COUNT(cd.sr_id) DESC) as rank,
	COUNT(cd.sr_id) as sr_number_of_closes,
	sitn.first_name, sitn.last_name
FROM qualified_leads_y_m ql 
INNER JOIN closed_deals cd
	ON ql.mql_id = cd.mql_id
INNER JOIN sales_id_to_name sitn
	ON cd.sr_id = sitn.sales_id
GROUP BY ql.first_contact_date, sitn.first_name, sitn.last_name
)
SELECT *
FROM sr_ranks sr
WHERE rank IN (1, 2, 3)
ORDER BY first_contact_date DESC
```
### What is the revenue generated from closed deals for each sales represntative on a monthly basis up until today?
For example, a total revenue of $100,000 in month-year 2018-01 for sales person 'Roger Smith' means that 'Roger Smith' closed deals with sellers in month-year 2018-01 that have since sold $100,000 worth of product through the e-commerce site.
```
WITH closed_deals_year_month AS (
-- Format 'closed_deals' won_date into the necessary month-year format.
	SELECT 
		cd.seller_id, 
		TO_CHAR(TO_DATE(cd.won_date, 'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM') as won_date
	FROM closed_deals cd
),
revenue_by_won_date as (
-- Gather the seller_id, won_date, and total_revenue for each seller into one table.
	SELECT 
		cd.won_date,
		cd.seller_id, 
		SUM(oi.price) as total_revenue
	FROM order_items oi
	INNER JOIN closed_deals_year_month cd
		ON oi.seller_id = cd.seller_id
	GROUP BY cd.seller_id, cd.won_date
)
SELECT sitn.first_name, sitn.last_name, rbwd.won_date, SUM(rbwd.total_revenue)
FROM revenue_by_won_date rbwd
INNER JOIN closed_deals cd
	ON rbwd.seller_id = cd.seller_id
INNER JOIN sales_id_to_name sitn
	ON cd.sdr_id = sitn.sales_id
GROUP BY sitn.first_name, sitn.last_name, rbwd.won_date
ORDER BY sitn.last_name DESC, rbwd.won_date DESC
```
