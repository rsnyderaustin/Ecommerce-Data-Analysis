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
WHERE ql.origin != ''
GROUP BY ql.origin
```
### What is the revenue generated and average revenue per deal for every month and year broken down by sales representative?

<div class='tableauPlaceholder' id='viz1708894095352' style='position: relative'><noscript><a href='#'><img alt='Monthly Closed Deals By Sales Representative ' src='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;Ol&#47;OlistSalesRepAnalysis&#47;Sheet3&#47;1_rss.png' style='border: none' /></a></noscript><object class='tableauViz'  style='display:none;'><param name='host_url' value='https%3A%2F%2Fpublic.tableau.com%2F' /> <param name='embed_code_version' value='3' /> <param name='site_root' value='' /><param name='name' value='OlistSalesRepAnalysis&#47;Sheet3' /><param name='tabs' value='no' /><param name='toolbar' value='yes' /><param name='static_image' value='https:&#47;&#47;public.tableau.com&#47;static&#47;images&#47;Ol&#47;OlistSalesRepAnalysis&#47;Sheet3&#47;1.png' /> <param name='animate_transition' value='yes' /><param name='display_static_image' value='yes' /><param name='display_spinner' value='yes' /><param name='display_overlay' value='yes' /><param name='display_count' value='yes' /><param name='language' value='en-US' /><param name='filter' value='publish=yes' /></object></div>                <script type='text/javascript'>                    var divElement = document.getElementById('viz1708894095352');                    var vizElement = divElement.getElementsByTagName('object')[0];                    vizElement.style.width='100%';vizElement.style.height=(divElement.offsetWidth*0.75)+'px';                    var scriptElement = document.createElement('script');                    scriptElement.src = 'https://public.tableau.com/javascripts/api/viz_v1.js';                    vizElement.parentNode.insertBefore(scriptElement, vizElement);                </script>

For example, a total revenue of $100,000 in year-month 2018-01 for sales person 'Roger Smith' means that 'Roger Smith' closed deals with sellers in year-month 2018-01 that have since sold $100,000 worth of product through the e-commerce site.
```
WITH seller_revenue_and_won_date as (
-- Find the total revenue for each seller
	SELECT 
		cd.seller_id,
		SUM(oi.price) as total_revenue
	FROM order_items oi
	INNER JOIN closed_deals cd
		ON oi.seller_id = cd.seller_id
	GROUP BY cd.seller_id
)
SELECT sales_name.first_name, sales_name.last_name, cd.won_date, COUNT(cd.sr_id) as closed_deals, 
SUM(srwd.total_revenue) AS total_revenue
FROM closed_deals cd
INNER JOIN seller_revenue_and_won_date srwd
	ON cd.seller_id = srwd.seller_id
INNER JOIN sales_id_to_name sales_name
	ON cd.sr_id = sales_name.sales_id
GROUP BY sales_name.first_name, sales_name.last_name, cd.won_date
ORDER BY sales_name.last_name DESC, cd.won_date ASC
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
