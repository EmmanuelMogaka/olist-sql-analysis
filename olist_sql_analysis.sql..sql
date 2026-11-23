-- This s telling postgres that every table I create  goes in the olist schema
SET search_path TO olist;

-- Olist e-commerce database: table setup
-- Each table matches one CSV file. Column names match the CSV headers exactly.

CREATE TABLE customers (
    customer_id              TEXT,  -- unique ID per order (changes per order)
    customer_unique_id       TEXT,  -- the real customer; repeats if they order again
    customer_zip_code_prefix TEXT,
    customer_city            TEXT,
    customer_state           TEXT
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat             NUMERIC,
    geolocation_lng             NUMERIC,
    geolocation_city            TEXT,
    geolocation_state           TEXT
);

CREATE TABLE order_items (
    order_id            TEXT,
    order_item_id       INT,   -- item number within an order 
    product_id          TEXT,
    seller_id           TEXT,
    shipping_limit_date TIMESTAMP,
    price               NUMERIC,
    freight_value       NUMERIC  -- shipping cost
);

CREATE TABLE order_payments (
    order_id             TEXT,
    payment_sequential   INT,
    payment_type         TEXT,   -- credit_card, boleto, voucher, 
    payment_installments INT,
    payment_value        NUMERIC
);

CREATE TABLE order_reviews (
    review_id               TEXT,
    order_id                TEXT,
    review_score            INT,   -- 1 to 5
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

CREATE TABLE orders (
    order_id                      TEXT,
    customer_id                   TEXT,
    order_status                  TEXT,  -- delivered, shipped, canceled, 
    order_purchase_timestamp      TIMESTAMP,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE products (
    product_id                 TEXT,
    product_category_name      TEXT,  -- in Portuguese
    product_name_lenght        INT,   -- "lenght" is a typo in the original data
    product_description_lenght INT,   -- same typo, keep it so the CSV matches
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

CREATE TABLE sellers (
    seller_id              TEXT,
    seller_zip_code_prefix TEXT,
    seller_city            TEXT,
    seller_state           TEXT
);

CREATE TABLE product_category_name_translation (
    product_category_name         TEXT,
    product_category_name_english TEXT
);

-- want to confirm if the data that has been imported has been done right.Look at the first 5 rows to confirm the data loaded
SELECT * FROM olist.geolocation LIMIT 5;

-- Count the rows. This table should have 71 rows.
SELECT COUNT(*) FROM olist.geolocation;

SELECT * FROM olist.customers LIMIT 5;

SELECT * FROM olist.order_items LIMIT 5;

SELECT * FROM olist.order_payments LIMIT 5;

SELECT COUNT(*) FROM olist.order_reviews;

-- Empty the table (this deletes rows only; the columns stay). I have added the data thrice and the rows are high about 129000.
TRUNCATE TABLE olist.order_reviews;

-- Confirming if  it's empty. This should return 0.
SELECT COUNT(*) FROM olist.order_reviews;

-- Confirm it's empty. This should return 0.
SELECT COUNT(*) FROM olist.orders;

-- Confirm it's empty. This should return 0.
SELECT COUNT(*) FROM olist.products;

-- Row count check for all 9 Olist tables
-- Each line counts one table and labels it, then UNION ALL stacks the results into one list
SELECT 'customers' AS table_name, COUNT(*) AS rows_loaded FROM olist.customers
UNION ALL SELECT 'geolocation', COUNT(*) FROM olist.geolocation
UNION ALL SELECT 'order_items', COUNT(*) FROM olist.order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM olist.order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM olist.order_reviews
UNION ALL SELECT 'orders', COUNT(*) FROM olist.orders
UNION ALL SELECT 'products', COUNT(*) FROM olist.products
UNION ALL SELECT 'sellers', COUNT(*) FROM olist.sellers
UNION ALL SELECT 'product_category_name_translation', COUNT(*) FROM olist.product_category_name_translation;

--  question: How many orders are in each status, biggest group first?
-- Why it matters: shows how many orders were delivered vs stuck, canceled, or unavailable.

SELECT
    order_status,               
    COUNT(*) AS total_orders     
FROM olist.orders
GROUP BY order_status            
ORDER BY total_orders DESC;    

-- question: Which 10 states have the most customers?
-- Why it matters: shows marketing where to focus campaigns and deliveries.

SELECT
    customer_state,                                  
    COUNT(DISTINCT customer_unique_id) AS total_customers  
FROM olist.customers
GROUP BY customer_state                              
ORDER BY total_customers DESC                        
LIMIT 10;                                             

--  question: For each payment type, how many payments were made
-- and how much money was paid in total, biggest total first?
-- Why it matters: shows finance which payment methods customers rely on most.

SELECT
    payment_type,                          
    COUNT(*) AS number_of_payments,        
    SUM(payment_value) AS total_money_paid 
FROM olist.order_payments
GROUP BY payment_type                     
ORDER BY total_money_paid DESC;           

--  question: How many reviews received each score from 1 to 5?
-- Why it matters: shows customer service the overall satisfaction picture at a glance.

SELECT
    review_score,                  -- the score a customer gave
    COUNT(*) AS total_reviews      -- how many reviews gave that score
FROM olist.order_reviews
GROUP BY review_score              -- one row per score
ORDER BY review_score ASC;         -- 1 to 5, in order


--  question: What was the total revenue for each month?
-- Why it matters: shows the sales trend over time and the busiest months.
-- Note: only delivered orders count because canceled orders bring in no money.

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS revenue_month,  -- 2017-11-24 becomes 2017-11-01
    SUM(p.payment_value) AS monthly_revenue                            -- total money that month
FROM olist.orders AS o
JOIN olist.order_payments AS p
    ON o.order_id = p.order_id               -- the shared column that connects the two tables
WHERE o.order_status = 'delivered'           -- filter ROWS first: delivered orders only
GROUP BY revenue_month                       -- one row per month
ORDER BY revenue_month;                      -- oldest month first, like a timeline

-- question: Which 10 product categories generate the most sales?
-- Why it matters: shows which product lines to stock more of and promote.
-- Note: INNER JOIN drops products with no category or no English translation.

SELECT
    t.product_category_name_english AS product_category,  -- category name in English
    SUM(oi.price) AS total_sales,                         -- total money from items in this category
    COUNT(*) AS items_sold                                -- each row in order_items is one item sold
FROM olist.order_items AS oi
JOIN olist.products AS p
    ON oi.product_id = p.product_id                       -- item to product (gets the category)
JOIN olist.product_category_name_translation AS t
    ON p.product_category_name = t.product_category_name  -- Portuguese name to English name
GROUP BY t.product_category_name_english                  -- one row per category
ORDER BY total_sales DESC                                 -- biggest first
LIMIT 10;                                                   -- top 10 only

-- question: What is the average delivery time (in days) for each state?
-- Why it matters: shows logistics which regions are slowest and need attention.
-- Note: only delivered orders with a recorded delivery date are counted.

SELECT
    c.customer_state AS state,
    ROUND(AVG(
        EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0
    )::numeric, 1) AS avg_delivery_days,        -- purchase to delivery, converted from seconds to days
    COUNT(*) AS total_delivered_orders          -- each row in orders is one order
FROM olist.orders AS o
JOIN olist.customers AS c
    ON o.customer_id = c.customer_id            -- order to customer (gets the state)
WHERE o.order_status = 'delivered'              -- filter ROWS first: delivered only
  AND o.order_delivered_customer_date IS NOT NULL   -- skip orders with no delivery date
GROUP BY c.customer_state                       -- one row per state
ORDER BY avg_delivery_days DESC;                -- slowest state first

--  question: Which 10 sellers have the most late deliveries?
-- Why it matters: helps operations find sellers whose delays hurt customer experience.
-- Note: "late" means delivered after the estimated delivery date.

SELECT
    s.seller_id,
    s.seller_state,
    s.seller_city,
    COUNT(DISTINCT oi.order_id) AS late_deliveries   -- distinct, because one order can have several items
FROM olist.order_items AS oi
JOIN olist.orders AS o
    ON oi.order_id = o.order_id                      -- item to order (gets the dates)
JOIN olist.sellers AS s
    ON oi.seller_id = s.seller_id                    -- item to seller (gets the seller details)
WHERE o.order_status = 'delivered'                   -- filter ROWS first
  AND o.order_delivered_customer_date IS NOT NULL    -- skip rows with missing dates
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_delivered_customer_date > o.order_estimated_delivery_date  -- the "late" test
GROUP BY s.seller_id, s.seller_state, s.seller_city  -- one row per seller
ORDER BY late_deliveries DESC                        -- worst first
LIMIT 10;                                            -- top 10 only

--  question: Who are our highest-spending customers over their lifetime?
-- Why it matters: shows which customers to reward, retain, or target for loyalty offers.
-- Note: only delivered orders count, because canceled orders are not real spend.
WITH customer_spending AS (                    -- Step 1: total spend per real customer
    SELECT
        c.customer_unique_id,                  -- the real person, not the per-order ID
        SUM(p.payment_value) AS lifetime_spend,    -- all the money they paid
        COUNT(DISTINCT o.order_id) AS total_orders -- distinct, because an order can have several payment rows
    FROM olist.customers AS c
    JOIN olist.orders AS o
        ON c.customer_id = o.customer_id       -- customer to their orders
    JOIN olist.order_payments AS p
        ON o.order_id = p.order_id             -- order to its payments
    WHERE o.order_status = 'delivered'         -- filter ROWS first
    GROUP BY c.customer_unique_id              -- one row per person
)
-- Step 2: rank the people by spend
SELECT
    RANK() OVER (ORDER BY lifetime_spend DESC) AS customer_rank,  -- 1 = biggest spender
    customer_unique_id,
    total_orders,
    lifetime_spend
FROM customer_spending
ORDER BY customer_rank
LIMIT 20;                                      -- the full list is about 93,000 rows, so show the top 20

--  question: How many customers ordered only once, and how many came back?
-- Why it matters: shows the repeat-purchase rate, which tells the business whether retention is a problem.
-- Note: only delivered orders count.
WITH customer_orders AS (                      -- Step 1: how many orders each real person placed
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM olist.customers AS c
    JOIN olist.orders AS o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'         -- filter ROWS first
    GROUP BY c.customer_unique_id              -- one row per person
)
-- Step 2: sort each person into a group and summarise the groups
SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS total_customers,               -- people in this group
    SUM(total_orders) AS orders_placed,        -- orders those people placed
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS customer_percentage  -- share of all customers
FROM customer_orders
GROUP BY customer_type                         -- one row per group
ORDER BY total_customers DESC;