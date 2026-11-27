-- ============================================================
-- SALES ORDER, BACKLOG & INVENTORY ANALYTICS
-- File: 08_Inventory_Optimization.sql
-- Purpose: Inventory Optimization Analysis
-- ============================================================

USE Sales_Order_Backlog_Inventory_Analytics;
GO

-- ============================================================
-- Step 1: Inventory Optimization Baseline
-- ============================================================

SELECT
    COUNT(*) AS Inventory_Records,

    COUNT(DISTINCT product_id) AS Products,

    COUNT(DISTINCT warehouse_id) AS Warehouses,

    SUM(on_hand_qty) AS Total_On_Hand_Qty,

    SUM(allocated_qty) AS Total_Allocated_Qty,

    SUM(available_qty) AS Total_Available_Qty,

    CAST(
        SUM(inventory_value)
        AS DECIMAL(18,2)
    ) AS Total_Inventory_Value,

    CAST(
        AVG(
            available_qty /
            NULLIF(1.0 * avg_daily_demand, 0)
        )
        AS DECIMAL(10,2)
    ) AS Avg_Days_Of_Inventory,

    SUM(
        CASE
            WHEN available_qty <= reorder_point
            THEN 1 ELSE 0
        END
    ) AS Reorder_Required_Records,

    SUM(
        CASE
            WHEN available_qty = 0
            THEN 1 ELSE 0
        END
    ) AS Zero_Available_Stock_Records

FROM raw.Inventory;



-- ============================================================
-- Step 2: Inventory Coverage Distribution
-- ============================================================

WITH InventoryCoverage AS
(
    SELECT
        product_id,
        warehouse_id,
        available_qty,
        inventory_value,

        available_qty /
        NULLIF(1.0 * avg_daily_demand, 0)
            AS Days_Of_Inventory

    FROM raw.Inventory
),

CoverageBands AS
(
    SELECT
        *,

        CASE
            WHEN Days_Of_Inventory = 0
                THEN '0 Days'

            WHEN Days_Of_Inventory <= 7
                THEN '1-7 Days'

            WHEN Days_Of_Inventory <= 15
                THEN '8-15 Days'

            WHEN Days_Of_Inventory <= 30
                THEN '16-30 Days'

            WHEN Days_Of_Inventory <= 60
                THEN '31-60 Days'

            ELSE '61+ Days'
        END AS Coverage_Band

    FROM InventoryCoverage
)

SELECT
    Coverage_Band,

    COUNT(*) AS Inventory_Records,

    SUM(available_qty) AS Available_Qty,

    CAST(
        SUM(inventory_value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        100.0 * SUM(inventory_value)
        / SUM(SUM(inventory_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Inventory_Value_Share_Pct,

    CAST(
        AVG(Days_Of_Inventory)
        AS DECIMAL(10,2)
    ) AS Avg_Days_Of_Inventory

FROM CoverageBands

GROUP BY Coverage_Band

ORDER BY
    CASE Coverage_Band
        WHEN '0 Days' THEN 1
        WHEN '1-7 Days' THEN 2
        WHEN '8-15 Days' THEN 3
        WHEN '16-30 Days' THEN 4
        WHEN '31-60 Days' THEN 5
        WHEN '61+ Days' THEN 6
    END;




-- ============================================================
-- Step 3: Safety Stock Risk Analysis
-- ============================================================

SELECT
    COUNT(*) AS Below_Safety_Stock_Records,

    COUNT(DISTINCT product_id) AS Products_Affected,

    COUNT(DISTINCT warehouse_id) AS Warehouses_Affected,

    SUM(available_qty) AS Available_Qty,

    SUM(safety_stock) AS Safety_Stock_Qty,

    SUM(safety_stock - available_qty)
        AS Safety_Stock_Shortfall_Qty,

    CAST(
        SUM(inventory_value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        100.0 * SUM(inventory_value)
        /
        (
            SELECT SUM(inventory_value)
            FROM raw.Inventory
        )
        AS DECIMAL(8,2)
    ) AS Inventory_Value_Share_Pct

FROM raw.Inventory

WHERE available_qty < safety_stock;



-- ============================================================
-- Step 4: Gross Replenishment Gap Analysis
-- Gap = Reorder Point - Available Quantity
-- ============================================================

WITH ReplenishmentGap AS
(
    SELECT
        product_id,
        warehouse_id,
        available_qty,
        reorder_point,
        avg_daily_demand,
        unit_cost,

        CASE
            WHEN reorder_point > available_qty
            THEN reorder_point - available_qty
            ELSE 0
        END AS Replenishment_Gap_Qty

    FROM raw.Inventory

    WHERE available_qty <= reorder_point
)

SELECT
    COUNT(*) AS Reorder_Required_Records,

    SUM(
        CASE
            WHEN Replenishment_Gap_Qty > 0
            THEN 1 ELSE 0
        END
    ) AS Positive_Gap_Records,

    COUNT(DISTINCT product_id) AS Products_Affected,

    SUM(Replenishment_Gap_Qty)
        AS Gross_Replenishment_Gap_Qty,

    CAST(
        SUM(Replenishment_Gap_Qty * unit_cost)
        AS DECIMAL(18,2)
    ) AS Gross_Replenishment_Gap_Value,

    CAST(
        AVG(
            CASE
                WHEN Replenishment_Gap_Qty > 0
                THEN 1.0 * Replenishment_Gap_Qty
            END
        )
        AS DECIMAL(10,2)
    ) AS Avg_Positive_Gap_Qty

FROM ReplenishmentGap;



-- ============================================================
-- Step 5: Outstanding PO Quantity by Product & Warehouse
-- Outstanding = Ordered Qty - Received Qty
-- ============================================================

WITH InboundPO AS
(
    SELECT
        product_id,
        warehouse_id,

        SUM(ordered_qty - received_qty)
            AS Outstanding_PO_Qty,

        COUNT(*) AS PO_Records,

        COUNT(DISTINCT supplier_id)
            AS Suppliers_Involved

    FROM raw.Purchase_Orders

    WHERE ordered_qty > received_qty

    GROUP BY
        product_id,
        warehouse_id
)

SELECT
    COUNT(*) AS Product_Warehouse_With_Inbound,

    COUNT(DISTINCT product_id)
        AS Products_With_Inbound,

    SUM(PO_Records)
        AS PO_Records_With_Outstanding_Qty,

    SUM(Outstanding_PO_Qty)
        AS Total_Outstanding_PO_Qty,

    CAST(
        AVG(1.0 * Outstanding_PO_Qty)
        AS DECIMAL(10,2)
    ) AS Avg_Inbound_Qty_Per_Product_Warehouse,

    MAX(Outstanding_PO_Qty)
        AS Max_Inbound_Qty

FROM InboundPO;




-- ============================================================
-- Step 6: Net Replenishment Gap After Inbound POs
-- Net Gap = Gross Gap - Outstanding PO Qty
-- ============================================================

WITH ReplenishmentGap AS
(
    SELECT
        product_id,
        warehouse_id,
        available_qty,
        reorder_point,
        unit_cost,

        CASE
            WHEN reorder_point > available_qty
            THEN reorder_point - available_qty
            ELSE 0
        END AS Gross_Gap_Qty

    FROM raw.Inventory

    WHERE available_qty <= reorder_point
),

InboundPO AS
(
    SELECT
        product_id,
        warehouse_id,

        SUM(ordered_qty - received_qty)
            AS Outstanding_PO_Qty

    FROM raw.Purchase_Orders

    WHERE ordered_qty > received_qty

    GROUP BY
        product_id,
        warehouse_id
),

NetReplenishment AS
(
    SELECT
        r.product_id,
        r.warehouse_id,
        r.Gross_Gap_Qty,
        r.unit_cost,

        ISNULL(p.Outstanding_PO_Qty, 0)
            AS Outstanding_PO_Qty,

        CASE
            WHEN r.Gross_Gap_Qty
                 - ISNULL(p.Outstanding_PO_Qty, 0) > 0
            THEN r.Gross_Gap_Qty
                 - ISNULL(p.Outstanding_PO_Qty, 0)
            ELSE 0
        END AS Net_Replenishment_Gap_Qty

    FROM ReplenishmentGap AS r

    LEFT JOIN InboundPO AS p
        ON r.product_id = p.product_id
       AND r.warehouse_id = p.warehouse_id
)

SELECT
    COUNT(*) AS Reorder_Required_Records,

    SUM(
        CASE
            WHEN Outstanding_PO_Qty > 0
            THEN 1 ELSE 0
        END
    ) AS Records_With_Inbound_PO,

    SUM(
        CASE
            WHEN Gross_Gap_Qty > 0
             AND Net_Replenishment_Gap_Qty = 0
            THEN 1 ELSE 0
        END
    ) AS Shortage_Records_Fully_Covered,

    SUM(
        CASE
            WHEN Net_Replenishment_Gap_Qty > 0
            THEN 1 ELSE 0
        END
    ) AS Net_Replenishment_Records,

    SUM(Net_Replenishment_Gap_Qty)
        AS Net_Replenishment_Qty,

    CAST(
        SUM(Net_Replenishment_Gap_Qty * unit_cost)
        AS DECIMAL(18,2)
    ) AS Net_Replenishment_Value

FROM NetReplenishment;





-- ============================================================
-- Step 7: Potential Excess Inventory Above 60-Day Demand
-- ============================================================

WITH ExcessInventory AS
(
    SELECT
        product_id,
        warehouse_id,
        available_qty,
        avg_daily_demand,
        unit_cost,

        60.0 * avg_daily_demand
            AS Sixty_Day_Demand_Qty,

        CASE
            WHEN available_qty > 60.0 * avg_daily_demand
            THEN available_qty - (60.0 * avg_daily_demand)
            ELSE 0
        END AS Potential_Excess_Qty

    FROM raw.Inventory
)

SELECT
    SUM(
        CASE
            WHEN Potential_Excess_Qty > 0
            THEN 1 ELSE 0
        END
    ) AS Potential_Excess_Records,

    COUNT(
        DISTINCT CASE
            WHEN Potential_Excess_Qty > 0
            THEN product_id
        END
    ) AS Products_Affected,

    CAST(
        SUM(Potential_Excess_Qty)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Qty,

    CAST(
        SUM(Potential_Excess_Qty * unit_cost)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Value,

    CAST(
        100.0 *
        SUM(Potential_Excess_Qty * unit_cost)
        /
        (
            SELECT SUM(inventory_value)
            FROM raw.Inventory
        )
        AS DECIMAL(8,2)
    ) AS Inventory_Value_At_Excess_Pct

FROM ExcessInventory

WHERE Potential_Excess_Qty > 0;



-- ============================================================
-- Step 8: Inventory Optimization Status
-- ============================================================

WITH InboundPO AS
(
    SELECT
        product_id,
        warehouse_id,
        SUM(ordered_qty - received_qty) AS Outstanding_PO_Qty

    FROM raw.Purchase_Orders

    WHERE ordered_qty > received_qty

    GROUP BY
        product_id,
        warehouse_id
),

OptimizationBase AS
(
    SELECT
        i.product_id,
        i.warehouse_id,
        i.available_qty,
        i.avg_daily_demand,
        i.reorder_point,
        i.inventory_value,

        ISNULL(p.Outstanding_PO_Qty, 0)
            AS Outstanding_PO_Qty,

        CASE
            WHEN i.reorder_point > i.available_qty
            THEN i.reorder_point - i.available_qty
            ELSE 0
        END AS Gross_Replenishment_Gap_Qty,

        CASE
            WHEN i.available_qty > 60.0 * i.avg_daily_demand
            THEN i.available_qty - (60.0 * i.avg_daily_demand)
            ELSE 0
        END AS Potential_Excess_Qty

    FROM raw.Inventory AS i

    LEFT JOIN InboundPO AS p
        ON i.product_id = p.product_id
       AND i.warehouse_id = p.warehouse_id
),

OptimizationStatus AS
(
    SELECT
        *,

        CASE
            WHEN Gross_Replenishment_Gap_Qty
                 - Outstanding_PO_Qty > 0
                THEN 'Replenishment Required'

            WHEN Potential_Excess_Qty > 0
                THEN 'Potential Excess'

            ELSE 'Balanced / Monitor'
        END AS Optimization_Status

    FROM OptimizationBase
)

SELECT
    Optimization_Status,

    COUNT(*) AS Inventory_Records,

    COUNT(DISTINCT product_id)
        AS Products,

    SUM(available_qty)
        AS Available_Qty,

    CAST(
        SUM(inventory_value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Record_Share_Pct

FROM OptimizationStatus

GROUP BY Optimization_Status

ORDER BY
    CASE Optimization_Status
        WHEN 'Replenishment Required' THEN 1
        WHEN 'Potential Excess' THEN 2
        WHEN 'Balanced / Monitor' THEN 3
    END;




-- ============================================================
-- Step 9: Replenishment Priority Analysis
-- ============================================================

WITH InboundPO AS
(
    SELECT
        product_id,
        warehouse_id,
        SUM(ordered_qty - received_qty) AS Outstanding_PO_Qty
    FROM raw.Purchase_Orders
    WHERE ordered_qty > received_qty
    GROUP BY product_id, warehouse_id
),

ReplenishmentBase AS
(
    SELECT
        i.product_id,
        i.warehouse_id,
        i.available_qty,
        i.avg_daily_demand,
        i.safety_stock,
        i.reorder_point,
        i.unit_cost,

        ISNULL(p.Outstanding_PO_Qty, 0) AS Outstanding_PO_Qty,

        CASE
            WHEN i.reorder_point > i.available_qty
            THEN i.reorder_point - i.available_qty
            ELSE 0
        END AS Gross_Gap_Qty

    FROM raw.Inventory AS i

    LEFT JOIN InboundPO AS p
        ON i.product_id = p.product_id
       AND i.warehouse_id = p.warehouse_id
),

NetGap AS
(
    SELECT
        *,

        CASE
            WHEN Gross_Gap_Qty - Outstanding_PO_Qty > 0
            THEN Gross_Gap_Qty - Outstanding_PO_Qty
            ELSE 0
        END AS Net_Gap_Qty

    FROM ReplenishmentBase
),

Priority AS
(
    SELECT
        *,

        CASE
            WHEN available_qty = 0
                THEN 'Critical'

            WHEN available_qty < safety_stock
                THEN 'High'

            WHEN available_qty <= reorder_point
                 AND available_qty /
                     NULLIF(1.0 * avg_daily_demand, 0) <= 15
                THEN 'Moderate'

            ELSE 'Low'
        END AS Replenishment_Priority

    FROM NetGap

    WHERE Net_Gap_Qty > 0
)

SELECT
    Replenishment_Priority,

    COUNT(*) AS Inventory_Records,

    COUNT(DISTINCT product_id) AS Products,

    SUM(Net_Gap_Qty) AS Net_Replenishment_Qty,

    CAST(
        SUM(Net_Gap_Qty * unit_cost)
        AS DECIMAL(18,2)
    ) AS Net_Replenishment_Value,

    CAST(
        100.0 * SUM(Net_Gap_Qty * unit_cost)
        / SUM(SUM(Net_Gap_Qty * unit_cost)) OVER ()
        AS DECIMAL(8,2)
    ) AS Replenishment_Value_Share_Pct

FROM Priority

GROUP BY Replenishment_Priority

ORDER BY
    CASE Replenishment_Priority
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Moderate' THEN 3
        WHEN 'Low' THEN 4
    END;






-- ============================================================
-- Step 10: Net Replenishment Risk by Warehouse
-- ============================================================

WITH InboundPO AS
(
    SELECT
        product_id,
        warehouse_id,
        SUM(ordered_qty - received_qty) AS Outstanding_PO_Qty

    FROM raw.Purchase_Orders

    WHERE ordered_qty > received_qty

    GROUP BY
        product_id,
        warehouse_id
),

ReplenishmentBase AS
(
    SELECT
        i.product_id,
        i.warehouse_id,
        i.available_qty,
        i.avg_daily_demand,
        i.safety_stock,
        i.reorder_point,
        i.unit_cost,

        ISNULL(p.Outstanding_PO_Qty, 0)
            AS Outstanding_PO_Qty,

        CASE
            WHEN i.reorder_point > i.available_qty
            THEN i.reorder_point - i.available_qty
            ELSE 0
        END AS Gross_Gap_Qty

    FROM raw.Inventory AS i

    LEFT JOIN InboundPO AS p
        ON i.product_id = p.product_id
       AND i.warehouse_id = p.warehouse_id
),

NetGap AS
(
    SELECT
        *,

        CASE
            WHEN Gross_Gap_Qty - Outstanding_PO_Qty > 0
            THEN Gross_Gap_Qty - Outstanding_PO_Qty
            ELSE 0
        END AS Net_Gap_Qty

    FROM ReplenishmentBase
)

SELECT
    n.warehouse_id,
    w.warehouse_name,

    COUNT(*) AS Replenishment_Records,

    COUNT(DISTINCT n.product_id)
        AS Products_Affected,

    SUM(n.Net_Gap_Qty)
        AS Net_Replenishment_Qty,

    CAST(
        SUM(n.Net_Gap_Qty * n.unit_cost)
        AS DECIMAL(18,2)
    ) AS Net_Replenishment_Value,

    CAST(
        100.0 * SUM(n.Net_Gap_Qty * n.unit_cost)
        / SUM(SUM(n.Net_Gap_Qty * n.unit_cost)) OVER ()
        AS DECIMAL(8,2)
    ) AS Replenishment_Value_Share_Pct

FROM NetGap AS n

INNER JOIN raw.Warehouses AS w
    ON n.warehouse_id = w.warehouse_id

WHERE n.Net_Gap_Qty > 0

GROUP BY
    n.warehouse_id,
    w.warehouse_name

ORDER BY
    Net_Replenishment_Value DESC;



-- ============================================================
-- Step 11: Net Replenishment Risk by Product Category
-- ============================================================

WITH InboundPO AS
(
    SELECT
        product_id,
        warehouse_id,
        SUM(ordered_qty - received_qty) AS Outstanding_PO_Qty
    FROM raw.Purchase_Orders
    WHERE ordered_qty > received_qty
    GROUP BY
        product_id,
        warehouse_id
),

ReplenishmentBase AS
(
    SELECT
        i.product_id,
        i.warehouse_id,
        i.reorder_point,
        i.available_qty,
        i.unit_cost,

        ISNULL(p.Outstanding_PO_Qty, 0)
            AS Outstanding_PO_Qty,

        CASE
            WHEN i.reorder_point > i.available_qty
            THEN i.reorder_point - i.available_qty
            ELSE 0
        END AS Gross_Gap_Qty

    FROM raw.Inventory AS i

    LEFT JOIN InboundPO AS p
        ON i.product_id = p.product_id
       AND i.warehouse_id = p.warehouse_id
),

NetGap AS
(
    SELECT
        *,

        CASE
            WHEN Gross_Gap_Qty - Outstanding_PO_Qty > 0
            THEN Gross_Gap_Qty - Outstanding_PO_Qty
            ELSE 0
        END AS Net_Gap_Qty

    FROM ReplenishmentBase
)

SELECT
    p.category,

    COUNT(*) AS Replenishment_Records,

    COUNT(DISTINCT n.product_id)
        AS Products_Affected,

    SUM(n.Net_Gap_Qty)
        AS Net_Replenishment_Qty,

    CAST(
        SUM(n.Net_Gap_Qty * n.unit_cost)
        AS DECIMAL(18,2)
    ) AS Net_Replenishment_Value,

    CAST(
        100.0 * SUM(n.Net_Gap_Qty * n.unit_cost)
        / SUM(SUM(n.Net_Gap_Qty * n.unit_cost)) OVER ()
        AS DECIMAL(8,2)
    ) AS Replenishment_Value_Share_Pct

FROM NetGap AS n

INNER JOIN raw.Products AS p
    ON n.product_id = p.product_id

WHERE n.Net_Gap_Qty > 0

GROUP BY
    p.category

ORDER BY
    Net_Replenishment_Value DESC;




-- ============================================================
-- Step 12: Potential Excess Inventory by Warehouse
-- ============================================================

WITH ExcessInventory AS
(
    SELECT
        product_id,
        warehouse_id,
        available_qty,
        avg_daily_demand,
        unit_cost,

        CASE
            WHEN available_qty > 60.0 * avg_daily_demand
            THEN available_qty - (60.0 * avg_daily_demand)
            ELSE 0
        END AS Potential_Excess_Qty

    FROM raw.Inventory
)

SELECT
    e.warehouse_id,
    w.warehouse_name,

    COUNT(*) AS Excess_Records,

    COUNT(DISTINCT e.product_id)
        AS Products_Affected,

    CAST(
        SUM(e.Potential_Excess_Qty)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Qty,

    CAST(
        SUM(e.Potential_Excess_Qty * e.unit_cost)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Value,

    CAST(
        100.0 * SUM(e.Potential_Excess_Qty * e.unit_cost)
        / SUM(SUM(e.Potential_Excess_Qty * e.unit_cost)) OVER ()
        AS DECIMAL(8,2)
    ) AS Excess_Value_Share_Pct

FROM ExcessInventory AS e

INNER JOIN raw.Warehouses AS w
    ON e.warehouse_id = w.warehouse_id

WHERE e.Potential_Excess_Qty > 0

GROUP BY
    e.warehouse_id,
    w.warehouse_name

ORDER BY
    Potential_Excess_Value DESC;




-- ============================================================
-- Step 13: Potential Excess Inventory by Product Category
-- ============================================================

WITH ExcessInventory AS
(
    SELECT
        product_id,
        warehouse_id,
        available_qty,
        avg_daily_demand,
        unit_cost,

        CASE
            WHEN available_qty > 60.0 * avg_daily_demand
            THEN available_qty - (60.0 * avg_daily_demand)
            ELSE 0
        END AS Potential_Excess_Qty

    FROM raw.Inventory
)

SELECT
    p.category,

    COUNT(*) AS Excess_Records,

    COUNT(DISTINCT e.product_id)
        AS Products_Affected,

    CAST(
        SUM(e.Potential_Excess_Qty)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Qty,

    CAST(
        SUM(e.Potential_Excess_Qty * e.unit_cost)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Value,

    CAST(
        100.0 * SUM(e.Potential_Excess_Qty * e.unit_cost)
        / SUM(SUM(e.Potential_Excess_Qty * e.unit_cost)) OVER ()
        AS DECIMAL(8,2)
    ) AS Excess_Value_Share_Pct

FROM ExcessInventory AS e

INNER JOIN raw.Products AS p
    ON e.product_id = p.product_id

WHERE e.Potential_Excess_Qty > 0

GROUP BY
    p.category

ORDER BY
    Potential_Excess_Value DESC;




-- ============================================================
-- Step 14: Net Replenishment by ABC-XYZ Class
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
        ISNULL(md.Monthly_Demand_Qty, 0)
            AS Monthly_Demand_Qty
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

ABCXYZ AS
(
    SELECT
        a.product_id,
        a.ABC_Class + x.XYZ_Class AS ABC_XYZ_Class
    FROM ABC AS a
    INNER JOIN XYZ AS x
        ON a.product_id = x.product_id
),

InboundPO AS
(
    SELECT
        product_id,
        warehouse_id,
        SUM(ordered_qty - received_qty)
            AS Outstanding_PO_Qty
    FROM raw.Purchase_Orders
    WHERE ordered_qty > received_qty
    GROUP BY
        product_id,
        warehouse_id
),

NetGap AS
(
    SELECT
        i.product_id,
        i.warehouse_id,
        i.unit_cost,

        CASE
            WHEN
                CASE
                    WHEN i.reorder_point > i.available_qty
                    THEN i.reorder_point - i.available_qty
                    ELSE 0
                END
                - ISNULL(po.Outstanding_PO_Qty, 0) > 0

            THEN
                CASE
                    WHEN i.reorder_point > i.available_qty
                    THEN i.reorder_point - i.available_qty
                    ELSE 0
                END
                - ISNULL(po.Outstanding_PO_Qty, 0)

            ELSE 0
        END AS Net_Gap_Qty

    FROM raw.Inventory AS i

    LEFT JOIN InboundPO AS po
        ON i.product_id = po.product_id
       AND i.warehouse_id = po.warehouse_id
)

SELECT
    ax.ABC_XYZ_Class,

    COUNT(*) AS Replenishment_Records,

    COUNT(DISTINCT n.product_id)
        AS Products_Affected,

    SUM(n.Net_Gap_Qty)
        AS Net_Replenishment_Qty,

    CAST(
        SUM(n.Net_Gap_Qty * n.unit_cost)
        AS DECIMAL(18,2)
    ) AS Net_Replenishment_Value,

    CAST(
        100.0 * SUM(n.Net_Gap_Qty * n.unit_cost)
        / SUM(SUM(n.Net_Gap_Qty * n.unit_cost)) OVER ()
        AS DECIMAL(8,2)
    ) AS Replenishment_Value_Share_Pct

FROM NetGap AS n

INNER JOIN ABCXYZ AS ax
    ON n.product_id = ax.product_id

WHERE n.Net_Gap_Qty > 0

GROUP BY
    ax.ABC_XYZ_Class

ORDER BY
    Net_Replenishment_Value DESC;






-- ============================================================
-- Step 15: Potential Excess Inventory by ABC-XYZ Class
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
    WHERE transaction_date >= '2024-01-01'
      AND transaction_date < '2026-10-01'
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
        ISNULL(md.Monthly_Demand_Qty, 0)
            AS Monthly_Demand_Qty

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

ABCXYZ AS
(
    SELECT
        a.product_id,
        a.ABC_Class + x.XYZ_Class AS ABC_XYZ_Class

    FROM ABC AS a

    INNER JOIN XYZ AS x
        ON a.product_id = x.product_id
),

ExcessInventory AS
(
    SELECT
        product_id,
        warehouse_id,
        unit_cost,

        CASE
            WHEN available_qty > 60.0 * avg_daily_demand
            THEN available_qty - (60.0 * avg_daily_demand)
            ELSE 0
        END AS Potential_Excess_Qty

    FROM raw.Inventory
)

SELECT
    ax.ABC_XYZ_Class,

    COUNT(*) AS Excess_Records,

    COUNT(DISTINCT e.product_id)
        AS Products_Affected,

    CAST(
        SUM(e.Potential_Excess_Qty)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Qty,

    CAST(
        SUM(e.Potential_Excess_Qty * e.unit_cost)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Value,

    CAST(
        100.0 * SUM(e.Potential_Excess_Qty * e.unit_cost)
        / SUM(SUM(e.Potential_Excess_Qty * e.unit_cost)) OVER ()
        AS DECIMAL(8,2)
    ) AS Excess_Value_Share_Pct

FROM ExcessInventory AS e

INNER JOIN ABCXYZ AS ax
    ON e.product_id = ax.product_id

WHERE e.Potential_Excess_Qty > 0

GROUP BY
    ax.ABC_XYZ_Class

ORDER BY
    Potential_Excess_Value DESC;





-- ============================================================
-- Step 16: Excess Inventory Reduction Priority
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

    WHERE transaction_date >= '2024-01-01'
      AND transaction_date < '2026-10-01'
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

        STDEV(1.0 * Monthly_Demand_Qty)
            AS StdDev_Monthly_Demand

    FROM CompleteDemand

    GROUP BY product_id
),

XYZ AS
(
    SELECT
        product_id,

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

ABCXYZ AS
(
    SELECT
        a.product_id,
        a.ABC_Class + x.XYZ_Class AS ABC_XYZ_Class

    FROM ABC AS a

    INNER JOIN XYZ AS x
        ON a.product_id = x.product_id
),

ExcessInventory AS
(
    SELECT
        i.product_id,
        i.warehouse_id,
        i.unit_cost,

        CASE
            WHEN i.available_qty > 60.0 * i.avg_daily_demand
            THEN i.available_qty - (60.0 * i.avg_daily_demand)
            ELSE 0
        END AS Potential_Excess_Qty

    FROM raw.Inventory AS i
),

PrioritizedExcess AS
(
    SELECT
        e.*,
        ax.ABC_XYZ_Class,

        CASE
            WHEN ax.ABC_XYZ_Class IN ('CZ','BZ')
                THEN 'Highest'

            WHEN ax.ABC_XYZ_Class IN ('CY','AZ')
                THEN 'High'

            WHEN ax.ABC_XYZ_Class IN ('BY','CX')
                THEN 'Moderate'

            WHEN ax.ABC_XYZ_Class = 'BX'
                THEN 'Low'

            WHEN ax.ABC_XYZ_Class IN ('AX','AY')
                THEN 'Protect / Review'

            ELSE 'Review'
        END AS Reduction_Priority

    FROM ExcessInventory AS e

    INNER JOIN ABCXYZ AS ax
        ON e.product_id = ax.product_id

    WHERE e.Potential_Excess_Qty > 0
)

SELECT
    Reduction_Priority,

    COUNT(*) AS Excess_Records,

    COUNT(DISTINCT product_id) AS Products_Affected,

    CAST(
        SUM(Potential_Excess_Qty)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Qty,

    CAST(
        SUM(Potential_Excess_Qty * unit_cost)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Value,

    CAST(
        100.0 * SUM(Potential_Excess_Qty * unit_cost)
        / SUM(SUM(Potential_Excess_Qty * unit_cost)) OVER ()
        AS DECIMAL(8,2)
    ) AS Excess_Value_Share_Pct

FROM PrioritizedExcess

GROUP BY Reduction_Priority

ORDER BY
    CASE Reduction_Priority
        WHEN 'Highest' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Moderate' THEN 3
        WHEN 'Low' THEN 4
        WHEN 'Protect / Review' THEN 5
        ELSE 6
    END;


-- ============================================================
-- Step 17: Top Net Replenishment Products
-- ============================================================

WITH InboundPO AS
(
    SELECT
        product_id,
        warehouse_id,
        SUM(ordered_qty - received_qty) AS Outstanding_PO_Qty

    FROM raw.Purchase_Orders

    WHERE ordered_qty > received_qty

    GROUP BY
        product_id,
        warehouse_id
),

NetGap AS
(
    SELECT
        i.product_id,
        i.warehouse_id,
        i.unit_cost,

        CASE
            WHEN
                CASE
                    WHEN i.reorder_point > i.available_qty
                    THEN i.reorder_point - i.available_qty
                    ELSE 0
                END
                - ISNULL(po.Outstanding_PO_Qty, 0) > 0

            THEN
                CASE
                    WHEN i.reorder_point > i.available_qty
                    THEN i.reorder_point - i.available_qty
                    ELSE 0
                END
                - ISNULL(po.Outstanding_PO_Qty, 0)

            ELSE 0
        END AS Net_Gap_Qty

    FROM raw.Inventory AS i

    LEFT JOIN InboundPO AS po
        ON i.product_id = po.product_id
       AND i.warehouse_id = po.warehouse_id
),

ProductRisk AS
(
    SELECT
        product_id,

        COUNT(*) AS Replenishment_Records,

        SUM(Net_Gap_Qty)
            AS Net_Replenishment_Qty,

        SUM(Net_Gap_Qty * unit_cost)
            AS Net_Replenishment_Value

    FROM NetGap

    WHERE Net_Gap_Qty > 0

    GROUP BY product_id
)

SELECT TOP 15
    r.product_id,
    p.product_name,
    p.category,

    r.Replenishment_Records,

    r.Net_Replenishment_Qty,

    CAST(
        r.Net_Replenishment_Value
        AS DECIMAL(18,2)
    ) AS Net_Replenishment_Value,

    CAST(
        100.0 * r.Net_Replenishment_Value
        / SUM(r.Net_Replenishment_Value) OVER ()
        AS DECIMAL(8,2)
    ) AS Replenishment_Value_Share_Pct

FROM ProductRisk AS r

INNER JOIN raw.Products AS p
    ON r.product_id = p.product_id

ORDER BY
    r.Net_Replenishment_Value DESC;




-- ============================================================
-- Step 18: Top Potential Excess Products
-- ============================================================

WITH ExcessInventory AS
(
    SELECT
        product_id,
        warehouse_id,
        unit_cost,

        CASE
            WHEN available_qty > 60.0 * avg_daily_demand
            THEN available_qty - (60.0 * avg_daily_demand)
            ELSE 0
        END AS Potential_Excess_Qty

    FROM raw.Inventory
),

ProductExcess AS
(
    SELECT
        product_id,

        COUNT(*) AS Excess_Records,

        SUM(Potential_Excess_Qty)
            AS Potential_Excess_Qty,

        SUM(Potential_Excess_Qty * unit_cost)
            AS Potential_Excess_Value

    FROM ExcessInventory

    WHERE Potential_Excess_Qty > 0

    GROUP BY product_id
)

SELECT TOP 15
    e.product_id,
    p.product_name,
    p.category,

    e.Excess_Records,

    CAST(
        e.Potential_Excess_Qty
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Qty,

    CAST(
        e.Potential_Excess_Value
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Value,

    CAST(
        100.0 * e.Potential_Excess_Value
        / SUM(e.Potential_Excess_Value) OVER ()
        AS DECIMAL(8,2)
    ) AS Excess_Value_Share_Pct

FROM ProductExcess AS e

INNER JOIN raw.Products AS p
    ON e.product_id = p.product_id

ORDER BY
    e.Potential_Excess_Value DESC;



-- ============================================================
-- Step 19: Inventory Optimization Action Matrix
-- ============================================================

SELECT *
FROM
(
    VALUES

    (
        'Critical Replenishment',
        'Immediate',
        'Net shortage remains after considering inbound purchase orders',
        'Prioritize replenishment or inventory transfer immediately',
        'Net Replenishment Qty / Stockout Rate'
    ),

    (
        'High Replenishment',
        'High',
        'Available inventory is below safety stock and inbound supply is insufficient',
        'Expedite inbound supply and review safety-stock coverage',
        'Safety Stock Shortfall / Net Replenishment Qty'
    ),

    (
        'Moderate Replenishment',
        'Medium',
        'Inventory is below reorder point with limited days of coverage',
        'Schedule replenishment and monitor consumption',
        'Days of Inventory / Reorder Gap'
    ),

    (
        'Low Replenishment',
        'Low',
        'Replenishment gap exists but immediate availability risk is lower',
        'Include in normal replenishment cycle',
        'Reorder Gap'
    ),

    (
        'Highest Excess Reduction',
        'High',
        'Potential excess exists in CZ or BZ products with variable demand',
        'Review purchase reduction, stock transfer, or controlled depletion',
        'Potential Excess Value / Days of Inventory'
    ),

    (
        'High Excess Reduction',
        'High',
        'Potential excess exists in CY or AZ products',
        'Review demand pattern before reducing future replenishment',
        'Potential Excess Value / Demand Variability'
    ),

    (
        'Moderate Excess Reduction',
        'Medium',
        'Potential excess exists in BY or CX products',
        'Monitor consumption and adjust reorder parameters where justified',
        'Potential Excess Value'
    ),

    (
        'Protect / Review',
        'Critical Review',
        'Potential excess is concentrated in strategically important AX or AY products',
        'Do not automatically reduce; validate service requirements and demand outlook',
        'Service Level / Demand / Inventory Coverage'
    ),

    (
        'Balanced Inventory',
        'Monitor',
        'No material net replenishment gap or 60-day excess condition',
        'Continue routine inventory monitoring',
        'Days of Inventory / Reorder Status'
    )

) AS ActionMatrix
(
    Optimization_Scenario,
    Management_Priority,
    Analytical_Condition,
    Recommended_Action,
    KPI_To_Monitor
)

ORDER BY
    CASE Management_Priority
        WHEN 'Immediate' THEN 1
        WHEN 'Critical Review' THEN 2
        WHEN 'High' THEN 3
        WHEN 'Medium' THEN 4
        WHEN 'Low' THEN 5
        WHEN 'Monitor' THEN 6
    END;




-- ============================================================
-- Step 20: Final Inventory Optimization KPI Summary
-- ============================================================

WITH InboundPO AS
(
    SELECT
        product_id,
        warehouse_id,
        SUM(ordered_qty - received_qty) AS Outstanding_PO_Qty
    FROM raw.Purchase_Orders
    WHERE ordered_qty > received_qty
    GROUP BY product_id, warehouse_id
),

OptimizationBase AS
(
    SELECT
        i.product_id,
        i.warehouse_id,
        i.available_qty,
        i.avg_daily_demand,
        i.safety_stock,
        i.reorder_point,
        i.unit_cost,
        i.inventory_value,

        ISNULL(po.Outstanding_PO_Qty, 0)
            AS Outstanding_PO_Qty,

        CASE
            WHEN i.reorder_point > i.available_qty
            THEN i.reorder_point - i.available_qty
            ELSE 0
        END AS Gross_Gap_Qty,

        CASE
            WHEN i.available_qty > 60.0 * i.avg_daily_demand
            THEN i.available_qty - (60.0 * i.avg_daily_demand)
            ELSE 0
        END AS Potential_Excess_Qty

    FROM raw.Inventory AS i

    LEFT JOIN InboundPO AS po
        ON i.product_id = po.product_id
       AND i.warehouse_id = po.warehouse_id
),

FinalBase AS
(
    SELECT
        *,

        CASE
            WHEN Gross_Gap_Qty - Outstanding_PO_Qty > 0
            THEN Gross_Gap_Qty - Outstanding_PO_Qty
            ELSE 0
        END AS Net_Gap_Qty

    FROM OptimizationBase
)

SELECT
    COUNT(*) AS Total_Inventory_Records,

    COUNT(DISTINCT product_id)
        AS Total_Products,

    CAST(
        SUM(inventory_value)
        AS DECIMAL(18,2)
    ) AS Total_Inventory_Value,

    SUM(
        CASE
            WHEN available_qty <= reorder_point
            THEN 1 ELSE 0
        END
    ) AS Reorder_Required_Records,

    SUM(
        CASE
            WHEN available_qty < safety_stock
            THEN 1 ELSE 0
        END
    ) AS Below_Safety_Stock_Records,

    SUM(
        CASE
            WHEN available_qty = 0
            THEN 1 ELSE 0
        END
    ) AS Stockout_Records,

    SUM(
        CASE
            WHEN Net_Gap_Qty > 0
            THEN 1 ELSE 0
        END
    ) AS Net_Replenishment_Records,

    SUM(Net_Gap_Qty)
        AS Net_Replenishment_Qty,

    CAST(
        SUM(Net_Gap_Qty * unit_cost)
        AS DECIMAL(18,2)
    ) AS Net_Replenishment_Value,

    SUM(
        CASE
            WHEN Potential_Excess_Qty > 0
            THEN 1 ELSE 0
        END
    ) AS Potential_Excess_Records,

    CAST(
        SUM(Potential_Excess_Qty)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Qty,

    CAST(
        SUM(Potential_Excess_Qty * unit_cost)
        AS DECIMAL(18,2)
    ) AS Potential_Excess_Value

FROM FinalBase;




-- ============================================================
-- Step 21: Inventory Optimization Reconciliation
-- ============================================================

DECLARE @OptimizationChecks TABLE
(
    Validation_Check VARCHAR(150),
    Status VARCHAR(10)
);

INSERT INTO @OptimizationChecks
VALUES

('Total Inventory Records',
 CASE WHEN (SELECT COUNT(*) FROM raw.Inventory) = 3000
      THEN 'PASS' ELSE 'FAIL' END),

('Total Products',
 CASE WHEN (SELECT COUNT(DISTINCT product_id) FROM raw.Inventory) = 500
      THEN 'PASS' ELSE 'FAIL' END),

('Total Warehouses',
 CASE WHEN (SELECT COUNT(DISTINCT warehouse_id) FROM raw.Inventory) = 6
      THEN 'PASS' ELSE 'FAIL' END),

('Total On-Hand Quantity',
 CASE WHEN (SELECT SUM(on_hand_qty) FROM raw.Inventory) = 85305
      THEN 'PASS' ELSE 'FAIL' END),

('Total Available Quantity',
 CASE WHEN (SELECT SUM(available_qty) FROM raw.Inventory) = 78219
      THEN 'PASS' ELSE 'FAIL' END),

('Total Inventory Value',
 CASE WHEN ABS(
      (SELECT SUM(inventory_value) FROM raw.Inventory)
      - 285985182.32
      ) < 0.01
      THEN 'PASS' ELSE 'FAIL' END),

('Reorder Required Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Inventory
          WHERE available_qty <= reorder_point
      ) = 1311
      THEN 'PASS' ELSE 'FAIL' END),

('Below Safety Stock Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Inventory
          WHERE available_qty < safety_stock
      ) = 445
      THEN 'PASS' ELSE 'FAIL' END),

('Stockout Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Inventory
          WHERE available_qty = 0
      ) = 240
      THEN 'PASS' ELSE 'FAIL' END),

('Outstanding PO Quantity',
 CASE WHEN
      (
          SELECT SUM(ordered_qty - received_qty)
          FROM raw.Purchase_Orders
      ) = 132826
      THEN 'PASS' ELSE 'FAIL' END),

('Gross Replenishment Gap Quantity',
 CASE WHEN
      (
          SELECT SUM(
              CASE
                  WHEN reorder_point > available_qty
                  THEN reorder_point - available_qty
                  ELSE 0
              END
          )
          FROM raw.Inventory
      ) = 14788
      THEN 'PASS' ELSE 'FAIL' END),

('Potential Excess Record Count',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Inventory
          WHERE available_qty > 60.0 * avg_daily_demand
      ) = 330
      THEN 'PASS' ELSE 'FAIL' END);

SELECT *
FROM @OptimizationChecks;

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
    END AS Reconciliation_Status

FROM @OptimizationChecks;


-- ============================================================
-- Step 22: Final Business Insights
-- ============================================================

/*
1. INVENTORY POSITION
   - Total inventory value is approximately 285.99M.
   - Average inventory coverage is approximately 32.18 days.
   - 240 product-warehouse positions currently have zero
     available inventory.

2. REPLENISHMENT RISK
   - 1,311 inventory positions have reached or fallen below
     their reorder point.
   - 445 positions are already below safety stock.
   - The initial gross replenishment requirement is 14,788 units,
     valued at approximately 48.26M.

3. INBOUND PO IMPACT
   - Existing purchase orders significantly reduce the apparent
     replenishment requirement.
   - 1,080 reorder-required positions already have inbound supply.
   - 918 positive shortage positions are fully covered by inbound POs.
   - After inbound supply is considered, only 309 positions still
     require additional replenishment.

4. NET REPLENISHMENT REQUIREMENT
   - Final net replenishment requirement is 1,984 units.
   - Estimated replenishment value is approximately 6.85M.
   - This demonstrates why inbound supply must be considered before
     recommending additional purchasing.

5. REPLENISHMENT PRIORITY
   - Critical and High priority shortages should receive the
     fastest operational attention.
   - High-value A-class products represent a significant share of
     the remaining replenishment exposure.
   - AY and AX products together account for more than half of
     net replenishment value.

6. WAREHOUSE RISK
   - Pune DC has the largest net replenishment value exposure.
   - Bengaluru Central is the second-largest replenishment exposure.
   - Replenishment decisions should therefore consider warehouse-level
     availability rather than only company-wide inventory.

7. CATEGORY RISK
   - Electronics has the highest remaining replenishment value exposure.
   - Health & Personal Care and Office Supplies are the next-largest
     category-level exposures.

8. POTENTIAL EXCESS INVENTORY
   - 330 product-warehouse positions exceed the 60-day demand threshold.
   - Potential excess is approximately 1,903.80 units,
     valued at approximately 6.63M.
   - This represents only about 2.32% of total inventory value.

9. EXCESS INVENTORY CONTROL
   - Potential excess should not automatically be treated as removable.
   - AX and AY products account for 77.53% of potential excess value
     and should generally be protected or reviewed carefully.
   - Highest and High excess-reduction priorities represent only
     about 610,994 in potential excess value.

10. MANAGEMENT RECOMMENDATION
    - Prioritize genuine net shortages after accounting for inbound POs.
    - Protect strategically important AX/AY products.
    - Review CZ/BZ and other lower-priority excess positions for
      controlled depletion, transfers, or purchase reductions.
    - Use product, warehouse, category, demand variability and inbound
      supply together when making inventory optimization decisions.
*/



-- ============================================================
-- Step 23: Final Inventory Optimization Validation
-- ============================================================

DECLARE @FinalOptimizationValidation TABLE
(
    Validation_Check VARCHAR(150),
    Status VARCHAR(10)
);

INSERT INTO @FinalOptimizationValidation
VALUES

('Total Inventory Records',
 CASE WHEN (SELECT COUNT(*) FROM raw.Inventory) = 3000
      THEN 'PASS' ELSE 'FAIL' END),

('Total Products',
 CASE WHEN (SELECT COUNT(DISTINCT product_id) FROM raw.Inventory) = 500
      THEN 'PASS' ELSE 'FAIL' END),

('Total Warehouses',
 CASE WHEN (SELECT COUNT(DISTINCT warehouse_id) FROM raw.Inventory) = 6
      THEN 'PASS' ELSE 'FAIL' END),

('Total On-Hand Quantity',
 CASE WHEN (SELECT SUM(on_hand_qty) FROM raw.Inventory) = 85305
      THEN 'PASS' ELSE 'FAIL' END),

('Total Allocated Quantity',
 CASE WHEN (SELECT SUM(allocated_qty) FROM raw.Inventory) = 7086
      THEN 'PASS' ELSE 'FAIL' END),

('Total Available Quantity',
 CASE WHEN (SELECT SUM(available_qty) FROM raw.Inventory) = 78219
      THEN 'PASS' ELSE 'FAIL' END),

('Inventory Quantity Reconciles',
 CASE WHEN
      (SELECT SUM(on_hand_qty) FROM raw.Inventory) =
      (SELECT SUM(allocated_qty + available_qty) FROM raw.Inventory)
      THEN 'PASS' ELSE 'FAIL' END),

('Total Inventory Value',
 CASE WHEN ABS(
      (SELECT SUM(inventory_value) FROM raw.Inventory)
      - 285985182.32) < 0.01
      THEN 'PASS' ELSE 'FAIL' END),

('Reorder Required Records',
 CASE WHEN
      (SELECT COUNT(*) FROM raw.Inventory
       WHERE available_qty <= reorder_point) = 1311
      THEN 'PASS' ELSE 'FAIL' END),

('Below Safety Stock Records',
 CASE WHEN
      (SELECT COUNT(*) FROM raw.Inventory
       WHERE available_qty < safety_stock) = 445
      THEN 'PASS' ELSE 'FAIL' END),

('Stockout Records',
 CASE WHEN
      (SELECT COUNT(*) FROM raw.Inventory
       WHERE available_qty = 0) = 240
      THEN 'PASS' ELSE 'FAIL' END),

('Positive Gross Gap Records',
 CASE WHEN
      (SELECT COUNT(*)
       FROM raw.Inventory
       WHERE reorder_point > available_qty) = 1227
      THEN 'PASS' ELSE 'FAIL' END),

('Gross Replenishment Gap Quantity',
 CASE WHEN
      (
          SELECT SUM(
              CASE
                  WHEN reorder_point > available_qty
                  THEN reorder_point - available_qty
                  ELSE 0
              END
          )
          FROM raw.Inventory
      ) = 14788
      THEN 'PASS' ELSE 'FAIL' END),

('Outstanding PO Quantity',
 CASE WHEN
      (
          SELECT SUM(ordered_qty - received_qty)
          FROM raw.Purchase_Orders
      ) = 132826
      THEN 'PASS' ELSE 'FAIL' END),

('Inbound Product-Warehouse Coverage',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM
          (
              SELECT product_id, warehouse_id
              FROM raw.Purchase_Orders
              WHERE ordered_qty > received_qty
              GROUP BY product_id, warehouse_id
          ) x
      ) = 2525
      THEN 'PASS' ELSE 'FAIL' END),

('Potential Excess Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Inventory
          WHERE available_qty > 60.0 * avg_daily_demand
      ) = 330
      THEN 'PASS' ELSE 'FAIL' END),

('Potential Excess Quantity',
 CASE WHEN ABS(
      (
          SELECT SUM(
              CASE
                  WHEN available_qty > 60.0 * avg_daily_demand
                  THEN available_qty - (60.0 * avg_daily_demand)
                  ELSE 0
              END
          )
          FROM raw.Inventory
      ) - 1903.80) < 0.01
      THEN 'PASS' ELSE 'FAIL' END),

('No Negative Available Inventory',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Inventory
          WHERE available_qty < 0
      )
      THEN 'PASS' ELSE 'FAIL' END),

('No Negative Safety Stock',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Inventory
          WHERE safety_stock < 0
      )
      THEN 'PASS' ELSE 'FAIL' END),

('No Negative Reorder Point',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Inventory
          WHERE reorder_point < 0
      )
      THEN 'PASS' ELSE 'FAIL' END),

('Inventory Product Foreign Keys Valid',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Inventory i
          LEFT JOIN raw.Products p
              ON i.product_id = p.product_id
          WHERE p.product_id IS NULL
      )
      THEN 'PASS' ELSE 'FAIL' END),

('Inventory Warehouse Foreign Keys Valid',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Inventory i
          LEFT JOIN raw.Warehouses w
              ON i.warehouse_id = w.warehouse_id
          WHERE w.warehouse_id IS NULL
      )
      THEN 'PASS' ELSE 'FAIL' END),

('Inventory Product-Warehouse Unique',
 CASE WHEN NOT EXISTS
      (
          SELECT
              product_id,
              warehouse_id
          FROM raw.Inventory
          GROUP BY
              product_id,
              warehouse_id
          HAVING COUNT(*) > 1
      )
      THEN 'PASS' ELSE 'FAIL' END);

SELECT *
FROM @FinalOptimizationValidation;

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
    END AS Final_Inventory_Optimization_Status

FROM @FinalOptimizationValidation;


