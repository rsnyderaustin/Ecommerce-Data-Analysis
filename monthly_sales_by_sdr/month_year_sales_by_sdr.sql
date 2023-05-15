SELECT strftime('%m-%Y', cd.won_date) as month_year, ip.sdr_first_name, ip.sdr_last_name, COUNT(strftime('%m-%Y', cd.won_date)) as num_sales
FROM olist_closed_deals_dataset cd
INNER JOIN ids_processed ip
    ON cd.sdr_id = ip.sdr_id
GROUP BY strftime('%m-%Y', cd.won_date), ip.sdr_first_name, ip.sdr_last_name
ORDER BY month_year ASC
