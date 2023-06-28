-- Gather data associated with each review

 with price as
     (SELECT DISTINCT reviews.review_id, reviews.order_id, reviews.review_score,
                 order_items.price
     FROM olist_order_reviews_dataset reviews
     LEFT JOIN olist_order_items_dataset order_items
        ON reviews.order_id = order_items.order_id),

 order_status as
     (SELECT DISTINCT price.*, orders.order_status,
              orders.order_delivered_customer_date,
              orders.order_purchase_timestamp,
              (strftime('%s', orders.order_delivered_customer_date) -
              strftime('%s', orders.order_purchase_timestamp))/3600 as delivery_time_in_hours
     FROM price
     LEFT JOIN  olist_orders_dataset orders
        ON price.order_id = orders.order_id),

 payments as
     (SELECT DISTINCT order_status.*,
            payments.payment_installments
     FROM order_status
     LEFT JOIN olist_order_payments_dataset payments
        ON order_status.order_id = payments.order_id),

 order_id_item_photos as (
    SELECT order_items.order_id, order_items.product_id, products.product_photos_qty as number_of_product_photos
    FROM olist_order_items_dataset order_items
    INNER JOIN olist_products_dataset products
        ON order_items.product_id = products.product_id)

 SELECT DISTINCT payments.*, photos.number_of_product_photos
 FROM payments
 LEFT JOIN order_id_item_photos photos
     ON payments.order_id = photos.order_id
