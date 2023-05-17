SELECT strftime('%Y-%m', won_date) as year_month, business_segment, COUNT(strftime('%m-%Y', won_date)) as num_sales
FROM olist_closed_deals_dataset
GROUP BY strftime('%m-%Y', won_date), business_segment
ORDER BY year_month ASC