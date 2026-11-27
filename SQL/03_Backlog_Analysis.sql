-- ============================================================
-- SALES ORDER, BACKLOG & INVENTORY ANALYTICS
-- File: 03_Backlog_Analysis.sql
-- Purpose: Analyze backlog volume, value, severity,
--          priority, products, customers and warehouses
-- ============================================================

USE Sales_Order_Backlog_Inventory_Analytics;
GO

-- ============================================================
-- Step 1: Validate Backlog Analysis Source Data
-- ============================================================

SELECT
    COUNT(*) AS Total_Orders,

    SUM(CASE
            WHEN backlog_qty > 0 THEN 1
            ELSE 0
        END) AS Orders_With_Backlog,

    SUM(ordered_qty) AS Total_Ordered_Qty,

    SUM(backlog_qty) AS Total_Backlog_Qty,

    CAST(
        SUM(order_value)
        AS DECIMAL(18,2)
    ) AS Total_Order_Value,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Total_Backlog_Value

FROM raw.Sales_Orders;

-- ============================================================
-- Step 2: Overall Backlog KPI Summary
-- ============================================================

SELECT
    COUNT(*) AS Total_Orders,

    SUM(CASE
            WHEN backlog_qty > 0 THEN 1
            ELSE 0
        END) AS Orders_With_Backlog,

    CAST(
        100.0 *
        SUM(CASE
                WHEN backlog_qty > 0 THEN 1
                ELSE 0
            END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Backlog_Order_Rate_Pct,

    SUM(ordered_qty) AS Total_Ordered_Qty,

    SUM(backlog_qty) AS Total_Backlog_Qty,

    CAST(
        100.0 * SUM(backlog_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Total_Backlog_Value,

    CAST(
        100.0 * SUM(backlog_value)
        / NULLIF(SUM(order_value), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Rate_Pct,

    CAST(
        SUM(backlog_value)
        / NULLIF(
            SUM(CASE WHEN backlog_qty > 0 THEN 1 ELSE 0 END),
            0
        )
        AS DECIMAL(18,2)
    ) AS Avg_Backlog_Value_Per_Backlogged_Order

FROM raw.Sales_Orders;

-- ============================================================
-- Step 3: Backlog Severity Analysis
-- ============================================================

WITH BacklogSeverity AS
(
    SELECT
        order_id,
        backlog_qty,
        backlog_value,

        100.0 * backlog_qty
        / NULLIF(ordered_qty, 0) AS Backlog_Pct,

        CASE
            WHEN 100.0 * backlog_qty
                 / NULLIF(ordered_qty, 0) <= 10
                THEN 'Low'

            WHEN 100.0 * backlog_qty
                 / NULLIF(ordered_qty, 0) <= 25
                THEN 'Moderate'

            WHEN 100.0 * backlog_qty
                 / NULLIF(ordered_qty, 0) <= 50
                THEN 'High'

            ELSE 'Critical'
        END AS Backlog_Severity

    FROM raw.Sales_Orders

    WHERE backlog_qty > 0
)

SELECT
    Backlog_Severity,

    COUNT(*) AS Backlogged_Orders,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(backlog_value)
        / SUM(SUM(backlog_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Share_Pct

FROM BacklogSeverity

GROUP BY
    Backlog_Severity

ORDER BY
    CASE Backlog_Severity
        WHEN 'Low' THEN 1
        WHEN 'Moderate' THEN 2
        WHEN 'High' THEN 3
        WHEN 'Critical' THEN 4
    END;


-- ============================================================
-- Step 4: Backlog Analysis by Order Priority
-- ============================================================

SELECT
    priority,

    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN backlog_qty > 0 THEN 1
            ELSE 0
        END
    ) AS Backlogged_Orders,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(backlog_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(backlog_value)
        / SUM(SUM(backlog_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Share_Pct

FROM raw.Sales_Orders

GROUP BY
    priority

ORDER BY
    Backlog_Value DESC;

-- ============================================================
-- Step 5: Backlog Analysis by Sales Channel
-- ============================================================

SELECT
    sales_channel,

    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN backlog_qty > 0 THEN 1
            ELSE 0
        END
    ) AS Backlogged_Orders,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(backlog_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(backlog_value)
        / SUM(SUM(backlog_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Share_Pct

FROM raw.Sales_Orders

GROUP BY
    sales_channel

ORDER BY
    Backlog_Value DESC;

-- ============================================================
-- Step 6: Backlog Analysis by Customer Segment
-- ============================================================

SELECT
    c.customer_segment,

    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN so.backlog_qty > 0 THEN 1
            ELSE 0
        END
    ) AS Backlogged_Orders,

    SUM(so.ordered_qty) AS Ordered_Qty,

    SUM(so.backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(so.backlog_qty)
        / NULLIF(SUM(so.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(so.backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(so.backlog_value)
        / SUM(SUM(so.backlog_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Share_Pct

FROM raw.Sales_Orders AS so

INNER JOIN raw.Customers AS c
    ON so.customer_id = c.customer_id

GROUP BY
    c.customer_segment

ORDER BY
    Backlog_Value DESC;


-- ============================================================
-- Step 7: Backlog Analysis by Customer Region
-- ============================================================

SELECT
    c.region,

    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN so.backlog_qty > 0 THEN 1
            ELSE 0
        END
    ) AS Backlogged_Orders,

    SUM(so.ordered_qty) AS Ordered_Qty,

    SUM(so.backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(so.backlog_qty)
        / NULLIF(SUM(so.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(so.backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(so.backlog_value)
        / SUM(SUM(so.backlog_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Share_Pct

FROM raw.Sales_Orders AS so

INNER JOIN raw.Customers AS c
    ON so.customer_id = c.customer_id

GROUP BY
    c.region

ORDER BY
    Backlog_Value DESC;

-- ============================================================
-- Step 8: Backlog Analysis by Product Category
-- ============================================================

SELECT
    p.category,

    COUNT(*) AS Total_Order_Lines,

    SUM(
        CASE
            WHEN soi.backlog_qty > 0 THEN 1
            ELSE 0
        END
    ) AS Backlogged_Lines,

    SUM(soi.ordered_qty) AS Ordered_Qty,

    SUM(soi.backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(soi.backlog_qty)
        / NULLIF(SUM(soi.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(soi.backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(soi.backlog_value)
        / SUM(SUM(soi.backlog_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Share_Pct

FROM raw.Sales_Order_Items AS soi

INNER JOIN raw.Products AS p
    ON soi.product_id = p.product_id

GROUP BY
    p.category

ORDER BY
    Backlog_Value DESC;

-- ============================================================
-- Step 9: Top 10 Products by Backlog Value
-- ============================================================

WITH ProductBacklog AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(soi.ordered_qty) AS Ordered_Qty,
        SUM(soi.backlog_qty) AS Backlog_Qty,
        SUM(soi.backlog_value) AS Backlog_Value

    FROM raw.Sales_Order_Items AS soi

    INNER JOIN raw.Products AS p
        ON soi.product_id = p.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

RankedProducts AS
(
    SELECT
        *,

        DENSE_RANK() OVER (
            ORDER BY Backlog_Value DESC
        ) AS Backlog_Rank

    FROM ProductBacklog
)

SELECT TOP 10
    Backlog_Rank,
    product_id,
    product_name,
    category,
    Ordered_Qty,
    Backlog_Qty,

    CAST(
        100.0 * Backlog_Qty
        / NULLIF(Ordered_Qty, 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        Backlog_Value
        AS DECIMAL(18,2)
    ) AS Backlog_Value

FROM RankedProducts

ORDER BY
    Backlog_Rank,
    product_id;


-- ============================================================
-- Step 10: Backlog Analysis by Warehouse
-- ============================================================

SELECT
    w.warehouse_id,
    w.warehouse_name,

    COUNT(so.order_id) AS Total_Orders,

    SUM(
        CASE
            WHEN so.backlog_qty > 0 THEN 1
            ELSE 0
        END
    ) AS Backlogged_Orders,

    SUM(so.ordered_qty) AS Ordered_Qty,

    SUM(so.backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(so.backlog_qty)
        / NULLIF(SUM(so.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(so.backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(so.backlog_value)
        / SUM(SUM(so.backlog_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Share_Pct

FROM raw.Sales_Orders AS so

INNER JOIN raw.Warehouses AS w
    ON so.warehouse_id = w.warehouse_id

GROUP BY
    w.warehouse_id,
    w.warehouse_name

ORDER BY
    Backlog_Value DESC;


-- ============================================================
-- Step 11: Yearly Backlog Trend
-- ============================================================

SELECT
    YEAR(order_date) AS Sales_Year,

    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN backlog_qty > 0 THEN 1
            ELSE 0
        END
    ) AS Backlogged_Orders,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(backlog_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value

FROM raw.Sales_Orders

GROUP BY
    YEAR(order_date)

ORDER BY
    Sales_Year;


-- ============================================================
-- Step 12: Comparable Jan-Sep Backlog Trend
-- ============================================================

SELECT
    YEAR(order_date) AS Sales_Year,

    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN backlog_qty > 0 THEN 1
            ELSE 0
        END
    ) AS Backlogged_Orders,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(backlog_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Jan_Sep_Backlog_Value

FROM raw.Sales_Orders

WHERE MONTH(order_date) BETWEEN 1 AND 9

GROUP BY
    YEAR(order_date)

ORDER BY
    Sales_Year;


-- ============================================================
-- Step 13: Jan-Sep Backlog Value YoY Growth
-- ============================================================

WITH JanSepBacklog AS
(
    SELECT
        YEAR(order_date) AS Sales_Year,
        SUM(backlog_value) AS Backlog_Value

    FROM raw.Sales_Orders

    WHERE MONTH(order_date) BETWEEN 1 AND 9

    GROUP BY
        YEAR(order_date)
),

BacklogGrowth AS
(
    SELECT
        Sales_Year,
        Backlog_Value,

        LAG(Backlog_Value) OVER (
            ORDER BY Sales_Year
        ) AS Previous_Year_Backlog_Value

    FROM JanSepBacklog
)

SELECT
    Sales_Year,

    CAST(
        Backlog_Value
        AS DECIMAL(18,2)
    ) AS Jan_Sep_Backlog_Value,

    CAST(
        Previous_Year_Backlog_Value
        AS DECIMAL(18,2)
    ) AS Previous_Year_Backlog_Value,

    CAST(
        100.0 *
        (Backlog_Value - Previous_Year_Backlog_Value)
        / NULLIF(Previous_Year_Backlog_Value, 0)
        AS DECIMAL(8,2)
    ) AS YoY_Backlog_Growth_Pct

FROM BacklogGrowth

ORDER BY
    Sales_Year;


-- ============================================================
-- Step 14: Monthly Backlog Trend
-- ============================================================

SELECT
    YEAR(order_date) AS Sales_Year,

    MONTH(order_date) AS Month_No,

    DATENAME(MONTH, order_date) AS Month_Name,

    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN backlog_qty > 0 THEN 1
            ELSE 0
        END
    ) AS Backlogged_Orders,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(backlog_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value

FROM raw.Sales_Orders

GROUP BY
    YEAR(order_date),
    MONTH(order_date),
    DATENAME(MONTH, order_date)

ORDER BY
    Sales_Year,
    Month_No;



-- ============================================================
-- Step 15: Top 10 Months by Backlog Value
-- ============================================================

WITH MonthlyBacklog AS
(
    SELECT
        YEAR(order_date) AS Sales_Year,
        MONTH(order_date) AS Month_No,
        DATENAME(MONTH, order_date) AS Month_Name,

        SUM(backlog_qty) AS Backlog_Qty,
        SUM(backlog_value) AS Backlog_Value

    FROM raw.Sales_Orders

    GROUP BY
        YEAR(order_date),
        MONTH(order_date),
        DATENAME(MONTH, order_date)
),

RankedMonths AS
(
    SELECT
        *,

        DENSE_RANK() OVER (
            ORDER BY Backlog_Value DESC
        ) AS Backlog_Rank

    FROM MonthlyBacklog
)

SELECT TOP 10
    Backlog_Rank,
    Sales_Year,
    Month_No,
    Month_Name,
    Backlog_Qty,

    CAST(
        Backlog_Value
        AS DECIMAL(18,2)
    ) AS Backlog_Value

FROM RankedMonths

ORDER BY
    Backlog_Rank,
    Sales_Year,
    Month_No;


-- ============================================================
-- Step 16: Top 10 Customers by Backlog Value
-- ============================================================

WITH CustomerBacklog AS
(
    SELECT
        c.customer_id,
        c.customer_name,
        c.customer_segment,
        c.region,

        COUNT(so.order_id) AS Total_Orders,

        SUM(
            CASE
                WHEN so.backlog_qty > 0 THEN 1
                ELSE 0
            END
        ) AS Backlogged_Orders,

        SUM(so.backlog_qty) AS Backlog_Qty,

        SUM(so.backlog_value) AS Backlog_Value

    FROM raw.Sales_Orders AS so

    INNER JOIN raw.Customers AS c
        ON so.customer_id = c.customer_id

    GROUP BY
        c.customer_id,
        c.customer_name,
        c.customer_segment,
        c.region
),

RankedCustomers AS
(
    SELECT
        *,

        DENSE_RANK() OVER (
            ORDER BY Backlog_Value DESC
        ) AS Backlog_Rank

    FROM CustomerBacklog
)

SELECT TOP 10
    Backlog_Rank,
    customer_id,
    customer_name,
    customer_segment,
    region,
    Total_Orders,
    Backlogged_Orders,
    Backlog_Qty,

    CAST(
        Backlog_Value
        AS DECIMAL(18,2)
    ) AS Backlog_Value

FROM RankedCustomers

ORDER BY
    Backlog_Rank,
    customer_id;


-- ============================================================
-- Step 17: Top 10 Customer Backlog Concentration
-- ============================================================

WITH CustomerBacklog AS
(
    SELECT
        customer_id,
        SUM(backlog_value) AS Backlog_Value

    FROM raw.Sales_Orders

    GROUP BY
        customer_id
),

RankedCustomers AS
(
    SELECT
        customer_id,
        Backlog_Value,

        ROW_NUMBER() OVER (
            ORDER BY Backlog_Value DESC
        ) AS Backlog_Rank

    FROM CustomerBacklog
)

SELECT
    CAST(
        SUM(
            CASE
                WHEN Backlog_Rank <= 10
                THEN Backlog_Value
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Top_10_Customer_Backlog_Value,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN Backlog_Rank <= 10
                THEN Backlog_Value
                ELSE 0
            END
        )
        / NULLIF(SUM(Backlog_Value), 0)
        AS DECIMAL(8,2)
    ) AS Top_10_Backlog_Share_Pct

FROM RankedCustomers;


-- ============================================================
-- Step 18: Top 10 Product Backlog Concentration
-- ============================================================

WITH ProductBacklog AS
(
    SELECT
        product_id,
        SUM(backlog_value) AS Backlog_Value

    FROM raw.Sales_Order_Items

    GROUP BY
        product_id
),

RankedProducts AS
(
    SELECT
        product_id,
        Backlog_Value,

        ROW_NUMBER() OVER (
            ORDER BY Backlog_Value DESC
        ) AS Backlog_Rank

    FROM ProductBacklog
)

SELECT
    CAST(
        SUM(
            CASE
                WHEN Backlog_Rank <= 10
                THEN Backlog_Value
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Top_10_Product_Backlog_Value,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN Backlog_Rank <= 10
                THEN Backlog_Value
                ELSE 0
            END
        )
        / NULLIF(SUM(Backlog_Value), 0)
        AS DECIMAL(8,2)
    ) AS Top_10_Backlog_Share_Pct

FROM RankedProducts;

-- ============================================================
-- Step 19: Backlog Analysis by Order Status
-- ============================================================

SELECT
    order_status,

    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN backlog_qty > 0 THEN 1
            ELSE 0
        END
    ) AS Backlogged_Orders,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(backlog_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(backlog_value)
        / NULLIF(SUM(order_value), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Rate_Pct

FROM raw.Sales_Orders

GROUP BY
    order_status

ORDER BY
    Backlog_Value DESC


-- ============================================================
-- Step 20: High & Critical Backlog Exposure
-- ============================================================

WITH BacklogSeverity AS
(
    SELECT
        order_id,
        backlog_qty,
        backlog_value,

        CASE
            WHEN 100.0 * backlog_qty
                 / NULLIF(ordered_qty, 0) <= 10
                THEN 'Low'

            WHEN 100.0 * backlog_qty
                 / NULLIF(ordered_qty, 0) <= 25
                THEN 'Moderate'

            WHEN 100.0 * backlog_qty
                 / NULLIF(ordered_qty, 0) <= 50
                THEN 'High'

            ELSE 'Critical'
        END AS Backlog_Severity

    FROM raw.Sales_Orders

    WHERE backlog_qty > 0
)

SELECT
    COUNT(*) AS High_Critical_Orders,

    SUM(backlog_qty) AS High_Critical_Backlog_Qty,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS High_Critical_Backlog_Value,

    CAST(
        100.0 * SUM(backlog_value)
        /
        (SELECT SUM(backlog_value)
         FROM raw.Sales_Orders)
        AS DECIMAL(8,2)
    ) AS Share_Of_Total_Backlog_Value_Pct

FROM BacklogSeverity

WHERE Backlog_Severity IN ('High', 'Critical');


-- ============================================================
-- Step 21: Product Backlog Pareto Analysis
-- ============================================================

WITH ProductBacklog AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(soi.backlog_value) AS Backlog_Value

    FROM raw.Sales_Order_Items AS soi

    INNER JOIN raw.Products AS p
        ON soi.product_id = p.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

ParetoAnalysis AS
(
    SELECT
        product_id,
        product_name,
        category,
        Backlog_Value,

        SUM(Backlog_Value) OVER (
            ORDER BY Backlog_Value DESC
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS Cumulative_Backlog_Value,

        SUM(Backlog_Value) OVER ()
            AS Total_Backlog_Value

    FROM ProductBacklog
)

SELECT TOP 20
    product_id,
    product_name,
    category,

    CAST(
        Backlog_Value
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        Cumulative_Backlog_Value
        AS DECIMAL(18,2)
    ) AS Cumulative_Backlog_Value,

    CAST(
        100.0 * Cumulative_Backlog_Value
        / NULLIF(Total_Backlog_Value, 0)
        AS DECIMAL(8,2)
    ) AS Cumulative_Backlog_Pct

FROM ParetoAnalysis

ORDER BY
    Backlog_Value DESC;


-- ============================================================
-- Step 22: Backlog Analysis by Product Demand Level
-- ============================================================

WITH ProductPerformance AS
(
    SELECT
        product_id,
        SUM(ordered_qty) AS Ordered_Qty,
        SUM(backlog_qty) AS Backlog_Qty,
        SUM(backlog_value) AS Backlog_Value

    FROM raw.Sales_Order_Items

    GROUP BY
        product_id
),

DemandQuartiles AS
(
    SELECT
        *,

        NTILE(4) OVER (
            ORDER BY Ordered_Qty
        ) AS Demand_Quartile

    FROM ProductPerformance
)

SELECT
    CONCAT('Q', Demand_Quartile) AS Demand_Group,

    COUNT(*) AS Products,

    SUM(Ordered_Qty) AS Ordered_Qty,

    SUM(Backlog_Qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(Backlog_Qty)
        / NULLIF(SUM(Ordered_Qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        SUM(Backlog_Value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(Backlog_Value)
        / SUM(SUM(Backlog_Value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Share_Pct

FROM DemandQuartiles

GROUP BY
    Demand_Quartile

ORDER BY
    Demand_Quartile;


-- ============================================================
-- Step 23: High-Demand Product Backlog Risk
-- ============================================================

WITH ProductPerformance AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(soi.ordered_qty) AS Ordered_Qty,
        SUM(soi.backlog_qty) AS Backlog_Qty,
        SUM(soi.backlog_value) AS Backlog_Value

    FROM raw.Sales_Order_Items AS soi

    INNER JOIN raw.Products AS p
        ON soi.product_id = p.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

DemandQuartiles AS
(
    SELECT
        *,

        NTILE(4) OVER (
            ORDER BY Ordered_Qty
        ) AS Demand_Quartile

    FROM ProductPerformance
)

SELECT TOP 10
    product_id,
    product_name,
    category,
    Ordered_Qty,
    Backlog_Qty,

    CAST(
        100.0 * Backlog_Qty
        / NULLIF(Ordered_Qty, 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Rate_Pct,

    CAST(
        Backlog_Value
        AS DECIMAL(18,2)
    ) AS Backlog_Value

FROM DemandQuartiles

WHERE Demand_Quartile = 4

ORDER BY
    Backlog_Value DESC;


-- ============================================================
-- Step 24: Backlog Reconciliation Validation
-- ============================================================

SELECT
    (SELECT SUM(backlog_qty)
     FROM raw.Sales_Orders)
        AS Order_Level_Backlog_Qty,

    (SELECT SUM(backlog_qty)
     FROM raw.Sales_Order_Items)
        AS Item_Level_Backlog_Qty,

    (SELECT SUM(backlog_qty)
     FROM raw.Sales_Orders)
    -
    (SELECT SUM(backlog_qty)
     FROM raw.Sales_Order_Items)
        AS Backlog_Qty_Difference,

    CAST(
        (SELECT SUM(backlog_value)
         FROM raw.Sales_Orders)
        AS DECIMAL(18,2)
    ) AS Order_Level_Backlog_Value,

    CAST(
        (SELECT SUM(backlog_value)
         FROM raw.Sales_Order_Items)
        AS DECIMAL(18,2)
    ) AS Item_Level_Backlog_Value,

    CAST(
        (SELECT SUM(backlog_value)
         FROM raw.Sales_Orders)
        -
        (SELECT SUM(backlog_value)
         FROM raw.Sales_Order_Items)
        AS DECIMAL(18,2)
    ) AS Backlog_Value_Difference;

-- ============================================================
-- Step 25: Final Backlog Analysis Validation
-- ============================================================

DECLARE @BacklogValidation TABLE
(
    Validation_Check VARCHAR(100),
    Status VARCHAR(10)
);

INSERT INTO @BacklogValidation
VALUES

('Total Orders',
 CASE WHEN (SELECT COUNT(*) FROM raw.Sales_Orders) = 25000
      THEN 'PASS' ELSE 'FAIL' END),

('Orders With Backlog',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Sales_Orders
     WHERE backlog_qty > 0
 ) = 10850
 THEN 'PASS' ELSE 'FAIL' END),

('Total Backlog Quantity',
 CASE WHEN
 (
     SELECT SUM(backlog_qty)
     FROM raw.Sales_Orders
 ) = 61179
 THEN 'PASS' ELSE 'FAIL' END),

('Order vs Item Backlog Quantity',
 CASE WHEN
 (
     SELECT SUM(backlog_qty)
     FROM raw.Sales_Orders
 )
 =
 (
     SELECT SUM(backlog_qty)
     FROM raw.Sales_Order_Items
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Order vs Item Backlog Value Within Tolerance',
 CASE WHEN ABS(
     (SELECT SUM(backlog_value)
      FROM raw.Sales_Orders)
     -
     (SELECT SUM(backlog_value)
      FROM raw.Sales_Order_Items)
 ) <= 1.00
 THEN 'PASS' ELSE 'FAIL' END),

('Backlog Quantity Never Exceeds Ordered Quantity',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Sales_Orders
     WHERE backlog_qty > ordered_qty
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Backlog Equation Valid',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Sales_Orders
     WHERE ordered_qty <> fulfilled_qty + backlog_qty
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Fully Fulfilled Orders Have Zero Backlog',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Sales_Orders
     WHERE order_status = 'Fulfilled'
       AND backlog_qty <> 0
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Product Backlog Quantity Reconciles',
 CASE WHEN
 (
     SELECT SUM(backlog_qty)
     FROM raw.Sales_Order_Items
 ) = 61179
 THEN 'PASS' ELSE 'FAIL' END);

-- Detailed results
SELECT *
FROM @BacklogValidation;

-- Overall status
SELECT
    COUNT(*) AS Total_Checks,

    SUM(CASE WHEN Status = 'PASS' THEN 1 ELSE 0 END)
        AS Passed_Checks,

    SUM(CASE WHEN Status = 'FAIL' THEN 1 ELSE 0 END)
        AS Failed_Checks,

    CASE
        WHEN SUM(CASE WHEN Status = 'FAIL' THEN 1 ELSE 0 END) = 0
        THEN 'PASSED'
        ELSE 'FAILED'
    END AS Final_Backlog_Analysis_Status

FROM @BacklogValidation;


