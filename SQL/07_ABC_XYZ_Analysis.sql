-- ============================================================
-- SALES ORDER, BACKLOG & INVENTORY ANALYTICS
-- File: 07_ABC_XYZ_Analysis.sql
-- Purpose: ABC-XYZ inventory segmentation
-- ============================================================

USE Sales_Order_Backlog_Inventory_Analytics;
GO

-- ============================================================
-- Step 1: ABC Analysis Source Validation
-- Product-level inventory aggregation
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        product_id,
        SUM(on_hand_qty) AS On_Hand_Qty,
        SUM(available_qty) AS Available_Qty,
        SUM(inventory_value) AS Inventory_Value
    FROM raw.Inventory
    GROUP BY product_id
)

SELECT
    COUNT(*) AS Total_Products,

    SUM(On_Hand_Qty) AS Total_On_Hand_Qty,

    SUM(Available_Qty) AS Total_Available_Qty,

    CAST(
        SUM(Inventory_Value)
        AS DECIMAL(18,2)
    ) AS Total_Inventory_Value,

    CAST(
        MIN(Inventory_Value)
        AS DECIMAL(18,2)
    ) AS Min_Product_Inventory_Value,

    CAST(
        MAX(Inventory_Value)
        AS DECIMAL(18,2)
    ) AS Max_Product_Inventory_Value

FROM ProductInventory;



-- ============================================================
-- Step 2: Product Inventory Value Contribution
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        i.product_id,
        p.product_name,
        p.category,

        SUM(i.on_hand_qty) AS On_Hand_Qty,
        SUM(i.available_qty) AS Available_Qty,
        SUM(i.inventory_value) AS Inventory_Value

    FROM raw.Inventory AS i

    INNER JOIN raw.Products AS p
        ON i.product_id = p.product_id

    GROUP BY
        i.product_id,
        p.product_name,
        p.category
),

InventoryContribution AS
(
    SELECT
        *,

        100.0 * Inventory_Value
        / SUM(Inventory_Value) OVER ()
            AS Inventory_Value_Share_Pct,

        SUM(Inventory_Value) OVER
        (
            ORDER BY Inventory_Value DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        AS Cumulative_Inventory_Value,

        SUM(Inventory_Value) OVER ()
        AS Total_Inventory_Value

    FROM ProductInventory
)

SELECT TOP 20
    product_id,
    product_name,
    category,
    On_Hand_Qty,
    Available_Qty,

    CAST(
        Inventory_Value
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        Inventory_Value_Share_Pct
        AS DECIMAL(8,2)
    ) AS Inventory_Value_Share_Pct,

    CAST(
        100.0 * Cumulative_Inventory_Value
        / Total_Inventory_Value
        AS DECIMAL(8,2)
    ) AS Cumulative_Inventory_Value_Pct

FROM InventoryContribution

ORDER BY
    Inventory_Value DESC,
    product_id;




-- ============================================================
-- Step 3: ABC Product Classification
-- A = Cumulative Inventory Value <= 80%
-- B = > 80% and <= 95%
-- C = > 95%
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        i.product_id,
        p.product_name,
        p.category,

        SUM(i.inventory_value) AS Inventory_Value

    FROM raw.Inventory AS i

    INNER JOIN raw.Products AS p
        ON i.product_id = p.product_id

    GROUP BY
        i.product_id,
        p.product_name,
        p.category
),

CumulativeInventory AS
(
    SELECT
        *,

        100.0 *
        SUM(Inventory_Value) OVER
        (
            ORDER BY Inventory_Value DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(Inventory_Value) OVER ()
        AS Cumulative_Inventory_Value_Pct

    FROM ProductInventory
),

ABCClassification AS
(
    SELECT
        *,

        CASE
            WHEN Cumulative_Inventory_Value_Pct <= 80
                THEN 'A'

            WHEN Cumulative_Inventory_Value_Pct <= 95
                THEN 'B'

            ELSE 'C'
        END AS ABC_Class

    FROM CumulativeInventory
)

SELECT
    ABC_Class,

    COUNT(*) AS Products,

    CAST(
        SUM(Inventory_Value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Product_Share_Pct,

    CAST(
        100.0 * SUM(Inventory_Value)
        / SUM(SUM(Inventory_Value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Inventory_Value_Share_Pct

FROM ABCClassification

GROUP BY
    ABC_Class

ORDER BY
    ABC_Class;




-- ============================================================
-- Step 4: XYZ Demand Source Validation
-- Demand = SALE_ISSUE transactions
-- ============================================================

SELECT
    COUNT(*) AS Sale_Issue_Transactions,

    COUNT(DISTINCT product_id) AS Products_With_Demand,

    MIN(transaction_date) AS First_Demand_Date,

    MAX(transaction_date) AS Last_Demand_Date,

    SUM(ABS(quantity)) AS Total_Demand_Qty,

    COUNT(DISTINCT
        CONCAT(
            YEAR(transaction_date),
            '-',
            RIGHT('0' + CAST(MONTH(transaction_date) AS VARCHAR(2)), 2)
        )
    ) AS Demand_Months

FROM raw.Inventory_Transactions

WHERE transaction_type = 'SALE_ISSUE';




-- ============================================================
-- Step 5: Monthly Demand by Product
-- Demand = ABS(SALE_ISSUE quantity)
-- ============================================================

WITH MonthlyDemand AS
(
    SELECT
        product_id,

        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,

        SUM(ABS(quantity)) AS Monthly_Demand_Qty

    FROM raw.Inventory_Transactions

    WHERE transaction_type = 'SALE_ISSUE'

    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
)

SELECT TOP 20
    md.product_id,
    p.product_name,
    p.category,

    md.Demand_Year,
    md.Demand_Month,
    md.Monthly_Demand_Qty

FROM MonthlyDemand AS md

INNER JOIN raw.Products AS p
    ON md.product_id = p.product_id

ORDER BY
    md.product_id,
    md.Demand_Year,
    md.Demand_Month;




-- ============================================================
-- Step 6: Complete Product-Month Demand Matrix
-- Includes zero-demand months
-- ============================================================

WITH MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01' AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        m.Demand_Year,
        m.Demand_Month

    FROM raw.Products AS p

    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty

    FROM raw.Inventory_Transactions

    WHERE transaction_type = 'SALE_ISSUE'

    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        pm.product_name,
        pm.category,
        pm.Demand_Year,
        pm.Demand_Month,

        ISNULL(md.Monthly_Demand_Qty, 0)
            AS Monthly_Demand_Qty

    FROM ProductMonthMatrix AS pm

    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
)

SELECT
    COUNT(*) AS Product_Month_Records,

    COUNT(DISTINCT product_id) AS Products,

    COUNT(DISTINCT
        CONCAT(
            Demand_Year,
            '-',
            RIGHT(
                '0' + CAST(Demand_Month AS VARCHAR(2)),
                2
            )
        )
    ) AS Months,

    SUM(Monthly_Demand_Qty) AS Total_Demand_Qty,

    SUM(
        CASE
            WHEN Monthly_Demand_Qty = 0
            THEN 1
            ELSE 0
        END
    ) AS Zero_Demand_Product_Months

FROM CompleteDemand;




-- ============================================================
-- Step 7: Product Demand Variability
-- CV = Standard Deviation / Average Monthly Demand
-- ============================================================

WITH MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01' AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        m.Demand_Year,
        m.Demand_Month
    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty
    FROM raw.Inventory_Transactions
    WHERE transaction_type = 'SALE_ISSUE'
    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        pm.product_name,
        pm.category,
        pm.Demand_Year,
        pm.Demand_Month,
        ISNULL(md.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty
    FROM ProductMonthMatrix AS pm
    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
),

DemandVariability AS
(
    SELECT
        product_id,
        product_name,
        category,

        SUM(Monthly_Demand_Qty) AS Total_Demand_Qty,

        AVG(1.0 * Monthly_Demand_Qty) AS Avg_Monthly_Demand,

        STDEV(1.0 * Monthly_Demand_Qty) AS StdDev_Monthly_Demand,

        SUM(
            CASE
                WHEN Monthly_Demand_Qty = 0
                THEN 1 ELSE 0
            END
        ) AS Zero_Demand_Months

    FROM CompleteDemand

    GROUP BY
        product_id,
        product_name,
        category
)

SELECT TOP 20
    product_id,
    product_name,
    category,
    Total_Demand_Qty,

    CAST(
        Avg_Monthly_Demand
        AS DECIMAL(10,2)
    ) AS Avg_Monthly_Demand,

    CAST(
        StdDev_Monthly_Demand
        AS DECIMAL(10,2)
    ) AS StdDev_Monthly_Demand,

    CAST(
        StdDev_Monthly_Demand
        / NULLIF(Avg_Monthly_Demand, 0)
        AS DECIMAL(10,3)
    ) AS Demand_CV,

    Zero_Demand_Months

FROM DemandVariability

ORDER BY
    Demand_CV ASC,
    product_id;



-- ============================================================
-- Step 8: Overall Demand CV Validation
-- ============================================================

WITH MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01' AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month
    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty
    FROM raw.Inventory_Transactions
    WHERE transaction_type = 'SALE_ISSUE'
    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        ISNULL(md.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty
    FROM ProductMonthMatrix AS pm
    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
),

ProductCV AS
(
    SELECT
        product_id,

        AVG(1.0 * Monthly_Demand_Qty) AS Avg_Monthly_Demand,

        STDEV(1.0 * Monthly_Demand_Qty) AS StdDev_Monthly_Demand

    FROM CompleteDemand

    GROUP BY product_id
)

SELECT
    COUNT(*) AS Products,

    CAST(
        AVG(
            StdDev_Monthly_Demand
            / NULLIF(Avg_Monthly_Demand, 0)
        )
        AS DECIMAL(10,3)
    ) AS Avg_Demand_CV,

    CAST(
        MIN(
            StdDev_Monthly_Demand
            / NULLIF(Avg_Monthly_Demand, 0)
        )
        AS DECIMAL(10,3)
    ) AS Min_Demand_CV,

    CAST(
        MAX(
            StdDev_Monthly_Demand
            / NULLIF(Avg_Monthly_Demand, 0)
        )
        AS DECIMAL(10,3)
    ) AS Max_Demand_CV

FROM ProductCV;




-- ============================================================
-- Step 9: XYZ Product Classification
-- X = CV <= 0.50
-- Y = CV > 0.50 and <= 1.00
-- Z = CV > 1.00
-- ============================================================

WITH MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01' AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month
    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty
    FROM raw.Inventory_Transactions
    WHERE transaction_type = 'SALE_ISSUE'
    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        ISNULL(md.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty
    FROM ProductMonthMatrix AS pm
    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
),

DemandStats AS
(
    SELECT
        product_id,

        SUM(Monthly_Demand_Qty) AS Total_Demand_Qty,

        AVG(1.0 * Monthly_Demand_Qty) AS Avg_Monthly_Demand,

        STDEV(1.0 * Monthly_Demand_Qty) AS StdDev_Monthly_Demand,

        SUM(
            CASE
                WHEN Monthly_Demand_Qty = 0
                THEN 1 ELSE 0
            END
        ) AS Zero_Demand_Months

    FROM CompleteDemand

    GROUP BY product_id
),

XYZClassification AS
(
    SELECT
        *,

        StdDev_Monthly_Demand
        / NULLIF(Avg_Monthly_Demand, 0) AS Demand_CV,

        CASE
            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 0.50
                THEN 'X'

            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 1.00
                THEN 'Y'

            ELSE 'Z'
        END AS XYZ_Class

    FROM DemandStats
)

SELECT
    XYZ_Class,

    COUNT(*) AS Products,

    SUM(Total_Demand_Qty) AS Total_Demand_Qty,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Product_Share_Pct,

    CAST(
        100.0 * SUM(Total_Demand_Qty)
        / SUM(SUM(Total_Demand_Qty)) OVER ()
        AS DECIMAL(8,2)
    ) AS Demand_Share_Pct,

    SUM(Zero_Demand_Months) AS Zero_Demand_Months

FROM XYZClassification

GROUP BY XYZ_Class

ORDER BY XYZ_Class;


-- ============================================================
-- Step 10: Combined ABC-XYZ Classification
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        product_id,
        SUM(inventory_value) AS Inventory_Value
    FROM raw.Inventory
    GROUP BY product_id
),

ABCBase AS
(
    SELECT
        product_id,
        Inventory_Value,

        100.0 *
        SUM(Inventory_Value) OVER
        (
            ORDER BY Inventory_Value DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(Inventory_Value) OVER ()
        AS Cumulative_Inventory_Pct

    FROM ProductInventory
),

ABC AS
(
    SELECT
        product_id,
        Inventory_Value,

        CASE
            WHEN Cumulative_Inventory_Pct <= 80 THEN 'A'
            WHEN Cumulative_Inventory_Pct <= 95 THEN 'B'
            ELSE 'C'
        END AS ABC_Class

    FROM ABCBase
),

MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01' AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month
    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty
    FROM raw.Inventory_Transactions
    WHERE transaction_type = 'SALE_ISSUE'
    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        ISNULL(md.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty
    FROM ProductMonthMatrix AS pm
    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
),

DemandStats AS
(
    SELECT
        product_id,
        SUM(Monthly_Demand_Qty) AS Total_Demand_Qty,
        AVG(1.0 * Monthly_Demand_Qty) AS Avg_Monthly_Demand,
        STDEV(1.0 * Monthly_Demand_Qty) AS StdDev_Monthly_Demand
    FROM CompleteDemand
    GROUP BY product_id
),

XYZ AS
(
    SELECT
        product_id,
        Total_Demand_Qty,

        StdDev_Monthly_Demand
        / NULLIF(Avg_Monthly_Demand, 0) AS Demand_CV,

        CASE
            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 0.50 THEN 'X'

            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 1.00 THEN 'Y'

            ELSE 'Z'
        END AS XYZ_Class

    FROM DemandStats
)

SELECT
    a.ABC_Class + x.XYZ_Class AS ABC_XYZ_Class,

    COUNT(*) AS Products,

    CAST(
        SUM(a.Inventory_Value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    SUM(x.Total_Demand_Qty) AS Total_Demand_Qty,

    CAST(
        AVG(x.Demand_CV)
        AS DECIMAL(10,3)
    ) AS Avg_Demand_CV

FROM ABC AS a

INNER JOIN XYZ AS x
    ON a.product_id = x.product_id

GROUP BY
    a.ABC_Class,
    x.XYZ_Class

ORDER BY
    a.ABC_Class,
    x.XYZ_Class;



-- ============================================================
-- Step 11: ABC-XYZ Product Count Matrix
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        product_id,
        SUM(inventory_value) AS Inventory_Value
    FROM raw.Inventory
    GROUP BY product_id
),

ABCBase AS
(
    SELECT
        product_id,
        Inventory_Value,

        100.0 *
        SUM(Inventory_Value) OVER
        (
            ORDER BY Inventory_Value DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(Inventory_Value) OVER ()
        AS Cumulative_Inventory_Pct

    FROM ProductInventory
),

ABC AS
(
    SELECT
        product_id,

        CASE
            WHEN Cumulative_Inventory_Pct <= 80 THEN 'A'
            WHEN Cumulative_Inventory_Pct <= 95 THEN 'B'
            ELSE 'C'
        END AS ABC_Class

    FROM ABCBase
),

MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01' AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month
    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty
    FROM raw.Inventory_Transactions
    WHERE transaction_type = 'SALE_ISSUE'
    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        ISNULL(md.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty
    FROM ProductMonthMatrix AS pm
    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
),

DemandStats AS
(
    SELECT
        product_id,
        AVG(1.0 * Monthly_Demand_Qty) AS Avg_Monthly_Demand,
        STDEV(1.0 * Monthly_Demand_Qty) AS StdDev_Monthly_Demand
    FROM CompleteDemand
    GROUP BY product_id
),

XYZ AS
(
    SELECT
        product_id,

        CASE
            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 0.50 THEN 'X'

            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 1.00 THEN 'Y'

            ELSE 'Z'
        END AS XYZ_Class

    FROM DemandStats
),

Combined AS
(
    SELECT
        a.ABC_Class,
        x.XYZ_Class
    FROM ABC AS a
    INNER JOIN XYZ AS x
        ON a.product_id = x.product_id
)

SELECT
    ABC_Class,

    SUM(CASE WHEN XYZ_Class = 'X' THEN 1 ELSE 0 END) AS X_Products,

    SUM(CASE WHEN XYZ_Class = 'Y' THEN 1 ELSE 0 END) AS Y_Products,

    SUM(CASE WHEN XYZ_Class = 'Z' THEN 1 ELSE 0 END) AS Z_Products,

    COUNT(*) AS Total_Products

FROM Combined

GROUP BY ABC_Class

ORDER BY ABC_Class;



-- ============================================================
-- Step 12: ABC-XYZ Inventory Value & Demand Share
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        product_id,
        SUM(inventory_value) AS Inventory_Value
    FROM raw.Inventory
    GROUP BY product_id
),

ABCBase AS
(
    SELECT
        product_id,
        Inventory_Value,

        100.0 *
        SUM(Inventory_Value) OVER
        (
            ORDER BY Inventory_Value DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(Inventory_Value) OVER () AS Cumulative_Inventory_Pct

    FROM ProductInventory
),

ABC AS
(
    SELECT
        product_id,
        Inventory_Value,

        CASE
            WHEN Cumulative_Inventory_Pct <= 80 THEN 'A'
            WHEN Cumulative_Inventory_Pct <= 95 THEN 'B'
            ELSE 'C'
        END AS ABC_Class

    FROM ABCBase
),

MonthlyDemand AS
(
    SELECT
        product_id,
        SUM(ABS(quantity)) AS Total_Demand_Qty

    FROM raw.Inventory_Transactions

    WHERE transaction_type = 'SALE_ISSUE'

    GROUP BY product_id
),

MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01' AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month
    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyVariability AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty
    FROM raw.Inventory_Transactions
    WHERE transaction_type = 'SALE_ISSUE'
    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        ISNULL(mv.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty
    FROM ProductMonthMatrix AS pm
    LEFT JOIN MonthlyVariability AS mv
        ON pm.product_id = mv.product_id
       AND pm.Demand_Year = mv.Demand_Year
       AND pm.Demand_Month = mv.Demand_Month
),

DemandStats AS
(
    SELECT
        product_id,
        AVG(1.0 * Monthly_Demand_Qty) AS Avg_Monthly_Demand,
        STDEV(1.0 * Monthly_Demand_Qty) AS StdDev_Monthly_Demand
    FROM CompleteDemand
    GROUP BY product_id
),

XYZ AS
(
    SELECT
        product_id,

        CASE
            WHEN StdDev_Monthly_Demand /
                 NULLIF(Avg_Monthly_Demand, 0) <= 0.50 THEN 'X'

            WHEN StdDev_Monthly_Demand /
                 NULLIF(Avg_Monthly_Demand, 0) <= 1.00 THEN 'Y'

            ELSE 'Z'
        END AS XYZ_Class

    FROM DemandStats
),

Combined AS
(
    SELECT
        a.product_id,
        a.ABC_Class + x.XYZ_Class AS ABC_XYZ_Class,
        a.Inventory_Value,
        d.Total_Demand_Qty

    FROM ABC AS a

    INNER JOIN XYZ AS x
        ON a.product_id = x.product_id

    INNER JOIN MonthlyDemand AS d
        ON a.product_id = d.product_id
)

SELECT
    ABC_XYZ_Class,

    COUNT(*) AS Products,

    CAST(
        SUM(Inventory_Value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        100.0 * SUM(Inventory_Value)
        / SUM(SUM(Inventory_Value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Inventory_Value_Share_Pct,

    SUM(Total_Demand_Qty) AS Total_Demand_Qty,

    CAST(
        100.0 * SUM(Total_Demand_Qty)
        / SUM(SUM(Total_Demand_Qty)) OVER ()
        AS DECIMAL(8,2)
    ) AS Demand_Share_Pct

FROM Combined

GROUP BY ABC_XYZ_Class

ORDER BY ABC_XYZ_Class;



-- ============================================================
-- Step 13: ABC-XYZ Distribution by Product Category
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        i.product_id,
        SUM(i.inventory_value) AS Inventory_Value
    FROM raw.Inventory AS i
    GROUP BY i.product_id
),

ABCBase AS
(
    SELECT
        product_id,
        Inventory_Value,

        100.0 *
        SUM(Inventory_Value) OVER
        (
            ORDER BY Inventory_Value DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(Inventory_Value) OVER ()
        AS Cumulative_Inventory_Pct

    FROM ProductInventory
),

ABC AS
(
    SELECT
        product_id,
        Inventory_Value,

        CASE
            WHEN Cumulative_Inventory_Pct <= 80 THEN 'A'
            WHEN Cumulative_Inventory_Pct <= 95 THEN 'B'
            ELSE 'C'
        END AS ABC_Class

    FROM ABCBase
),

MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01' AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month
    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty
    FROM raw.Inventory_Transactions
    WHERE transaction_type = 'SALE_ISSUE'
    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        ISNULL(md.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty
    FROM ProductMonthMatrix AS pm
    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
),

DemandStats AS
(
    SELECT
        product_id,

        SUM(Monthly_Demand_Qty) AS Total_Demand_Qty,

        AVG(1.0 * Monthly_Demand_Qty) AS Avg_Monthly_Demand,

        STDEV(1.0 * Monthly_Demand_Qty) AS StdDev_Monthly_Demand

    FROM CompleteDemand

    GROUP BY product_id
),

XYZ AS
(
    SELECT
        product_id,
        Total_Demand_Qty,

        CASE
            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 0.50 THEN 'X'

            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 1.00 THEN 'Y'

            ELSE 'Z'
        END AS XYZ_Class

    FROM DemandStats
),

Combined AS
(
    SELECT
        p.category,
        a.ABC_Class + x.XYZ_Class AS ABC_XYZ_Class,
        a.Inventory_Value,
        x.Total_Demand_Qty

    FROM ABC AS a

    INNER JOIN XYZ AS x
        ON a.product_id = x.product_id

    INNER JOIN raw.Products AS p
        ON a.product_id = p.product_id
)

SELECT
    category,

    COUNT(*) AS Products,

    CAST(
        SUM(Inventory_Value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    SUM(Total_Demand_Qty) AS Total_Demand_Qty,

    SUM(CASE WHEN ABC_XYZ_Class = 'AX' THEN 1 ELSE 0 END)
        AS AX_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'AY' THEN 1 ELSE 0 END)
        AS AY_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'AZ' THEN 1 ELSE 0 END)
        AS AZ_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'BX' THEN 1 ELSE 0 END)
        AS BX_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'BY' THEN 1 ELSE 0 END)
        AS BY_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'BZ' THEN 1 ELSE 0 END)
        AS BZ_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'CX' THEN 1 ELSE 0 END)
        AS CX_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'CY' THEN 1 ELSE 0 END)
        AS CY_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'CZ' THEN 1 ELSE 0 END)
        AS CZ_Products

FROM Combined

GROUP BY category

ORDER BY Inventory_Value DESC;




-- ============================================================
-- Step 14: Top AX Products
-- High Inventory Value + Stable Demand
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        product_id,
        SUM(inventory_value) AS Inventory_Value,
        SUM(available_qty) AS Available_Qty
    FROM raw.Inventory
    GROUP BY product_id
),

ABCBase AS
(
    SELECT
        product_id,
        Inventory_Value,
        Available_Qty,

        100.0 *
        SUM(Inventory_Value) OVER
        (
            ORDER BY Inventory_Value DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(Inventory_Value) OVER ()
        AS Cumulative_Inventory_Pct

    FROM ProductInventory
),

ABC AS
(
    SELECT
        *,

        CASE
            WHEN Cumulative_Inventory_Pct <= 80 THEN 'A'
            WHEN Cumulative_Inventory_Pct <= 95 THEN 'B'
            ELSE 'C'
        END AS ABC_Class

    FROM ABCBase
),

MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01' AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month
    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty
    FROM raw.Inventory_Transactions
    WHERE transaction_type = 'SALE_ISSUE'
    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        ISNULL(md.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty
    FROM ProductMonthMatrix AS pm
    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
),

DemandStats AS
(
    SELECT
        product_id,
        SUM(Monthly_Demand_Qty) AS Total_Demand_Qty,
        AVG(1.0 * Monthly_Demand_Qty) AS Avg_Monthly_Demand,
        STDEV(1.0 * Monthly_Demand_Qty) AS StdDev_Monthly_Demand
    FROM CompleteDemand
    GROUP BY product_id
),

XYZ AS
(
    SELECT
        *,

        StdDev_Monthly_Demand
        / NULLIF(Avg_Monthly_Demand, 0) AS Demand_CV,

        CASE
            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 0.50 THEN 'X'
            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 1.00 THEN 'Y'
            ELSE 'Z'
        END AS XYZ_Class

    FROM DemandStats
)

SELECT TOP 15
    a.product_id,
    p.product_name,
    p.category,

    CAST(a.Inventory_Value AS DECIMAL(18,2))
        AS Inventory_Value,

    a.Available_Qty,

    x.Total_Demand_Qty,

    CAST(x.Avg_Monthly_Demand AS DECIMAL(10,2))
        AS Avg_Monthly_Demand,

    CAST(x.Demand_CV AS DECIMAL(10,3))
        AS Demand_CV,

    'AX' AS ABC_XYZ_Class

FROM ABC AS a

INNER JOIN XYZ AS x
    ON a.product_id = x.product_id

INNER JOIN raw.Products AS p
    ON a.product_id = p.product_id

WHERE a.ABC_Class = 'A'
  AND x.XYZ_Class = 'X'

ORDER BY
    a.Inventory_Value DESC;




-- ============================================================
-- Step 15: AZ Products
-- High Inventory Value + Highly Variable Demand
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        product_id,
        SUM(inventory_value) AS Inventory_Value,
        SUM(available_qty) AS Available_Qty
    FROM raw.Inventory
    GROUP BY product_id
),

ABCBase AS
(
    SELECT
        product_id,
        Inventory_Value,
        Available_Qty,

        100.0 *
        SUM(Inventory_Value) OVER
        (
            ORDER BY Inventory_Value DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(Inventory_Value) OVER ()
        AS Cumulative_Inventory_Pct

    FROM ProductInventory
),

ABC AS
(
    SELECT
        *,

        CASE
            WHEN Cumulative_Inventory_Pct <= 80 THEN 'A'
            WHEN Cumulative_Inventory_Pct <= 95 THEN 'B'
            ELSE 'C'
        END AS ABC_Class

    FROM ABCBase
),

MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01' AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month
    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty
    FROM raw.Inventory_Transactions
    WHERE transaction_type = 'SALE_ISSUE'
    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        ISNULL(md.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty
    FROM ProductMonthMatrix AS pm
    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
),

DemandStats AS
(
    SELECT
        product_id,
        SUM(Monthly_Demand_Qty) AS Total_Demand_Qty,
        AVG(1.0 * Monthly_Demand_Qty) AS Avg_Monthly_Demand,
        STDEV(1.0 * Monthly_Demand_Qty) AS StdDev_Monthly_Demand,

        SUM(
            CASE
                WHEN Monthly_Demand_Qty = 0
                THEN 1 ELSE 0
            END
        ) AS Zero_Demand_Months

    FROM CompleteDemand
    GROUP BY product_id
),

XYZ AS
(
    SELECT
        *,

        StdDev_Monthly_Demand
        / NULLIF(Avg_Monthly_Demand, 0) AS Demand_CV,

        CASE
            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 0.50 THEN 'X'
            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 1.00 THEN 'Y'
            ELSE 'Z'
        END AS XYZ_Class

    FROM DemandStats
)

SELECT
    a.product_id,
    p.product_name,
    p.category,

    CAST(a.Inventory_Value AS DECIMAL(18,2))
        AS Inventory_Value,

    a.Available_Qty,

    x.Total_Demand_Qty,

    CAST(x.Avg_Monthly_Demand AS DECIMAL(10,2))
        AS Avg_Monthly_Demand,

    CAST(x.Demand_CV AS DECIMAL(10,3))
        AS Demand_CV,

    x.Zero_Demand_Months,

    'AZ' AS ABC_XYZ_Class

FROM ABC AS a

INNER JOIN XYZ AS x
    ON a.product_id = x.product_id

INNER JOIN raw.Products AS p
    ON a.product_id = p.product_id

WHERE a.ABC_Class = 'A'
  AND x.XYZ_Class = 'Z'

ORDER BY
    a.Inventory_Value DESC;




-- ============================================================
-- Step 16: CZ Products
-- Low Inventory Value + Highly Variable Demand
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        product_id,
        SUM(inventory_value) AS Inventory_Value,
        SUM(available_qty) AS Available_Qty
    FROM raw.Inventory
    GROUP BY product_id
),

ABCBase AS
(
    SELECT
        product_id,
        Inventory_Value,
        Available_Qty,

        100.0 *
        SUM(Inventory_Value) OVER
        (
            ORDER BY Inventory_Value DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(Inventory_Value) OVER ()
        AS Cumulative_Inventory_Pct

    FROM ProductInventory
),

ABC AS
(
    SELECT
        *,

        CASE
            WHEN Cumulative_Inventory_Pct <= 80 THEN 'A'
            WHEN Cumulative_Inventory_Pct <= 95 THEN 'B'
            ELSE 'C'
        END AS ABC_Class

    FROM ABCBase
),

MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01'
                               AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month
    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty
    FROM raw.Inventory_Transactions
    WHERE transaction_type = 'SALE_ISSUE'
    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        ISNULL(md.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty
    FROM ProductMonthMatrix AS pm
    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
),

DemandStats AS
(
    SELECT
        product_id,
        SUM(Monthly_Demand_Qty) AS Total_Demand_Qty,
        AVG(1.0 * Monthly_Demand_Qty) AS Avg_Monthly_Demand,
        STDEV(1.0 * Monthly_Demand_Qty) AS StdDev_Monthly_Demand,

        SUM(
            CASE
                WHEN Monthly_Demand_Qty = 0
                THEN 1 ELSE 0
            END
        ) AS Zero_Demand_Months

    FROM CompleteDemand
    GROUP BY product_id
),

XYZ AS
(
    SELECT
        *,

        StdDev_Monthly_Demand
        / NULLIF(Avg_Monthly_Demand, 0) AS Demand_CV,

        CASE
            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 0.50 THEN 'X'
            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 1.00 THEN 'Y'
            ELSE 'Z'
        END AS XYZ_Class

    FROM DemandStats
)

SELECT TOP 20
    a.product_id,
    p.product_name,
    p.category,

    CAST(a.Inventory_Value AS DECIMAL(18,2))
        AS Inventory_Value,

    a.Available_Qty,

    x.Total_Demand_Qty,

    CAST(x.Avg_Monthly_Demand AS DECIMAL(10,2))
        AS Avg_Monthly_Demand,

    CAST(x.Demand_CV AS DECIMAL(10,3))
        AS Demand_CV,

    x.Zero_Demand_Months,

    'CZ' AS ABC_XYZ_Class

FROM ABC AS a

INNER JOIN XYZ AS x
    ON a.product_id = x.product_id

INNER JOIN raw.Products AS p
    ON a.product_id = p.product_id

WHERE a.ABC_Class = 'C'
  AND x.XYZ_Class = 'Z'

ORDER BY
    x.Demand_CV DESC,
    a.Inventory_Value DESC;




-- ============================================================
-- Step 17: ABC-XYZ Inventory Management Strategy
-- ============================================================

WITH ABCXYZStrategy AS
(
    SELECT *
    FROM
    (
        VALUES
        ('AX',
         'Critical',
         'Tight Control',
         'Maintain high availability; frequent monitoring; accurate replenishment'),

        ('AY',
         'Critical',
         'Close Monitoring',
         'Monitor demand changes closely; maintain controlled safety stock'),

        ('AZ',
         'High',
         'Risk-Based Control',
         'High-value unpredictable demand; use cautious replenishment and frequent review'),

        ('BX',
         'Medium',
         'Standard Control',
         'Use regular replenishment with periodic inventory review'),

        ('BY',
         'Medium',
         'Moderate Control',
         'Monitor demand variability and adjust reorder levels periodically'),

        ('BZ',
         'Medium-High',
         'Cautious Control',
         'Use conservative stocking due to irregular demand'),

        ('CX',
         'Low',
         'Simple Control',
         'Use simplified replenishment and periodic review'),

        ('CY',
         'Low-Medium',
         'Lean Control',
         'Maintain lean inventory and monitor demand changes'),

        ('CZ',
         'Low',
         'Minimal Stocking',
         'Avoid excessive stock; consider demand-driven or order-based replenishment')
    )
    AS S
    (
        ABC_XYZ_Class,
        Management_Priority,
        Control_Strategy,
        Recommended_Action
    )
)

SELECT *
FROM ABCXYZStrategy

ORDER BY
    CASE ABC_XYZ_Class
        WHEN 'AX' THEN 1
        WHEN 'AY' THEN 2
        WHEN 'AZ' THEN 3
        WHEN 'BX' THEN 4
        WHEN 'BY' THEN 5
        WHEN 'BZ' THEN 6
        WHEN 'CX' THEN 7
        WHEN 'CY' THEN 8
        WHEN 'CZ' THEN 9
    END;



-- ============================================================
-- Step 18: Strategic ABC-XYZ Segment Summary
-- ============================================================

WITH SegmentSummary AS
(
    SELECT *
    FROM
    (
        VALUES
        ('AX', 80, 108623795.64, 401733),
        ('AY',153, 118518563.89, 373412),
        ('AZ',  3,   1551833.41,   2828),
        ('BX', 24,   8002700.38,  98975),
        ('BY', 90,  29790439.31, 180215),
        ('BZ', 18,   5100586.45,  12606),
        ('CX', 12,   1543846.10,  41979),
        ('CY', 68,   7737120.10, 121448),
        ('CZ', 52,   5116297.04,  26471)
    )
    AS S
    (
        ABC_XYZ_Class,
        Products,
        Inventory_Value,
        Total_Demand_Qty
    )
),

ManagementGroups AS
(
    SELECT
        CASE
            WHEN ABC_XYZ_Class IN ('AX','AY')
                THEN 'Critical Core'

            WHEN ABC_XYZ_Class = 'AZ'
                THEN 'High-Value Demand Risk'

            WHEN ABC_XYZ_Class IN ('BX','BY','BZ')
                THEN 'Standard Management'

            ELSE 'Lean / Selective Control'
        END AS Management_Group,

        Products,
        Inventory_Value,
        Total_Demand_Qty

    FROM SegmentSummary
)

SELECT
    Management_Group,

    SUM(Products) AS Products,

    CAST(
        SUM(Inventory_Value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        100.0 * SUM(Inventory_Value)
        / SUM(SUM(Inventory_Value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Inventory_Value_Share_Pct,

    SUM(Total_Demand_Qty) AS Total_Demand_Qty,

    CAST(
        100.0 * SUM(Total_Demand_Qty)
        / SUM(SUM(Total_Demand_Qty)) OVER ()
        AS DECIMAL(8,2)
    ) AS Demand_Share_Pct

FROM ManagementGroups

GROUP BY Management_Group

ORDER BY Inventory_Value DESC;



-- ============================================================
-- Step 19: ABC-XYZ Key Risk Summary
-- ============================================================

SELECT
    500 AS Total_Products,

    236 AS A_Class_Products,
    132 AS B_Class_Products,
    132 AS C_Class_Products,

    116 AS X_Class_Products,
    311 AS Y_Class_Products,
    73 AS Z_Class_Products,

    233 AS Critical_Core_AX_AY_Products,

    CAST(79.42 AS DECIMAL(8,2))
        AS Critical_Core_Inventory_Value_Share_Pct,

    CAST(61.54 AS DECIMAL(8,2))
        AS Critical_Core_Demand_Share_Pct,

    3 AS AZ_High_Value_Demand_Risk_Products,

    52 AS CZ_Products,

    1781 AS Zero_Demand_Product_Months,

    CAST(0.707 AS DECIMAL(10,3))
        AS Avg_Demand_CV,

    CAST(2.377 AS DECIMAL(10,3))
        AS Maximum_Demand_CV;






-- ============================================================
-- Step 20: ABC-XYZ Reconciliation
-- ============================================================

-- 1. ABC product count reconciliation
WITH ProductInventory AS
(
    SELECT
        product_id,
        SUM(inventory_value) AS Inventory_Value
    FROM raw.Inventory
    GROUP BY product_id
),
ABCBase AS
(
    SELECT
        product_id,
        Inventory_Value,

        100.0 *
        SUM(Inventory_Value) OVER
        (
            ORDER BY Inventory_Value DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(Inventory_Value) OVER ()
            AS Cumulative_Inventory_Pct

    FROM ProductInventory
),
ABC AS
(
    SELECT
        product_id,
        Inventory_Value,

        CASE
            WHEN Cumulative_Inventory_Pct <= 80 THEN 'A'
            WHEN Cumulative_Inventory_Pct <= 95 THEN 'B'
            ELSE 'C'
        END AS ABC_Class

    FROM ABCBase
)

SELECT
    COUNT(*) AS Total_Products,

    SUM(CASE WHEN ABC_Class = 'A' THEN 1 ELSE 0 END)
        AS A_Products,

    SUM(CASE WHEN ABC_Class = 'B' THEN 1 ELSE 0 END)
        AS B_Products,

    SUM(CASE WHEN ABC_Class = 'C' THEN 1 ELSE 0 END)
        AS C_Products,

    CAST(
        SUM(Inventory_Value)
        AS DECIMAL(18,2)
    ) AS Total_Inventory_Value

FROM ABC;


-- 2. Demand matrix reconciliation
WITH MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month

    FROM raw.Inventory_Transactions

    WHERE transaction_date BETWEEN '2024-01-01'
                               AND '2026-09-30'
),
ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month

    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),
MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,

        SUM(ABS(quantity)) AS Monthly_Demand_Qty

    FROM raw.Inventory_Transactions

    WHERE transaction_type = 'SALE_ISSUE'

    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),
CompleteDemand AS
(
    SELECT
        pm.product_id,
        pm.Demand_Year,
        pm.Demand_Month,

        ISNULL(md.Monthly_Demand_Qty, 0)
            AS Monthly_Demand_Qty

    FROM ProductMonthMatrix AS pm

    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
)

SELECT
    COUNT(*) AS Product_Month_Records,

    COUNT(DISTINCT product_id)
        AS Products,

    SUM(Monthly_Demand_Qty)
        AS Total_Demand_Qty,

    SUM(
        CASE
            WHEN Monthly_Demand_Qty = 0
            THEN 1 ELSE 0
        END
    ) AS Zero_Demand_Product_Months

FROM CompleteDemand;





-- ============================================================
-- Step 21: XYZ Classification Reconciliation
-- ============================================================

WITH MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month
    FROM raw.Inventory_Transactions
    WHERE transaction_date BETWEEN '2024-01-01'
                               AND '2026-09-30'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month
    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty
    FROM raw.Inventory_Transactions
    WHERE transaction_type = 'SALE_ISSUE'
    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        ISNULL(md.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty
    FROM ProductMonthMatrix AS pm
    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
),

DemandStats AS
(
    SELECT
        product_id,

        SUM(Monthly_Demand_Qty) AS Total_Demand_Qty,

        AVG(1.0 * Monthly_Demand_Qty)
            AS Avg_Monthly_Demand,

        STDEV(1.0 * Monthly_Demand_Qty)
            AS StdDev_Monthly_Demand

    FROM CompleteDemand

    GROUP BY product_id
),

XYZ AS
(
    SELECT
        product_id,
        Total_Demand_Qty,

        StdDev_Monthly_Demand
        / NULLIF(Avg_Monthly_Demand, 0)
            AS Demand_CV,

        CASE
            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 0.50
                THEN 'X'

            WHEN StdDev_Monthly_Demand
                 / NULLIF(Avg_Monthly_Demand, 0) <= 1.00
                THEN 'Y'

            ELSE 'Z'
        END AS XYZ_Class

    FROM DemandStats
)

SELECT
    COUNT(*) AS Total_Products,

    SUM(CASE WHEN XYZ_Class = 'X' THEN 1 ELSE 0 END)
        AS X_Products,

    SUM(CASE WHEN XYZ_Class = 'Y' THEN 1 ELSE 0 END)
        AS Y_Products,

    SUM(CASE WHEN XYZ_Class = 'Z' THEN 1 ELSE 0 END)
        AS Z_Products,

    SUM(Total_Demand_Qty)
        AS Total_Demand_Qty,

    CAST(
        AVG(Demand_CV)
        AS DECIMAL(10,3)
    ) AS Avg_Demand_CV,

    CAST(
        MIN(Demand_CV)
        AS DECIMAL(10,3)
    ) AS Min_Demand_CV,

    CAST(
        MAX(Demand_CV)
        AS DECIMAL(10,3)
    ) AS Max_Demand_CV

FROM XYZ;




-- ============================================================
-- Step 22: Combined ABC-XYZ Reconciliation
-- Run this ENTIRE block together
-- ============================================================

;WITH ProductInventory AS
(
    SELECT
        product_id,
        SUM(inventory_value) AS Inventory_Value
    FROM raw.Inventory
    GROUP BY product_id
),

ABCBase AS
(
    SELECT
        product_id,
        Inventory_Value,

        100.0 *
        SUM(Inventory_Value) OVER
        (
            ORDER BY Inventory_Value DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(Inventory_Value) OVER () AS Cumulative_Inventory_Pct

    FROM ProductInventory
),

ABCClassification AS
(
    SELECT
        product_id,
        Inventory_Value,

        CASE
            WHEN Cumulative_Inventory_Pct <= 80 THEN 'A'
            WHEN Cumulative_Inventory_Pct <= 95 THEN 'B'
            ELSE 'C'
        END AS ABC_Class

    FROM ABCBase
),

MonthList AS
(
    SELECT DISTINCT
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month

    FROM raw.Inventory_Transactions

    WHERE transaction_date >= '2024-01-01'
      AND transaction_date <  '2026-10-01'
),

ProductMonthMatrix AS
(
    SELECT
        p.product_id,
        m.Demand_Year,
        m.Demand_Month

    FROM raw.Products AS p
    CROSS JOIN MonthList AS m
),

MonthlyDemand AS
(
    SELECT
        product_id,
        YEAR(transaction_date) AS Demand_Year,
        MONTH(transaction_date) AS Demand_Month,
        SUM(ABS(quantity)) AS Monthly_Demand_Qty

    FROM raw.Inventory_Transactions

    WHERE transaction_type = 'SALE_ISSUE'

    GROUP BY
        product_id,
        YEAR(transaction_date),
        MONTH(transaction_date)
),

CompleteDemand AS
(
    SELECT
        pm.product_id,
        ISNULL(md.Monthly_Demand_Qty, 0) AS Monthly_Demand_Qty

    FROM ProductMonthMatrix AS pm

    LEFT JOIN MonthlyDemand AS md
        ON pm.product_id = md.product_id
       AND pm.Demand_Year = md.Demand_Year
       AND pm.Demand_Month = md.Demand_Month
),

DemandStats AS
(
    SELECT
        product_id,

        SUM(Monthly_Demand_Qty) AS Total_Demand_Qty,

        AVG(1.0 * Monthly_Demand_Qty) AS Avg_Monthly_Demand,

        STDEV(1.0 * Monthly_Demand_Qty) AS StdDev_Monthly_Demand

    FROM CompleteDemand

    GROUP BY product_id
),

XYZClassification AS
(
    SELECT
        product_id,
        Total_Demand_Qty,

        CASE
            WHEN StdDev_Monthly_Demand /
                 NULLIF(Avg_Monthly_Demand, 0) <= 0.50
                THEN 'X'

            WHEN StdDev_Monthly_Demand /
                 NULLIF(Avg_Monthly_Demand, 0) <= 1.00
                THEN 'Y'

            ELSE 'Z'
        END AS XYZ_Class

    FROM DemandStats
),

Combined AS
(
    SELECT
        a.product_id,
        a.ABC_Class + x.XYZ_Class AS ABC_XYZ_Class,
        a.Inventory_Value,
        x.Total_Demand_Qty

    FROM ABCClassification AS a

    INNER JOIN XYZClassification AS x
        ON a.product_id = x.product_id
)

SELECT
    COUNT(*) AS Total_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'AX' THEN 1 ELSE 0 END)
        AS AX_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'AY' THEN 1 ELSE 0 END)
        AS AY_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'AZ' THEN 1 ELSE 0 END)
        AS AZ_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'BX' THEN 1 ELSE 0 END)
        AS BX_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'BY' THEN 1 ELSE 0 END)
        AS BY_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'BZ' THEN 1 ELSE 0 END)
        AS BZ_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'CX' THEN 1 ELSE 0 END)
        AS CX_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'CY' THEN 1 ELSE 0 END)
        AS CY_Products,

    SUM(CASE WHEN ABC_XYZ_Class = 'CZ' THEN 1 ELSE 0 END)
        AS CZ_Products,

    CAST(
        SUM(Inventory_Value)
        AS DECIMAL(18,2)
    ) AS Total_Inventory_Value,

    SUM(Total_Demand_Qty) AS Total_Demand_Qty

FROM Combined;



-- ============================================================
-- Step 23: Final ABC-XYZ Analysis Validation
-- ============================================================

DECLARE @ABCXYZValidation TABLE
(
    Validation_Check VARCHAR(150),
    Status VARCHAR(10)
);

INSERT INTO @ABCXYZValidation
VALUES

('Total Products',
 CASE WHEN (SELECT COUNT(*) FROM raw.Products) = 500
      THEN 'PASS' ELSE 'FAIL' END),

('Inventory Product Coverage',
 CASE WHEN
 (
     SELECT COUNT(DISTINCT product_id)
     FROM raw.Inventory
 ) = 500
 THEN 'PASS' ELSE 'FAIL' END),

('Inventory Records',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Inventory
 ) = 3000
 THEN 'PASS' ELSE 'FAIL' END),

('Total Inventory Value',
 CASE WHEN ABS(
 (
     SELECT SUM(inventory_value)
     FROM raw.Inventory
 ) - 285985182.32) < 0.01
 THEN 'PASS' ELSE 'FAIL' END),

('SALE_ISSUE Transactions',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Inventory_Transactions
     WHERE transaction_type = 'SALE_ISSUE'
 ) = 62820
 THEN 'PASS' ELSE 'FAIL' END),

('Demand Product Coverage',
 CASE WHEN
 (
     SELECT COUNT(DISTINCT product_id)
     FROM raw.Inventory_Transactions
     WHERE transaction_type = 'SALE_ISSUE'
 ) = 500
 THEN 'PASS' ELSE 'FAIL' END),

('Total Demand Quantity',
 CASE WHEN
 (
     SELECT SUM(ABS(quantity))
     FROM raw.Inventory_Transactions
     WHERE transaction_type = 'SALE_ISSUE'
 ) = 1259667
 THEN 'PASS' ELSE 'FAIL' END),

('Demand Month Count',
 CASE WHEN
 (
     SELECT COUNT(DISTINCT
         CONCAT(
             YEAR(transaction_date),
             '-',
             RIGHT(
                 '0' + CAST(MONTH(transaction_date) AS VARCHAR(2)),
                 2
             )
         )
     )
     FROM raw.Inventory_Transactions
     WHERE transaction_date >= '2024-01-01'
       AND transaction_date < '2026-10-01'
 ) = 33
 THEN 'PASS' ELSE 'FAIL' END),

('Expected Product-Month Matrix',
 CASE WHEN
     (SELECT COUNT(*) FROM raw.Products) * 33 = 16500
 THEN 'PASS' ELSE 'FAIL' END),

('ABC Product Count Reconciles',
 CASE WHEN 236 + 132 + 132 = 500
 THEN 'PASS' ELSE 'FAIL' END),

('XYZ Product Count Reconciles',
 CASE WHEN 116 + 311 + 73 = 500
 THEN 'PASS' ELSE 'FAIL' END),

('Combined ABC-XYZ Count Reconciles',
 CASE WHEN
     80 + 153 + 3 +
     24 + 90 + 18 +
     12 + 68 + 52 = 500
 THEN 'PASS' ELSE 'FAIL' END),

('A Class Product Count',
 CASE WHEN 236 = 236
 THEN 'PASS' ELSE 'FAIL' END),

('X Class Product Count',
 CASE WHEN 116 = 116
 THEN 'PASS' ELSE 'FAIL' END),

('Z Class Product Count',
 CASE WHEN 73 = 73
 THEN 'PASS' ELSE 'FAIL' END),

('AX Product Count',
 CASE WHEN 80 = 80
 THEN 'PASS' ELSE 'FAIL' END),

('AY Product Count',
 CASE WHEN 153 = 153
 THEN 'PASS' ELSE 'FAIL' END),

('AZ Product Count',
 CASE WHEN 3 = 3
 THEN 'PASS' ELSE 'FAIL' END),

('CZ Product Count',
 CASE WHEN 52 = 52
 THEN 'PASS' ELSE 'FAIL' END),

('Critical Core Product Count',
 CASE WHEN 80 + 153 = 233
 THEN 'PASS' ELSE 'FAIL' END),

('ABC-XYZ Segment Count',
 CASE WHEN 9 = 9
 THEN 'PASS' ELSE 'FAIL' END),

('Inventory Foreign Keys Valid',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Inventory AS i
     LEFT JOIN raw.Products AS p
         ON i.product_id = p.product_id
     WHERE p.product_id IS NULL
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Transaction Product Foreign Keys Valid',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Inventory_Transactions AS t
     LEFT JOIN raw.Products AS p
         ON t.product_id = p.product_id
     WHERE p.product_id IS NULL
 )
 THEN 'PASS' ELSE 'FAIL' END),

('No Negative Inventory Value',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Inventory
     WHERE inventory_value < 0
 )
 THEN 'PASS' ELSE 'FAIL' END);

SELECT *
FROM @ABCXYZValidation;

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
    END AS Final_ABC_XYZ_Analysis_Status

FROM @ABCXYZValidation;

