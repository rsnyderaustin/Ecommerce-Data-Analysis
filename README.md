# Ecommerce-Data-Analysis
This repository details my process for analyzing data from a Brazilian e-commerce website named Olist.

Link to data: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce, https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist

## Database Setup
Database is running on a PostgreSQL database through DBeaver.

### Translate 'product' table product names from Spanish to English
```
SELECT distinct p.product_id, pcnt.product_category_name_english, p.product_photos_qty, p.product_weight_g,
p.product_length_cm, p.product_height_cm, p.product_width_cm
FROM public.product_category_name_translation pcnt 
INNER JOIN public.products p
	ON pcnt.product_category_name = p.product_category_name
```
Afterwards, export query result to the database as a new table.

## Queries
### Sales Analysis
SDR - Sales Development Representative

SR - Sales Representative
#### Revenue By Category
SDR
```
SELECT cd.sdr_id, cd.business_segment, SUM(oi.price)
FROM order_items oi
LEFT JOIN closed_deals cd
	ON oi.seller_id = cd.seller_id
GROUP BY cd.sdr_id, cd.business_segment 
```

SR
```
SELECT cd.sr_id sr_id, cd.business_segment, SUM(oi.price)
FROM order_items oi
LEFT JOIN closed_deals cd
	ON oi.seller_id = cd.seller_id
GROUP BY cd.sr_id, cd.business_segment
```
#### Revenue By Won Date
The month-year in 'won_date' and sum in 'total_revenue' indicates the amount of revenue generated from deals made from just that month-year. For example, a total revenue of $100,000 in month-year 2018-01 for sales person 'Roger Smith' means that 'Roger Smith' closed deals with sellers in month-year 2018-01 that have since generated $100,000 in revenue for the e-commerce site.
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
