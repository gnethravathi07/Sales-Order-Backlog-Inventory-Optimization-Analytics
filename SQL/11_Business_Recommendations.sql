-- ============================================================
-- SALES ORDER, BACKLOG & INVENTORY ANALYTICS
-- File: 11_Business_Recommendations.sql
-- Purpose: Executive Business Recommendations
-- ============================================================

USE Sales_Order_Backlog_Inventory_Analytics;
GO

-- ============================================================
-- Step 1: Executive Business Baseline
-- ============================================================

SELECT
    (SELECT COUNT(*)
     FROM raw.Sales_Orders)
        AS Total_Orders,

    CAST(
        (SELECT SUM(order_value)
         FROM raw.Sales_Orders)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        100.0 *
        (SELECT SUM(fulfilled_qty)
         FROM raw.Sales_Orders)
        /
        NULLIF(
            (SELECT SUM(ordered_qty)
             FROM raw.Sales_Orders), 0
        )
        AS DECIMAL(8,2)
    ) AS Overall_Fill_Rate_Pct,

    (SELECT COUNT(*)
     FROM raw.Sales_Orders
     WHERE backlog_qty > 0)
        AS Orders_With_Backlog,

    CAST(
        100.0 *
        (SELECT COUNT(*)
         FROM raw.Sales_Orders
         WHERE backlog_qty > 0)
        /
        NULLIF(
            (SELECT COUNT(*)
             FROM raw.Sales_Orders), 0
        )
        AS DECIMAL(8,2)
    ) AS Backlog_Order_Rate_Pct,

    (SELECT SUM(backlog_qty)
     FROM raw.Sales_Orders)
        AS Total_Backlog_Qty,

    CAST(
        (SELECT SUM(backlog_value)
         FROM raw.Sales_Orders)
        AS DECIMAL(18,2)
    ) AS Total_Backlog_Value,

    CAST(
        (SELECT SUM(inventory_value)
         FROM raw.Inventory)
        AS DECIMAL(18,2)
    ) AS Total_Inventory_Value,

    (SELECT COUNT(*)
     FROM raw.Inventory
     WHERE available_qty <= reorder_point)
        AS Reorder_Required_Records,

    (SELECT COUNT(*)
     FROM raw.Inventory
     WHERE available_qty = 0)
        AS Stockout_Records,

    (SELECT COUNT(*)
     FROM raw.Inventory
     WHERE stock_status = 'Overstock')
        AS Overstock_Records;




    -- ============================================================
-- Step 2: Executive Business Risk Summary
-- ============================================================

SELECT *
FROM
(
    VALUES

    (1,
     'Backlog Exposure',
     'HIGH',
     '10,850 orders have backlog (43.40% of all orders)',
     '₹257.35M backlog value is commercially exposed',
     'Reduce backlog occurrence and prioritize high-value orders'),

    (2,
     'Inventory Replenishment',
     'HIGH',
     '1,311 product-warehouse records require reorder',
     'Potential service-level and availability risk',
     'Prioritize reorder-required SKUs using demand and backlog exposure'),

    (3,
     'Stockout Risk',
     'HIGH',
     '240 product-warehouse records currently have zero available stock',
     'Potential lost sales and fulfillment disruption',
     'Accelerate replenishment for high-demand stockout SKUs'),

    (4,
     'Uncovered Replenishment',
     'CRITICAL',
     '231 reorder-required records have no inbound purchase order',
     'Immediate replenishment gap',
     'Create or review procurement action for uncovered shortages'),

    (5,
     'Delivery Performance',
     'HIGH',
     'Valid shipment on-time performance is 71.22%',
     'Late delivery can reduce customer service performance',
     'Improve fulfillment readiness and shipment execution'),

    (6,
     'OTIF Performance',
     'CRITICAL',
     'Valid shipment OTIF performance is 46.25%',
     'Less than half of valid shipments meet complete and on-time requirements',
     'Improve order completeness before shipment'),

    (7,
     'Supplier Reliability',
     'MEDIUM-HIGH',
     'Lower-reliability suppliers show materially weaker delivery performance',
     'Supplier delays can increase procurement uncertainty',
     'Shift critical demand toward reliable suppliers where commercially feasible'),

    (8,
     'Warehouse Risk',
     'HIGH',
     'Pune DC has the highest reorder-required rate at 48.20%',
     'Inventory and service pressure are concentrated at the warehouse level',
     'Perform targeted Pune DC inventory and fulfillment review'),

    (9,
     'Category Fulfillment',
     'HIGH',
     'Automotive has the lowest fill rate at 86.63%',
     'Category-level fulfillment weakness increases backlog exposure',
     'Review Automotive forecasting, allocation and replenishment'),

    (10,
     'Commercial Concentration',
     'CRITICAL',
     'Highest-sales-value quartile carries 68.01% of backlog value',
     'Backlog is concentrated in commercially important products',
     'Protect availability for high-value and high-demand SKUs')

) AS Risk_Summary
(
    Priority_Rank,
    Risk_Area,
    Risk_Level,
    Evidence,
    Business_Impact,
    Recommended_Response
)

ORDER BY Priority_Rank;



-- ============================================================
-- Step 3: Backlog Reduction Priority Matrix
-- ============================================================

WITH ProductWarehousePerformance AS
(
    SELECT
        soi.product_id,
        soi.warehouse_id,

        SUM(soi.ordered_qty) AS Ordered_Qty,
        SUM(soi.fulfilled_qty) AS Fulfilled_Qty,
        SUM(soi.backlog_qty) AS Backlog_Qty,

        CAST(
            SUM(soi.backlog_value)
            AS DECIMAL(18,2)
        ) AS Backlog_Value

    FROM raw.Sales_Order_Items soi

    GROUP BY
        soi.product_id,
        soi.warehouse_id
),

PriorityBase AS
(
    SELECT
        pwp.product_id,
        p.product_name,
        p.category,

        pwp.warehouse_id,
        w.warehouse_name,

        pwp.Ordered_Qty,
        pwp.Fulfilled_Qty,
        pwp.Backlog_Qty,
        pwp.Backlog_Value,

        CAST(
            100.0 * pwp.Backlog_Qty /
            NULLIF(pwp.Ordered_Qty, 0)
            AS DECIMAL(8,2)
        ) AS Backlog_Rate_Pct,

        i.available_qty AS Available_Qty,
        i.avg_daily_demand AS Avg_Daily_Demand,
        i.reorder_point AS Reorder_Point,

        CASE
            WHEN i.available_qty <= i.reorder_point
            THEN 'Y'
            ELSE 'N'
        END AS Reorder_Required

    FROM ProductWarehousePerformance pwp

    INNER JOIN raw.Products p
        ON pwp.product_id = p.product_id

    INNER JOIN raw.Warehouses w
        ON pwp.warehouse_id = w.warehouse_id

    INNER JOIN raw.Inventory i
        ON pwp.product_id = i.product_id
       AND pwp.warehouse_id = i.warehouse_id
)

SELECT TOP 25

    product_id,
    product_name,
    category,

    warehouse_id,
    warehouse_name,

    Ordered_Qty,
    Fulfilled_Qty,
    Backlog_Qty,
    Backlog_Rate_Pct,

    Backlog_Value,

    Available_Qty,
    Avg_Daily_Demand,
    Reorder_Point,
    Reorder_Required,

    CASE
        WHEN Backlog_Value >= 500000
             AND Reorder_Required = 'Y'
        THEN 'CRITICAL'

        WHEN Backlog_Value >= 500000
             OR Backlog_Rate_Pct >= 20
        THEN 'HIGH'

        WHEN Backlog_Rate_Pct >= 10
        THEN 'MEDIUM'

        ELSE 'LOW'
    END AS Business_Priority,

    CASE
        WHEN Reorder_Required = 'Y'
             AND Backlog_Qty > 0
        THEN 'Replenishment + Backlog Action'

        WHEN Reorder_Required = 'Y'
        THEN 'Replenishment Action'

        WHEN Backlog_Qty > 0
        THEN 'Backlog / Allocation Review'

        ELSE 'Monitor'
    END AS Recommended_Action

FROM PriorityBase

WHERE Backlog_Qty > 0

ORDER BY
    CASE
        WHEN Backlog_Value >= 500000
             AND Reorder_Required = 'Y' THEN 1
        WHEN Backlog_Value >= 500000
             OR Backlog_Rate_Pct >= 20 THEN 2
        WHEN Backlog_Rate_Pct >= 10 THEN 3
        ELSE 4
    END,
    Backlog_Value DESC;


-- ============================================================
-- Step 4: Inventory Replenishment Priority
-- ============================================================

WITH InboundPO AS
(
    SELECT
        product_id,
        warehouse_id,

        SUM(
            CASE
                WHEN ordered_qty > received_qty
                THEN ordered_qty - received_qty
                ELSE 0
            END
        ) AS Outstanding_PO_Qty

    FROM raw.Purchase_Orders

    GROUP BY
        product_id,
        warehouse_id
),

ReplenishmentBase AS
(
    SELECT
        i.product_id,
        p.product_name,
        p.category,

        i.warehouse_id,
        w.warehouse_name,

        i.available_qty,
        i.avg_daily_demand,
        i.safety_stock,
        i.reorder_point,

        CAST(
            CASE
                WHEN i.avg_daily_demand > 0
                THEN 1.0 * i.available_qty /
                     i.avg_daily_demand
            END
            AS DECIMAL(10,2)
        ) AS Inventory_DOH,

        ISNULL(po.Outstanding_PO_Qty, 0)
            AS Outstanding_PO_Qty,

        CASE
            WHEN ISNULL(po.Outstanding_PO_Qty, 0) > 0
            THEN 'Y'
            ELSE 'N'
        END AS Inbound_PO_Coverage,

        CASE
            WHEN i.reorder_point > i.available_qty
            THEN i.reorder_point - i.available_qty
            ELSE 0
        END AS Reorder_Gap_Qty

    FROM raw.Inventory i

    INNER JOIN raw.Products p
        ON i.product_id = p.product_id

    INNER JOIN raw.Warehouses w
        ON i.warehouse_id = w.warehouse_id

    LEFT JOIN InboundPO po
        ON i.product_id = po.product_id
       AND i.warehouse_id = po.warehouse_id

    WHERE i.available_qty <= i.reorder_point
)

SELECT TOP 25

    product_id,
    product_name,
    category,

    warehouse_id,
    warehouse_name,

    available_qty,
    avg_daily_demand,
    safety_stock,
    reorder_point,

    Inventory_DOH,
    Reorder_Gap_Qty,

    Outstanding_PO_Qty,
    Inbound_PO_Coverage,

    CASE
        WHEN available_qty = 0
             AND Inbound_PO_Coverage = 'N'
        THEN 'CRITICAL'

        WHEN Inbound_PO_Coverage = 'N'
        THEN 'HIGH'

        WHEN Outstanding_PO_Qty < Reorder_Gap_Qty
        THEN 'HIGH'

        ELSE 'MEDIUM'
    END AS Replenishment_Priority,

    CASE
        WHEN available_qty = 0
             AND Inbound_PO_Coverage = 'N'
        THEN 'Immediate PO Required'

        WHEN Inbound_PO_Coverage = 'N'
        THEN 'Create / Review Purchase Order'

        WHEN Outstanding_PO_Qty < Reorder_Gap_Qty
        THEN 'Increase Inbound Quantity'

        ELSE 'Monitor Existing Inbound PO'
    END AS Recommended_Action

FROM ReplenishmentBase

ORDER BY
    CASE
        WHEN available_qty = 0
             AND Inbound_PO_Coverage = 'N' THEN 1

        WHEN Inbound_PO_Coverage = 'N' THEN 2

        WHEN Outstanding_PO_Qty < Reorder_Gap_Qty THEN 3

        ELSE 4
    END,

    Inventory_DOH ASC,
    avg_daily_demand DESC;




-- ============================================================
-- Step 5: Stockout Risk & Revenue Exposure
-- ============================================================

WITH SalesExposure AS
(
    SELECT
        product_id,
        warehouse_id,
        SUM(ordered_qty) AS Ordered_Qty,
        SUM(fulfilled_qty) AS Fulfilled_Qty,
        SUM(backlog_qty) AS Backlog_Qty,
        SUM(net_order_value) AS Sales_Value,
        SUM(backlog_value) AS Backlog_Value
    FROM raw.Sales_Order_Items
    GROUP BY product_id, warehouse_id
)

SELECT TOP 25
    i.product_id,
    p.product_name,
    p.category,
    i.warehouse_id,
    w.warehouse_name,

    i.available_qty,
    i.avg_daily_demand,
    i.reorder_point,

    ISNULL(s.Ordered_Qty, 0) AS Ordered_Qty,
    ISNULL(s.Fulfilled_Qty, 0) AS Fulfilled_Qty,
    ISNULL(s.Backlog_Qty, 0) AS Backlog_Qty,

    CAST(ISNULL(s.Sales_Value, 0) AS DECIMAL(18,2))
        AS Historical_Sales_Value,

    CAST(ISNULL(s.Backlog_Value, 0) AS DECIMAL(18,2))
        AS Historical_Backlog_Value,

    CASE
        WHEN ISNULL(s.Backlog_Value, 0) >= 100000
        THEN 'CRITICAL'
        WHEN ISNULL(s.Backlog_Value, 0) >= 50000
        THEN 'HIGH'
        WHEN ISNULL(s.Backlog_Value, 0) > 0
        THEN 'MEDIUM'
        ELSE 'LOW'
    END AS Stockout_Commercial_Priority,

    'Urgent Replenishment Review'
        AS Recommended_Action

FROM raw.Inventory i

INNER JOIN raw.Products p
    ON i.product_id = p.product_id

INNER JOIN raw.Warehouses w
    ON i.warehouse_id = w.warehouse_id

LEFT JOIN SalesExposure s
    ON i.product_id = s.product_id
   AND i.warehouse_id = s.warehouse_id

WHERE i.available_qty = 0

ORDER BY
    ISNULL(s.Backlog_Value, 0) DESC,
    ISNULL(s.Sales_Value, 0) DESC;





-- ============================================================
-- Step 6: Warehouse-Level Stockout Risk Prioritization
-- ============================================================

WITH StockoutExposure AS
(
    SELECT
        i.warehouse_id,
        i.product_id,
        i.avg_daily_demand,

        ISNULL(SUM(soi.backlog_qty), 0)
            AS Backlog_Qty,

        ISNULL(SUM(soi.backlog_value), 0)
            AS Backlog_Value

    FROM raw.Inventory i

    LEFT JOIN raw.Sales_Order_Items soi
        ON i.product_id = soi.product_id
       AND i.warehouse_id = soi.warehouse_id

    WHERE i.available_qty = 0

    GROUP BY
        i.warehouse_id,
        i.product_id,
        i.avg_daily_demand
)

SELECT
    w.warehouse_id,
    w.warehouse_name,

    COUNT(*) AS Stockout_SKU_Count,

    CAST(
        SUM(se.avg_daily_demand)
        AS DECIMAL(12,2)
    ) AS Combined_Avg_Daily_Demand,

    SUM(se.Backlog_Qty)
        AS Historical_Backlog_Qty,

    CAST(
        SUM(se.Backlog_Value)
        AS DECIMAL(18,2)
    ) AS Historical_Backlog_Value,

    CAST(
        100.0 * SUM(se.Backlog_Value)
        / NULLIF(
            SUM(SUM(se.Backlog_Value)) OVER (), 0
        )
        AS DECIMAL(8,2)
    ) AS Stockout_Backlog_Value_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY SUM(se.Backlog_Value) DESC
    ) AS Commercial_Risk_Rank,

    CASE
        WHEN SUM(se.Backlog_Value) >= 10000000
        THEN 'CRITICAL'

        WHEN SUM(se.Backlog_Value) >= 5000000
        THEN 'HIGH'

        ELSE 'MEDIUM'
    END AS Warehouse_Risk_Level,

    'Prioritize stockout replenishment by backlog exposure'
        AS Recommended_Action

FROM StockoutExposure se

INNER JOIN raw.Warehouses w
    ON se.warehouse_id = w.warehouse_id

GROUP BY
    w.warehouse_id,
    w.warehouse_name

ORDER BY
    Commercial_Risk_Rank;



-- ============================================================
-- Step 7: Category-Level Stockout Risk Prioritization
-- ============================================================

WITH StockoutExposure AS
(
    SELECT
        i.product_id,
        i.warehouse_id,
        p.category,
        i.avg_daily_demand,

        ISNULL(SUM(soi.ordered_qty), 0)
            AS Historical_Ordered_Qty,

        ISNULL(SUM(soi.backlog_qty), 0)
            AS Historical_Backlog_Qty,

        ISNULL(SUM(soi.backlog_value), 0)
            AS Historical_Backlog_Value

    FROM raw.Inventory i

    INNER JOIN raw.Products p
        ON i.product_id = p.product_id

    LEFT JOIN raw.Sales_Order_Items soi
        ON i.product_id = soi.product_id
       AND i.warehouse_id = soi.warehouse_id

    WHERE i.available_qty = 0

    GROUP BY
        i.product_id,
        i.warehouse_id,
        p.category,
        i.avg_daily_demand
),

CategorySummary AS
(
    SELECT
        category,

        COUNT(*) AS Stockout_Records,

        CAST(
            SUM(avg_daily_demand)
            AS DECIMAL(12,2)
        ) AS Combined_Avg_Daily_Demand,

        SUM(Historical_Ordered_Qty)
            AS Historical_Ordered_Qty,

        SUM(Historical_Backlog_Qty)
            AS Historical_Backlog_Qty,

        CAST(
            SUM(Historical_Backlog_Value)
            AS DECIMAL(18,2)
        ) AS Historical_Backlog_Value

    FROM StockoutExposure

    GROUP BY category
)

SELECT
    category,
    Stockout_Records,
    Combined_Avg_Daily_Demand,
    Historical_Ordered_Qty,
    Historical_Backlog_Qty,
    Historical_Backlog_Value,

    CAST(
        100.0 * Historical_Backlog_Qty /
        NULLIF(Historical_Ordered_Qty, 0)
        AS DECIMAL(8,2)
    ) AS Historical_Backlog_Rate_Pct,

    CAST(
        100.0 * Historical_Backlog_Value /
        NULLIF(
            SUM(Historical_Backlog_Value) OVER (), 0
        )
        AS DECIMAL(8,2)
    ) AS Stockout_Backlog_Value_Share_Pct,

    DENSE_RANK() OVER
    (
        ORDER BY Historical_Backlog_Value DESC
    ) AS Commercial_Risk_Rank,

    CASE
        WHEN Historical_Backlog_Value >= 5000000
        THEN 'CRITICAL'

        WHEN Historical_Backlog_Value >= 3000000
        THEN 'HIGH'

        ELSE 'MEDIUM'
    END AS Category_Risk_Level,

    'Prioritize high-exposure stockout SKUs within category'
        AS Recommended_Action

FROM CategorySummary

ORDER BY Commercial_Risk_Rank;



-- ============================================================
-- Step 8: Supplier Performance Improvement Priorities
-- ============================================================

WITH SupplierPerformance AS
(
    SELECT
        s.supplier_id,
        s.supplier_name,
        s.supplier_region,
        s.reliability_factor,

        COUNT(po.po_id) AS Total_POs,

        SUM(
            CASE
                WHEN po.actual_receipt_date IS NOT NULL
                 AND po.supplier_delay_days IS NOT NULL
                THEN 1 ELSE 0
            END
        ) AS Evaluated_POs,

        CAST(
            100.0 * SUM(
                CASE
                    WHEN po.actual_receipt_date IS NOT NULL
                     AND po.supplier_delay_days <= 0
                    THEN 1 ELSE 0
                END
            ) /
            NULLIF(
                SUM(
                    CASE
                        WHEN po.actual_receipt_date IS NOT NULL
                         AND po.supplier_delay_days IS NOT NULL
                        THEN 1 ELSE 0
                    END
                ), 0
            )
            AS DECIMAL(8,2)
        ) AS On_Time_Rate_Pct,

        CAST(
            AVG(
                CASE
                    WHEN po.actual_receipt_date IS NOT NULL
                     AND po.supplier_delay_days IS NOT NULL
                    THEN 1.0 * po.supplier_delay_days
                END
            )
            AS DECIMAL(10,2)
        ) AS Avg_Supplier_Delay_Days,

        SUM(
            CASE
                WHEN po.ordered_qty > po.received_qty
                THEN po.ordered_qty - po.received_qty
                ELSE 0
            END
        ) AS Outstanding_PO_Qty,

        CAST(
            SUM(
                CASE
                    WHEN po.ordered_qty > po.received_qty
                    THEN
                        (po.ordered_qty - po.received_qty)
                        * po.unit_cost
                    ELSE 0
                END
            )
            AS DECIMAL(18,2)
        ) AS Outstanding_PO_Value

    FROM raw.Suppliers s

    LEFT JOIN raw.Purchase_Orders po
        ON s.supplier_id = po.supplier_id

    GROUP BY
        s.supplier_id,
        s.supplier_name,
        s.supplier_region,
        s.reliability_factor
)

SELECT TOP 25
    supplier_id,
    supplier_name,
    supplier_region,
    reliability_factor,

    Total_POs,
    Evaluated_POs,
    On_Time_Rate_Pct,
    Avg_Supplier_Delay_Days,

    Outstanding_PO_Qty,
    Outstanding_PO_Value,

    CASE
        WHEN On_Time_Rate_Pct < 50
             AND Outstanding_PO_Qty > 0
        THEN 'CRITICAL'

        WHEN On_Time_Rate_Pct < 60
        THEN 'HIGH'

        WHEN On_Time_Rate_Pct < 75
        THEN 'MEDIUM'

        ELSE 'LOW'
    END AS Supplier_Improvement_Priority,

    CASE
        WHEN On_Time_Rate_Pct < 50
             AND Outstanding_PO_Qty > 0
        THEN 'Escalate Supplier + Review Open POs'

        WHEN On_Time_Rate_Pct < 60
        THEN 'Supplier Corrective Action Plan'

        WHEN On_Time_Rate_Pct < 75
        THEN 'Monitor Delivery Improvement'

        ELSE 'Maintain Supplier Performance'
    END AS Recommended_Action

FROM SupplierPerformance

WHERE Evaluated_POs > 0

ORDER BY
    CASE
        WHEN On_Time_Rate_Pct < 50
             AND Outstanding_PO_Qty > 0 THEN 1
        WHEN On_Time_Rate_Pct < 60 THEN 2
        WHEN On_Time_Rate_Pct < 75 THEN 3
        ELSE 4
    END,
    Outstanding_PO_Value DESC,
    On_Time_Rate_Pct ASC;




-- ============================================================
-- Step 9: Warehouse Performance Improvement Recommendations
-- ============================================================

WITH InventoryKPI AS
(
    SELECT
        warehouse_id,
        COUNT(*) AS Inventory_Records,
        SUM(CASE WHEN available_qty = 0 THEN 1 ELSE 0 END)
            AS Stockout_Records,
        CAST(
            100.0 * SUM(
                CASE WHEN available_qty <= reorder_point
                     THEN 1 ELSE 0 END
            ) / NULLIF(COUNT(*), 0)
            AS DECIMAL(8,2)
        ) AS Reorder_Rate_Pct
    FROM raw.Inventory
    GROUP BY warehouse_id
),

FulfillmentKPI AS
(
    SELECT
        warehouse_id,
        COUNT(*) AS Total_Orders,
        SUM(backlog_qty) AS Backlog_Qty,
        CAST(SUM(backlog_value) AS DECIMAL(18,2))
            AS Backlog_Value,
        CAST(
            100.0 * SUM(fulfilled_qty) /
            NULLIF(SUM(ordered_qty), 0)
            AS DECIMAL(8,2)
        ) AS Fill_Rate_Pct
    FROM raw.Sales_Orders
    GROUP BY warehouse_id
),

DeliveryKPI AS
(
    SELECT
        warehouse_id,
        COUNT(*) AS Valid_Shipments,
        CAST(
            100.0 * SUM(
                CASE WHEN on_time_flag = 1 THEN 1 ELSE 0 END
            ) / NULLIF(COUNT(*), 0)
            AS DECIMAL(8,2)
        ) AS On_Time_Rate_Pct,
        CAST(
            100.0 * SUM(
                CASE WHEN otif_flag = 1 THEN 1 ELSE 0 END
            ) / NULLIF(COUNT(*), 0)
            AS DECIMAL(8,2)
        ) AS OTIF_Rate_Pct
    FROM raw.Shipments
    WHERE actual_delivery_date >= shipment_date
    GROUP BY warehouse_id
),

WarehousePerformance AS
(
    SELECT
        w.warehouse_id,
        w.warehouse_name,
        i.Stockout_Records,
        i.Reorder_Rate_Pct,
        f.Total_Orders,
        f.Backlog_Qty,
        f.Backlog_Value,
        f.Fill_Rate_Pct,
        d.Valid_Shipments,
        d.On_Time_Rate_Pct,
        d.OTIF_Rate_Pct,

        CASE
            WHEN i.Reorder_Rate_Pct >= 45
                 AND f.Fill_Rate_Pct < 88
            THEN 'CRITICAL'

            WHEN f.Fill_Rate_Pct < 88
                 OR d.On_Time_Rate_Pct < 71
            THEN 'HIGH'

            ELSE 'MEDIUM'
        END AS Improvement_Priority

    FROM raw.Warehouses w

    INNER JOIN InventoryKPI i
        ON w.warehouse_id = i.warehouse_id

    INNER JOIN FulfillmentKPI f
        ON w.warehouse_id = f.warehouse_id

    INNER JOIN DeliveryKPI d
        ON w.warehouse_id = d.warehouse_id
)

SELECT
    *,
    CASE
        WHEN Improvement_Priority = 'CRITICAL'
        THEN 'Immediate inventory and fulfillment review'

        WHEN Improvement_Priority = 'HIGH'
        THEN 'Improve replenishment and delivery execution'

        ELSE 'Maintain KPI monitoring'
    END AS Recommended_Action

FROM WarehousePerformance

ORDER BY
    CASE Improvement_Priority
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        ELSE 3
    END,
    Backlog_Value DESC;



    -- ============================================================
-- Step 10: Category-Level Performance Improvement
-- ============================================================

WITH CategorySales AS
(
    SELECT
        p.category,

        SUM(soi.ordered_qty) AS Ordered_Qty,
        SUM(soi.fulfilled_qty) AS Fulfilled_Qty,
        SUM(soi.backlog_qty) AS Backlog_Qty,

        CAST(
            SUM(soi.net_order_value)
            AS DECIMAL(18,2)
        ) AS Sales_Value,

        CAST(
            SUM(soi.backlog_value)
            AS DECIMAL(18,2)
        ) AS Backlog_Value

    FROM raw.Sales_Order_Items soi

    INNER JOIN raw.Products p
        ON soi.product_id = p.product_id

    GROUP BY p.category
),

CategoryInventory AS
(
    SELECT
        p.category,

        COUNT(*) AS Inventory_Records,

        SUM(
            CASE WHEN i.available_qty = 0
                 THEN 1 ELSE 0 END
        ) AS Stockout_Records,

        SUM(
            CASE WHEN i.available_qty <= i.reorder_point
                 THEN 1 ELSE 0 END
        ) AS Reorder_Required_Records

    FROM raw.Inventory i

    INNER JOIN raw.Products p
        ON i.product_id = p.product_id

    GROUP BY p.category
),

CategoryPerformance AS
(
    SELECT
        s.category,
        s.Ordered_Qty,
        s.Fulfilled_Qty,
        s.Backlog_Qty,
        s.Sales_Value,
        s.Backlog_Value,

        CAST(
            100.0 * s.Fulfilled_Qty /
            NULLIF(s.Ordered_Qty, 0)
            AS DECIMAL(8,2)
        ) AS Fill_Rate_Pct,

        CAST(
            100.0 * s.Backlog_Qty /
            NULLIF(s.Ordered_Qty, 0)
            AS DECIMAL(8,2)
        ) AS Backlog_Rate_Pct,

        i.Inventory_Records,
        i.Stockout_Records,
        i.Reorder_Required_Records,

        CAST(
            100.0 * i.Reorder_Required_Records /
            NULLIF(i.Inventory_Records, 0)
            AS DECIMAL(8,2)
        ) AS Reorder_Rate_Pct

    FROM CategorySales s

    INNER JOIN CategoryInventory i
        ON s.category = i.category
)

SELECT
    *,

    CASE
        WHEN Fill_Rate_Pct < 87
             OR Reorder_Rate_Pct >= 47
        THEN 'CRITICAL'

        WHEN Backlog_Rate_Pct >= 12
             OR Reorder_Rate_Pct >= 43
        THEN 'HIGH'

        ELSE 'MEDIUM'
    END AS Improvement_Priority,

    CASE
        WHEN Fill_Rate_Pct < 87
        THEN 'Improve category fulfillment and allocation'

        WHEN Reorder_Rate_Pct >= 47
        THEN 'Strengthen inventory replenishment'

        WHEN Backlog_Rate_Pct >= 12
        THEN 'Reduce category backlog exposure'

        ELSE 'Monitor category inventory and service KPIs'
    END AS Recommended_Action

FROM CategoryPerformance

ORDER BY
    CASE
        WHEN Fill_Rate_Pct < 87
             OR Reorder_Rate_Pct >= 47 THEN 1

        WHEN Backlog_Rate_Pct >= 12
             OR Reorder_Rate_Pct >= 43 THEN 2

        ELSE 3
    END,
    Backlog_Value DESC;



-- ============================================================
-- Step 11: High-Value Customer Backlog Prioritization
-- ============================================================

WITH CustomerPerformance AS
(
    SELECT
        c.customer_id,
        c.customer_name,
        c.customer_segment,
        c.region,
        c.credit_tier,

        COUNT(so.order_id) AS Total_Orders,

        SUM(so.ordered_qty) AS Ordered_Qty,
        SUM(so.fulfilled_qty) AS Fulfilled_Qty,
        SUM(so.backlog_qty) AS Backlog_Qty,

        SUM(
            CASE
                WHEN so.backlog_qty > 0 THEN 1
                ELSE 0
            END
        ) AS Backlogged_Orders,

        CAST(
            SUM(so.order_value)
            AS DECIMAL(18,2)
        ) AS Total_Order_Value,

        CAST(
            SUM(so.backlog_value)
            AS DECIMAL(18,2)
        ) AS Backlog_Value

    FROM raw.Customers c

    INNER JOIN raw.Sales_Orders so
        ON c.customer_id = so.customer_id

    GROUP BY
        c.customer_id,
        c.customer_name,
        c.customer_segment,
        c.region,
        c.credit_tier
),

CustomerRisk AS
(
    SELECT
        *,

        CAST(
            100.0 * Backlog_Qty /
            NULLIF(Ordered_Qty, 0)
            AS DECIMAL(8,2)
        ) AS Backlog_Rate_Pct,

        CAST(
            100.0 * Backlogged_Orders /
            NULLIF(Total_Orders, 0)
            AS DECIMAL(8,2)
        ) AS Backlogged_Order_Rate_Pct,

        NTILE(4) OVER
        (
            ORDER BY Total_Order_Value DESC, customer_id
        ) AS Customer_Value_Quartile

    FROM CustomerPerformance
)

SELECT TOP 25
    customer_id,
    customer_name,
    customer_segment,
    region,
    credit_tier,

    Total_Orders,
    Backlogged_Orders,

    Ordered_Qty,
    Fulfilled_Qty,
    Backlog_Qty,

    Total_Order_Value,
    Backlog_Value,

    Backlog_Rate_Pct,
    Backlogged_Order_Rate_Pct,

    Customer_Value_Quartile,

    CASE
        WHEN Customer_Value_Quartile = 1
             AND Backlog_Value >= 100000
        THEN 'CRITICAL'

        WHEN Customer_Value_Quartile = 1
             OR Backlog_Value >= 100000
        THEN 'HIGH'

        WHEN Backlog_Rate_Pct >= 15
        THEN 'MEDIUM'

        ELSE 'LOW'
    END AS Customer_Retention_Priority,

    CASE
        WHEN Customer_Value_Quartile = 1
             AND Backlog_Value >= 100000
        THEN 'Priority Fulfillment + Proactive Customer Contact'

        WHEN Backlog_Value >= 100000
        THEN 'Expedite Backlog Review'

        WHEN Backlog_Rate_Pct >= 15
        THEN 'Customer Service Recovery Review'

        ELSE 'Monitor Customer Backlog'
    END AS Recommended_Action

FROM CustomerRisk

WHERE Backlog_Qty > 0

ORDER BY
    CASE
        WHEN Customer_Value_Quartile = 1
             AND Backlog_Value >= 100000 THEN 1
        WHEN Customer_Value_Quartile = 1
             OR Backlog_Value >= 100000 THEN 2
        WHEN Backlog_Rate_Pct >= 15 THEN 3
        ELSE 4
    END,
    Backlog_Value DESC;


-- ============================================================
-- Step 12: High-Priority Order Recovery Plan
-- ============================================================

WITH OrderRecovery AS
(
    SELECT
        so.order_id,
        so.customer_id,
        c.customer_name,
        c.customer_segment,

        so.warehouse_id,
        w.warehouse_name,

        so.order_date,
        so.requested_delivery_date,
        so.priority,
        so.order_status,

        so.ordered_qty,
        so.fulfilled_qty,
        so.backlog_qty,

        CAST(so.backlog_value AS DECIMAL(18,2))
            AS Backlog_Value,

        CAST(
            100.0 * so.backlog_qty /
            NULLIF(so.ordered_qty, 0)
            AS DECIMAL(8,2)
        ) AS Backlog_Rate_Pct,

        DATEDIFF(
            DAY,
            so.order_date,
            CAST(GETDATE() AS DATE)
        ) AS Order_Age_Days

    FROM raw.Sales_Orders so

    INNER JOIN raw.Customers c
        ON so.customer_id = c.customer_id

    INNER JOIN raw.Warehouses w
        ON so.warehouse_id = w.warehouse_id

    WHERE so.backlog_qty > 0
),

RecoveryPriority AS
(
    SELECT
        *,

        CASE
            WHEN priority = 'Urgent'
                 AND Backlog_Value >= 10000
            THEN 'CRITICAL'

            WHEN priority IN ('Urgent', 'High')
                 AND Backlog_Value >= 5000
            THEN 'HIGH'

            WHEN Backlog_Rate_Pct >= 25
            THEN 'MEDIUM'

            ELSE 'LOW'
        END AS Recovery_Priority

    FROM OrderRecovery
)

SELECT TOP 25
    order_id,
    customer_id,
    customer_name,
    customer_segment,

    warehouse_id,
    warehouse_name,

    order_date,
    requested_delivery_date,
    priority,
    order_status,

    ordered_qty,
    fulfilled_qty,
    backlog_qty,

    Backlog_Value,
    Backlog_Rate_Pct,
    Order_Age_Days,

    Recovery_Priority,

    CASE
        WHEN Recovery_Priority = 'CRITICAL'
        THEN 'Immediate Allocation + Customer Escalation'

        WHEN Recovery_Priority = 'HIGH'
        THEN 'Priority Fulfillment Review'

        WHEN Recovery_Priority = 'MEDIUM'
        THEN 'Backlog Recovery Scheduling'

        ELSE 'Standard Backlog Monitoring'
    END AS Recommended_Action

FROM RecoveryPriority

ORDER BY
    CASE Recovery_Priority
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        ELSE 4
    END,
    Backlog_Value DESC,
    Order_Age_Days DESC;



-- ============================================================
-- Step 13: Delivery Performance Improvement Plan
-- ============================================================

WITH DeliveryPerformance AS
(
    SELECT
        s.warehouse_id,
        w.warehouse_name,

        COUNT(*) AS Valid_Shipments,

        SUM(
            CASE WHEN s.on_time_flag = 1
                 THEN 1 ELSE 0 END
        ) AS On_Time_Shipments,

        SUM(
            CASE WHEN s.on_time_flag = 0
                 THEN 1 ELSE 0 END
        ) AS Late_Shipments,

        SUM(
            CASE WHEN s.otif_flag = 1
                 THEN 1 ELSE 0 END
        ) AS OTIF_Shipments,

        CAST(
            AVG(1.0 * s.delivery_delay_days)
            AS DECIMAL(10,2)
        ) AS Avg_Delivery_Delay_Days

    FROM raw.Shipments s

    INNER JOIN raw.Warehouses w
        ON s.warehouse_id = w.warehouse_id

    WHERE s.actual_delivery_date >= s.shipment_date

    GROUP BY
        s.warehouse_id,
        w.warehouse_name
),

PerformanceRates AS
(
    SELECT
        *,

        CAST(
            100.0 * On_Time_Shipments /
            NULLIF(Valid_Shipments, 0)
            AS DECIMAL(8,2)
        ) AS On_Time_Rate_Pct,

        CAST(
            100.0 * OTIF_Shipments /
            NULLIF(Valid_Shipments, 0)
            AS DECIMAL(8,2)
        ) AS OTIF_Rate_Pct

    FROM DeliveryPerformance
)

SELECT
    warehouse_id,
    warehouse_name,

    Valid_Shipments,
    On_Time_Shipments,
    Late_Shipments,
    OTIF_Shipments,

    On_Time_Rate_Pct,
    OTIF_Rate_Pct,
    Avg_Delivery_Delay_Days,

    CAST(
        90.0 - On_Time_Rate_Pct
        AS DECIMAL(8,2)
    ) AS On_Time_Target_Gap_Pct_Points,

    CAST(
        85.0 - OTIF_Rate_Pct
        AS DECIMAL(8,2)
    ) AS OTIF_Target_Gap_Pct_Points,

    CASE
        WHEN OTIF_Rate_Pct < 46
        THEN 'CRITICAL'

        WHEN OTIF_Rate_Pct < 47
        THEN 'HIGH'

        ELSE 'MEDIUM'
    END AS Delivery_Improvement_Priority,

    CASE
        WHEN OTIF_Rate_Pct < 46
        THEN 'Improve Order Completeness + Delivery Execution'

        WHEN On_Time_Rate_Pct < 71
        THEN 'Investigate Warehouse Delivery Delays'

        ELSE 'Improve OTIF Through Fulfillment Coordination'
    END AS Recommended_Action

FROM PerformanceRates

ORDER BY
    OTIF_Rate_Pct ASC,
    On_Time_Rate_Pct ASC;


-- ============================================================
-- Step 14: Overstock Reduction & Inventory Capital Optimization
-- ============================================================

WITH OverstockBase AS
(
    SELECT
        i.product_id,
        p.product_name,
        p.category,

        i.warehouse_id,
        w.warehouse_name,

        i.on_hand_qty,
        i.allocated_qty,
        i.available_qty,
        i.avg_daily_demand,
        i.reorder_point,
        i.unit_cost,
        i.inventory_value,

        CAST(
            1.0 * i.available_qty /
            NULLIF(i.avg_daily_demand, 0)
            AS DECIMAL(12,2)
        ) AS Inventory_DOH,

        CASE
            WHEN i.available_qty > i.reorder_point
            THEN i.available_qty - i.reorder_point
            ELSE 0
        END AS Excess_Qty_Above_ROP

    FROM raw.Inventory i

    INNER JOIN raw.Products p
        ON i.product_id = p.product_id

    INNER JOIN raw.Warehouses w
        ON i.warehouse_id = w.warehouse_id

    WHERE i.stock_status = 'Overstock'
),

OverstockExposure AS
(
    SELECT
        *,

        CAST(
            Excess_Qty_Above_ROP * unit_cost
            AS DECIMAL(18,2)
        ) AS Potential_Excess_Stock_Value

    FROM OverstockBase
)

SELECT TOP 25
    product_id,
    product_name,
    category,

    warehouse_id,
    warehouse_name,

    on_hand_qty,
    allocated_qty,
    available_qty,
    avg_daily_demand,
    reorder_point,

    Inventory_DOH,
    Excess_Qty_Above_ROP,

    CAST(inventory_value AS DECIMAL(18,2))
        AS Inventory_Value,

    Potential_Excess_Stock_Value,

    CASE
        WHEN Potential_Excess_Stock_Value >= 100000
        THEN 'CRITICAL'

        WHEN Potential_Excess_Stock_Value >= 50000
        THEN 'HIGH'

        ELSE 'MEDIUM'
    END AS Capital_Optimization_Priority,

    CASE
        WHEN Inventory_DOH >= 180
        THEN 'Review Slow-Moving Stock + Transfer Options'

        WHEN Inventory_DOH >= 90
        THEN 'Reduce Future Replenishment + Review Transfers'

        ELSE 'Review Excess Stock Against Demand Forecast'
    END AS Recommended_Action

FROM OverstockExposure

ORDER BY
    Potential_Excess_Stock_Value DESC,
    Inventory_DOH DESC;



-- ============================================================
-- Step 15: Inter-Warehouse Stock Transfer Opportunities
-- ============================================================

WITH SourceStock AS
(
    SELECT
        product_id,
        warehouse_id AS Source_Warehouse_ID,
        available_qty AS Source_Available_Qty,
        reorder_point AS Source_Reorder_Point,
        unit_cost,

        available_qty - reorder_point
            AS Transferable_Qty

    FROM raw.Inventory

    WHERE stock_status = 'Overstock'
      AND available_qty > reorder_point
),

DestinationNeed AS
(
    SELECT
        product_id,
        warehouse_id AS Destination_Warehouse_ID,
        available_qty AS Destination_Available_Qty,
        reorder_point AS Destination_Reorder_Point,

        reorder_point - available_qty
            AS Replenishment_Gap_Qty

    FROM raw.Inventory

    WHERE available_qty < reorder_point
),

TransferCandidates AS
(
    SELECT
        s.product_id,
        p.product_name,
        p.category,

        s.Source_Warehouse_ID,
        sw.warehouse_name AS Source_Warehouse,

        d.Destination_Warehouse_ID,
        dw.warehouse_name AS Destination_Warehouse,

        s.Source_Available_Qty,
        s.Source_Reorder_Point,
        s.Transferable_Qty,

        d.Destination_Available_Qty,
        d.Destination_Reorder_Point,
        d.Replenishment_Gap_Qty,

        s.unit_cost,

        CASE
            WHEN s.Transferable_Qty < d.Replenishment_Gap_Qty
            THEN s.Transferable_Qty
            ELSE d.Replenishment_Gap_Qty
        END AS Proposed_Transfer_Qty

    FROM SourceStock s

    INNER JOIN DestinationNeed d
        ON s.product_id = d.product_id
       AND s.Source_Warehouse_ID <> d.Destination_Warehouse_ID

    INNER JOIN raw.Products p
        ON s.product_id = p.product_id

    INNER JOIN raw.Warehouses sw
        ON s.Source_Warehouse_ID = sw.warehouse_id

    INNER JOIN raw.Warehouses dw
        ON d.Destination_Warehouse_ID = dw.warehouse_id
)

SELECT TOP 25
    product_id,
    product_name,
    category,

    Source_Warehouse_ID,
    Source_Warehouse,

    Destination_Warehouse_ID,
    Destination_Warehouse,

    Source_Available_Qty,
    Source_Reorder_Point,
    Transferable_Qty,

    Destination_Available_Qty,
    Destination_Reorder_Point,
    Replenishment_Gap_Qty,

    Proposed_Transfer_Qty,

    CAST(
        Proposed_Transfer_Qty * unit_cost
        AS DECIMAL(18,2)
    ) AS Proposed_Transfer_Value,

    CASE
        WHEN Destination_Available_Qty = 0
        THEN 'CRITICAL'

        WHEN Replenishment_Gap_Qty >= 50
        THEN 'HIGH'

        ELSE 'MEDIUM'
    END AS Transfer_Priority,

    'Review Inter-Warehouse Stock Transfer'
        AS Recommended_Action

FROM TransferCandidates

WHERE Proposed_Transfer_Qty > 0

ORDER BY
    CASE
        WHEN Destination_Available_Qty = 0 THEN 1
        WHEN Replenishment_Gap_Qty >= 50 THEN 2
        ELSE 3
    END,
    Proposed_Transfer_Value DESC;



-- ============================================================
-- Step 16: Inventory Transfer Opportunity Summary
-- ============================================================

WITH SourceStock AS
(
    SELECT
        product_id,
        warehouse_id AS Source_Warehouse_ID,
        available_qty - reorder_point AS Transferable_Qty,
        unit_cost
    FROM raw.Inventory
    WHERE stock_status = 'Overstock'
      AND available_qty > reorder_point
),

DestinationNeed AS
(
    SELECT
        product_id,
        warehouse_id AS Destination_Warehouse_ID,
        available_qty AS Destination_Available_Qty,
        reorder_point - available_qty AS Replenishment_Gap_Qty
    FROM raw.Inventory
    WHERE available_qty < reorder_point
),

TransferCandidates AS
(
    SELECT
        s.product_id,
        s.Source_Warehouse_ID,
        d.Destination_Warehouse_ID,
        d.Destination_Available_Qty,

        CASE
            WHEN s.Transferable_Qty < d.Replenishment_Gap_Qty
            THEN s.Transferable_Qty
            ELSE d.Replenishment_Gap_Qty
        END AS Candidate_Transfer_Qty,

        s.unit_cost

    FROM SourceStock s

    INNER JOIN DestinationNeed d
        ON s.product_id = d.product_id
       AND s.Source_Warehouse_ID <> d.Destination_Warehouse_ID
),

TransferSummary AS
(
    SELECT
        Source_Warehouse_ID,
        Destination_Warehouse_ID,

        COUNT(*) AS Transfer_Opportunities,

        SUM(Candidate_Transfer_Qty)
            AS Candidate_Transfer_Qty,

        CAST(
            SUM(Candidate_Transfer_Qty * unit_cost)
            AS DECIMAL(18,2)
        ) AS Candidate_Transfer_Value,

        SUM(
            CASE
                WHEN Destination_Available_Qty = 0
                THEN 1 ELSE 0
            END
        ) AS Stockout_Recovery_Opportunities

    FROM TransferCandidates

    WHERE Candidate_Transfer_Qty > 0

    GROUP BY
        Source_Warehouse_ID,
        Destination_Warehouse_ID
)

SELECT
    ts.Source_Warehouse_ID,
    sw.warehouse_name AS Source_Warehouse,

    ts.Destination_Warehouse_ID,
    dw.warehouse_name AS Destination_Warehouse,

    ts.Transfer_Opportunities,
    ts.Candidate_Transfer_Qty,
    ts.Candidate_Transfer_Value,
    ts.Stockout_Recovery_Opportunities,

    DENSE_RANK() OVER
    (
        ORDER BY ts.Candidate_Transfer_Value DESC
    ) AS Opportunity_Rank,

    'Review Transfer Feasibility'
        AS Recommended_Action

FROM TransferSummary ts

INNER JOIN raw.Warehouses sw
    ON ts.Source_Warehouse_ID = sw.warehouse_id

INNER JOIN raw.Warehouses dw
    ON ts.Destination_Warehouse_ID = dw.warehouse_id

ORDER BY
    Opportunity_Rank;



-- ============================================================
-- Step 17: Executive Action Plan (30 / 60 / 90 Days)
-- ============================================================

SELECT *
FROM
(
    VALUES

    (1, '0-30 Days', 'CRITICAL',
     'Procurement',
     'Uncovered Replenishment',
     'Review 231 reorder-required records without inbound POs',
     'Confirm supply requirements and initiate justified POs',
     'Uncovered Reorder Records',
     '231 baseline; target 0 unresolved'),

    (2, '0-30 Days', 'CRITICAL',
     'Inventory Planning',
     'Stockout Recovery',
     'Prioritize 240 zero-available-stock records',
     'Validate demand and allocate available replenishment',
     'Stockout Records',
     '240 baseline; reduce month over month'),

    (3, '0-30 Days', 'CRITICAL',
     'Sales Operations',
     'High-Value Backlog',
     'Review high-value and urgent backlogged orders',
     'Validate current open status and establish recovery ownership',
     'Backlog Value',
     '257.35M baseline; reduce month over month'),

    (4, '0-30 Days', 'HIGH',
     'Supplier Management',
     'Supplier Escalation',
     'Review suppliers with on-time performance below 50%',
     'Investigate delays and agree corrective actions',
     'Supplier On-Time Rate',
     'Track improvement from supplier baseline'),

    (5, '0-30 Days', 'HIGH',
     'Warehouse Operations',
     'Pune DC Improvement',
     'Investigate Pune DC reorder and fulfillment performance',
     'Review allocation, replenishment and shipment execution',
     'Reorder Rate / Fill Rate',
     '48.20% reorder / 87.12% fill baseline'),

    (6, '31-60 Days', 'HIGH',
     'Inventory Planning',
     'Demand-Based Replenishment',
     'Review high-demand product-warehouse combinations',
     'Adjust reorder parameters using demand and lead-time evidence',
     'Backlog Rate / Stockout Rate',
     'Improve against validated baseline'),

    (7, '31-60 Days', 'HIGH',
     'Logistics',
     'Delivery Performance',
     'Improve warehouse delivery execution',
     'Investigate late shipments and fulfillment handoffs',
     'On-Time Delivery Rate',
     '71.22% baseline; target 80% pilot'),

    (8, '31-60 Days', 'HIGH',
     'Fulfillment Operations',
     'Complete-Order Fulfillment',
     'Reduce partially fulfilled shipments',
     'Review inventory allocation and shipment release controls',
     'OTIF Rate',
     '46.25% baseline; target 55% pilot'),

    (9, '31-60 Days', 'MEDIUM',
     'Inventory Control',
     'Overstock Optimization',
     'Review 478 overstock records',
     'Validate excess stock and assess transfers or purchase reductions',
     'Overstock Records / Inventory Value',
     '478 baseline; reduce avoidable overstock'),

    (10, '31-60 Days', 'MEDIUM',
     'Warehouse Operations',
     'Inter-Warehouse Transfers',
     'Evaluate candidate transfer routes',
     'Allocate stock without duplication and assess transport feasibility',
     'Approved Transfer Quantity',
     'Track only feasible approved transfers'),

    (11, '61-90 Days', 'HIGH',
     'Category Management',
     'Automotive Fulfillment',
     'Improve Automotive category fulfillment',
     'Review forecasting, product availability and allocation',
     'Automotive Fill Rate',
     '86.63% baseline; target 90% pilot'),

    (12, '61-90 Days', 'HIGH',
     'Commercial Operations',
     'High-Value SKU Protection',
     'Protect products with concentrated backlog exposure',
     'Introduce differentiated replenishment and service monitoring',
     'High-Value SKU Backlog Value',
     'Reduce from validated quartile baseline'),

    (13, '61-90 Days', 'MEDIUM',
     'Supplier Management',
     'Supplier Scorecards',
     'Separate supplier quality and delivery reliability metrics',
     'Introduce regular supplier scorecard reviews',
     'Supplier Reliability / On-Time Rate',
     'Monthly scorecard adoption'),

    (14, '61-90 Days', 'MEDIUM',
     'Business Intelligence',
     'KPI Monitoring',
     'Develop executive Power BI monitoring dashboards',
     'Track sales, backlog, inventory, delivery and procurement KPIs',
     'Dashboard Refresh / KPI Coverage',
     'Validated dashboard with scheduled refresh'),

    (15, '61-90 Days', 'MEDIUM',
     'Operations Leadership',
     'Performance Governance',
     'Review cross-functional KPI improvements',
     'Establish monthly exception reviews and accountable owners',
     'Action Closure Rate',
     'Monthly management review')

) AS ActionPlan
(
    Action_ID,
    Timeline,
    Priority,
    Responsible_Team,
    Focus_Area,
    Business_Problem,
    Recommended_Action,
    Success_KPI,
    Baseline_And_Target
)

ORDER BY Action_ID;


-- ============================================================
-- Step 18: Executive KPI Monitoring Framework
-- ============================================================

SELECT *
FROM
(
    VALUES

    (1, 'Sales', 'Total Sales Value',
     '2068495698.91', 'Monitor monthly growth',
     'Monthly', 'Sales Operations', 'Revenue Performance'),

    (2, 'Fulfillment', 'Order Fill Rate',
     '87.81%', '>= 90%',
     'Weekly', 'Fulfillment Operations', 'Service Improvement'),

    (3, 'Backlog', 'Backlogged Order Rate',
     '43.40%', '< 40%',
     'Weekly', 'Sales Operations', 'Backlog Reduction'),

    (4, 'Backlog', 'Total Backlog Value',
     '257349919.66', 'Reduce month over month',
     'Weekly', 'Sales Operations', 'Commercial Exposure'),

    (5, 'Inventory', 'Stockout Records',
     '240', '< 200',
     'Daily', 'Inventory Planning', 'Availability Improvement'),

    (6, 'Inventory', 'Reorder Required Records',
     '1311', 'Reduce unresolved shortages',
     'Daily', 'Inventory Planning', 'Replenishment Control'),

    (7, 'Procurement', 'Uncovered Reorder Records',
     '231', '0 unresolved',
     'Daily', 'Procurement', 'Supply Coverage'),

    (8, 'Inventory', 'Overstock Records',
     '478', 'Reduce avoidable overstock',
     'Monthly', 'Inventory Control', 'Working Capital'),

    (9, 'Delivery', 'On-Time Delivery Rate',
     '71.22%', '>= 80% pilot',
     'Weekly', 'Logistics', 'Delivery Reliability'),

    (10, 'Delivery', 'OTIF Rate',
     '46.25%', '>= 55% pilot',
     'Weekly', 'Fulfillment Operations', 'Complete and On-Time Service'),

    (11, 'Suppliers', 'Supplier On-Time Rate',
     '65.35%', '>= 70% pilot',
     'Monthly', 'Supplier Management', 'Procurement Reliability'),

    (12, 'Category', 'Automotive Fill Rate',
     '86.63%', '>= 90% pilot',
     'Monthly', 'Category Management', 'Category Fulfillment'),

    (13, 'Warehouse', 'Pune DC Reorder Rate',
     '48.20%', '< 45% pilot',
     'Weekly', 'Warehouse Operations', 'Warehouse Availability'),

    (14, 'Inventory', 'Approved Transfer Quantity',
     'Not established', 'Track approved transfers',
     'Monthly', 'Warehouse Operations', 'Inventory Rebalancing'),

    (15, 'Governance', 'Action Closure Rate',
     'Not established', '>= 90% by due date',
     'Monthly', 'Operations Leadership', 'Execution Accountability')

) AS KPIFramework
(
    KPI_ID,
    Business_Area,
    KPI_Name,
    Current_Baseline,
    Proposed_Target,
    Review_Frequency,
    Responsible_Team,
    Business_Objective
)

ORDER BY KPI_ID;



-- ============================================================
-- Step 19: Executive Recommendations Summary
-- ============================================================

WITH Recommendations AS
(
    SELECT *
    FROM
    (
        VALUES
        (1, 'CRITICAL', 'Inventory & Procurement',
         '231 reorder-required records have no inbound PO',
         'Validate shortages and initiate justified replenishment',
         '0 unresolved uncovered reorder records',
         '0-30 Days'),

        (2, 'CRITICAL', 'Inventory Availability',
         '240 product-warehouse records have zero available stock',
         'Prioritize stockout recovery using demand and backlog exposure',
         'Reduce stockout records from 240',
         '0-30 Days'),

        (3, 'CRITICAL', 'Backlog Management',
         '10,850 orders have backlog worth 257.35M',
         'Prioritize high-value and high-demand backlog exposure',
         'Reduce backlog value and backlogged order rate',
         '0-30 Days'),

        (4, 'HIGH', 'Supplier Performance',
         'Four suppliers identified as critical in supplier review',
         'Escalate delivery failures and review outstanding purchase orders',
         'Improve supplier on-time performance',
         '0-30 Days'),

        (5, 'HIGH', 'Warehouse Operations',
         'Bengaluru Central and Pune DC are critical warehouse priorities',
         'Review inventory availability, allocation and fulfillment',
         'Improve warehouse fill rate and reorder coverage',
         '0-30 Days'),

        (6, 'HIGH', 'Delivery Performance',
         'On-time delivery is 71.22% and OTIF is 46.25%',
         'Improve complete-order fulfillment and delivery execution',
         'On-time >= 80%; OTIF >= 55% pilot',
         '31-60 Days'),

        (7, 'HIGH', 'Category Management',
         'Automotive has the lowest fill rate at 86.63%',
         'Review category forecasting and replenishment',
         'Automotive fill rate >= 90% pilot',
         '31-90 Days'),

        (8, 'MEDIUM', 'Inventory Optimization',
         '478 records are classified as overstock',
         'Validate surplus stock and assess purchase reductions or transfers',
         'Reduce avoidable overstock',
         '31-60 Days'),

        (9, 'MEDIUM', 'Inventory Rebalancing',
         'Inter-warehouse transfer candidates identified',
         'Evaluate feasible transfers without duplicate allocation',
         'Track approved transfer quantities',
         '31-60 Days'),

        (10, 'MEDIUM', 'Business Intelligence',
         'Cross-functional KPI monitoring required',
         'Build validated Power BI executive and operational dashboards',
         'Regular KPI reporting and exception monitoring',
         '61-90 Days')
    ) AS R
    (
        Recommendation_ID,
        Priority,
        Business_Area,
        Evidence,
        Recommended_Action,
        Success_Measure,
        Implementation_Timeline
    )
)

SELECT
    Recommendation_ID,
    Priority,
    Business_Area,
    Evidence,
    Recommended_Action,
    Success_Measure,
    Implementation_Timeline,

    CASE Priority
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        ELSE 3
    END AS Priority_Score

FROM Recommendations

ORDER BY
    Priority_Score,
    Recommendation_ID;


-- ============================================================
-- Step 20: Final Business Recommendations Reconciliation
-- ============================================================

DECLARE @Checks TABLE
(
    Check_Name VARCHAR(150),
    Actual_Value DECIMAL(20,2),
    Expected_Value DECIMAL(20,2),
    Status VARCHAR(10)
);

INSERT INTO @Checks
SELECT
    'Total Orders',
    COUNT(*),
    25000,
    CASE WHEN COUNT(*) = 25000 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Total Ordered Quantity',
    SUM(ordered_qty),
    501755,
    CASE WHEN SUM(ordered_qty) = 501755 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Total Fulfilled Quantity',
    SUM(fulfilled_qty),
    440576,
    CASE WHEN SUM(fulfilled_qty) = 440576 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Total Backlog Quantity',
    SUM(backlog_qty),
    61179,
    CASE WHEN SUM(backlog_qty) = 61179 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Backlogged Orders',
    COUNT(*),
    10850,
    CASE WHEN COUNT(*) = 10850 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders
WHERE backlog_qty > 0

UNION ALL

SELECT
    'Inventory Records',
    COUNT(*),
    3000,
    CASE WHEN COUNT(*) = 3000 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory

UNION ALL

SELECT
    'Stockout Records',
    COUNT(*),
    240,
    CASE WHEN COUNT(*) = 240 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory
WHERE available_qty = 0

UNION ALL

SELECT
    'Reorder Required Records',
    COUNT(*),
    1311,
    CASE WHEN COUNT(*) = 1311 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory
WHERE available_qty <= reorder_point

UNION ALL

SELECT
    'Overstock Records',
    COUNT(*),
    478,
    CASE WHEN COUNT(*) = 478 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory
WHERE stock_status = 'Overstock'

UNION ALL

SELECT
    'Valid Shipments',
    COUNT(*),
    20331,
    CASE WHEN COUNT(*) = 20331 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Shipments
WHERE actual_delivery_date >= shipment_date

UNION ALL

SELECT
    'Evaluated Purchase Orders',
    COUNT(*),
    8470,
    CASE WHEN COUNT(*) = 8470 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Purchase_Orders
WHERE actual_receipt_date IS NOT NULL
  AND supplier_delay_days IS NOT NULL;

SELECT *
FROM @Checks;

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
    END AS Business_Recommendations_Reconciliation_Status
FROM @Checks;



-- ============================================================
-- Step 21: Final Business Insights & Recommendations
-- ============================================================

/*
1. BACKLOG REDUCTION
   - 10,850 orders have backlog (43.40%).
   - Total backlog value: 257.35M.
   - Prioritize high-demand and high-value products.
   - Validate open orders before initiating recovery.

2. INVENTORY AVAILABILITY
   - 240 product-warehouse records have zero available stock.
   - 1,311 records require replenishment.
   - Prioritize stockouts using demand and commercial exposure.

3. PROCUREMENT COVERAGE
   - 231 reorder-required records have no inbound PO.
   - Review these records for immediate procurement action.
   - Validate outstanding PO quantities before ordering.

4. SUPPLIER IMPROVEMENT
   - Overall supplier on-time performance: 65.35%.
   - Four suppliers were classified as CRITICAL in Step 8.
   - Prioritize corrective action and open PO reviews.

5. WAREHOUSE IMPROVEMENT
   - Bengaluru Central and Pune DC are CRITICAL
     under the proposed warehouse priority rules.
   - Bengaluru Central has the highest backlog value.
   - Pune DC has the highest reorder-required rate.

6. DELIVERY PERFORMANCE
   - Valid shipment on-time rate: 71.22%.
   - Valid shipment OTIF rate: 46.25%.
   - Improve fulfillment completeness and delivery execution.

7. CATEGORY IMPROVEMENT
   - Automotive has the lowest fill rate: 86.63%.
   - Health & Personal Care has the highest reorder rate:
     47.05%.
   - Electronics has the highest category backlog value.

8. INVENTORY CAPITAL OPTIMIZATION
   - 478 inventory records are classified as overstock.
   - Review excess stock against forecast demand,
     safety stock and lead-time requirements.
   - Do not assume all inventory above reorder point
     represents disposable surplus.

9. INTER-WAREHOUSE TRANSFERS
   - Candidate stock transfer routes were identified.
   - Validate available quantities and destination needs.
   - Prevent duplicate allocation of source inventory.
   - Evaluate transfer cost and delivery feasibility.

10. CUSTOMER RETENTION
    - Prioritize high-value customers with backlog exposure.
    - Verify current order status before contacting customers.
    - Establish ownership for critical service recovery.

11. EXECUTIVE ACTION PLAN
    - 0-30 days: Stockouts, uncovered replenishment,
      critical backlog and supplier escalation.
    - 31-60 days: Delivery, OTIF, replenishment optimization
      and inventory transfers.
    - 61-90 days: Category improvement, supplier scorecards,
      Power BI monitoring and governance.

12. PERFORMANCE MONITORING
    - Track the 15 executive KPIs defined in Step 18.
    - Assign KPI ownership and reporting frequency.
    - Treat proposed targets as pilot objectives.

13. ANALYTICAL LIMITATIONS
    - Historical backlog is not verified current backlog.
    - Correlation does not establish causation.
    - Stockout exposure is not confirmed lost revenue.
    - Candidate transfer quantities may overlap.
    - Operational recommendations require current-data
      validation before implementation.

14. FINAL MANAGEMENT RECOMMENDATION
    - Prioritize service recovery and inventory availability.
    - Strengthen supplier and warehouse accountability.
    - Reduce avoidable backlog and excess inventory.
    - Use



-- ============================================================
-- Step 22: Final SQL Project Validation
-- ============================================================

DECLARE @FinalChecks TABLE
(
    Check_ID INT IDENTITY(1,1),
    Validation_Check VARCHAR(150),
    Status VARCHAR(10)
);

INSERT INTO @FinalChecks
    (Validation_Check, Status)

SELECT
    'Total Sales Orders',
    CASE WHEN COUNT(*) = 25000
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Total Sales Order Items',
    CASE WHEN COUNT(*) = 61397
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Order_Items

UNION ALL

SELECT
    'Total Inventory Records',
    CASE WHEN COUNT(*) = 3000
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory

UNION ALL

SELECT
    'Total Products',
    CASE WHEN COUNT(*) = 500
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Products

UNION ALL

SELECT
    'Total Customers',
    CASE WHEN COUNT(*) = 2500
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Customers

UNION ALL

SELECT
    'Total Warehouses',
    CASE WHEN COUNT(*) = 6
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Warehouses

UNION ALL

SELECT
    'Total Suppliers',
    CASE WHEN COUNT(*) = 100
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Suppliers

UNION ALL

SELECT
    'Total Purchase Orders',
    CASE WHEN COUNT(*) = 8500
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Purchase_Orders

UNION ALL

SELECT
    'Total Shipments',
    CASE WHEN COUNT(*) = 24798
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Shipments

UNION ALL

SELECT
    'Clean Inventory Transactions',
    CASE WHEN COUNT(*) = 110000
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory_Transactions

UNION ALL

SELECT
    'Total Ordered Quantity',
    CASE WHEN SUM(ordered_qty) = 501755
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Total Fulfilled Quantity',
    CASE WHEN SUM(fulfilled_qty) = 440576
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Total Backlog Quantity',
    CASE WHEN SUM(backlog_qty) = 61179
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Backlogged Orders',
    CASE WHEN COUNT(*) = 10850
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders
WHERE backlog_qty > 0

UNION ALL

SELECT
    'Order Quantity Reconciliation',
    CASE WHEN SUM(ordered_qty) =
              SUM(fulfilled_qty + backlog_qty)
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Overall Fill Rate',
    CASE WHEN CAST(
        100.0 * SUM(fulfilled_qty) /
        NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)) = 87.81
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Stockout Records',
    CASE WHEN COUNT(*) = 240
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory
WHERE available_qty = 0

UNION ALL

SELECT
    'Reorder Required Records',
    CASE WHEN COUNT(*) = 1311
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory
WHERE available_qty <= reorder_point

UNION ALL

SELECT
    'Overstock Records',
    CASE WHEN COUNT(*) = 478
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory
WHERE stock_status = 'Overstock'

UNION ALL

SELECT
    'Valid Shipment Chronology',
    CASE WHEN COUNT(*) = 20331
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Shipments
WHERE actual_delivery_date >= shipment_date

UNION ALL

SELECT
    'Invalid Shipment Chronology',
    CASE WHEN COUNT(*) = 4467
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Shipments
WHERE actual_delivery_date < shipment_date

UNION ALL

SELECT
    'Evaluated Purchase Orders',
    CASE WHEN COUNT(*) = 8470
         THEN 'PASS' ELSE 'FAIL' END
FROM raw.Purchase_Orders
WHERE actual_receipt_date IS NOT NULL
  AND supplier_delay_days IS NOT NULL

UNION ALL

SELECT
    'Inventory Product Relationships',
    CASE WHEN NOT EXISTS
    (
        SELECT 1
        FROM raw.Inventory i
        LEFT JOIN raw.Products p
            ON i.product_id = p.product_id
        WHERE p.product_id IS NULL
    )
    THEN 'PASS' ELSE 'FAIL' END

UNION ALL

SELECT
    'Inventory Warehouse Relationships',
    CASE WHEN NOT EXISTS
    (
        SELECT 1
        FROM raw.Inventory i
        LEFT JOIN raw.Warehouses w
            ON i.warehouse_id = w.warehouse_id
        WHERE w.warehouse_id IS NULL
    )
    THEN 'PASS' ELSE 'FAIL' END;

-- Individual validation results
SELECT
    Check_ID,
    Validation_Check,
    Status
FROM @FinalChecks
ORDER BY Check_ID;

-- Final project validation summary
SELECT
    COUNT(*) AS Total_Checks,

    SUM(CASE WHEN Status = 'PASS' THEN 1 ELSE 0 END)
        AS Passed_Checks,

    SUM(CASE WHEN Status = 'FAIL' THEN 1 ELSE 0 END)
        AS Failed_Checks,

    CASE
        WHEN COUNT(*) =
             SUM(CASE WHEN Status = 'PASS' THEN 1 ELSE 0 END)
        THEN 'PASSED'
        ELSE 'FAILED'
    END AS Final_SQL_Project_Status

FROM @FinalChecks;