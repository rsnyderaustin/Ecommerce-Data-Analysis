SELECT strftime('%Y-%m', won_date) as year_month, lead_type, COUNT(strftime('%m-%Y', won_date)) as num_sales
FROM olist_closed_deals_dataset
GROUP BY strftime('%m-%Y', won_date), lead_type
ORDER BY year_month ASC
