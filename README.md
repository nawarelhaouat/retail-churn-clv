# Retail Data Warehouse + Customer Churn & CLV Prediction

## 1. The problem

An online retailer loses customers without noticing: a customer simply stops ordering. This project predicts which customers are likely to stop buying, estimates how much each customer is worth over the next 6 months (CLV), and explains why. The output is a ranked list that marketing can act on: high-value customers at high risk of leaving.

## 2. Architecture

```mermaid
flowchart LR
    A[UCI Online Retail II .xlsx] -->|extract.py| B[CSV per sheet]
    B -->|load_raw.py| C[(PostgreSQL raw)]
    C -->|dbt| D[(star schema)]
    D --> E[Power BI]
    D --> F[Churn + CLV models]
```

## 3. Data

Source: [Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii) (UCI). Transactions of a UK online gift shop, Dec 2009 – Dec 2011.

## 4. Star schema

```mermaid
erDiagram
    fact_sales }o--|| dim_date : date_key
    fact_sales }o--|| dim_customer : customer_key
    fact_sales }o--|| dim_product : product_key
    fact_sales }o--|| dim_country : country_key

    fact_sales {
        bigint sales_key PK
        text invoice_no
        int date_key FK
        bigint customer_key FK
        bigint product_key FK
        int country_key FK
        timestamp invoice_ts
        int quantity
        numeric unit_price
        numeric revenue
        boolean is_cancellation
    }
    dim_customer {
        bigint customer_key PK
        text customer_id
        date first_purchase_date
    }
    dim_product {
        bigint product_key PK
        text stock_code
        text description
    }
    dim_date {
        int date_key PK
        date full_date
        int year
        int month
        text month_name
        boolean is_weekend
    }
    dim_country {
        int country_key PK
        text country_name
    }
```

**Grain:** one row of `fact_sales` = one invoice line (one product on one invoice).

**Key decisions:**
- Price is stored in the fact, because the same product sells at different prices.
- Guest checkouts (no Customer ID) are linked to an "unknown customer" (`customer_key = -1`) so revenue totals stay correct; the churn model excludes them.
- Cancellations stay in the fact with `is_cancellation = true` and negative quantity, so `SUM(revenue)` is net revenue.
- `dim_date` is generated (one row per calendar day), so days without sales still appear.