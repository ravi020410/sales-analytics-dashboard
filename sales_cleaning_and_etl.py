"""
Sales Analytics - Raw Data Cleaning & ETL Pipeline
Author: Ravikant Yadav
Description: This script simulates the programmatic data cleaning phase of the Sales Analytics project.
             It generates a simulated "messy" raw sales dataset containing nulls, duplicates, and inconsistent regional labels,
             and performs robust Pandas-based cleaning and data standardization, preparing the dataset for SQL database ingestion or Power BI visualization.
"""

import pandas as pd
import numpy as np
import os

def generate_messy_sales_data(num_records=1000):
    """Generates a simulated dataset with deliberate data quality issues (nulls, duplicates, inconsistencies)"""
    np.random.seed(42)

    # Base structural lists
    transaction_ids = [f"TXN-{10000 + i}" for i in range(num_records - 50)]  # 50 records will be duplicates
    # Inject 50 duplicate IDs to simulate transactional redundancies
    transaction_ids = transaction_ids + transaction_ids[:50]

    # Dates spanning 3 years
    date_range = pd.date_range(start="2023-01-01", end="2025-12-31", freq="H")
    dates = np.random.choice(date_range, num_records)

    # Customer IDs (some nulls to simulate guest checkouts / entry failures)
    customer_ids = [f"CUST-{np.random.randint(100, 500)}" for _ in range(num_records)]
    for i in range(num_records):
        if np.random.rand() < 0.14:  # 14% nulls as per resume details
            customer_ids[i] = None

    # Product categories with inconsistent naming labels
    raw_categories = ["Electronics", "Appliances", "Furniture", "Elec.", "APPLIANCES", "furn."]
    categories = np.random.choice(raw_categories, num_records, p=[0.3, 0.2, 0.2, 0.1, 0.1, 0.1])

    # Quantities and Unit Prices (with some negative values to simulate returns/payment anomalies)
    quantities = np.random.randint(1, 10, num_records)
    unit_prices = np.random.uniform(10.0, 500.0, num_records).round(2)

    # Regions with inconsistent casing/naming
    raw_regions = ["North", "South", "East", "West", "north", "south", "EAST", "WEST_REGION"]
    regions = np.random.choice(raw_regions, num_records)

    # Create DataFrame
    df = pd.DataFrame({
        "TransactionID": transaction_ids,
        "Date": dates,
        "CustomerID": customer_ids,
        "ProductCategory": categories,
        "Quantity": quantities,
        "UnitPrice": unit_prices,
        "Region": regions
    })

    # Force negative prices for 2% of the records to simulate payment anomalies/returns
    anomaly_indices = np.random.choice(num_records, int(num_records * 0.02), replace=False)
    df.loc[anomaly_indices, "UnitPrice"] = -df.loc[anomaly_indices, "UnitPrice"]

    return df

def clean_sales_data(raw_df):
    """Executes the data wrangling and ETL steps listed on the resume"""
    print("--- Starting ETL & Data Cleaning Pipeline ---")
    print(f"Initial shape of raw dataset: {raw_df.shape}")

    # 1. Deduplication: Identify and drop duplicate transactions
    duplicates_count = raw_df.duplicated(subset=["TransactionID"]).sum()
    print(f"Found {duplicates_count} duplicate TransactionIDs. Removing duplicates...")
    cleaned_df = raw_df.drop_duplicates(subset=["TransactionID"], keep="first").copy()

    # 2. Handling Missing Customer IDs (Standardization)
    null_cust_count = cleaned_df["CustomerID"].isnull().sum()
    print(f"Found {null_cust_count} missing Customer IDs (guest transactions). Imputing with 'CUST-GUEST'...")
    cleaned_df["CustomerID"] = cleaned_df["CustomerID"].fillna("CUST-GUEST")

    # 3. Fixing Price Anomalies: Filtering out negative transactions or converting to return logs
    negative_prices_count = (cleaned_df["UnitPrice"] <= 0).sum()
    print(f"Found {negative_prices_count} records with negative/invalid unit prices. Rectifying anomalies...")
    # Convert negative prices to positive (assuming they are magnitude records) or filter out depending on rule
    cleaned_df["UnitPrice"] = cleaned_df["UnitPrice"].abs()

    # 4. Standardizing Product Categories (Data Mapping)
    print("Standardizing product category labels...")
    category_map = {
        "Electronics": "Electronics",
        "Elec.": "Electronics",
        "Appliances": "Home Appliances",
        "APPLIANCES": "Home Appliances",
        "Furniture": "Furniture",
        "furn.": "Furniture"
    }
    cleaned_df["ProductCategory"] = cleaned_df["ProductCategory"].map(category_map)

    # 5. Standardizing Regional Labels
    print("Standardizing geographical region names...")
    region_map = {
        "North": "North",
        "north": "North",
        "South": "South",
        "south": "South",
        "East": "East",
        "EAST": "East",
        "West": "West",
        "WEST_REGION": "West"
    }
    cleaned_df["Region"] = cleaned_df["Region"].map(region_map)

    # 6. Schema Calculations & Feature Engineering
    print("Calculating gross revenue columns...")
    cleaned_df["Revenue"] = (cleaned_df["Quantity"] * cleaned_df["UnitPrice"]).round(2)
    # Estimate gross profit margin (assuming a static 45% cost of goods sold model for this pipeline)
    cleaned_df["CostOfGoodsSold"] = (cleaned_df["Revenue"] * 0.55).round(2)
    cleaned_df["GrossProfit"] = (cleaned_df["Revenue"] - cleaned_df["CostOfGoodsSold"]).round(2)

    print(f"Final shape of cleaned dataset: {cleaned_df.shape}")
    print("--- ETL Pipeline Completed Successfully ---")

    return cleaned_df

if __name__ == "__main__":
    # Create output directory using relative paths
    os.makedirs("data", exist_ok=True)

    # Run Generation
    raw_sales = generate_messy_sales_data(1000)
    # Save raw data for reference into relative path
    raw_sales.to_csv("data/raw_uncleaned_sales.csv", index=False)
    print("Simulated raw dataset saved to relative path: 'data/raw_uncleaned_sales.csv'")

    # Run Cleaning
    cleaned_sales = clean_sales_data(raw_sales)
    # Save clean, structured data into relative path
    cleaned_sales.to_csv("data/cleaned_sales_dataset.csv", index=False)
    print("Cleaned, production-ready dataset saved to relative path: 'data/cleaned_sales_dataset.csv'\n")

    # Print sample of data
    print("Preview of cleaned dataset:")
    print(cleaned_sales.head(5))
