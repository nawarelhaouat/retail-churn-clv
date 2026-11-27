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

## Data cleaning (dbt staging)

| Step | Rows removed | Rows left | Why |
|---|---:|---:|---|
| Raw load | – | 1,067,371 | Both Excel sheets, unchanged |
| Exact duplicates | 34,335 | 1,033,036 | 1–9 Dec 2010 appears in both sheets, plus double-scanned lines |
| Bad-debt adjustments (`A…` invoices) | 6 | 1,033,030 | Accounting entries, not sales |
| Price ≤ 0 after rounding to pence | 6,032 | 1,026,998 | Free items and stock corrections; includes 18 lines priced £0.001 |
| Quantity sign wrong | 1 | 1,026,997 | 1 cancellation with positive quantity (found by a dbt test) |
| **Staging total** | | **1,026,997** | |

Guests (no customer ID) and cancellations are **kept and flagged**, not removed.

![dbt lineage](docs/dbt_lineage.png)

### Orchestration (Airflow)

The DAG `retail_pipeline` runs daily: extract → load → dbt seed → dbt run → dbt test. Each task retries twice; only one run can be active at a time, because the load truncates and reloads the raw table.

![Airflow DAG](docs/airflow_dag.png)

## SQL analysis

Queries are in [`sql/analysis/`](sql/analysis). Key findings:

- **Seasonality:** revenue peaks from September to November (Nov 2010: £1.42M, Nov 2011: £1.46M), when shops stock up for Christmas. December drops sharply because the stock is already bought.
- **Country mix:** the UK brings 84.9% of net revenue. Some export markets are a few large B2B accounts: Ireland generates £610k from only 5 customers.
- **Top products:** REGENCY CAKESTAND 3 TIER leads by revenue (£314k); JUMBO BAG RED RETROSPOT sells the most units (95,963) but at a much lower price per unit (£1.88 vs £12.55).
- **Repeat customers:** 72.4% of customers placed 2+ orders (median: 3 orders), as expected for a mostly wholesale customer base.
- **Basket size:** the average order (£533 in 2011) is far above the median (£305): order values are right-skewed by a few very large orders.
- **Retention:** only ~15–25% of a cohort buys again in the month after their first purchase, but many return later, so a 30-day churn window would be too short. This motivates a longer window (e.g. 90 days) in Part B.
- **Revenue concentration:** the top 10% of customers generate 63.7% of revenue (top 20%: 77.4%). Losing a single high-value customer matters far more than losing a small one, which is why churn risk is combined with CLV.
- **Data caveats:** December 2011 is a partial month (data ends 9 Dec 2011). Dec 2009 counts every customer as new, and some customers have negative total revenue because they cancelled orders placed before the data starts (left-censoring).