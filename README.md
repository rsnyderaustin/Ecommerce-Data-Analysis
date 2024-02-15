# Table of Contents
* [Database Setup](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/tree/main?tab=readme-ov-file#database-setup)
* [Queries: Sales Analysis](https://github.com/rsnyderaustin/Ecommerce-Data-Analysis/tree/main?tab=readme-ov-file#sales-analysis)
* Visualizations: Sales Analysis
* Queries: Products and Sellers Analysis
* Visualizations: Products and Sellers Analysis

Data source: 

https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist

# Database Setup

### Translate 'product' table product names from Spanish to English
```
SELECT distinct p.product_id, pcnt.product_category_name_english, p.product_photos_qty, p.product_weight_g,
p.product_length_cm, p.product_height_cm, p.product_width_cm
FROM public.product_category_name_translation pcnt 
INNER JOIN public.products p
	ON pcnt.product_category_name = p.product_category_name
```

# Queries
## Sales Analysis
SR - Sales Representative
### Revenue By Category
```
SELECT cd.sr_id sr_id, cd.business_segment, SUM(oi.price)
FROM order_items oi
LEFT JOIN closed_deals cd
	ON oi.seller_id = cd.seller_id
GROUP BY cd.sr_id, cd.business_segment
```
### Top Closers By Year and Month
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
WHERE rank =  1
ORDER BY first_contact_date DESC
```
### Revenue By Won Date
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
