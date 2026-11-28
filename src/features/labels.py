"""Churn label: did an active customer stop buying after a cutoff date?"""

import pandas as pd


def make_churn_labels(
    orders: pd.DataFrame,
    cutoff: str | pd.Timestamp,
    churn_window_days: int = 90,
    lookback_days: int = 365,
) -> pd.DataFrame:
    """Label each customer who was active before `cutoff`.

    Population: customers with at least one order in the `lookback_days`
    before the cutoff (customers gone for longer are already lost).
    Label: churned = 1 if the customer places NO order in the
    `churn_window_days` starting at the cutoff, else 0.

    Only the label looks at data after the cutoff. Features (next step) must
    use data before the cutoff only, otherwise the model sees the future.
    """
    cutoff = pd.Timestamp(cutoff)
    window_end = cutoff + pd.Timedelta(days=churn_window_days)
    lookback_start = cutoff - pd.Timedelta(days=lookback_days)

    before = orders[(orders["order_ts"] >= lookback_start) & (orders["order_ts"] < cutoff)]
    after = orders[(orders["order_ts"] >= cutoff) & (orders["order_ts"] < window_end)]

    labels = pd.DataFrame({"customer_id": before["customer_id"].unique()})
    labels["churned"] = (~labels["customer_id"].isin(after["customer_id"])).astype(int)
    labels["cutoff"] = cutoff
    return labels