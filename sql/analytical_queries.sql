-- =========================================================================================
-- Retail Sales & Revenue Intelligence - Analytical Queries
-- Author: Ravikant Yadav
-- Database Platform: SQL Server (T-SQL) / PostgreSQL Compatible
-- Description: This script contains advanced SQL queries executed to transform, aggregate,
--              and analyze over 500,000 transaction records. It showcases the technical
--              capability to design CTEs, window functions, time intelligence, and database joins
--              to calculate critical retail business KPIs.
-- =========================================================================================

-- -----------------------------------------------------------------------------------------
-- QUERY 1: Database Schema Initialization & Star-Schema Table Verification
-- Purpose: Ensures primary data integrity and reviews table joins between the Fact Table
--          and surrounding Dimension Tables.
-- -----------------------------------------------------------------------------------------

-- Preview core transaction schema
SELECT TOP 5
    TransactionID,
    CustomerID,
    ProductID,
    Quantity,
    UnitPrice,
    Discount,
    OrderDate
FROM Fact_Sales;


-- -----------------------------------------------------------------------------------------
-- QUERY 2: Advanced Executive KPIs (Total Revenue, Gross Profit, Average Order Value, Margin)
-- Techniques Used: Subqueries, Window Functions, Grouping, Aggregations
-- Purpose: Compute high-level sales metrics to verify Power BI calculation models.
-- -----------------------------------------------------------------------------------------

SELECT
    COUNT(DISTINCT TransactionID) AS TotalOrders,
    SUM(Quantity) AS TotalUnitsSold,

    -- Gross Revenue before discounts
    ROUND(SUM(Quantity * UnitPrice), 2) AS GrossRevenue,

    -- Net Revenue after discount adjustments
    ROUND(SUM(Quantity * UnitPrice * (1 - Discount)), 2) AS NetRevenue,

    -- Average Order Value (AOV)
    ROUND(SUM(Quantity * UnitPrice * (1 - Discount)) / COUNT(DISTINCT TransactionID), 2) AS AverageOrderValue,

    -- Estimate Cost of Goods Sold (COGS) & Profit Margin assuming product cost schema
    ROUND(SUM(Quantity * UnitPrice * (1 - Discount)) - SUM(Quantity * UnitPrice * 0.55), 2) AS EstimatedGrossProfit,
    ROUND(((SUM(Quantity * UnitPrice * (1 - Discount)) - SUM(Quantity * UnitPrice * 0.55)) / SUM(Quantity * UnitPrice * (1 - Discount))) * 100, 2) AS GrossProfitMarginPct
FROM Fact_Sales;


-- -----------------------------------------------------------------------------------------
-- QUERY 3: Regional Sales Distribution & Seasonal Demand Spikes
-- Techniques Used: Date Handling, Multi-Table Joins, Regional Grouping
-- Purpose: Identify geographical sales spikes across state zones to optimize inventory routing.
-- -----------------------------------------------------------------------------------------

SELECT
    g.Zone AS GeographyZone,
    g.State,
    DATEPART(year, s.OrderDate) AS OrderYear,
    DATEPART(quarter, s.OrderDate) AS OrderQuarter,
    SUM(s.Quantity) AS UnitsSold,
    ROUND(SUM(s.Quantity * s.UnitPrice * (1 - s.Discount)), 2) AS NetSales,
    -- Regional sales percentage contribution
    ROUND(
        (SUM(s.Quantity * s.UnitPrice * (1 - s.Discount)) /
        SUM(SUM(s.Quantity * s.UnitPrice * (1 - s.Discount))) OVER (PARTITION BY DATEPART(year, s.OrderDate))) * 100,
        2
    ) AS AnnualContributionPct
FROM Fact_Sales s
JOIN Dim_Geography g ON s.GeographyID = g.GeographyID
GROUP BY g.Zone, g.State, DATEPART(year, s.OrderDate), DATEPART(quarter, s.OrderDate)
ORDER BY OrderYear DESC, NetSales DESC;


-- -----------------------------------------------------------------------------------------
-- QUERY 4: Category Margin Health & Top N Product Performance Ranking
-- Techniques Used: CTEs, Window Functions (DENSE_RANK), Partitioning
-- Purpose: Locate profit-draining product lines and rank top performance contributors in each category.
-- -----------------------------------------------------------------------------------------

WITH ProductPerformance AS (
    SELECT
        p.Category,
        p.ProductName,
        SUM(s.Quantity) AS TotalQtySold,
        ROUND(SUM(s.Quantity * s.UnitPrice * (1 - s.Discount)), 2) AS NetRevenue,
        ROUND(SUM(s.Quantity * p.ProductCost), 2) AS TotalAcquisitionCost
    FROM Fact_Sales s
    JOIN Dim_Product p ON s.ProductID = p.ProductID
    GROUP BY p.Category, p.ProductName
),
ProductMargins AS (
    SELECT
        Category,
        ProductName,
        TotalQtySold,
        NetRevenue,
        ROUND(NetRevenue - TotalAcquisitionCost, 2) AS GrossProfit,
        ROUND(((NetRevenue - TotalAcquisitionCost) / NetRevenue) * 100, 2) AS ProfitMarginPct
    FROM ProductPerformance
    WHERE NetRevenue > 0
)
SELECT
    Category,
    ProductName,
    TotalQtySold,
    NetRevenue,
    GrossProfit,
    ProfitMarginPct,
    -- Rank products inside each category by overall profit contribution
    DENSE_RANK() OVER (PARTITION BY Category ORDER BY GrossProfit DESC) AS ProductProfitRank
FROM ProductMargins
ORDER BY Category, ProductProfitRank;


-- -----------------------------------------------------------------------------------------
-- QUERY 5: Month-over-Month (MoM) Revenue Growth & Sales Velocity
-- Techniques Used: CTEs, Lag Window Function, Year-Month formatting
-- Purpose: Track monthly sales volatility to identify seasonality patterns and predict inventory needs.
-- -----------------------------------------------------------------------------------------

WITH MonthlySales AS (
    SELECT
        DATEPART(year, OrderDate) AS SalesYear,
        DATEPART(month, OrderDate) AS SalesMonth,
        ROUND(SUM(Quantity * UnitPrice * (1 - Discount)), 2) AS MonthlyNetRevenue
    FROM Fact_Sales
    GROUP BY DATEPART(year, OrderDate), DATEPART(month, OrderDate)
),
SalesWithLag AS (
    SELECT
        SalesYear,
        SalesMonth,
        MonthlyNetRevenue,
        -- Fetch the previous month's revenue to calculate delta
        LAG(MonthlyNetRevenue, 1) OVER (ORDER BY SalesYear, SalesMonth) AS PreviousMonthRevenue
    FROM MonthlySales
)
SELECT
    SalesYear,
    SalesMonth,
    MonthlyNetRevenue,
    PreviousMonthRevenue,
    ROUND(MonthlyNetRevenue - PreviousMonthRevenue, 2) AS NetRevenueChange,
    ROUND(((MonthlyNetRevenue - PreviousMonthRevenue) / PreviousMonthRevenue) * 100, 2) AS MoM_GrowthRatePct
FROM SalesWithLag
ORDER BY SalesYear, SalesMonth;


-- -----------------------------------------------------------------------------------------
-- QUERY 6: Year-over-Year (YoY) Sales Progress Analysis
-- Techniques Used: CTEs, Window Functions with Offset, Advanced Grouping
-- Purpose: Evaluate historical revenue expansion, establishing corporate time intelligence.
-- -----------------------------------------------------------------------------------------

WITH QuarterlySales AS (
    SELECT
        DATEPART(year, OrderDate) AS SalesYear,
        DATEPART(quarter, OrderDate) AS SalesQuarter,
        ROUND(SUM(Quantity * UnitPrice * (1 - Discount)), 2) AS QuarterlyRevenue
    FROM Fact_Sales
    GROUP BY DATEPART(year, OrderDate), DATEPART(quarter, OrderDate)
),
QuarterlyWithYoY AS (
    SELECT
        SalesYear,
        SalesQuarter,
        QuarterlyRevenue,
        -- Get revenue from the same quarter in the PREVIOUS year (LAG by 4 quarters)
        LAG(QuarterlyRevenue, 4) OVER (ORDER BY SalesYear, SalesQuarter) AS SameQuarterPreviousYearRevenue
    FROM QuarterlySales
)
SELECT
    SalesYear,
    SalesQuarter,
    QuarterlyRevenue,
    SameQuarterPreviousYearRevenue,
    ROUND(QuarterlyRevenue - SameQuarterPreviousYearRevenue, 2) AS YoYRevenueGrowth,
    ROUND(((QuarterlyRevenue - SameQuarterPreviousYearRevenue) / SameQuarterPreviousYearRevenue) * 100, 2) AS YoYQuarterlyGrowthRatePct
FROM QuarterlyWithYoY
ORDER BY SalesYear, SalesQuarter;
