# Olist E-Commerce SQL Analysis

Answering real business questions about a Brazilian online marketplace using PostgreSQL.

I loaded the 9 Olist tables (about 99,000 orders from 2016 to 2018) into PostgreSQL and wrote SQL to answer questions that sales, finance, customer service and logistics teams would ask.

## Business questions and findings

| Team | Question | Finding |
|---|---|---|
| Operations | How many orders are in each status? | 97.02% of orders were delivered; only 625 (0.63%) were canceled. |
| Marketing | Which 10 states have the most customers? | SP leads with 40,302 customers. |
| Finance | How much money flows through each payment type? | Credit card makes up 78.34% of the money paid. |
| Customer service | How are review scores distributed? | 57.78% of reviews give 5 stars, but 11.51% give 1 star. |
| Finance | What is the monthly revenue trend? | Grew strongly through 2017, peaking in Nov 2017 at R$ 1.15M, then levelled off around R$ 1M a month in 2018. |
| Sales | Which 10 product categories sell the most? | health_beauty, watches_gifts and bed_bath_table lead sales. |
| Logistics | What is the average delivery time per state? | RR waits about 29 days on average, compared with 9 days in SP. |
| Marketing | Who are the top-spending customers? | Customers ranked by lifetime spend using `RANK()`; 
| Marketing | What share of customers are repeat buyers? | Only 3% of customers ever placed a second order. |

## SQL skills shown

Multi-table JOINs, GROUP BY and HAVING, CTEs, window functions (`RANK`, `SUM() OVER`), `CASE WHEN`, `DATE_TRUNC`, date arithmetic.

## Data decisions I made

- Revenue counts **delivered orders only**, because canceled orders bring in no money.
- Customers are counted with `customer_unique_id`, because the same person gets a new `customer_id` on every order.
- `INNER JOIN` on the category translation drops a few products with no category.
- "Late" means delivered after the estimated delivery date.

## How to reproduce

. Download the [Olist dataset from Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce). The data is not stored in this repo.
. In PostgreSQL, create a schema called `olist`.
. Import each CSV into its matching table (DBeaver: right-click the table, then Import Data).
   For `order_reviews`, set the escape character to one that isn't in the file (I used `~`), because review comments contain quotes and line breaks.
. Check the row counts, then run 
## Repository structure

```text
olist-sql-analysis/
├── README.md
├── 01_create_tables.sql
└── 02_analysis_queries.sql
```

## Tools

PostgreSQL, DBeaver, GitHub. Dataset: Olist Brazilian E-Commerce Public Dataset (Kaggle).
