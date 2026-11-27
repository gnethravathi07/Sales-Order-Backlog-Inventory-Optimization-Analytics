-- ============================================================
-- SALES ORDER, BACKLOG & INVENTORY ANALYTICS
-- File: 06_Supplier_Procurement_Analysis.sql
-- Purpose: Analyze procurement performance, purchase orders,
--          supplier delivery reliability and procurement risk
-- ============================================================

USE Sales_Order_Backlog_Inventory_Analytics;
GO

-- ============================================================
-- Step 1: Procurement Source Data Validation
-- ============================================================

SELECT
    COUNT(*) AS Total_Purchase_Orders,

    COUNT(DISTINCT po_id) AS Unique_PO_IDs,

    COUNT(DISTINCT supplier_id) AS Unique_Suppliers,

    COUNT(DISTINCT product_id) AS Unique_Products,

    COUNT(DISTINCT warehouse_id) AS Unique_Warehouses,

    SUM(ordered_qty) AS Total_Ordered_Qty,

    SUM(received_qty) AS Total_Received_Qty,

    SUM(ordered_qty - received_qty) AS Outstanding_Qty,

    CAST(
        SUM(po_value)
        AS DECIMAL(18,2)
    ) AS Total_Procurement_Value,

    SUM(
        CASE
            WHEN actual_receipt_date IS NULL
            THEN 1 ELSE 0
        END
    ) AS Missing_Actual_Receipt_Date,

    SUM(
        CASE
            WHEN supplier_delay_days IS NULL
            THEN 1 ELSE 0
        END
    ) AS Missing_Supplier_Delay_Days

FROM raw.Purchase_Orders;



-- ============================================================
-- Step 2: Purchase Order Status Analysis
-- ============================================================

SELECT
    po_status,

    COUNT(*) AS Total_POs,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(received_qty) AS Received_Qty,

    SUM(ordered_qty - received_qty) AS Outstanding_Qty,

    CAST(
        SUM(po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS PO_Share_Pct,

    SUM(
        CASE
            WHEN actual_receipt_date IS NULL
            THEN 1 ELSE 0
        END
    ) AS Missing_Receipt_Dates,

    SUM(
        CASE
            WHEN supplier_delay_days IS NULL
            THEN 1 ELSE 0
        END
    ) AS Missing_Delay_Values

FROM raw.Purchase_Orders

GROUP BY
    po_status

ORDER BY
    Total_POs DESC;


-- ============================================================
-- Step 3: Overall Procurement Performance KPIs
-- ============================================================

SELECT
    COUNT(*) AS Total_POs,

    COUNT(DISTINCT supplier_id) AS Total_Suppliers,

    SUM(ordered_qty) AS Total_Ordered_Qty,

    SUM(received_qty) AS Total_Received_Qty,

    SUM(ordered_qty - received_qty) AS Outstanding_Qty,

    CAST(
        100.0 * SUM(received_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Receipt_Rate_Pct,

    CAST(
        SUM(po_value)
        AS DECIMAL(18,2)
    ) AS Total_Procurement_Value,

    CAST(
        AVG(po_value)
        AS DECIMAL(18,2)
    ) AS Avg_PO_Value

FROM raw.Purchase_Orders;



-- ============================================================
-- Step 4: Overall Supplier Delivery Performance
-- Excludes Open POs without actual receipt dates
-- ============================================================

SELECT
    COUNT(*) AS Evaluated_POs,

    SUM(
        CASE
            WHEN supplier_delay_days <= 0
            THEN 1 ELSE 0
        END
    ) AS On_Time_Or_Early_POs,

    SUM(
        CASE
            WHEN supplier_delay_days > 0
            THEN 1 ELSE 0
        END
    ) AS Delayed_POs,

    CAST(
        100.0 *
        SUM(CASE WHEN supplier_delay_days <= 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Supplier_On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(CASE WHEN supplier_delay_days > 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Supplier_Delay_Rate_Pct,

    CAST(
        AVG(1.0 * supplier_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Supplier_Delay_Days,

    MAX(supplier_delay_days) AS Max_Supplier_Delay_Days

FROM raw.Purchase_Orders

WHERE actual_receipt_date IS NOT NULL
  AND supplier_delay_days IS NOT NULL;



-- ============================================================
-- Step 5: Supplier Delay Severity Analysis
-- Delayed POs only
-- ============================================================

WITH DelaySeverity AS
(
    SELECT
        po_id,
        ordered_qty,
        received_qty,
        po_value,
        supplier_delay_days,

        CASE
            WHEN supplier_delay_days BETWEEN 1 AND 2
                THEN '1-2 Days Late'

            WHEN supplier_delay_days BETWEEN 3 AND 5
                THEN '3-5 Days Late'

            WHEN supplier_delay_days BETWEEN 6 AND 10
                THEN '6-10 Days Late'

            ELSE '11+ Days Late'
        END AS Delay_Severity,

        CASE
            WHEN supplier_delay_days BETWEEN 1 AND 2 THEN 1
            WHEN supplier_delay_days BETWEEN 3 AND 5 THEN 2
            WHEN supplier_delay_days BETWEEN 6 AND 10 THEN 3
            ELSE 4
        END AS Sort_Order

    FROM raw.Purchase_Orders

    WHERE supplier_delay_days > 0
)

SELECT
    Delay_Severity,

    COUNT(*) AS Delayed_POs,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Delayed_PO_Share_Pct,

    SUM(ordered_qty) AS Ordered_Qty,

    CAST(
        SUM(po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        AVG(1.0 * supplier_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    MAX(supplier_delay_days) AS Max_Delay_Days

FROM DelaySeverity

GROUP BY
    Delay_Severity,
    Sort_Order

ORDER BY
    Sort_Order;



-- ============================================================
-- Step 6: Supplier-Level Delivery Performance
-- Completed receipt POs only
-- ============================================================

SELECT
    s.supplier_id,
    s.supplier_name,
    s.supplier_region,
    s.preferred_supplier_flag,
    s.reliability_factor,

    COUNT(*) AS Evaluated_POs,

    CAST(
        SUM(po.po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days > 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Delay_Rate_Pct,

    CAST(
        AVG(1.0 * po.supplier_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    SUM(
        CASE
            WHEN po.supplier_delay_days >= 11
            THEN 1 ELSE 0
        END
    ) AS Severe_Delay_POs

FROM raw.Purchase_Orders AS po

INNER JOIN raw.Suppliers AS s
    ON po.supplier_id = s.supplier_id

WHERE po.actual_receipt_date IS NOT NULL
  AND po.supplier_delay_days IS NOT NULL

GROUP BY
    s.supplier_id,
    s.supplier_name,
    s.supplier_region,
    s.preferred_supplier_flag,
    s.reliability_factor

ORDER BY
    On_Time_Rate_Pct DESC;



-- ============================================================
-- Step 7: Bottom 10 Suppliers by On-Time Performance
-- Completed receipt POs only
-- ============================================================

SELECT TOP 10
    s.supplier_id,
    s.supplier_name,
    s.supplier_region,
    s.preferred_supplier_flag,
    s.reliability_factor,

    COUNT(*) AS Evaluated_POs,

    CAST(
        SUM(po.po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days > 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Delay_Rate_Pct,

    CAST(
        AVG(1.0 * po.supplier_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    SUM(
        CASE
            WHEN po.supplier_delay_days >= 11
            THEN 1 ELSE 0
        END
    ) AS Severe_Delay_POs

FROM raw.Purchase_Orders AS po

INNER JOIN raw.Suppliers AS s
    ON po.supplier_id = s.supplier_id

WHERE po.actual_receipt_date IS NOT NULL
  AND po.supplier_delay_days IS NOT NULL

GROUP BY
    s.supplier_id,
    s.supplier_name,
    s.supplier_region,
    s.preferred_supplier_flag,
    s.reliability_factor

ORDER BY
    On_Time_Rate_Pct ASC,
    Avg_Delay_Days DESC;



-- ============================================================
-- Step 8: Preferred vs Non-Preferred Supplier Performance
-- Completed receipt POs only
-- ============================================================

SELECT
    s.preferred_supplier_flag,

    CASE
        WHEN s.preferred_supplier_flag = 1
            THEN 'Preferred Supplier'
        ELSE 'Non-Preferred Supplier'
    END AS Supplier_Type,

    COUNT(DISTINCT s.supplier_id) AS Suppliers,

    COUNT(*) AS Evaluated_POs,

    CAST(
        SUM(po.po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days > 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Delay_Rate_Pct,

    CAST(
        AVG(1.0 * po.supplier_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    SUM(
        CASE
            WHEN po.supplier_delay_days >= 11
            THEN 1 ELSE 0
        END
    ) AS Severe_Delay_POs

FROM raw.Purchase_Orders AS po

INNER JOIN raw.Suppliers AS s
    ON po.supplier_id = s.supplier_id

WHERE po.actual_receipt_date IS NOT NULL
  AND po.supplier_delay_days IS NOT NULL

GROUP BY
    s.preferred_supplier_flag

ORDER BY
    s.preferred_supplier_flag DESC;


-- ============================================================
-- Step 9: Supplier Performance by Region
-- Completed receipt POs only
-- ============================================================

SELECT
    s.supplier_region,

    COUNT(DISTINCT s.supplier_id) AS Suppliers,

    COUNT(*) AS Evaluated_POs,

    CAST(
        SUM(po.po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days > 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Delay_Rate_Pct,

    CAST(
        AVG(1.0 * po.supplier_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    SUM(
        CASE
            WHEN po.supplier_delay_days >= 11
            THEN 1 ELSE 0
        END
    ) AS Severe_Delay_POs

FROM raw.Purchase_Orders AS po

INNER JOIN raw.Suppliers AS s
    ON po.supplier_id = s.supplier_id

WHERE po.actual_receipt_date IS NOT NULL
  AND po.supplier_delay_days IS NOT NULL

GROUP BY
    s.supplier_region

ORDER BY
    On_Time_Rate_Pct DESC;



-- ============================================================
-- Step 10: Procurement Performance by Product Category
-- Completed receipt POs only
-- ============================================================

SELECT
    p.category,

    COUNT(*) AS Evaluated_POs,

    COUNT(DISTINCT po.product_id) AS Products,

    SUM(po.ordered_qty) AS Ordered_Qty,

    SUM(po.received_qty) AS Received_Qty,

    CAST(
        SUM(po.po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        100.0 * SUM(po.po_value)
        / SUM(SUM(po.po_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Procurement_Value_Share_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        AVG(1.0 * po.supplier_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days

FROM raw.Purchase_Orders AS po

INNER JOIN raw.Products AS p
    ON po.product_id = p.product_id

WHERE po.actual_receipt_date IS NOT NULL
  AND po.supplier_delay_days IS NOT NULL

GROUP BY
    p.category

ORDER BY
    Procurement_Value DESC;


-- ============================================================
-- Step 11: Procurement Performance by Warehouse
-- Completed receipt POs only
-- ============================================================

SELECT
    w.warehouse_id,
    w.warehouse_name,

    COUNT(*) AS Evaluated_POs,

    SUM(po.ordered_qty) AS Ordered_Qty,

    SUM(po.received_qty) AS Received_Qty,

    CAST(
        SUM(po.po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        100.0 * SUM(po.received_qty)
        / NULLIF(SUM(po.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Receipt_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        AVG(1.0 * po.supplier_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    SUM(
        CASE
            WHEN po.supplier_delay_days >= 11
            THEN 1 ELSE 0
        END
    ) AS Severe_Delay_POs

FROM raw.Purchase_Orders AS po

INNER JOIN raw.Warehouses AS w
    ON po.warehouse_id = w.warehouse_id

WHERE po.actual_receipt_date IS NOT NULL
  AND po.supplier_delay_days IS NOT NULL

GROUP BY
    w.warehouse_id,
    w.warehouse_name

ORDER BY
    On_Time_Rate_Pct DESC;



-- ============================================================
-- Step 12: Monthly Procurement Trend
-- ============================================================

SELECT
    YEAR(po_date) AS PO_Year,

    MONTH(po_date) AS Month_No,

    DATENAME(MONTH, po_date) AS Month_Name,

    COUNT(*) AS Total_POs,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(received_qty) AS Received_Qty,

    CAST(
        SUM(po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        100.0 * SUM(received_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Receipt_Rate_Pct

FROM raw.Purchase_Orders

GROUP BY
    YEAR(po_date),
    MONTH(po_date),
    DATENAME(MONTH, po_date)

ORDER BY
    PO_Year,
    Month_No;



-- ============================================================
-- Step 13: Yearly Procurement Performance
-- ============================================================

SELECT
    YEAR(po_date) AS PO_Year,

    COUNT(*) AS Total_POs,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(received_qty) AS Received_Qty,

    SUM(ordered_qty - received_qty) AS Outstanding_Qty,

    CAST(
        SUM(po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        100.0 * SUM(received_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Receipt_Rate_Pct,

    COUNT(DISTINCT supplier_id) AS Active_Suppliers

FROM raw.Purchase_Orders

GROUP BY
    YEAR(po_date)

ORDER BY
    PO_Year;


-- ============================================================
-- Step 14: Comparable Jan-Sep Procurement Performance
-- ============================================================

SELECT
    YEAR(po_date) AS PO_Year,

    COUNT(*) AS Total_POs,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(received_qty) AS Received_Qty,

    SUM(ordered_qty - received_qty) AS Outstanding_Qty,

    CAST(
        SUM(po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        100.0 * SUM(received_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Receipt_Rate_Pct

FROM raw.Purchase_Orders

WHERE MONTH(po_date) BETWEEN 1 AND 9

GROUP BY
    YEAR(po_date)

ORDER BY
    PO_Year;



-- ============================================================
-- Step 15: Jan-Sep Procurement Value YoY Growth
-- ============================================================

WITH JanSepProcurement AS
(
    SELECT
        YEAR(po_date) AS PO_Year,

        SUM(po_value) AS Procurement_Value

    FROM raw.Purchase_Orders

    WHERE MONTH(po_date) BETWEEN 1 AND 9

    GROUP BY
        YEAR(po_date)
),

YoYProcurement AS
(
    SELECT
        PO_Year,
        Procurement_Value,

        LAG(Procurement_Value) OVER (
            ORDER BY PO_Year
        ) AS Previous_Year_Procurement_Value

    FROM JanSepProcurement
)

SELECT
    PO_Year,

    CAST(
        Procurement_Value
        AS DECIMAL(18,2)
    ) AS Jan_Sep_Procurement_Value,

    CAST(
        Previous_Year_Procurement_Value
        AS DECIMAL(18,2)
    ) AS Previous_Year_Procurement_Value,

    CAST(
        100.0 *
        (Procurement_Value - Previous_Year_Procurement_Value)
        / NULLIF(Previous_Year_Procurement_Value, 0)
        AS DECIMAL(8,2)
    ) AS YoY_Procurement_Growth_Pct

FROM YoYProcurement

ORDER BY
    PO_Year;




-- ============================================================
-- Step 16: Open Purchase Order Exposure
-- ============================================================

SELECT
    COUNT(*) AS Open_POs,

    COUNT(DISTINCT supplier_id) AS Suppliers_Affected,

    COUNT(DISTINCT product_id) AS Products_Affected,

    COUNT(DISTINCT warehouse_id) AS Warehouses_Affected,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(received_qty) AS Received_Qty,

    SUM(ordered_qty - received_qty) AS Outstanding_Qty,

    CAST(
        SUM(po_value)
        AS DECIMAL(18,2)
    ) AS Open_PO_Value,

    CAST(
        AVG(po_value)
        AS DECIMAL(18,2)
    ) AS Avg_Open_PO_Value

FROM raw.Purchase_Orders

WHERE po_status = 'Open';




-- ============================================================
-- Step 17: Open PO Exposure by Supplier
-- ============================================================

SELECT
    s.supplier_id,
    s.supplier_name,
    s.supplier_region,
    s.preferred_supplier_flag,
    s.reliability_factor,

    COUNT(*) AS Open_POs,

    SUM(po.ordered_qty) AS Outstanding_Qty,

    CAST(
        SUM(po.po_value)
        AS DECIMAL(18,2)
    ) AS Open_PO_Value,

    CAST(
        100.0 * SUM(po.po_value)
        / SUM(SUM(po.po_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Open_PO_Value_Share_Pct

FROM raw.Purchase_Orders AS po

INNER JOIN raw.Suppliers AS s
    ON po.supplier_id = s.supplier_id

WHERE po.po_status = 'Open'

GROUP BY
    s.supplier_id,
    s.supplier_name,
    s.supplier_region,
    s.preferred_supplier_flag,
    s.reliability_factor

ORDER BY
    Open_PO_Value DESC;




-- ============================================================
-- Step 18: Supplier Procurement Concentration
-- ============================================================

WITH SupplierSpend AS
(
    SELECT
        supplier_id,
        SUM(po_value) AS Procurement_Value
    FROM raw.Purchase_Orders
    GROUP BY supplier_id
),

RankedSuppliers AS
(
    SELECT
        supplier_id,
        Procurement_Value,

        ROW_NUMBER() OVER
        (
            ORDER BY Procurement_Value DESC
        ) AS Supplier_Rank,

        SUM(Procurement_Value) OVER () AS Total_Procurement_Value

    FROM SupplierSpend
)

SELECT
    CAST(
        SUM(
            CASE
                WHEN Supplier_Rank <= 5
                THEN Procurement_Value
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Top_5_Supplier_Value,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN Supplier_Rank <= 5
                THEN Procurement_Value
                ELSE 0
            END
        )
        / MAX(Total_Procurement_Value)
        AS DECIMAL(8,2)
    ) AS Top_5_Supplier_Share_Pct,

    CAST(
        SUM(
            CASE
                WHEN Supplier_Rank <= 10
                THEN Procurement_Value
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Top_10_Supplier_Value,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN Supplier_Rank <= 10
                THEN Procurement_Value
                ELSE 0
            END
        )
        / MAX(Total_Procurement_Value)
        AS DECIMAL(8,2)
    ) AS Top_10_Supplier_Share_Pct

FROM RankedSuppliers;




-- ============================================================
-- Step 19: High-Risk Supplier Exposure
-- High Risk:
-- On-Time Rate < 60% OR Average Delay > 2 Days
-- ============================================================

WITH SupplierPerformance AS
(
    SELECT
        s.supplier_id,
        s.supplier_name,
        s.supplier_region,
        s.preferred_supplier_flag,
        s.reliability_factor,

        COUNT(*) AS Evaluated_POs,

        SUM(po.po_value) AS Procurement_Value,

        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        ) / COUNT(*) AS On_Time_Rate_Pct,

        AVG(1.0 * po.supplier_delay_days) AS Avg_Delay_Days

    FROM raw.Purchase_Orders AS po

    INNER JOIN raw.Suppliers AS s
        ON po.supplier_id = s.supplier_id

    WHERE po.actual_receipt_date IS NOT NULL
      AND po.supplier_delay_days IS NOT NULL

    GROUP BY
        s.supplier_id,
        s.supplier_name,
        s.supplier_region,
        s.preferred_supplier_flag,
        s.reliability_factor
),

RiskSuppliers AS
(
    SELECT *
    FROM SupplierPerformance

    WHERE On_Time_Rate_Pct < 60
       OR Avg_Delay_Days > 2
)

SELECT
    COUNT(*) AS High_Risk_Suppliers,

    CAST(
        SUM(Procurement_Value)
        AS DECIMAL(18,2)
    ) AS High_Risk_Procurement_Value,

    CAST(
        100.0 * SUM(Procurement_Value)
        /
        (
            SELECT SUM(po_value)
            FROM raw.Purchase_Orders
            WHERE actual_receipt_date IS NOT NULL
        )
        AS DECIMAL(8,2)
    ) AS High_Risk_Procurement_Share_Pct,

    CAST(
        MIN(On_Time_Rate_Pct)
        AS DECIMAL(8,2)
    ) AS Lowest_On_Time_Rate_Pct,

    CAST(
        MAX(Avg_Delay_Days)
        AS DECIMAL(8,2)
    ) AS Highest_Avg_Delay_Days

FROM RiskSuppliers;




-- ============================================================
-- Step 20: High-Risk Supplier Ranking
-- High Risk:
-- On-Time Rate < 60% OR Average Delay > 2 Days
-- ============================================================

WITH SupplierPerformance AS
(
    SELECT
        s.supplier_id,
        s.supplier_name,
        s.supplier_region,
        s.preferred_supplier_flag,
        s.reliability_factor,

        COUNT(*) AS Evaluated_POs,

        SUM(po.po_value) AS Procurement_Value,

        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        ) / COUNT(*) AS On_Time_Rate_Pct,

        AVG(1.0 * po.supplier_delay_days) AS Avg_Delay_Days,

        SUM(
            CASE
                WHEN po.supplier_delay_days >= 11
                THEN 1 ELSE 0
            END
        ) AS Severe_Delay_POs

    FROM raw.Purchase_Orders AS po

    INNER JOIN raw.Suppliers AS s
        ON po.supplier_id = s.supplier_id

    WHERE po.actual_receipt_date IS NOT NULL
      AND po.supplier_delay_days IS NOT NULL

    GROUP BY
        s.supplier_id,
        s.supplier_name,
        s.supplier_region,
        s.preferred_supplier_flag,
        s.reliability_factor
),

HighRiskSuppliers AS
(
    SELECT *
    FROM SupplierPerformance

    WHERE On_Time_Rate_Pct < 60
       OR Avg_Delay_Days > 2
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY Procurement_Value DESC
    ) AS Risk_Rank,

    supplier_id,
    supplier_name,
    supplier_region,
    preferred_supplier_flag,
    reliability_factor,
    Evaluated_POs,

    CAST(
        Procurement_Value
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        On_Time_Rate_Pct
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        Avg_Delay_Days
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    Severe_Delay_POs

FROM HighRiskSuppliers

ORDER BY
    Risk_Rank;



-- ============================================================
-- Step 21: Supplier Quality Rating vs Delivery Performance
-- Completed receipt POs only
-- ============================================================

SELECT
    CASE
        WHEN s.quality_rating < 3.5
            THEN 'Below 3.5'

        WHEN s.quality_rating < 4.0
            THEN '3.5 - 3.99'

        WHEN s.quality_rating < 4.5
            THEN '4.0 - 4.49'

        ELSE '4.5+'
    END AS Quality_Rating_Group,

    COUNT(DISTINCT s.supplier_id) AS Suppliers,

    COUNT(*) AS Evaluated_POs,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        AVG(1.0 * po.supplier_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    SUM(
        CASE
            WHEN po.supplier_delay_days >= 11
            THEN 1 ELSE 0
        END
    ) AS Severe_Delay_POs

FROM raw.Purchase_Orders AS po

INNER JOIN raw.Suppliers AS s
    ON po.supplier_id = s.supplier_id

WHERE po.actual_receipt_date IS NOT NULL
  AND po.supplier_delay_days IS NOT NULL
  AND s.quality_rating IS NOT NULL

GROUP BY
    CASE
        WHEN s.quality_rating < 3.5 THEN 'Below 3.5'
        WHEN s.quality_rating < 4.0 THEN '3.5 - 3.99'
        WHEN s.quality_rating < 4.5 THEN '4.0 - 4.49'
        ELSE '4.5+'
    END

ORDER BY
    MIN(s.quality_rating);




-- ============================================================
-- Step 22: Reliability Factor vs Delivery Performance
-- Completed receipt POs only
-- ============================================================

SELECT
    CASE
        WHEN s.reliability_factor < 0.70
            THEN 'Below 0.70'

        WHEN s.reliability_factor < 0.80
            THEN '0.70 - 0.79'

        WHEN s.reliability_factor < 0.90
            THEN '0.80 - 0.89'

        ELSE '0.90+'
    END AS Reliability_Group,

    COUNT(DISTINCT s.supplier_id) AS Suppliers,

    COUNT(*) AS Evaluated_POs,

    CAST(
        SUM(po.po_value)
        AS DECIMAL(18,2)
    ) AS Procurement_Value,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN po.supplier_delay_days > 0
                THEN 1 ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Delay_Rate_Pct,

    CAST(
        AVG(1.0 * po.supplier_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    SUM(
        CASE
            WHEN po.supplier_delay_days >= 11
            THEN 1 ELSE 0
        END
    ) AS Severe_Delay_POs

FROM raw.Purchase_Orders AS po

INNER JOIN raw.Suppliers AS s
    ON po.supplier_id = s.supplier_id

WHERE po.actual_receipt_date IS NOT NULL
  AND po.supplier_delay_days IS NOT NULL

GROUP BY
    CASE
        WHEN s.reliability_factor < 0.70 THEN 'Below 0.70'
        WHEN s.reliability_factor < 0.80 THEN '0.70 - 0.79'
        WHEN s.reliability_factor < 0.90 THEN '0.80 - 0.89'
        ELSE '0.90+'
    END

ORDER BY
    MIN(s.reliability_factor);




-- ============================================================
-- Step 23: Procurement Risk Summary
-- ============================================================

SELECT
    -- Overall quantity receipt rate
    CAST(
        100.0 * SUM(received_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Overall_Receipt_Rate_Pct,

    -- Open procurement
    SUM(
        CASE
            WHEN po_status = 'Open'
            THEN 1 ELSE 0
        END
    ) AS Open_POs,

    CAST(
        SUM(
            CASE
                WHEN po_status = 'Open'
                THEN po_value ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Open_PO_Value,

    -- Supplier delivery performance
    CAST(
        100.0 *
        SUM(
            CASE
                WHEN supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN supplier_delay_days IS NOT NULL
                    THEN 1 ELSE 0
                END
            ), 0
        )
        AS DECIMAL(8,2)
    ) AS Supplier_On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN supplier_delay_days > 0
                THEN 1 ELSE 0
            END
        )
        /
        NULLIF(
            SUM(
                CASE
                    WHEN supplier_delay_days IS NOT NULL
                    THEN 1 ELSE 0
                END
            ), 0
        )
        AS DECIMAL(8,2)
    ) AS Supplier_Delay_Rate_Pct,

    -- Long supplier delays
    SUM(
        CASE
            WHEN supplier_delay_days >= 11
            THEN 1 ELSE 0
        END
    ) AS Severe_Delay_POs

FROM raw.Purchase_Orders;




-- ============================================================
-- Step 24: Procurement Reconciliation
-- ============================================================

SELECT
    SUM(ordered_qty) AS Total_Ordered_Qty,

    SUM(received_qty) AS Total_Received_Qty,

    SUM(ordered_qty - received_qty) AS Outstanding_Qty,

    SUM(received_qty)
        + SUM(ordered_qty - received_qty)
        AS Received_Plus_Outstanding_Qty,

    SUM(ordered_qty)
        - (
            SUM(received_qty)
            + SUM(ordered_qty - received_qty)
          )
        AS Quantity_Difference,

    CAST(
        SUM(po_value)
        AS DECIMAL(18,2)
    ) AS Total_Procurement_Value,

    SUM(
        CASE
            WHEN po_status = 'Open'
            THEN 1 ELSE 0
        END
    ) AS Open_POs,

    SUM(
        CASE
            WHEN po_status <> 'Open'
            THEN 1 ELSE 0
        END
    ) AS Non_Open_POs,

    COUNT(*) AS Total_POs

FROM raw.Purchase_Orders;



-- ============================================================
-- Step 25: Final Supplier & Procurement Analysis Validation
-- ============================================================

DECLARE @ProcurementValidation TABLE
(
    Validation_Check VARCHAR(160),
    Status VARCHAR(10)
);

INSERT INTO @ProcurementValidation
VALUES

('Total Purchase Orders',
 CASE WHEN (SELECT COUNT(*) FROM raw.Purchase_Orders) = 8500
      THEN 'PASS' ELSE 'FAIL' END),

('Unique Purchase Order IDs',
 CASE WHEN
 (
     SELECT COUNT(DISTINCT po_id)
     FROM raw.Purchase_Orders
 ) = 8500
 THEN 'PASS' ELSE 'FAIL' END),

('Unique Suppliers',
 CASE WHEN
 (
     SELECT COUNT(DISTINCT supplier_id)
     FROM raw.Purchase_Orders
 ) = 100
 THEN 'PASS' ELSE 'FAIL' END),

('Unique Products',
 CASE WHEN
 (
     SELECT COUNT(DISTINCT product_id)
     FROM raw.Purchase_Orders
 ) = 500
 THEN 'PASS' ELSE 'FAIL' END),

('Unique Warehouses',
 CASE WHEN
 (
     SELECT COUNT(DISTINCT warehouse_id)
     FROM raw.Purchase_Orders
 ) = 6
 THEN 'PASS' ELSE 'FAIL' END),

('Total Ordered Quantity',
 CASE WHEN
 (
     SELECT SUM(ordered_qty)
     FROM raw.Purchase_Orders
 ) = 2012081
 THEN 'PASS' ELSE 'FAIL' END),

('Total Received Quantity',
 CASE WHEN
 (
     SELECT SUM(received_qty)
     FROM raw.Purchase_Orders
 ) = 1879255
 THEN 'PASS' ELSE 'FAIL' END),

('Outstanding Quantity',
 CASE WHEN
 (
     SELECT SUM(ordered_qty - received_qty)
     FROM raw.Purchase_Orders
 ) = 132826
 THEN 'PASS' ELSE 'FAIL' END),

('Procurement Quantity Equation',
 CASE WHEN
 (
     SELECT SUM(ordered_qty)
     FROM raw.Purchase_Orders
 ) =
 (
     SELECT
         SUM(received_qty)
         + SUM(ordered_qty - received_qty)
     FROM raw.Purchase_Orders
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Open Purchase Orders',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Purchase_Orders
     WHERE po_status = 'Open'
 ) = 30
 THEN 'PASS' ELSE 'FAIL' END),

('Non-Open Purchase Orders',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Purchase_Orders
     WHERE po_status <> 'Open'
 ) = 8470
 THEN 'PASS' ELSE 'FAIL' END),

('Open POs Have Missing Receipt Dates',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Purchase_Orders
     WHERE po_status = 'Open'
       AND actual_receipt_date IS NULL
 ) = 30
 THEN 'PASS' ELSE 'FAIL' END),

('Open POs Have Missing Delay Values',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Purchase_Orders
     WHERE po_status = 'Open'
       AND supplier_delay_days IS NULL
 ) = 30
 THEN 'PASS' ELSE 'FAIL' END),

('Completed POs Have Receipt Dates',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Purchase_Orders
     WHERE po_status <> 'Open'
       AND actual_receipt_date IS NULL
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Completed POs Have Supplier Delay Values',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Purchase_Orders
     WHERE po_status <> 'Open'
       AND supplier_delay_days IS NULL
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Supplier Delivery Evaluated POs',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Purchase_Orders
     WHERE supplier_delay_days IS NOT NULL
 ) = 8470
 THEN 'PASS' ELSE 'FAIL' END),

('Delayed Purchase Orders',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Purchase_Orders
     WHERE supplier_delay_days > 0
 ) = 2935
 THEN 'PASS' ELSE 'FAIL' END),

('Severe Supplier Delay POs',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Purchase_Orders
     WHERE supplier_delay_days >= 11
 ) = 514
 THEN 'PASS' ELSE 'FAIL' END),

('No Negative Ordered Quantity',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Purchase_Orders
     WHERE ordered_qty < 0
 )
 THEN 'PASS' ELSE 'FAIL' END),

('No Negative Received Quantity',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Purchase_Orders
     WHERE received_qty < 0
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Received Quantity Does Not Exceed Ordered Quantity',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Purchase_Orders
     WHERE received_qty > ordered_qty
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Supplier Foreign Keys Valid',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Purchase_Orders AS po
     LEFT JOIN raw.Suppliers AS s
         ON po.supplier_id = s.supplier_id
     WHERE s.supplier_id IS NULL
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Product Foreign Keys Valid',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Purchase_Orders AS po
     LEFT JOIN raw.Products AS p
         ON po.product_id = p.product_id
     WHERE p.product_id IS NULL
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Warehouse Foreign Keys Valid',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Purchase_Orders AS po
     LEFT JOIN raw.Warehouses AS w
         ON po.warehouse_id = w.warehouse_id
     WHERE w.warehouse_id IS NULL
 )
 THEN 'PASS' ELSE 'FAIL' END);

-- Detailed validation results
SELECT *
FROM @ProcurementValidation;

-- Final validation status
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
    END AS Final_Supplier_Procurement_Analysis_Status

FROM @ProcurementValidation;