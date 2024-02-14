# Ecommerce-Data-Analysis
This repository details my process for analyzing data from a Brazilian e-commerce website named Olist.

Link to data: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce, https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist

## Database Setup
Database is running on a PostgreSQL database through DBeaver.

1. Product names in table 'product' are in Spanish. Use a join on table 'product_category_name_translation' to change product names to English.
```
SELECT distinct p.product_id, pcnt.product_category_name_english, p.product_photos_qty, p.product_weight_g,
p.product_length_cm, p.product_height_cm, p.product_width_cm
FROM public.product_category_name_translation pcnt 
INNER JOIN public.products p
	ON pcnt.product_category_name = p.product_category_name
```
After 
