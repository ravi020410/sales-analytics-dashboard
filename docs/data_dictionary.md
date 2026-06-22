# Data Dictionary

| Field | Description |
|---|---|
| TransactionID | Unique transaction identifier after deduplication. |
| Date | Transaction timestamp. |
| CustomerID | Customer identifier; missing raw IDs are mapped to `CUST-GUEST`. |
| ProductCategory | Standardized product category. |
| Quantity | Units sold in the transaction. |
| UnitPrice | Cleaned unit price. |
| Region | Standardized sales region. |
| Revenue | Quantity multiplied by unit price. |
| CostOfGoodsSold | Estimated COGS using a 55% cost model. |
| GrossProfit | Revenue minus cost of goods sold. |
