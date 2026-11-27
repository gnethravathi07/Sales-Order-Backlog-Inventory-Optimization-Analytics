-- ============================================================
-- SALES ORDER, BACKLOG & INVENTORY ANALYTICS
-- File: 04_Inventory_Analysis.sql
-- Purpose: Analyze inventory levels, stock status, stockouts,
--          reorder requirements and inventory exposure
-- ============================================================

USE Sales_Order_Backlog_Inventory_Analytics;
GO

-- ============================================================
-- Step 1: Validate Inventory Analysis Source Data
-- ============================================================

SELECT
    COUNT(*) AS Inventory_Rows,

    COUNT(DISTINCT product_id) AS Unique_Products,

    COUNT(DISTINCT warehouse_id) AS Unique_Warehouses,

    SUM(on_hand_qty) AS Total_On_Hand_Qty,

    SUM(allocated_qty) AS Total_Allocated_Qty,

    SUM(available_qty) AS Total_Available_Qty,

    CAST(
        SUM(inventory_value)
        AS DECIMAL(18,2)
    ) AS Total_Inventory_Value

FROM raw.Inventory;


-- ============================================================
-- Step 2: Overall Inventory KPI Summary
-- ============================================================

SELECT
    SUM(on_hand_qty) AS Total_On_Hand_Qty,

    SUM(allocated_qty) AS Total_Allocated_Qty,

    SUM(available_qty) AS Total_Available_Qty,

    CAST(
        100.0 * SUM(allocated_qty)
        / NULLIF(SUM(on_hand_qty), 0)
        AS DECIMAL(8,2)
    ) AS Allocation_Rate_Pct,

    CAST(
        SUM(inventory_value)
        AS DECIMAL(18,2)
    ) AS Total_Inventory_Value,

    SUM(
        CASE
            WHEN available_qty <= reorder_point
            THEN 1
            ELSE 0
        END
    ) AS Reorder_Required_Records,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN available_qty <= reorder_point
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Reorder_Required_Rate_Pct,

    CAST(
        AVG(
            1.0 * available_qty
            / NULLIF(avg_daily_demand, 0)
        )
        AS DECIMAL(8,2)
    ) AS Avg_Inventory_Days_On_Hand

FROM raw.Inventory;



-- ============================================================
-- Step 3: Inventory Analysis by Stock Status
-- ============================================================

SELECT
    stock_status,

    COUNT(*) AS Inventory_Records,

    COUNT(DISTINCT product_id) AS Unique_Products,

    SUM(on_hand_qty) AS On_Hand_Qty,

    SUM(available_qty) AS Available_Qty,

    CAST(
        SUM(inventory_value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        100.0 * SUM(inventory_value)
        / SUM(SUM(inventory_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Inventory_Value_Share_Pct

FROM raw.Inventory

GROUP BY
    stock_status

ORDER BY
    Inventory_Value DESC;



-- ============================================================
-- Step 4: Reorder Requirement Analysis
-- ============================================================

SELECT
    CASE
        WHEN available_qty <= reorder_point
            THEN 'Reorder Required'
        ELSE 'No Reorder Required'
    END AS Reorder_Status,

    COUNT(*) AS Inventory_Records,

    COUNT(DISTINCT product_id) AS Unique_Products,

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
        AVG(
            1.0 * available_qty
            / NULLIF(avg_daily_demand, 0)
        )
        AS DECIMAL(8,2)
    ) AS Avg_Days_On_Hand

FROM raw.Inventory

GROUP BY
    CASE
        WHEN available_qty <= reorder_point
            THEN 'Reorder Required'
        ELSE 'No Reorder Required'
    END

ORDER BY
    Inventory_Value DESC;


-- ============================================================
-- Step 5: Inventory Days-on-Hand Distribution
-- ============================================================

WITH InventoryDOH AS
(
    SELECT
        product_id,
        warehouse_id,
        available_qty,
        inventory_value,

        1.0 * available_qty
        / NULLIF(avg_daily_demand, 0) AS Days_On_Hand

    FROM raw.Inventory
),

DOHBands AS
(
    SELECT
        *,

        CASE
            WHEN Days_On_Hand = 0
                THEN '0 Days'

            WHEN Days_On_Hand <= 7
                THEN '1-7 Days'

            WHEN Days_On_Hand <= 15
                THEN '8-15 Days'

            WHEN Days_On_Hand <= 30
                THEN '16-30 Days'

            WHEN Days_On_Hand <= 60
                THEN '31-60 Days'

            ELSE '61+ Days'
        END AS DOH_Band

    FROM InventoryDOH
)

SELECT
    DOH_Band,

    COUNT(*) AS Inventory_Records,

    COUNT(DISTINCT product_id) AS Unique_Products,

    SUM(available_qty) AS Available_Qty,

    CAST(
        SUM(inventory_value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        100.0 * SUM(inventory_value)
        / SUM(SUM(inventory_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Inventory_Value_Share_Pct

FROM DOHBands

GROUP BY
    DOH_Band

ORDER BY
    CASE DOH_Band
        WHEN '0 Days' THEN 1
        WHEN '1-7 Days' THEN 2
        WHEN '8-15 Days' THEN 3
        WHEN '16-30 Days' THEN 4
        WHEN '31-60 Days' THEN 5
        WHEN '61+ Days' THEN 6
    END;


-- ============================================================
-- Step 6: Inventory Analysis by Product Category
-- ============================================================

SELECT
    p.category,

    COUNT(*) AS Inventory_Records,

    COUNT(DISTINCT i.product_id) AS Unique_Products,

    SUM(i.on_hand_qty) AS On_Hand_Qty,

    SUM(i.available_qty) AS Available_Qty,

    CAST(
        SUM(i.inventory_value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    SUM(
        CASE
            WHEN i.available_qty <= i.reorder_point
            THEN 1
            ELSE 0
        END
    ) AS Reorder_Required_Records,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN i.available_qty <= i.reorder_point
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Reorder_Rate_Pct,

    SUM(
        CASE
            WHEN i.stock_status = 'Stockout'
            THEN 1
            ELSE 0
        END
    ) AS Stockout_Records

FROM raw.Inventory AS i

INNER JOIN raw.Products AS p
    ON i.product_id = p.product_id

GROUP BY
    p.category

ORDER BY
    Inventory_Value DESC;



-- ============================================================
-- Step 7: Inventory Analysis by Warehouse
-- ============================================================

SELECT
    w.warehouse_id,
    w.warehouse_name,

    COUNT(*) AS Inventory_Records,

    SUM(i.on_hand_qty) AS On_Hand_Qty,

    SUM(i.allocated_qty) AS Allocated_Qty,

    SUM(i.available_qty) AS Available_Qty,

    CAST(
        SUM(i.inventory_value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    SUM(
        CASE
            WHEN i.available_qty <= i.reorder_point
            THEN 1
            ELSE 0
        END
    ) AS Reorder_Required_Records,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN i.available_qty <= i.reorder_point
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Reorder_Rate_Pct,

    SUM(
        CASE
            WHEN i.stock_status = 'Stockout'
            THEN 1
            ELSE 0
        END
    ) AS Stockout_Records

FROM raw.Inventory AS i

INNER JOIN raw.Warehouses AS w
    ON i.warehouse_id = w.warehouse_id

GROUP BY
    w.warehouse_id,
    w.warehouse_name

ORDER BY
    Inventory_Value DESC;


-- ============================================================
-- Step 8: Stockout Risk Analysis
-- ============================================================

SELECT
    COUNT(*) AS Stockout_Records,

    COUNT(DISTINCT product_id) AS Products_Affected,

    COUNT(DISTINCT warehouse_id) AS Warehouses_Affected,

    CAST(
        SUM(avg_daily_demand)
        AS DECIMAL(18,2)
    ) AS Total_Daily_Demand_Affected,

    CAST(
        AVG(avg_daily_demand)
        AS DECIMAL(18,2)
    ) AS Avg_Daily_Demand_Per_Stockout,

    SUM(safety_stock) AS Total_Safety_Stock,

    SUM(reorder_point) AS Total_Reorder_Point,

    SUM(on_hand_qty) AS On_Hand_Qty,

    SUM(available_qty) AS Available_Qty

FROM raw.Inventory

WHERE stock_status = 'Stockout';


-- ============================================================
-- Step 9: Stockout Analysis by Warehouse
-- ============================================================

SELECT
    w.warehouse_id,
    w.warehouse_name,

    COUNT(*) AS Stockout_Records,

    COUNT(DISTINCT i.product_id) AS Products_Affected,

    CAST(
        SUM(i.avg_daily_demand)
        AS DECIMAL(18,2)
    ) AS Daily_Demand_Affected,

    CAST(
        AVG(i.avg_daily_demand)
        AS DECIMAL(18,2)
    ) AS Avg_Daily_Demand_Per_Stockout,

    SUM(i.safety_stock) AS Safety_Stock,

    SUM(i.reorder_point) AS Reorder_Point

FROM raw.Inventory AS i

INNER JOIN raw.Warehouses AS w
    ON i.warehouse_id = w.warehouse_id

WHERE i.stock_status = 'Stockout'

GROUP BY
    w.warehouse_id,
    w.warehouse_name

ORDER BY
    Stockout_Records DESC,
    Daily_Demand_Affected DESC;



-- ============================================================
-- Step 10: Stockout Analysis by Product Category
-- ============================================================

SELECT
    p.category,

    COUNT(*) AS Stockout_Records,

    COUNT(DISTINCT i.product_id) AS Products_Affected,

    CAST(
        SUM(i.avg_daily_demand)
        AS DECIMAL(18,2)
    ) AS Daily_Demand_Affected,

    CAST(
        AVG(i.avg_daily_demand)
        AS DECIMAL(18,2)
    ) AS Avg_Daily_Demand_Per_Stockout,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Stockout_Record_Share_Pct

FROM raw.Inventory AS i

INNER JOIN raw.Products AS p
    ON i.product_id = p.product_id

WHERE i.stock_status = 'Stockout'

GROUP BY
    p.category

ORDER BY
    Daily_Demand_Affected DESC;


-- ============================================================
-- Step 11: Overstock Risk Analysis
-- ============================================================

SELECT
    COUNT(*) AS Overstock_Records,

    COUNT(DISTINCT product_id) AS Products_Affected,

    COUNT(DISTINCT warehouse_id) AS Warehouses_Affected,

    SUM(on_hand_qty) AS On_Hand_Qty,

    SUM(available_qty) AS Available_Qty,

    CAST(
        SUM(inventory_value)
        AS DECIMAL(18,2)
    ) AS Overstock_Inventory_Value,

    CAST(
        100.0 * SUM(inventory_value)
        /
        (SELECT SUM(inventory_value)
         FROM raw.Inventory)
        AS DECIMAL(8,2)
    ) AS Share_Of_Total_Inventory_Value_Pct,

    CAST(
        AVG(
            1.0 * available_qty
            / NULLIF(avg_daily_demand, 0)
        )
        AS DECIMAL(8,2)
    ) AS Avg_Days_On_Hand

FROM raw.Inventory

WHERE stock_status = 'Overstock';


-- ============================================================
-- Step 12: Overstock Analysis by Product Category
-- ============================================================

SELECT
    p.category,

    COUNT(*) AS Overstock_Records,

    COUNT(DISTINCT i.product_id) AS Products_Affected,

    SUM(i.available_qty) AS Available_Qty,

    CAST(
        SUM(i.inventory_value)
        AS DECIMAL(18,2)
    ) AS Overstock_Inventory_Value,

    CAST(
        100.0 * SUM(i.inventory_value)
        / SUM(SUM(i.inventory_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Overstock_Value_Share_Pct,

    CAST(
        AVG(
            1.0 * i.available_qty
            / NULLIF(i.avg_daily_demand, 0)
        )
        AS DECIMAL(8,2)
    ) AS Avg_Days_On_Hand

FROM raw.Inventory AS i

INNER JOIN raw.Products AS p
    ON i.product_id = p.product_id

WHERE i.stock_status = 'Overstock'

GROUP BY
    p.category

ORDER BY
    Overstock_Inventory_Value DESC;



-- ============================================================
-- Step 13: Overstock Analysis by Warehouse
-- ============================================================

SELECT
    w.warehouse_id,
    w.warehouse_name,

    COUNT(*) AS Overstock_Records,

    COUNT(DISTINCT i.product_id) AS Products_Affected,

    SUM(i.available_qty) AS Available_Qty,

    CAST(
        SUM(i.inventory_value)
        AS DECIMAL(18,2)
    ) AS Overstock_Inventory_Value,

    CAST(
        100.0 * SUM(i.inventory_value)
        / SUM(SUM(i.inventory_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Overstock_Value_Share_Pct,

    CAST(
        AVG(
            1.0 * i.available_qty
            / NULLIF(i.avg_daily_demand, 0)
        )
        AS DECIMAL(8,2)
    ) AS Avg_Days_On_Hand

FROM raw.Inventory AS i

INNER JOIN raw.Warehouses AS w
    ON i.warehouse_id = w.warehouse_id

WHERE i.stock_status = 'Overstock'

GROUP BY
    w.warehouse_id,
    w.warehouse_name

ORDER BY
    Overstock_Inventory_Value DESC;


-- ============================================================
-- Step 14: Top 10 Products by Inventory Value
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(i.on_hand_qty) AS On_Hand_Qty,
        SUM(i.available_qty) AS Available_Qty,
        SUM(i.inventory_value) AS Inventory_Value

    FROM raw.Inventory AS i

    INNER JOIN raw.Products AS p
        ON i.product_id = p.product_id

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
            ORDER BY Inventory_Value DESC
        ) AS Inventory_Value_Rank

    FROM ProductInventory
)

SELECT TOP 10
    Inventory_Value_Rank,
    product_id,
    product_name,
    category,
    On_Hand_Qty,
    Available_Qty,

    CAST(
        Inventory_Value
        AS DECIMAL(18,2)
    ) AS Inventory_Value

FROM RankedProducts

ORDER BY
    Inventory_Value_Rank,
    product_id;


-- ============================================================
-- Step 15: Top 10 Product Inventory Value Concentration
-- ============================================================

WITH ProductInventory AS
(
    SELECT
        product_id,
        SUM(inventory_value) AS Inventory_Value

    FROM raw.Inventory

    GROUP BY
        product_id
),

RankedProducts AS
(
    SELECT
        product_id,
        Inventory_Value,

        ROW_NUMBER() OVER (
            ORDER BY Inventory_Value DESC
        ) AS Inventory_Rank

    FROM ProductInventory
)

SELECT
    CAST(
        SUM(
            CASE
                WHEN Inventory_Rank <= 10
                THEN Inventory_Value
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Top_10_Product_Inventory_Value,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN Inventory_Rank <= 10
                THEN Inventory_Value
                ELSE 0
            END
        )
        / NULLIF(SUM(Inventory_Value), 0)
        AS DECIMAL(8,2)
    ) AS Top_10_Inventory_Value_Share_Pct

FROM RankedProducts;


-- ============================================================
-- Step 16: Top 10 Products by Average Inventory Days on Hand
-- ============================================================

WITH ProductDOH AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(i.available_qty) AS Available_Qty,

        CAST(
            AVG(
                1.0 * i.available_qty
                / NULLIF(i.avg_daily_demand, 0)
            )
            AS DECIMAL(8,2)
        ) AS Avg_Days_On_Hand

    FROM raw.Inventory AS i

    INNER JOIN raw.Products AS p
        ON i.product_id = p.product_id

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
            ORDER BY Avg_Days_On_Hand DESC
        ) AS DOH_Rank

    FROM ProductDOH
)

SELECT TOP 10
    DOH_Rank,
    product_id,
    product_name,
    category,
    Available_Qty,
    Avg_Days_On_Hand

FROM RankedProducts

ORDER BY
    DOH_Rank,
    product_id;


-- ============================================================
-- Step 17: Inventory Allocation Analysis by Warehouse
-- ============================================================

SELECT
    w.warehouse_id,
    w.warehouse_name,

    SUM(i.on_hand_qty) AS On_Hand_Qty,

    SUM(i.allocated_qty) AS Allocated_Qty,

    SUM(i.available_qty) AS Available_Qty,

    CAST(
        100.0 * SUM(i.allocated_qty)
        / NULLIF(SUM(i.on_hand_qty), 0)
        AS DECIMAL(8,2)
    ) AS Allocation_Rate_Pct,

    CAST(
        SUM(i.inventory_value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value

FROM raw.Inventory AS i

INNER JOIN raw.Warehouses AS w
    ON i.warehouse_id = w.warehouse_id

GROUP BY
    w.warehouse_id,
    w.warehouse_name

ORDER BY
    Allocation_Rate_Pct DESC;



-- ============================================================
-- Step 18: Reorder Risk by Product Category
-- ============================================================

SELECT
    p.category,

    COUNT(*) AS Reorder_Required_Records,

    COUNT(DISTINCT i.product_id) AS Products_Affected,

    SUM(i.available_qty) AS Available_Qty,

    CAST(
        SUM(i.avg_daily_demand)
        AS DECIMAL(18,2)
    ) AS Daily_Demand,

    CAST(
        SUM(i.inventory_value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        AVG(
            1.0 * i.available_qty
            / NULLIF(i.avg_daily_demand, 0)
        )
        AS DECIMAL(8,2)
    ) AS Avg_Days_On_Hand,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Reorder_Record_Share_Pct

FROM raw.Inventory AS i

INNER JOIN raw.Products AS p
    ON i.product_id = p.product_id

WHERE i.available_qty <= i.reorder_point

GROUP BY
    p.category

ORDER BY
    Reorder_Required_Records DESC;

-- ============================================================
-- Step 19: Reorder Risk by Warehouse
-- ============================================================

SELECT
    w.warehouse_id,
    w.warehouse_name,

    COUNT(*) AS Reorder_Required_Records,

    COUNT(DISTINCT i.product_id) AS Products_Affected,

    SUM(i.available_qty) AS Available_Qty,

    CAST(
        SUM(i.avg_daily_demand)
        AS DECIMAL(18,2)
    ) AS Daily_Demand,

    CAST(
        SUM(i.inventory_value)
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        AVG(
            1.0 * i.available_qty
            / NULLIF(i.avg_daily_demand, 0)
        )
        AS DECIMAL(8,2)
    ) AS Avg_Days_On_Hand,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Reorder_Record_Share_Pct

FROM raw.Inventory AS i

INNER JOIN raw.Warehouses AS w
    ON i.warehouse_id = w.warehouse_id

WHERE i.available_qty <= i.reorder_point

GROUP BY
    w.warehouse_id,
    w.warehouse_name

ORDER BY
    Reorder_Required_Records DESC;



-- ============================================================
-- Step 20: Top 10 Reorder-Risk Products
-- ============================================================

WITH ReorderRisk AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        COUNT(*) AS Reorder_Required_Locations,

        SUM(i.available_qty) AS Available_Qty,

        SUM(i.reorder_point) AS Reorder_Point,

        SUM(
            CASE
                WHEN i.available_qty <= i.reorder_point
                THEN i.reorder_point - i.available_qty
                ELSE 0
            END
        ) AS Replenishment_Gap_Qty,

        SUM(i.avg_daily_demand) AS Daily_Demand

    FROM raw.Inventory AS i

    INNER JOIN raw.Products AS p
        ON i.product_id = p.product_id

    WHERE i.available_qty <= i.reorder_point

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
)

SELECT TOP 10
    product_id,
    product_name,
    category,
    Reorder_Required_Locations,
    Available_Qty,
    Reorder_Point,
    Replenishment_Gap_Qty,

    CAST(
        Daily_Demand
        AS DECIMAL(18,2)
    ) AS Daily_Demand

FROM ReorderRisk

ORDER BY
    Replenishment_Gap_Qty DESC,
    Daily_Demand DESC;



-- ============================================================
-- Step 21: Inventory Risk Summary
-- ============================================================

SELECT
    COUNT(*) AS Total_Inventory_Records,

    SUM(
        CASE
            WHEN stock_status = 'Stockout'
            THEN 1 ELSE 0
        END
    ) AS Stockout_Records,

    SUM(
        CASE
            WHEN stock_status = 'Low Stock'
            THEN 1 ELSE 0
        END
    ) AS Low_Stock_Records,

    SUM(
        CASE
            WHEN stock_status = 'Overstock'
            THEN 1 ELSE 0
        END
    ) AS Overstock_Records,

    SUM(
        CASE
            WHEN available_qty <= reorder_point
            THEN 1 ELSE 0
        END
    ) AS Reorder_Required_Records,

    CAST(
        SUM(
            CASE
                WHEN stock_status = 'Overstock'
                THEN inventory_value
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Overstock_Inventory_Value,

    CAST(
        SUM(
            CASE
                WHEN available_qty <= reorder_point
                THEN inventory_value
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Reorder_Risk_Inventory_Value,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN stock_status = 'Overstock'
                THEN inventory_value
                ELSE 0
            END
        )
        / NULLIF(SUM(inventory_value), 0)
        AS DECIMAL(8,2)
    ) AS Overstock_Value_Share_Pct

FROM raw.Inventory;



-- ============================================================
-- Step 22: Inventory Quantity Reconciliation
-- ============================================================

SELECT
    SUM(on_hand_qty) AS Total_On_Hand_Qty,

    SUM(allocated_qty) AS Total_Allocated_Qty,

    SUM(available_qty) AS Total_Available_Qty,

    SUM(allocated_qty) + SUM(available_qty)
        AS Allocated_Plus_Available_Qty,

    SUM(on_hand_qty)
        - (SUM(allocated_qty) + SUM(available_qty))
        AS Quantity_Difference,

    SUM(
        CASE
            WHEN on_hand_qty <> allocated_qty + available_qty
            THEN 1
            ELSE 0
        END
    ) AS Invalid_Inventory_Records

FROM raw.Inventory;



-- ============================================================
-- Step 23: Final Inventory Analysis Validation
-- ============================================================

DECLARE @InventoryValidation TABLE
(
    Validation_Check VARCHAR(120),
    Status VARCHAR(10)
);

INSERT INTO @InventoryValidation
VALUES

('Total Inventory Records',
 CASE WHEN (SELECT COUNT(*) FROM raw.Inventory) = 3000
      THEN 'PASS' ELSE 'FAIL' END),

('Unique Products',
 CASE WHEN (SELECT COUNT(DISTINCT product_id)
            FROM raw.Inventory) = 500
      THEN 'PASS' ELSE 'FAIL' END),

('Unique Warehouses',
 CASE WHEN (SELECT COUNT(DISTINCT warehouse_id)
            FROM raw.Inventory) = 6
      THEN 'PASS' ELSE 'FAIL' END),

('Total On-Hand Quantity',
 CASE WHEN (SELECT SUM(on_hand_qty)
            FROM raw.Inventory) = 85305
      THEN 'PASS' ELSE 'FAIL' END),

('Total Allocated Quantity',
 CASE WHEN (SELECT SUM(allocated_qty)
            FROM raw.Inventory) = 7086
      THEN 'PASS' ELSE 'FAIL' END),

('Total Available Quantity',
 CASE WHEN (SELECT SUM(available_qty)
            FROM raw.Inventory) = 78219
      THEN 'PASS' ELSE 'FAIL' END),

('Inventory Quantity Equation',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Inventory
     WHERE on_hand_qty <> allocated_qty + available_qty
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Reorder Required Records',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Inventory
     WHERE available_qty <= reorder_point
 ) = 1311
 THEN 'PASS' ELSE 'FAIL' END),

('Stockout Records',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Inventory
     WHERE stock_status = 'Stockout'
 ) = 240
 THEN 'PASS' ELSE 'FAIL' END),

('Overstock Records',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Inventory
     WHERE stock_status = 'Overstock'
 ) = 478
 THEN 'PASS' ELSE 'FAIL' END),

('No Negative Inventory Quantities',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Inventory
     WHERE on_hand_qty < 0
        OR allocated_qty < 0
        OR available_qty < 0
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Unique Product-Warehouse Keys',
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

-- Detailed validation
SELECT *
FROM @InventoryValidation;

-- Final status
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
    END AS Final_Inventory_Analysis_Status

FROM @InventoryValidation;



-- ============================================================
-- Step 17: Top 10 Months with Lowest On-Time Performance
-- Excludes partial October 2026
-- Valid chronology shipments only
-- ============================================================

WITH MonthlyDelivery AS
(
    SELECT
        YEAR(shipment_date) AS Shipment_Year,
        MONTH(shipment_date) AS Month_No,
        DATENAME(MONTH, shipment_date) AS Month_Name,

        COUNT(*) AS Total_Shipments,

        100.0 *
        SUM(CASE WHEN on_time_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*) AS On_Time_Rate_Pct,

        100.0 *
        SUM(CASE WHEN otif_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*) AS OTIF_Rate_Pct,

        AVG(1.0 * delivery_delay_days) AS Avg_Delay_Days

    FROM raw.Shipments

    WHERE actual_delivery_date >= shipment_date

      AND NOT (
          YEAR(shipment_date) = 2026
          AND MONTH(shipment_date) = 10
      )

    GROUP BY
        YEAR(shipment_date),
        MONTH(shipment_date),
        DATENAME(MONTH, shipment_date)
)

SELECT TOP 10
    Shipment_Year,
    Month_No,
    Month_Name,
    Total_Shipments,

    CAST(
        On_Time_Rate_Pct
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        OTIF_Rate_Pct
        AS DECIMAL(8,2)
    ) AS OTIF_Rate_Pct,

    CAST(
        Avg_Delay_Days
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days

FROM MonthlyDelivery

ORDER BY
    On_Time_Rate_Pct ASC,
    OTIF_Rate_Pct ASC;



-- ============================================================
-- Step 18: Delivery Performance by Customer Segment
-- Valid chronology shipments only
-- ============================================================

SELECT
    c.customer_segment,

    COUNT(*) AS Total_Shipments,

    SUM(s.shipped_qty) AS Shipped_Qty,

    CAST(
        100.0 *
        SUM(CASE WHEN s.on_time_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(CASE WHEN s.otif_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS OTIF_Rate_Pct,

    CAST(
        AVG(1.0 * s.delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    SUM(
        CASE
            WHEN s.delivery_delay_days >= 6
            THEN 1
            ELSE 0
        END
    ) AS Severe_Delay_Shipments

FROM raw.Shipments AS s

INNER JOIN raw.Sales_Orders AS so
    ON s.order_id = so.order_id

INNER JOIN raw.Customers AS c
    ON so.customer_id = c.customer_id

WHERE s.actual_delivery_date >= s.shipment_date

GROUP BY
    c.customer_segment

ORDER BY
    On_Time_Rate_Pct DESC;



-- ============================================================
-- Step 19: Delivery Performance by Order Fulfillment Status
-- Valid chronology shipments only
-- ============================================================

SELECT
    so.order_status,

    COUNT(*) AS Total_Shipments,

    SUM(s.shipped_qty) AS Shipped_Qty,

    CAST(
        AVG(1.0 * so.order_fill_rate_pct)
        AS DECIMAL(8,2)
    ) AS Avg_Order_Fill_Rate_Pct,

    CAST(
        100.0 *
        SUM(CASE WHEN s.on_time_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(CASE WHEN s.otif_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS OTIF_Rate_Pct,

    CAST(
        AVG(1.0 * s.delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days

FROM raw.Shipments AS s

INNER JOIN raw.Sales_Orders AS so
    ON s.order_id = so.order_id

WHERE s.actual_delivery_date >= s.shipment_date

GROUP BY
    so.order_status

ORDER BY
    Avg_Order_Fill_Rate_Pct DESC;



-- ============================================================
-- Step 20: Shipment vs Order Coverage Reconciliation
-- ============================================================

SELECT
    COUNT(*) AS Total_Orders,

    SUM(
        CASE
            WHEN s.order_id IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS Orders_With_Shipment,

    SUM(
        CASE
            WHEN s.order_id IS NULL
            THEN 1 ELSE 0
        END
    ) AS Orders_Without_Shipment,

    CAST(
        100.0 *
        SUM(CASE WHEN s.order_id IS NOT NULL THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Shipment_Coverage_Pct

FROM raw.Sales_Orders AS so

LEFT JOIN
(
    SELECT DISTINCT order_id
    FROM raw.Shipments
) AS s
    ON so.order_id = s.order_id;



-- ============================================================
-- Step 21: Orders Without Shipment Analysis
-- ============================================================

SELECT
    so.order_status,

    COUNT(*) AS Orders_Without_Shipment,

    SUM(so.ordered_qty) AS Ordered_Qty,

    SUM(so.fulfilled_qty) AS Fulfilled_Qty,

    SUM(so.backlog_qty) AS Backlog_Qty,

    CAST(
        SUM(so.order_value)
        AS DECIMAL(18,2)
    ) AS Order_Value,

    CAST(
        SUM(so.backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        AVG(1.0 * so.order_fill_rate_pct)
        AS DECIMAL(8,2)
    ) AS Avg_Order_Fill_Rate_Pct

FROM raw.Sales_Orders AS so

LEFT JOIN raw.Shipments AS s
    ON so.order_id = s.order_id

WHERE s.order_id IS NULL

GROUP BY
    so.order_status

ORDER BY
    Orders_Without_Shipment DESC;


-- ============================================================
-- Step 22: Shipment Quantity Reconciliation
-- ============================================================

WITH ShipmentQty AS
(
    SELECT
        order_id,
        SUM(shipped_qty) AS Shipped_Qty
    FROM raw.Shipments
    GROUP BY order_id
)

SELECT
    SUM(so.fulfilled_qty) AS Total_Fulfilled_Qty,

    SUM(ISNULL(sq.Shipped_Qty, 0)) AS Total_Shipped_Qty,

    SUM(so.fulfilled_qty)
        - SUM(ISNULL(sq.Shipped_Qty, 0))
        AS Quantity_Difference,

    SUM(
        CASE
            WHEN so.fulfilled_qty <> ISNULL(sq.Shipped_Qty, 0)
            THEN 1
            ELSE 0
        END
    ) AS Orders_With_Qty_Mismatch

FROM raw.Sales_Orders AS so

LEFT JOIN ShipmentQty AS sq
    ON so.order_id = sq.order_id;


-- ============================================================
-- Step 23: Final Shipment & Delivery Analysis Validation
-- ============================================================

DECLARE @ShipmentValidation TABLE
(
    Validation_Check VARCHAR(150),
    Status VARCHAR(10)
);

INSERT INTO @ShipmentValidation
VALUES

('Total Shipment Records',
 CASE WHEN (SELECT COUNT(*) FROM raw.Shipments) = 24798
      THEN 'PASS' ELSE 'FAIL' END),

('Valid Chronology Shipments',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Shipments
     WHERE actual_delivery_date >= shipment_date
 ) = 20331
 THEN 'PASS' ELSE 'FAIL' END),

('Invalid Chronology Shipments',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Shipments
     WHERE actual_delivery_date < shipment_date
 ) = 4467
 THEN 'PASS' ELSE 'FAIL' END),

('Valid + Invalid Equals Total',
 CASE WHEN
 (
     SELECT
         SUM(
             CASE
                 WHEN actual_delivery_date >= shipment_date
                 THEN 1 ELSE 0
             END
         )
         +
         SUM(
             CASE
                 WHEN actual_delivery_date < shipment_date
                 THEN 1 ELSE 0
             END
         )
     FROM raw.Shipments
 ) = 24798
 THEN 'PASS' ELSE 'FAIL' END),

('Valid On-Time Shipments',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Shipments
     WHERE actual_delivery_date >= shipment_date
       AND on_time_flag = 1
 ) = 14480
 THEN 'PASS' ELSE 'FAIL' END),

('Valid Late Shipments',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Shipments
     WHERE actual_delivery_date >= shipment_date
       AND on_time_flag = 0
 ) = 5851
 THEN 'PASS' ELSE 'FAIL' END),

('Valid OTIF Shipments',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Shipments
     WHERE actual_delivery_date >= shipment_date
       AND otif_flag = 1
 ) = 9404
 THEN 'PASS' ELSE 'FAIL' END),

('Valid On-Time + Late Equals Valid Shipments',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Shipments
     WHERE actual_delivery_date >= shipment_date
       AND on_time_flag IN (0,1)
 ) = 20331
 THEN 'PASS' ELSE 'FAIL' END),

('Severe Delay Shipments',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Shipments
     WHERE actual_delivery_date >= shipment_date
       AND delivery_delay_days >= 6
 ) = 2961
 THEN 'PASS' ELSE 'FAIL' END),

('Orders With Shipment',
 CASE WHEN
 (
     SELECT COUNT(DISTINCT order_id)
     FROM raw.Shipments
 ) = 24798
 THEN 'PASS' ELSE 'FAIL' END),

('Orders Without Shipment',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Sales_Orders AS so
     WHERE NOT EXISTS
     (
         SELECT 1
         FROM raw.Shipments AS s
         WHERE s.order_id = so.order_id
     )
 ) = 202
 THEN 'PASS' ELSE 'FAIL' END),

('Shipment Quantity Reconciles With Fulfilled Quantity',
 CASE WHEN
 (
     SELECT SUM(shipped_qty)
     FROM raw.Shipments
 ) =
 (
     SELECT SUM(fulfilled_qty)
     FROM raw.Sales_Orders
 )
 THEN 'PASS' ELSE 'FAIL' END),

('No Negative Shipped Quantity',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Shipments
     WHERE shipped_qty < 0
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Unique Shipment IDs',
 CASE WHEN NOT EXISTS
 (
     SELECT shipment_id
     FROM raw.Shipments
     GROUP BY shipment_id
     HAVING COUNT(*) > 1
 )
 THEN 'PASS' ELSE 'FAIL' END);

-- Detailed validation
SELECT *
FROM @ShipmentValidation;

-- Final status
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
    END AS Final_Shipment_Delivery_Analysis_Status

FROM @ShipmentValidation;