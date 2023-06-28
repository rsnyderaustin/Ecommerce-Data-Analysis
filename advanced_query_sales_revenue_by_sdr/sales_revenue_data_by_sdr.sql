-- Calculate the revenue per deal and the total revenue generated for each sdr

with sdr_sellers as (SELECT ip.sdr_first_name, ip.sdr_last_name, ip.sdr_id, cd.seller_id
              FROM olist_closed_deals_dataset cd
                       INNER JOIN ids_processed ip
                                  ON cd.sdr_id = ip.sdr_id)
SELECT ss.sdr_first_name, ss.sdr_last_name,
       ROUND(SUM(oi.price), 2) as total_revenue,
       COUNT(ss.seller_id) as number_of_deals,
       ROUND(SUM(oi.price)/COUNT(*), 2) as revenue_per_deal
FROM sdr_sellers as ss
INNER JOIN olist_order_items_dataset oi
    ON ss.seller_id = oi.seller_id
GROUP BY ss.sdr_first_name, ss.sdr_last_name
ORDER BY total_revenue DESC