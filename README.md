# Retail Sales and Revenue Intelligence Dashboard

    ![Power BI](https://img.shields.io/badge/Power_BI-dashboard_spec-F2C811)
    ![SQL](https://img.shields.io/badge/SQL-analytics-blue)
    ![Python](https://img.shields.io/badge/Python-pandas-blue)
    ![Status](https://img.shields.io/badge/status-portfolio_ready-386411)

    ## About This Project

    This project demonstrates a compact end-to-end retail analytics workflow: synthetic raw sales generation, Python ETL, SQL business analysis, Power BI dashboard planning, and recruiter-facing documentation.

    ## Business Problem

    A retail business needs to monitor revenue, gross profit, product performance, and regional sales patterns from messy transaction data. The goal is to convert raw sales logs into a clean dataset that can support executive KPI reporting and inventory decisions.

    ## Dashboard Preview

    ![Executive Sales Overview](images/01_executive_sales_overview.svg)

    ![Product Performance Analysis](images/02_product_performance_analysis.svg)

    ![Regional Revenue Distribution](images/03_regional_revenue.svg)

    ## Data Assets

    | File | Purpose |
    |---|---|
    | `data/raw_uncleaned_sales.csv` | Raw synthetic transactions with duplicates, null customer IDs, inconsistent categories, inconsistent regions, and price anomalies. |
    | `data/cleaned_sales_dataset.csv` | Cleaned analytical table produced by the Python ETL pipeline. |
    | `docs/data_dictionary.md` | Field definitions for the cleaned sales dataset. |
    | `docs/data_quality_report.md` | Cleaning checks and validation summary. |

    ## Key Metrics From Current Data

    | KPI | Value |
    |---|---:|
    | Total revenue | $1,184,427 |
| Gross profit | $532,992 |
| Average order value | $1,246.77 |
| Duplicate transactions removed | 50 |
| Nulls in cleaned dataset | 0 |

    ## Technical Workflow

    1. Generate synthetic retail sales transactions in `sales_cleaning_and_etl.py`.
    2. Deduplicate transaction IDs and handle missing customer identifiers.
    3. Standardize category and region labels.
    4. Create revenue, COGS, and gross profit fields.
    5. Use `sql/analytical_queries.sql` for KPI, region, product, and margin analysis.
    6. Use `powerbi/dashboard_spec.md` and `powerbi/measures.dax` to build the Power BI model.

    ## How To Run

    ```bash
    python -m pip install -r requirements.txt
    python sales_cleaning_and_etl.py
    ```

    ## Repository Structure

    ```text
    data/        Raw and cleaned CSV files
    docs/        Data dictionary and data quality report
    images/      Dashboard preview charts generated from the data
    powerbi/     Dashboard specification, DAX measures, and theme JSON
    sql/         Analytical SQL queries
    ```

    ## Interview Talking Points

    - Shows Python data cleaning with deliberate data quality issues.
    - Shows SQL analysis for executive KPIs, product profitability, and regional performance.
    - Shows BI planning through dashboard specs and DAX measures.
    - Strong supporting project next to the larger retail e-commerce showcase repository.
