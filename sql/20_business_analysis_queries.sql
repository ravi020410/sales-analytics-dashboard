-- =========================================================================================
-- Retail Sales & Revenue Intelligence - 20+ Advanced SQL Business Queries
-- Author: Ravikant Yadav
-- Database Platform: SQL Server (T-SQL) / PostgreSQL Compatible
-- Description: This script contains 22 production-grade, highly optimized SQL queries
--              designed to answer critical retail sales leadership questions regarding revenue
--              seasonality, product profit margins, and regional sales performance.
-- =========================================================================================

-- -----------------------------------------------------------------------------------------
-- QUERY 1: Executive KPI Summary
-- Purpose: Calculates foundational business-ready metrics: Total gross revenue, average
--          sales margins, total orders, and total items sold.
-- -----------------------------------------------------------------------------------------
SELECT
    SUM(Quantity * ItemPrice) AS Total_Gross_Revenue,
    ROUND(AVG(GrossMarginPercent) * 100.0, 2) AS Average_Gross_Margin_Percent,
    COUNT(DISTINCT OrderID) AS Total_Unique_Orders,
    COUNT(TransactionID) AS Total_Sales_Records,
    SUM(Quantity) AS Total_Units_Sold
FROM Fact_Sales
WHERE Quantity > 0;


-- -----------------------------------------------------------------------------------------
-- QUERY 2: Monthly Revenue Trend & Growth Index
-- Purpose: Identifies Month-over-Month (MoM) revenue trends and growth momentum to assess
--          retail seasonality and consumer behavior cycles.
-- -----------------------------------------------------------------------------------------
WITH MonthlySales AS (
    SELECT
        DATETRUNC(month, OrderDate) AS Sale_Month,
        SUM(Quantity * ItemPrice) AS Monthly_Revenue,
        COUNT(DISTINCT OrderID) AS Monthly_Orders
    FROM Fact_Sales
    WHERE Quantity > 0
    GROUP BY DATETRUNC(month, OrderDate)
)
SELECT
    Sale_Month,
    Monthly_Orders,
    ROUND(Monthly_Revenue, 2) AS Monthly_Revenue,
    ROUND(Monthly_Revenue - LAG(Monthly_Revenue, 1) OVER (ORDER BY Sale_Month), 2) AS MoM_Variance,
    ROUND(((Monthly_Revenue - LAG(Monthly_Revenue, 1) OVER (ORDER BY Sale_Month)) /
           LAG(Monthly_Revenue, 1) OVER (ORDER BY Sale_Month)) * 100, 2) AS MoM_Growth_Percent
FROM MonthlySales
ORDER BY Sale_Month;


-- -----------------------------------------------------------------------------------------
-- QUERY 3: Quarter-Over-Quarter (QoQ) Growth & Corporate Headwinds
-- Purpose: Aggregates revenues into fiscal quarters and measures corporate growth trends.
-- -----------------------------------------------------------------------------------------
WITH QuarterlySales AS (
    SELECT
        YEAR(OrderDate) AS Fiscal_Year,
        DATEPART(quarter, OrderDate) AS Fiscal_Quarter,
        SUM(Quantity * ItemPrice) AS Quarterly_Revenue
    FROM Fact_Sales
    WHERE Quantity > 0
    GROUP BY YEAR(OrderDate), DATEPART(quarter, OrderDate)
)
SELECT
    Fiscal_Year,
    Fiscal_Quarter,
    ROUND(Quarterly_Revenue, 2) AS Quarterly_Revenue,
    ROUND(((Quarterly_Revenue - LAG(Quarterly_Revenue, 1) OVER (ORDER BY Fiscal_Year, Fiscal_Quarter)) /
           LAG(Quarterly_Revenue, 1) OVER (ORDER BY Fiscal_Year, Fiscal_Quarter)) * 100, 2) AS QoQ_Growth_Percent
FROM QuarterlySales
ORDER BY Fiscal_Year, Fiscal_Quarter;


-- -----------------------------------------------------------------------------------------
-- QUERY 4: Top 10 High-Value Customers (Monetary Contribution)
-- Purpose: Identifies and ranks top customers to target for loyalty incentives.
-- -----------------------------------------------------------------------------------------
SELECT TOP 10
    CustomerID,
    COUNT(DISTINCT OrderID) AS Total_Orders,
    ROUND(SUM(Quantity * ItemPrice), 2) AS Cumulative_Spend,
    ROUND(AVG(Quantity * ItemPrice), 2) AS Average_Order_Spend
FROM Fact_Sales
WHERE Quantity > 0
GROUP BY CustomerID
ORDER BY Cumulative_Spend DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 5: Bottom 10 Underperforming Customers (Slip Risk)
-- Purpose: Identifies active customers with the lowest overall transaction value.
-- -----------------------------------------------------------------------------------------
SELECT TOP 10
    CustomerID,
    COUNT(DISTINCT OrderID) AS Total_Orders,
    ROUND(SUM(Quantity * ItemPrice), 2) AS Cumulative_Spend
FROM Fact_Sales
WHERE Quantity > 0
GROUP BY CustomerID
ORDER BY Cumulative_Spend ASC;


-- -----------------------------------------------------------------------------------------
-- QUERY 6: Customer Segmentation Profile Analysis
-- Purpose: Groups customers by purchasing frequency to understand loyal vs. transient buyer
--          shares and focus retention strategy.
-- -----------------------------------------------------------------------------------------
WITH CustomerFrequencies AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT OrderID) AS Order_Count,
        SUM(Quantity * ItemPrice) AS Lifetime_Value
    FROM Fact_Sales
    WHERE Quantity > 0
    GROUP BY CustomerID
)
SELECT
    CASE
        WHEN Order_Count >= 10 THEN 'VIP / High Frequency (10+ Orders)'
        WHEN Order_Count BETWEEN 5 AND 9 THEN 'Loyal Repeat Buyer (5-9 Orders)'
        WHEN Order_Count BETWEEN 2 AND 4 THEN 'Transient Repeat Buyer'
        ELSE 'One-Time Trial Purchaser'
    END AS Customer_Loyalty_Segment,
    COUNT(CustomerID) AS Customer_Count,
    ROUND(SUM(Lifetime_Value), 2) AS Segment_Revenue_Contribution,
    ROUND((SUM(Lifetime_Value) * 100.0) / (SELECT SUM(Quantity * ItemPrice) FROM Fact_Sales WHERE Quantity > 0), 2) AS Revenue_Contribution_Percent
FROM CustomerFrequencies
GROUP BY
    CASE
        WHEN Order_Count >= 10 THEN 'VIP / High Frequency (10+ Orders)'
        WHEN Order_Count BETWEEN 5 AND 9 THEN 'Loyal Repeat Buyer (5-9 Orders)'
        WHEN Order_Count BETWEEN 2 AND 4 THEN 'Transient Repeat Buyer'
        ELSE 'One-Time Trial Purchaser'
    END
ORDER BY Segment_Revenue_Contribution DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 7: Regional Sales & Profitability Distribution
-- Purpose: Analyzes total sales volume, revenue, and gross profit by geographical region.
-- -----------------------------------------------------------------------------------------
SELECT
    Region,
    COUNT(DISTINCT OrderID) AS Region_Total_Orders,
    ROUND(SUM(Quantity * ItemPrice), 2) AS Region_Total_Revenue,
    ROUND(SUM(Quantity * ItemPrice * GrossMarginPercent), 2) AS Region_Gross_Profit,
    ROUND((SUM(Quantity * ItemPrice * GrossMarginPercent) * 100.0) / SUM(Quantity * ItemPrice), 2) AS Region_Realized_Profit_Margin_Percent
FROM Fact_Sales fs
JOIN Dim_Geography dg ON fs.GeographyID = dg.GeographyID
WHERE Quantity > 0
GROUP BY Region
ORDER BY Region_Total_Revenue DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 8: Product Category Performance Matrix
-- Purpose: Compares category-level sales volumes, revenue contributions, and profitability.
-- -----------------------------------------------------------------------------------------
SELECT
    ProductCategory,
    SUM(Quantity) AS Total_Units_Sold,
    ROUND(SUM(Quantity * ItemPrice), 2) AS Category_Revenue,
    ROUND(SUM(Quantity * ItemPrice * GrossMarginPercent), 2) AS Category_Gross_Profit,
    ROUND((SUM(Quantity * ItemPrice * GrossMarginPercent) * 100.0) / SUM(Quantity * ItemPrice), 2) AS Realized_Margin_Percent
FROM Fact_Sales fs
JOIN Dim_Products dp ON fs.ProductID = dp.ProductID
WHERE Quantity > 0
GROUP BY ProductCategory
ORDER BY Category_Gross_Profit DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 9: Customer Monthly Cohort Retention
-- Purpose: Identifies customer cohort retention trends on a monthly basis to measure
--          how long customer relationships remain active.
-- -----------------------------------------------------------------------------------------
WITH CustomerAcquisitions AS (
    SELECT
        CustomerID,
        DATETRUNC(month, MIN(OrderDate)) AS Acquisition_Month
    FROM Fact_Sales
    WHERE Quantity > 0
    GROUP BY CustomerID
),
CohortActivity AS (
    SELECT
        fs.CustomerID,
        ca.Acquisition_Month,
        DATETRUNC(month, fs.OrderDate) AS Activity_Month,
        DATEDIFF(month, ca.Acquisition_Month, DATETRUNC(month, fs.OrderDate)) AS Month_Index
    FROM Fact_Sales fs
    JOIN CustomerAcquisitions ca ON fs.CustomerID = ca.CustomerID
    WHERE fs.Quantity > 0
)
SELECT
    Acquisition_Month,
    Month_Index,
    COUNT(DISTINCT CustomerID) AS Retained_Active_Customers
FROM CohortActivity
WHERE Month_Index BETWEEN 0 AND 12
GROUP BY Acquisition_Month, Month_Index
ORDER BY Acquisition_Month, Month_Index;


-- -----------------------------------------------------------------------------------------
-- QUERY 10: Slipping Customer Analysis (No Activity in 90+ Days)
-- Purpose: Highlights customer accounts that have spent over $500 historically but show
--          no activity in 90 days, indicating high attrition risk.
-- -----------------------------------------------------------------------------------------
SELECT
    CustomerID,
    DATEDIFF(day, MAX(OrderDate), '2026-01-01') AS Days_Since_Last_Order,
    COUNT(DISTINCT OrderID) AS Lifetime_Orders,
    ROUND(SUM(Quantity * ItemPrice), 2) AS Lifetime_Revenue
FROM Fact_Sales
WHERE Quantity > 0
GROUP BY CustomerID
HAVING DATEDIFF(day, MAX(OrderDate), '2026-01-01') > 90
   AND SUM(Quantity * ItemPrice) > 500.00
ORDER BY Lifetime_Revenue DESC, Days_Since_Last_Order ASC;


-- -----------------------------------------------------------------------------------------
-- QUERY 11: Transactional Duplication Audit
-- Purpose: Quality control audit. Flags potential identical duplicate transaction logs
--          recorded within the same minute.
-- -----------------------------------------------------------------------------------------
SELECT
    TransactionID,
    CustomerID,
    ProductID,
    OrderDate,
    Quantity,
    ItemPrice,
    COUNT(*) AS Row_Occurrences
FROM Fact_Sales
GROUP BY TransactionID, CustomerID, ProductID, OrderDate, Quantity, ItemPrice
HAVING COUNT(*) > 1;


-- -----------------------------------------------------------------------------------------
-- QUERY 12: High-Value Revenue Outliers (Statistical Z-Score Filter)
-- Purpose: Highlights orders with spending profiles exceeding 3 standard deviations from
--          mean values to isolate extreme customer behaviors.
-- -----------------------------------------------------------------------------------------
WITH SalesMetrics AS (
    SELECT
        AVG(Quantity * ItemPrice) AS Avg_Spend,
        STDEV(Quantity * ItemPrice) AS Stdev_Spend
    FROM Fact_Sales
    WHERE Quantity > 0
)
SELECT
    fs.OrderID,
    fs.CustomerID,
    fs.OrderDate,
    ROUND(fs.Quantity * fs.ItemPrice, 2) AS Gross_Order_Value,
    ROUND((fs.Quantity * fs.ItemPrice - sm.Avg_Spend) / sm.Stdev_Spend, 2) AS Spend_Z_Score
FROM Fact_Sales fs
CROSS JOIN SalesMetrics sm
WHERE fs.Quantity > 0
  AND (fs.Quantity * fs.ItemPrice - sm.Avg_Spend) / sm.Stdev_Spend > 3.0
ORDER BY Gross_Order_Value DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 13: Daily Sales Run Rates & Moving Averages
-- Purpose: Calculates rolling 7-day average sales revenues to smooth out day-of-week
--          variance and highlight true underlying run-rates.
-- -----------------------------------------------------------------------------------------
WITH DailySales AS (
    SELECT
        DATETRUNC(day, OrderDate) AS Sale_Day,
        SUM(Quantity * ItemPrice) AS Daily_Revenue
    FROM Fact_Sales
    WHERE Quantity > 0
    GROUP BY DATETRUNC(day, OrderDate)
)
SELECT
    Sale_Day,
    ROUND(Daily_Revenue, 2) AS Daily_Revenue,
    ROUND(AVG(Daily_Revenue) OVER (
        ORDER BY Sale_Day
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS Rolling_7Day_Average_Revenue
FROM DailySales
ORDER BY Sale_Day;


-- -----------------------------------------------------------------------------------------
-- QUERY 14: Return & Refund Rates by Product Category
-- Purpose: Analyzes refund volumes and return frequencies by product category to identify
--          product lines causing margin leakage or operational challenges.
-- -----------------------------------------------------------------------------------------
SELECT
    dp.ProductCategory,
    COUNT(CASE WHEN fs.Quantity > 0 THEN fs.OrderID END) AS Total_Valid_Orders,
    COUNT(CASE WHEN fs.Quantity < 0 THEN fs.OrderID END) AS Total_Returns,
    ROUND(SUM(CASE WHEN fs.Quantity < 0 THEN ABS(fs.Quantity * fs.ItemPrice) ELSE 0 END), 2) AS Total_Refunded_Amount,
    ROUND((COUNT(CASE WHEN fs.Quantity < 0 THEN fs.OrderID END) * 100.0) /
          NULLIF(COUNT(CASE WHEN fs.Quantity > 0 THEN fs.OrderID END), 0), 2) AS Return_Rate_Percent
FROM Fact_Sales fs
JOIN Dim_Products dp ON fs.ProductID = dp.ProductID
GROUP BY dp.ProductCategory
ORDER BY Return_Rate_Percent DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 15: Sales Concentration Risk (Pareto Principle / 80-20 Rule)
-- Purpose: Reviews revenue concentration. Calculates the proportion of total revenue
--          generated by the top 20% of product SKUs.
-- -----------------------------------------------------------------------------------------
WITH ProductSales AS (
    SELECT
        ProductID,
        SUM(Quantity * ItemPrice) AS Product_Revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(Quantity * ItemPrice) DESC) AS Product_Rank,
        COUNT(*) OVER() AS Total_Product_Count
    FROM Fact_Sales
    WHERE Quantity > 0
    GROUP BY ProductID
),
CumulativeProductSales AS (
    SELECT
        ProductID,
        Product_Revenue,
        Product_Rank,
        Total_Product_Count,
        SUM(Product_Revenue) OVER (ORDER BY Product_Revenue DESC) AS Cumulative_Revenue,
        (SELECT SUM(Quantity * ItemPrice) FROM Fact_Sales WHERE Quantity > 0) AS Grand_Total_Revenue
    FROM ProductSales
)
SELECT
    Product_Rank,
    ProductID,
    ROUND(Product_Revenue, 2) AS Product_Revenue,
    ROUND((Product_Rank * 100.0) / Total_Product_Count, 2) AS Product_Percentile,
    ROUND((Cumulative_Revenue * 100.0) / Grand_Total_Revenue, 2) AS Cumulative_Revenue_Percent
FROM CumulativeProductSales
WHERE ROUND((Product_Rank * 100.0) / Total_Product_Count, 2) <= 30.0
ORDER BY Product_Rank;


-- -----------------------------------------------------------------------------------------
-- QUERY 16: Top 5 Highest-Grossing Products per Category
-- Purpose: Highlights the premier revenue-generating products in each category using
--          DENSE_RANK.
-- -----------------------------------------------------------------------------------------
WITH RankedProducts AS (
    SELECT
        dp.ProductCategory,
        fs.ProductID,
        SUM(fs.Quantity * fs.ItemPrice) AS Product_Revenue,
        DENSE_RANK() OVER (PARTITION BY dp.ProductCategory ORDER BY SUM(fs.Quantity * fs.ItemPrice) DESC) AS Revenue_Rank
    FROM Fact_Sales fs
    JOIN Dim_Products dp ON fs.ProductID = dp.ProductID
    WHERE fs.Quantity > 0
    GROUP BY dp.ProductCategory, fs.ProductID
)
SELECT
    ProductCategory,
    ProductID,
    ROUND(Product_Revenue, 2) AS Product_Revenue,
    Revenue_Rank
FROM RankedProducts
WHERE Revenue_Rank <= 5
ORDER BY ProductCategory, Revenue_Rank;


-- -----------------------------------------------------------------------------------------
-- QUERY 17: Null CustomerID Inflow Audits
-- Purpose: Identifies transactions lacking CustomerIDs, estimating the volume of guest
--          checkouts or unlinked transaction records.
-- -----------------------------------------------------------------------------------------
SELECT
    COUNT(*) AS Total_Logged_Transactions,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Anonymous_Transactions,
    ROUND((SUM(CASE WHEN CustomerID IS NULL THEN 1.0 ELSE 0.0 END) * 100.0) / COUNT(*), 2) AS Anonymous_Ratio_Percent,
    ROUND(SUM(CASE WHEN CustomerID IS NULL THEN Quantity * ItemPrice ELSE 0 END), 2) AS Anonymous_Unattributed_Revenue
FROM Fact_Sales;


-- -----------------------------------------------------------------------------------------
-- QUERY 18: Operational Profit Drag (Category Margin Drifts)
-- Purpose: Examines category-level profitability. Highlights if any category margins
--          fall below the company-wide average.
-- -----------------------------------------------------------------------------------------
WITH CompanyAverage AS (
    SELECT AVG(GrossMarginPercent) AS Company_Avg_Margin FROM Fact_Sales WHERE Quantity > 0
)
SELECT
    dp.ProductCategory,
    ROUND(AVG(fs.GrossMarginPercent) * 100.0, 2) AS Category_Avg_Margin_Percent,
    ROUND(ca.Company_Avg_Margin * 100.0, 2) AS Company_Target_Margin_Percent,
    ROUND((AVG(fs.GrossMarginPercent) - ca.Company_Avg_Margin) * 100.0, 2) AS Margin_Deviation_Percent
FROM Fact_Sales fs
JOIN Dim_Products dp ON fs.ProductID = dp.ProductID
CROSS JOIN CompanyAverage ca
WHERE fs.Quantity > 0
GROUP BY dp.ProductCategory, ca.Company_Avg_Margin
ORDER BY Margin_Deviation_Percent ASC;


-- -----------------------------------------------------------------------------------------
-- QUERY 19: Basket Analysis (Frequently Co-Purchased Categories)
-- Purpose: Analyzes purchase patterns. Identifies product categories frequently purchased
--          together in the same transactional basket.
-- -----------------------------------------------------------------------------------------
WITH TransactionBaskets AS (
    SELECT DISTINCT
        fs.OrderID,
        dp.ProductCategory
    FROM Fact_Sales fs
    JOIN Dim_Products dp ON fs.ProductID = dp.ProductID
    WHERE fs.Quantity > 0
)
SELECT
    b1.ProductCategory AS Primary_Category,
    b2.ProductCategory AS Associated_Category,
    COUNT(*) AS Co_Purchase_Occurrences
FROM TransactionBaskets b1
JOIN TransactionBaskets b2 ON b1.OrderID = b2.OrderID AND b1.ProductCategory < b2.ProductCategory
GROUP BY b1.ProductCategory, b2.ProductCategory
ORDER BY Co_Purchase_Occurrences DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 20: Average Units per Order (Basket Size) Trends
-- Purpose: Measures average transaction basket sizes by month to monitor cross-selling
--          performance and average order velocity.
-- -----------------------------------------------------------------------------------------
SELECT
    DATETRUNC(month, OrderDate) AS Sale_Month,
    COUNT(DISTINCT OrderID) AS Unique_Orders,
    SUM(Quantity) AS Total_Units,
    ROUND(SUM(Quantity) * 1.0 / COUNT(DISTINCT OrderID), 2) AS Average_Units_Per_Basket
FROM Fact_Sales
WHERE Quantity > 0
GROUP BY DATETRUNC(month, OrderDate)
ORDER BY Sale_Month;


-- -----------------------------------------------------------------------------------------
-- QUERY 21: Rolling Annual Sales & Peak Demand Outlines
-- Purpose: Identifies daily transaction and sales volume records to locate peak demand
--          periods.
-- -----------------------------------------------------------------------------------------
SELECT TOP 5
    DATETRUNC(day, OrderDate) AS Sales_Date,
    COUNT(DISTINCT OrderID) AS Order_Volume,
    ROUND(SUM(Quantity * ItemPrice), 2) AS Daily_Sales_Revenue
FROM Fact_Sales
WHERE Quantity > 0
GROUP BY DATETRUNC(day, OrderDate)
ORDER BY Daily_Sales_Revenue DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 22: Consolidated Regional Executive Scorecard
-- Purpose: Generates a high-level summary of regional performance indicators (orders,
--          revenue, profits, and average basket sizes) for senior leadership reviews.
-- -----------------------------------------------------------------------------------------
SELECT
    dg.Region,
    COUNT(DISTINCT fs.OrderID) AS Total_Region_Orders,
    ROUND(SUM(fs.Quantity * fs.ItemPrice), 2) AS Total_Region_Revenue,
    ROUND(SUM(fs.Quantity * fs.ItemPrice * fs.GrossMarginPercent), 2) AS Total_Region_Profit,
    ROUND(AVG(fs.Quantity * fs.ItemPrice), 2) AS Average_Order_Spend_Per_Region
FROM Fact_Sales fs
JOIN Dim_Geography dg ON fs.GeographyID = dg.GeographyID
WHERE fs.Quantity > 0
GROUP BY dg.Region
ORDER BY Total_Region_Revenue DESC;
