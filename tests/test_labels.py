import pandas as pd

from src.features.labels import make_churn_labels


def make_orders(rows):
    return pd.DataFrame(rows, columns=["customer_id", "order_ts"]).assign(
        order_ts=lambda df: pd.to_datetime(df["order_ts"])
    )


def test_customer_who_returns_is_not_churned():
    orders = make_orders([(1, "2011-05-01"), (1, "2011-07-01")])
    labels = make_churn_labels(orders, cutoff="2011-06-01")
    assert labels.loc[labels.customer_id == 1, "churned"].item() == 0


def test_customer_who_does_not_return_is_churned():
    orders = make_orders([(2, "2011-05-01")])
    labels = make_churn_labels(orders, cutoff="2011-06-01")
    assert labels.loc[labels.customer_id == 2, "churned"].item() == 1


def test_return_after_window_still_counts_as_churn():
    orders = make_orders([(3, "2011-05-01"), (3, "2011-10-01")])  # 122 days after cutoff
    labels = make_churn_labels(orders, cutoff="2011-06-01", churn_window_days=90)
    assert labels.loc[labels.customer_id == 3, "churned"].item() == 1


def test_customers_outside_lookback_are_excluded():
    orders = make_orders([(4, "2009-12-01"), (5, "2011-05-01")])
    labels = make_churn_labels(orders, cutoff="2011-06-01", lookback_days=365)
    assert set(labels.customer_id) == {5}