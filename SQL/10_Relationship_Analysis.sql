-- ============================================================
-- SALES ORDER, BACKLOG & INVENTORY ANALYTICS
-- File: 10_Relationship_Analysis.sql
-- Purpose: Cross-Functional Relationship Analysis
-- ============================================================

USE Sales_Order_Backlog_Inventory_Analytics;
GO

-- ============================================================
-- Step 1: Validate Core Relationship Tables
-- ============================================================

SELECT
    'Sales Orders' AS Dataset,
    COUNT(*) AS Records
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Sales Order Items',
    COUNT(*)
FROM raw.Sales_Order_Items

UNION ALL

SELECT
    'Inventory',
    COUNT(*)
FROM raw.Inventory

UNION ALL

SELECT
    'Inventory Transactions',
    COUNT(*)
FROM raw.Inventory_Transactions

UNION ALL

SELECT
    'Shipments',
    COUNT(*)
FROM raw.Shipments

UNION ALL

SELECT
    'Purchase Orders',
    COUNT(*)
FROM raw.Purchase_Orders

UNION ALL

SELECT
    'Products',
    COUNT(*)
FROM raw.Products

UNION ALL

SELECT
    'Suppliers',
    COUNT(*)
FROM raw.Suppliers

UNION ALL

SELECT
    'Warehouses',
    COUNT(*)
FROM raw.Warehouses;



-- ============================================================
-- Step 2: Inventory vs Fulfillment Relationship
-- Product × Warehouse Level
-- Corrected for raw.Inventory schema
-- ============================================================

WITH FulfillmentPW AS
(
    SELECT
        soi.product_id,
        soi.warehouse_id,

        COUNT(*) AS Order_Lines,

        SUM(soi.ordered_qty) AS Ordered_Qty,
        SUM(soi.fulfilled_qty) AS Fulfilled_Qty,
        SUM(soi.backlog_qty) AS Backlog_Qty,

        CAST(
            100.0 * SUM(soi.fulfilled_qty)
            / NULLIF(SUM(soi.ordered_qty), 0)
            AS DECIMAL(8,2)
        ) AS Fill_Rate_Pct,

        CAST(
            100.0 * SUM(soi.backlog_qty)
            / NULLIF(SUM(soi.ordered_qty), 0)
            AS DECIMAL(8,2)
        ) AS Backlog_Rate_Pct

    FROM raw.Sales_Order_Items AS soi

    GROUP BY
        soi.product_id,
        soi.warehouse_id
)

SELECT TOP 20
    i.product_id,
    p.product_name,
    p.category,

    i.warehouse_id,
    w.warehouse_name,

    i.on_hand_qty,
    i.allocated_qty,
    i.available_qty,
    i.avg_daily_demand,
    i.safety_stock,
    i.reorder_point,

    -- Days of Inventory
    CAST(
        i.available_qty * 1.0
        / NULLIF(i.avg_daily_demand, 0)
        AS DECIMAL(10,2)
    ) AS Inventory_Days_On_Hand,

    -- Reorder Required
    CASE
        WHEN i.available_qty <= i.reorder_point
        THEN 'Y'
        ELSE 'N'
    END AS Reorder_Required_Flag,

    ISNULL(f.Order_Lines, 0) AS Order_Lines,
    ISNULL(f.Ordered_Qty, 0) AS Ordered_Qty,
    ISNULL(f.Fulfilled_Qty, 0) AS Fulfilled_Qty,
    ISNULL(f.Backlog_Qty, 0) AS Backlog_Qty,
    ISNULL(f.Fill_Rate_Pct, 0) AS Fill_Rate_Pct,
    ISNULL(f.Backlog_Rate_Pct, 0) AS Backlog_Rate_Pct

FROM raw.Inventory AS i

INNER JOIN raw.Products AS p
    ON i.product_id = p.product_id

INNER JOIN raw.Warehouses AS w
    ON i.warehouse_id = w.warehouse_id

LEFT JOIN FulfillmentPW AS f
    ON i.product_id = f.product_id
   AND i.warehouse_id = f.warehouse_id

ORDER BY
    Backlog_Qty DESC,
    i.available_qty ASC;



-- ============================================================
-- Step 3: Inventory vs Backlog Correlation
-- Product × Warehouse Level
-- ============================================================

WITH FulfillmentPW AS
(
    SELECT
        product_id,
        warehouse_id,

        SUM(ordered_qty) AS Ordered_Qty,
        SUM(backlog_qty) AS Backlog_Qty,

        100.0 * SUM(backlog_qty)
        / NULLIF(SUM(ordered_qty), 0) AS Backlog_Rate_Pct

    FROM raw.Sales_Order_Items

    GROUP BY
        product_id,
        warehouse_id
),

RelationshipBase AS
(
    SELECT
        i.product_id,
        i.warehouse_id,

        CAST(i.available_qty AS FLOAT)
            AS Available_Qty,

        CAST(i.avg_daily_demand AS FLOAT)
            AS Avg_Daily_Demand,

        CAST(
            i.available_qty * 1.0
            / NULLIF(i.avg_daily_demand, 0)
            AS FLOAT
        ) AS Inventory_Days_On_Hand,

        CAST(ISNULL(f.Backlog_Qty, 0) AS FLOAT)
            AS Backlog_Qty,

        CAST(ISNULL(f.Backlog_Rate_Pct, 0) AS FLOAT)
            AS Backlog_Rate_Pct

    FROM raw.Inventory AS i

    LEFT JOIN FulfillmentPW AS f
        ON i.product_id = f.product_id
       AND i.warehouse_id = f.warehouse_id
)

SELECT
    COUNT(*) AS Product_Warehouse_Records,

    CAST(
        (
            AVG(Available_Qty * Backlog_Qty)
            - AVG(Available_Qty) * AVG(Backlog_Qty)
        )
        /
        NULLIF(
            STDEV(Available_Qty) * STDEV(Backlog_Qty),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_AvailableQty_BacklogQty,

    CAST(
        (
            AVG(Available_Qty * Backlog_Rate_Pct)
            - AVG(Available_Qty) * AVG(Backlog_Rate_Pct)
        )
        /
        NULLIF(
            STDEV(Available_Qty) * STDEV(Backlog_Rate_Pct),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_AvailableQty_BacklogRate,

    CAST(
        (
            AVG(Inventory_Days_On_Hand * Backlog_Rate_Pct)
            - AVG(Inventory_Days_On_Hand) * AVG(Backlog_Rate_Pct)
        )
        /
        NULLIF(
            STDEV(Inventory_Days_On_Hand)
            * STDEV(Backlog_Rate_Pct),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_InventoryDOH_BacklogRate,

    CAST(
        (
            AVG(Avg_Daily_Demand * Backlog_Qty)
            - AVG(Avg_Daily_Demand) * AVG(Backlog_Qty)
        )
        /
        NULLIF(
            STDEV(Avg_Daily_Demand) * STDEV(Backlog_Qty),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_Demand_BacklogQty

FROM RelationshipBase;



-- ============================================================
-- Step 4: Demand Level vs Backlog Performance
-- Product × Warehouse Level
-- ============================================================

WITH FulfillmentPW AS
(
    SELECT
        product_id,
        warehouse_id,

        SUM(ordered_qty) AS Ordered_Qty,
        SUM(fulfilled_qty) AS Fulfilled_Qty,
        SUM(backlog_qty) AS Backlog_Qty,
        SUM(backlog_value) AS Backlog_Value

    FROM raw.Sales_Order_Items

    GROUP BY
        product_id,
        warehouse_id
),

DemandBase AS
(
    SELECT
        i.product_id,
        i.warehouse_id,
        i.avg_daily_demand,

        ISNULL(f.Ordered_Qty, 0) AS Ordered_Qty,
        ISNULL(f.Fulfilled_Qty, 0) AS Fulfilled_Qty,
        ISNULL(f.Backlog_Qty, 0) AS Backlog_Qty,
        ISNULL(f.Backlog_Value, 0) AS Backlog_Value

    FROM raw.Inventory AS i

    LEFT JOIN FulfillmentPW AS f
        ON i.product_id = f.product_id
       AND i.warehouse_id = f.warehouse_id
),

DemandQuartiles AS
(
    SELECT
        *,

        NTILE(4) OVER
        (
            ORDER BY avg_daily_demand
        ) AS Demand_Quartile

    FROM DemandBase
)

SELECT
    CASE Demand_Quartile
        WHEN 1 THEN 'Q1 - Lowest Demand'
        WHEN 2 THEN 'Q2 - Low-Medium Demand'
        WHEN 3 THEN 'Q3 - High-Medium Demand'
        WHEN 4 THEN 'Q4 - Highest Demand'
    END AS Demand_Group,

    COUNT(*) AS Product_Warehouse_Records,

    SUM(Ordered_Qty) AS Ordered_Qty,
    SUM(Fulfilled_Qty) AS Fulfilled_Qty,
    SUM(Backlog_Qty) AS Backlog_Qty,

    CAST(
        SUM(Backlog_Value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(Fulfilled_Qty)
        / NULLIF(SUM(Ordered_Qty), 0)
        AS DECIMAL(8,2)
    ) AS Fill_Rate_Pct,

    CAST(
        100.0 * SUM(Backlog_Qty)
        / NULLIF(SUM(Ordered_Qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Rate_Pct,

    CAST(
        100.0 * SUM(Backlog_Qty)
        / NULLIF(SUM(SUM(Backlog_Qty)) OVER (), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Qty_Share_Pct,

    CAST(
        100.0 * SUM(Backlog_Value)
        / NULLIF(SUM(SUM(Backlog_Value)) OVER (), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Share_Pct

FROM DemandQuartiles

GROUP BY Demand_Quartile

ORDER BY Demand_Quartile;



-- ============================================================
-- Step 5: Product Sales Value vs Backlog Exposure
-- Product Level
-- ============================================================

WITH ProductPerformance AS
(
    SELECT
        soi.product_id,

        SUM(soi.net_order_value) AS Sales_Value,
        SUM(soi.ordered_qty) AS Ordered_Qty,
        SUM(soi.fulfilled_qty) AS Fulfilled_Qty,
        SUM(soi.backlog_qty) AS Backlog_Qty,
        SUM(soi.backlog_value) AS Backlog_Value

    FROM raw.Sales_Order_Items AS soi

    GROUP BY soi.product_id
),

ValueQuartiles AS
(
    SELECT
        *,

        NTILE(4) OVER
        (
            ORDER BY Sales_Value
        ) AS Sales_Value_Quartile

    FROM ProductPerformance
)

SELECT
    CASE Sales_Value_Quartile
        WHEN 1 THEN 'Q1 - Lowest Sales Value'
        WHEN 2 THEN 'Q2 - Low-Medium Sales Value'
        WHEN 3 THEN 'Q3 - High-Medium Sales Value'
        WHEN 4 THEN 'Q4 - Highest Sales Value'
    END AS Sales_Value_Group,

    COUNT(*) AS Products,

    CAST(
        SUM(Sales_Value)
        AS DECIMAL(18,2)
    ) AS Sales_Value,

    SUM(Ordered_Qty) AS Ordered_Qty,

    SUM(Backlog_Qty) AS Backlog_Qty,

    CAST(
        SUM(Backlog_Value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(Sales_Value)
        / NULLIF(SUM(SUM(Sales_Value)) OVER (), 0)
        AS DECIMAL(8,2)
    ) AS Sales_Value_Share_Pct,

    CAST(
        100.0 * SUM(Backlog_Qty)
        / NULLIF(SUM(Ordered_Qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Rate_Pct,

    CAST(
        100.0 * SUM(Backlog_Value)
        / NULLIF(SUM(SUM(Backlog_Value)) OVER (), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Share_Pct

FROM ValueQuartiles

GROUP BY Sales_Value_Quartile

ORDER BY Sales_Value_Quartile;


-- ============================================================
-- Step 6: Sales Value vs Backlog Value Correlation
-- Product Level
-- ============================================================

WITH ProductPerformance AS
(
    SELECT
        product_id,

        CAST(SUM(net_order_value) AS FLOAT)
            AS Sales_Value,

        CAST(SUM(backlog_value) AS FLOAT)
            AS Backlog_Value,

        CAST(SUM(ordered_qty) AS FLOAT)
            AS Ordered_Qty,

        CAST(SUM(backlog_qty) AS FLOAT)
            AS Backlog_Qty

    FROM raw.Sales_Order_Items

    GROUP BY product_id
),

ProductMetrics AS
(
    SELECT
        *,

        100.0 * Backlog_Qty
        / NULLIF(Ordered_Qty, 0)
            AS Backlog_Rate_Pct

    FROM ProductPerformance
)

SELECT
    COUNT(*) AS Products,

    CAST(
        (
            AVG(Sales_Value * Backlog_Value)
            - AVG(Sales_Value) * AVG(Backlog_Value)
        )
        /
        NULLIF(
            STDEV(Sales_Value) * STDEV(Backlog_Value),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_SalesValue_BacklogValue,

    CAST(
        (
            AVG(Sales_Value * Backlog_Rate_Pct)
            - AVG(Sales_Value) * AVG(Backlog_Rate_Pct)
        )
        /
        NULLIF(
            STDEV(Sales_Value) * STDEV(Backlog_Rate_Pct),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_SalesValue_BacklogRate

FROM ProductMetrics;



-- ============================================================
-- Step 7: Fulfillment Rate vs Delivery Delay
-- Valid Shipment Chronology Only
-- ============================================================

WITH FulfillmentDelivery AS
(
    SELECT
        so.order_id,

        CAST(so.order_fill_rate_pct AS FLOAT)
            AS Fill_Rate_Pct,

        CAST(s.delivery_delay_days AS FLOAT)
            AS Delivery_Delay_Days

    FROM raw.Sales_Orders AS so

    INNER JOIN raw.Shipments AS s
        ON so.order_id = s.order_id

    WHERE s.actual_delivery_date >= s.shipment_date
)

SELECT
    COUNT(*) AS Valid_Orders,

    CAST(
        (
            AVG(Fill_Rate_Pct * Delivery_Delay_Days)
            - AVG(Fill_Rate_Pct) * AVG(Delivery_Delay_Days)
        )
        /
        NULLIF(
            STDEV(Fill_Rate_Pct) *
            STDEV(Delivery_Delay_Days),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_FillRate_DeliveryDelay

FROM FulfillmentDelivery;


-- ============================================================
-- Step 8: Fulfillment Level vs Delivery Performance
-- Valid Shipment Chronology Only
-- ============================================================

WITH FulfillmentDelivery AS
(
    SELECT
        so.order_id,
        so.order_fill_rate_pct,

        s.delivery_delay_days,
        s.on_time_flag,
        s.otif_flag,

        CASE
            WHEN so.order_fill_rate_pct = 100
                THEN '100% Fulfilled'

            WHEN so.order_fill_rate_pct >= 75
                THEN '75-99% Fulfilled'

            WHEN so.order_fill_rate_pct >= 50
                THEN '50-74% Fulfilled'

            ELSE 'Below 50% Fulfilled'
        END AS Fulfillment_Band

    FROM raw.Sales_Orders AS so

    INNER JOIN raw.Shipments AS s
        ON so.order_id = s.order_id

    WHERE s.actual_delivery_date >= s.shipment_date
)

SELECT
    Fulfillment_Band,

    COUNT(*) AS Orders,

    CAST(
        AVG(1.0 * order_fill_rate_pct)
        AS DECIMAL(8,2)
    ) AS Avg_Fill_Rate_Pct,

    CAST(
        AVG(1.0 * delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delivery_Delay_Days,

    CAST(
        100.0 *
        SUM(CASE WHEN on_time_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(CASE WHEN otif_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS OTIF_Rate_Pct

FROM FulfillmentDelivery

GROUP BY Fulfillment_Band

ORDER BY
    CASE Fulfillment_Band
        WHEN '100% Fulfilled' THEN 1
        WHEN '75-99% Fulfilled' THEN 2
        WHEN '50-74% Fulfilled' THEN 3
        WHEN 'Below 50% Fulfilled' THEN 4
    END;



-- ============================================================
-- Step 9: Backlog Severity vs Delivery Performance
-- Valid Shipment Chronology Only
-- ============================================================

WITH BacklogDelivery AS
(
    SELECT
        so.order_id,

        CAST(
            100.0 * so.backlog_qty
            / NULLIF(so.ordered_qty, 0)
            AS DECIMAL(8,2)
        ) AS Backlog_Pct,

        s.delivery_delay_days,
        s.on_time_flag,

        CASE
            WHEN so.backlog_qty = 0
                THEN 'No Backlog'

            WHEN 100.0 * so.backlog_qty
                 / NULLIF(so.ordered_qty, 0) <= 10
                THEN 'Low Backlog (<=10%)'

            WHEN 100.0 * so.backlog_qty
                 / NULLIF(so.ordered_qty, 0) <= 25
                THEN 'Moderate Backlog (11-25%)'

            WHEN 100.0 * so.backlog_qty
                 / NULLIF(so.ordered_qty, 0) <= 50
                THEN 'High Backlog (26-50%)'

            ELSE 'Critical Backlog (>50%)'
        END AS Backlog_Severity

    FROM raw.Sales_Orders AS so

    INNER JOIN raw.Shipments AS s
        ON so.order_id = s.order_id

    WHERE s.actual_delivery_date >= s.shipment_date
)

SELECT
    Backlog_Severity,

    COUNT(*) AS Orders,

    CAST(
        AVG(1.0 * Backlog_Pct)
        AS DECIMAL(8,2)
    ) AS Avg_Backlog_Pct,

    CAST(
        AVG(1.0 * delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delivery_Delay_Days,

    CAST(
        100.0 *
        SUM(CASE WHEN on_time_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(CASE WHEN on_time_flag = 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Late_Rate_Pct

FROM BacklogDelivery

GROUP BY Backlog_Severity

ORDER BY
    CASE Backlog_Severity
        WHEN 'No Backlog' THEN 1
        WHEN 'Low Backlog (<=10%)' THEN 2
        WHEN 'Moderate Backlog (11-25%)' THEN 3
        WHEN 'High Backlog (26-50%)' THEN 4
        WHEN 'Critical Backlog (>50%)' THEN 5
    END;



-- ============================================================
-- Step 10: Backlog Percentage vs Delivery Delay Correlation
-- Valid Shipment Chronology Only
-- ============================================================

WITH BacklogDelivery AS
(
    SELECT
        so.order_id,

        CAST(
            100.0 * so.backlog_qty
            / NULLIF(so.ordered_qty, 0)
            AS FLOAT
        ) AS Backlog_Pct,

        CAST(
            s.delivery_delay_days
            AS FLOAT
        ) AS Delivery_Delay_Days

    FROM raw.Sales_Orders AS so

    INNER JOIN raw.Shipments AS s
        ON so.order_id = s.order_id

    WHERE s.actual_delivery_date >= s.shipment_date
)

SELECT
    COUNT(*) AS Valid_Orders,

    CAST(
        (
            AVG(Backlog_Pct * Delivery_Delay_Days)
            - AVG(Backlog_Pct) * AVG(Delivery_Delay_Days)
        )
        /
        NULLIF(
            STDEV(Backlog_Pct) *
            STDEV(Delivery_Delay_Days),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_BacklogPct_DeliveryDelay

FROM BacklogDelivery;



-- ============================================================
-- Step 11: Supplier Reliability vs Supplier Delivery Delay
-- Closed / Received Purchase Orders Only
-- ============================================================

WITH SupplierDelivery AS
(
    SELECT
        po.po_id,
        po.supplier_id,

        CAST(s.reliability_factor AS FLOAT)
            AS Reliability_Factor,

        CAST(po.supplier_delay_days AS FLOAT)
            AS Supplier_Delay_Days

    FROM raw.Purchase_Orders AS po

    INNER JOIN raw.Suppliers AS s
        ON po.supplier_id = s.supplier_id

    WHERE po.actual_receipt_date IS NOT NULL
      AND po.supplier_delay_days IS NOT NULL
)

SELECT
    COUNT(*) AS Evaluated_POs,

    CAST(
        (
            AVG(Reliability_Factor * Supplier_Delay_Days)
            - AVG(Reliability_Factor) * AVG(Supplier_Delay_Days)
        )
        /
        NULLIF(
            STDEV(Reliability_Factor) *
            STDEV(Supplier_Delay_Days),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_Reliability_SupplierDelay

FROM SupplierDelivery;



-- ============================================================
-- Step 12: Supplier Quality Rating vs Supplier Delivery Delay
-- Received Purchase Orders Only
-- ============================================================

WITH SupplierQualityDelivery AS
(
    SELECT
        po.po_id,
        po.supplier_id,

        CAST(s.quality_rating AS FLOAT)
            AS Quality_Rating,

        CAST(po.supplier_delay_days AS FLOAT)
            AS Supplier_Delay_Days

    FROM raw.Purchase_Orders AS po

    INNER JOIN raw.Suppliers AS s
        ON po.supplier_id = s.supplier_id

    WHERE po.actual_receipt_date IS NOT NULL
      AND po.supplier_delay_days IS NOT NULL
      AND s.quality_rating IS NOT NULL
)

SELECT
    COUNT(*) AS Evaluated_POs,

    CAST(
        (
            AVG(Quality_Rating * Supplier_Delay_Days)
            - AVG(Quality_Rating) * AVG(Supplier_Delay_Days)
        )
        /
        NULLIF(
            STDEV(Quality_Rating) *
            STDEV(Supplier_Delay_Days),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_QualityRating_SupplierDelay

FROM SupplierQualityDelivery;


-- ============================================================
-- Step 13: Contract Lead Time vs Supplier Delivery Delay
-- Received Purchase Orders Only
-- ============================================================

WITH LeadTimeDelay AS
(
    SELECT
        po.po_id,

        CAST(po.contract_lead_time_days AS FLOAT)
            AS Contract_Lead_Time_Days,

        CAST(po.supplier_delay_days AS FLOAT)
            AS Supplier_Delay_Days

    FROM raw.Purchase_Orders AS po

    WHERE po.actual_receipt_date IS NOT NULL
      AND po.supplier_delay_days IS NOT NULL
)

SELECT
    COUNT(*) AS Evaluated_POs,

    CAST(
        (
            AVG(Contract_Lead_Time_Days * Supplier_Delay_Days)
            - AVG(Contract_Lead_Time_Days)
              * AVG(Supplier_Delay_Days)
        )
        /
        NULLIF(
            STDEV(Contract_Lead_Time_Days)
            * STDEV(Supplier_Delay_Days),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_ContractLeadTime_SupplierDelay

FROM LeadTimeDelay;




-- ============================================================
-- Step 14: Supplier Reliability Groups vs Delivery Performance
-- ============================================================

WITH SupplierDelivery AS
(
    SELECT
        po.po_id,
        po.supplier_id,
        s.reliability_factor,
        po.supplier_delay_days,

        CASE
            WHEN s.reliability_factor < 0.70
                THEN 'Below 0.70'

            WHEN s.reliability_factor < 0.80
                THEN '0.70 - 0.79'

            WHEN s.reliability_factor < 0.90
                THEN '0.80 - 0.89'

            ELSE '0.90+'
        END AS Reliability_Group

    FROM raw.Purchase_Orders AS po

    INNER JOIN raw.Suppliers AS s
        ON po.supplier_id = s.supplier_id

    WHERE po.actual_receipt_date IS NOT NULL
      AND po.supplier_delay_days IS NOT NULL
)

SELECT
    Reliability_Group,

    COUNT(DISTINCT supplier_id) AS Suppliers,

    COUNT(*) AS Evaluated_POs,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN supplier_delay_days <= 0
                THEN 1 ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN supplier_delay_days > 0
                THEN 1 ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Delay_Rate_Pct,

    CAST(
        AVG(1.0 * supplier_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days

FROM SupplierDelivery

GROUP BY Reliability_Group

ORDER BY
    CASE Reliability_Group
        WHEN 'Below 0.70' THEN 1
        WHEN '0.70 - 0.79' THEN 2
        WHEN '0.80 - 0.89' THEN 3
        WHEN '0.90+' THEN 4
    END;



-- ============================================================
-- Step 15: Supplier Delay vs Current Inventory Position
-- Supplier → Product → Inventory Relationship
-- ============================================================

WITH SupplierPerformance AS
(
    SELECT
        supplier_id,

        AVG(
            CAST(supplier_delay_days AS FLOAT)
        ) AS Avg_Supplier_Delay_Days

    FROM raw.Purchase_Orders

    WHERE actual_receipt_date IS NOT NULL
      AND supplier_delay_days IS NOT NULL

    GROUP BY supplier_id
),

SupplierInventory AS
(
    SELECT
        p.supplier_id,

        SUM(i.available_qty) AS Available_Qty,

        AVG(
            CAST(i.available_qty AS FLOAT)
            / NULLIF(CAST(i.avg_daily_demand AS FLOAT), 0)
        ) AS Avg_Inventory_DOH

    FROM raw.Products AS p

    INNER JOIN raw.Inventory AS i
        ON p.product_id = i.product_id

    GROUP BY p.supplier_id
),

RelationshipBase AS
(
    SELECT
        sp.supplier_id,

        CAST(sp.Avg_Supplier_Delay_Days AS FLOAT)
            AS Avg_Supplier_Delay_Days,

        CAST(si.Available_Qty AS FLOAT)
            AS Available_Qty,

        CAST(si.Avg_Inventory_DOH AS FLOAT)
            AS Avg_Inventory_DOH

    FROM SupplierPerformance AS sp

    INNER JOIN SupplierInventory AS si
        ON sp.supplier_id = si.supplier_id
)

SELECT
    COUNT(*) AS Suppliers,

    CAST(
        (
            AVG(Avg_Supplier_Delay_Days * Available_Qty)
            - AVG(Avg_Supplier_Delay_Days)
              * AVG(Available_Qty)
        )
        /
        NULLIF(
            STDEV(Avg_Supplier_Delay_Days)
            * STDEV(Available_Qty),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_SupplierDelay_AvailableQty,

    CAST(
        (
            AVG(Avg_Supplier_Delay_Days * Avg_Inventory_DOH)
            - AVG(Avg_Supplier_Delay_Days)
              * AVG(Avg_Inventory_DOH)
        )
        /
        NULLIF(
            STDEV(Avg_Supplier_Delay_Days)
            * STDEV(Avg_Inventory_DOH),
            0
        )
        AS DECIMAL(10,4)
    ) AS Corr_SupplierDelay_InventoryDOH

FROM RelationshipBase;


-- ============================================================
-- Step 16: Reorder Requirement vs Inbound PO Coverage
-- Product × Warehouse Level
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

InventoryInbound AS
(
    SELECT
        i.product_id,
        i.warehouse_id,

        i.available_qty,
        i.reorder_point,

        CASE
            WHEN i.available_qty <= i.reorder_point
            THEN 'Y'
            ELSE 'N'
        END AS Reorder_Required_Flag,

        ISNULL(po.Outstanding_PO_Qty, 0)
            AS Outstanding_PO_Qty

    FROM raw.Inventory AS i

    LEFT JOIN InboundPO AS po
        ON i.product_id = po.product_id
       AND i.warehouse_id = po.warehouse_id
)

SELECT
    Reorder_Required_Flag,

    COUNT(*) AS Inventory_Records,

    SUM(
        CASE
            WHEN Outstanding_PO_Qty > 0
            THEN 1 ELSE 0
        END
    ) AS Records_With_Inbound_PO,

    SUM(
        CASE
            WHEN Outstanding_PO_Qty = 0
            THEN 1 ELSE 0
        END
    ) AS Records_Without_Inbound_PO,

    CAST(
        100.0 *
        SUM(CASE WHEN Outstanding_PO_Qty > 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Inbound_PO_Coverage_Pct,

    SUM(Outstanding_PO_Qty)
        AS Outstanding_PO_Qty

FROM InventoryInbound

GROUP BY Reorder_Required_Flag

ORDER BY
    CASE Reorder_Required_Flag
        WHEN 'Y' THEN 1
        ELSE 2
    END;




-- ============================================================
-- Step 17: Cross-Functional Warehouse Performance
-- Inventory + Fulfillment + Delivery
-- ============================================================

WITH InventorySummary AS
(
    SELECT
        warehouse_id,

        COUNT(*) AS Inventory_Records,

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
        ) AS Stockout_Records

    FROM raw.Inventory

    GROUP BY warehouse_id
),

FulfillmentSummary AS
(
    SELECT
        warehouse_id,

        SUM(ordered_qty) AS Ordered_Qty,
        SUM(fulfilled_qty) AS Fulfilled_Qty,
        SUM(backlog_qty) AS Backlog_Qty,

        SUM(backlog_value) AS Backlog_Value

    FROM raw.Sales_Orders

    GROUP BY warehouse_id
),

DeliverySummary AS
(
    SELECT
        warehouse_id,

        COUNT(*) AS Valid_Shipments,

        SUM(
            CASE
                WHEN on_time_flag = 1
                THEN 1 ELSE 0
            END
        ) AS On_Time_Shipments,

        SUM(
            CASE
                WHEN otif_flag = 1
                THEN 1 ELSE 0
            END
        ) AS OTIF_Shipments

    FROM raw.Shipments

    WHERE actual_delivery_date >= shipment_date

    GROUP BY warehouse_id
)

SELECT
    w.warehouse_id,
    w.warehouse_name,

    CAST(
        100.0 * i.Reorder_Required_Records
        / NULLIF(i.Inventory_Records, 0)
        AS DECIMAL(8,2)
    ) AS Reorder_Required_Rate_Pct,

    i.Stockout_Records,

    CAST(
        100.0 * f.Fulfilled_Qty
        / NULLIF(f.Ordered_Qty, 0)
        AS DECIMAL(8,2)
    ) AS Fill_Rate_Pct,

    CAST(
        100.0 * f.Backlog_Qty
        / NULLIF(f.Ordered_Qty, 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Rate_Pct,

    CAST(
        f.Backlog_Value
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * d.On_Time_Shipments
        / NULLIF(d.Valid_Shipments, 0)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    CAST(
        100.0 * d.OTIF_Shipments
        / NULLIF(d.Valid_Shipments, 0)
        AS DECIMAL(8,2)
    ) AS OTIF_Rate_Pct

FROM raw.Warehouses AS w

INNER JOIN InventorySummary AS i
    ON w.warehouse_id = i.warehouse_id

INNER JOIN FulfillmentSummary AS f
    ON w.warehouse_id = f.warehouse_id

INNER JOIN DeliverySummary AS d
    ON w.warehouse_id = d.warehouse_id

ORDER BY Reorder_Required_Rate_Pct DESC;




-- ============================================================
-- Step 18: Cross-Functional Category Performance
-- Inventory + Sales + Fulfillment + Backlog
-- ============================================================

WITH InventoryCategory AS
(
    SELECT
        p.category,

        COUNT(*) AS Inventory_Records,

        SUM(
            CASE
                WHEN i.available_qty <= i.reorder_point
                THEN 1 ELSE 0
            END
        ) AS Reorder_Required_Records,

        SUM(
            CASE
                WHEN i.available_qty = 0
                THEN 1 ELSE 0
            END
        ) AS Stockout_Records,

        SUM(i.inventory_value) AS Inventory_Value

    FROM raw.Inventory AS i

    INNER JOIN raw.Products AS p
        ON i.product_id = p.product_id

    GROUP BY p.category
),

FulfillmentCategory AS
(
    SELECT
        p.category,

        SUM(soi.net_order_value) AS Sales_Value,

        SUM(soi.ordered_qty) AS Ordered_Qty,

        SUM(soi.fulfilled_qty) AS Fulfilled_Qty,

        SUM(soi.backlog_qty) AS Backlog_Qty,

        SUM(soi.backlog_value) AS Backlog_Value

    FROM raw.Sales_Order_Items AS soi

    INNER JOIN raw.Products AS p
        ON soi.product_id = p.product_id

    GROUP BY p.category
)

SELECT
    i.category,

    CAST(
        f.Sales_Value
        AS DECIMAL(18,2)
    ) AS Sales_Value,

    CAST(
        100.0 * f.Sales_Value
        / SUM(f.Sales_Value) OVER ()
        AS DECIMAL(8,2)
    ) AS Sales_Value_Share_Pct,

    CAST(
        100.0 * f.Fulfilled_Qty
        / NULLIF(f.Ordered_Qty, 0)
        AS DECIMAL(8,2)
    ) AS Fill_Rate_Pct,

    CAST(
        100.0 * f.Backlog_Qty
        / NULLIF(f.Ordered_Qty, 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Rate_Pct,

    CAST(
        f.Backlog_Value
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * f.Backlog_Value
        / SUM(f.Backlog_Value) OVER ()
        AS DECIMAL(8,2)
    ) AS Backlog_Value_Share_Pct,

    CAST(
        i.Inventory_Value
        AS DECIMAL(18,2)
    ) AS Inventory_Value,

    CAST(
        100.0 * i.Reorder_Required_Records
        / NULLIF(i.Inventory_Records, 0)
        AS DECIMAL(8,2)
    ) AS Reorder_Required_Rate_Pct,

    i.Stockout_Records

FROM InventoryCategory AS i

INNER JOIN FulfillmentCategory AS f
    ON i.category = f.category

ORDER BY Backlog_Value DESC;




-- ============================================================
-- Step 19: Overall Cross-Functional Correlation Matrix
-- Product × Warehouse Level
-- ============================================================

WITH FulfillmentPW AS
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

    GROUP BY
        product_id,
        warehouse_id
),

RelationshipBase AS
(
    SELECT
        i.product_id,
        i.warehouse_id,

        CAST(i.available_qty AS FLOAT) AS Available_Qty,
        CAST(i.avg_daily_demand AS FLOAT) AS Avg_Daily_Demand,

        CAST(
            i.available_qty * 1.0
            / NULLIF(i.avg_daily_demand, 0)
            AS FLOAT
        ) AS Inventory_DOH,

        CAST(ISNULL(f.Ordered_Qty, 0) AS FLOAT) AS Ordered_Qty,
        CAST(ISNULL(f.Fulfilled_Qty, 0) AS FLOAT) AS Fulfilled_Qty,
        CAST(ISNULL(f.Backlog_Qty, 0) AS FLOAT) AS Backlog_Qty,
        CAST(ISNULL(f.Sales_Value, 0) AS FLOAT) AS Sales_Value,
        CAST(ISNULL(f.Backlog_Value, 0) AS FLOAT) AS Backlog_Value,

        CAST(
            100.0 * ISNULL(f.Fulfilled_Qty, 0)
            / NULLIF(ISNULL(f.Ordered_Qty, 0), 0)
            AS FLOAT
        ) AS Fill_Rate_Pct,

        CAST(
            100.0 * ISNULL(f.Backlog_Qty, 0)
            / NULLIF(ISNULL(f.Ordered_Qty, 0), 0)
            AS FLOAT
        ) AS Backlog_Rate_Pct

    FROM raw.Inventory AS i

    LEFT JOIN FulfillmentPW AS f
        ON i.product_id = f.product_id
       AND i.warehouse_id = f.warehouse_id
),

Unpivoted AS
(
    SELECT
        product_id,
        warehouse_id,
        Metric,
        Metric_Value

    FROM RelationshipBase

    CROSS APPLY
    (
        VALUES
            ('Available_Qty', Available_Qty),
            ('Avg_Daily_Demand', Avg_Daily_Demand),
            ('Inventory_DOH', Inventory_DOH),
            ('Ordered_Qty', Ordered_Qty),
            ('Fulfilled_Qty', Fulfilled_Qty),
            ('Backlog_Qty', Backlog_Qty),
            ('Sales_Value', Sales_Value),
            ('Backlog_Value', Backlog_Value),
            ('Fill_Rate_Pct', Fill_Rate_Pct),
            ('Backlog_Rate_Pct', Backlog_Rate_Pct)
    ) AS M(Metric, Metric_Value)

    WHERE Metric_Value IS NOT NULL
),

MetricPairs AS
(
    SELECT
        a.Metric AS Metric_1,
        b.Metric AS Metric_2,

        a.Metric_Value AS X,
        b.Metric_Value AS Y

    FROM Unpivoted AS a

    INNER JOIN Unpivoted AS b
        ON a.product_id = b.product_id
       AND a.warehouse_id = b.warehouse_id
)

SELECT
    Metric_1,
    Metric_2,

    CAST(
        (
            AVG(X * Y)
            - AVG(X) * AVG(Y)
        )
        /
        NULLIF(
            STDEV(X) * STDEV(Y),
            0
        )
        AS DECIMAL(10,4)
    ) AS Correlation

FROM MetricPairs

GROUP BY
    Metric_1,
    Metric_2

ORDER BY
    Metric_1,
    Metric_2;




-- ============================================================
-- Step 20: Key Cross-Functional Relationship Summary
-- ============================================================

SELECT *
FROM
(
    VALUES

    ('Demand vs Backlog Quantity',
     CAST(0.7755 AS DECIMAL(10,4)),
     'Strong Positive',
     'Higher-demand product-warehouse combinations carry substantially more backlog.'),

    ('Available Inventory vs Backlog Quantity',
     CAST(0.5308 AS DECIMAL(10,4)),
     'Moderate Positive',
     'Likely reflects product scale and demand concentration; current inventory should not be interpreted as causing backlog.'),

    ('Available Inventory vs Backlog Rate',
     CAST(0.2361 AS DECIMAL(10,4)),
     'Weak Positive',
     'Current available inventory has only a weak relationship with relative backlog exposure.'),

    ('Inventory DOH vs Backlog Rate',
     CAST(-0.0010 AS DECIMAL(10,4)),
     'Negligible',
     'Current inventory coverage shows virtually no linear relationship with historical backlog rate.'),

    ('Sales Value vs Backlog Value',
     CAST(0.9199 AS DECIMAL(10,4)),
     'Very Strong Positive',
     'Commercially larger products carry substantially greater absolute backlog value exposure.'),

    ('Sales Value vs Backlog Rate',
     CAST(0.4118 AS DECIMAL(10,4)),
     'Moderate Positive',
     'Higher-value products also tend to experience somewhat higher relative backlog rates.'),

    ('Fill Rate vs Delivery Delay',
     CAST(-0.1904 AS DECIMAL(10,4)),
     'Weak Negative',
     'Higher fulfillment is associated with somewhat lower delivery delay.'),

    ('Backlog Percentage vs Delivery Delay',
     CAST(0.1904 AS DECIMAL(10,4)),
     'Weak Positive',
     'Higher backlog percentage is associated with somewhat greater delivery delay.'),

    ('Supplier Reliability vs Supplier Delay',
     CAST(-0.2320 AS DECIMAL(10,4)),
     'Weak-Moderate Negative',
     'Higher supplier reliability is associated with lower supplier delay.'),

    ('Supplier Quality vs Supplier Delay',
     CAST(0.0005 AS DECIMAL(10,4)),
     'Negligible',
     'Quality rating provides almost no linear explanation of supplier delivery delay.'),

    ('Contract Lead Time vs Supplier Delay',
     CAST(0.0119 AS DECIMAL(10,4)),
     'Negligible',
     'Longer contractual lead times are not materially associated with lateness.'),

    ('Supplier Delay vs Available Inventory',
     CAST(0.0736 AS DECIMAL(10,4)),
     'Negligible',
     'Historical supplier delay alone does not explain current available inventory.'),

    ('Supplier Delay vs Inventory DOH',
     CAST(0.0753 AS DECIMAL(10,4)),
     'Negligible',
     'Historical supplier delay alone does not explain current inventory coverage.')

) AS RelationshipSummary
(
    Relationship,
    Correlation,
    Relationship_Strength,
    Business_Interpretation
)

ORDER BY ABS(Correlation) DESC;


-- ============================================================
-- Step 21: Consolidated Relationship Findings
-- ============================================================

SELECT *
FROM
(
    VALUES

    (1,
     'Demand Concentration',
     'Q4 highest-demand product-warehouse combinations carry the majority of backlog.',
     'High-demand items should receive stronger forecasting, allocation and replenishment controls.'),

    (2,
     'Demand vs Backlog',
     'Demand and backlog quantity have a strong positive correlation of 0.7755.',
     'Backlog reduction should focus first on high-demand product-location combinations.'),

    (3,
     'Commercial Value vs Backlog',
     'Sales value and backlog value have a very strong positive correlation of 0.9199.',
     'High-value products require protected availability and backlog monitoring.'),

    (4,
     'High-Value Product Risk',
     'Highest-sales-value products generate 56.66% of sales but 68.01% of backlog value.',
     'Commercially important SKUs should receive differentiated service controls.'),

    (5,
     'Current Inventory vs Historical Backlog',
     'Inventory DOH and backlog rate have virtually no linear relationship (-0.0010).',
     'Current inventory snapshots should not be treated as the direct cause of historical backlog.'),

    (6,
     'Fulfillment vs Delivery',
     'Fully fulfilled orders achieve 83.05% on-time delivery versus roughly 56-58% for partially fulfilled orders.',
     'Improving fulfillment completeness is strongly associated with better delivery outcomes.'),

    (7,
     'Backlog vs Delivery',
     'Backlog percentage and delivery delay have a weak positive correlation of 0.1904.',
     'Backlog presence matters operationally, but backlog severity alone does not fully explain delivery delay.'),

    (8,
     'Supplier Reliability',
     'Supplier reliability and supplier delay have a negative correlation of -0.2320.',
     'Reliability factor should remain an important supplier monitoring indicator.'),

    (9,
     'High-Reliability Suppliers',
     'Suppliers with reliability of 0.90+ achieve 71.44% on-time performance and only 0.09 average delay days.',
     'Supplier allocation and sourcing decisions should consider demonstrated reliability.'),

    (10,
     'Supplier Quality Rating',
     'Quality rating has almost zero correlation with supplier delay (0.0005).',
     'Quality and delivery reliability should be managed as separate supplier dimensions.'),

    (11,
     'Supplier Delay vs Inventory',
     'Historical supplier delay has negligible relationships with current available inventory and inventory DOH.',
     'Current inventory position is influenced by broader demand, replenishment and allocation factors.'),

    (12,
     'Inbound Replenishment Coverage',
     'Of 1,311 reorder-required records, 1,080 have inbound POs while 231 have no inbound PO.',
     'Procurement review should prioritize reorder-required locations without inbound supply.'),

    (13,
     'Warehouse Risk',
     'Pune DC combines the highest reorder-required rate with relatively weak fulfillment and delivery performance.',
     'Pune DC should receive cross-functional inventory and fulfillment review.'),

    (14,
     'Category Commercial Exposure',
     'Electronics contributes the largest sales and backlog value exposure.',
     'Electronics availability and backlog should receive enhanced commercial monitoring.'),

    (15,
     'Category Fulfillment Risk',
     'Automotive has the lowest fill rate and highest backlog rate among categories.',
     'Automotive requires focused demand-planning and replenishment review.')

) AS Findings
(
    Finding_No,
    Relationship_Area,
    Analytical_Finding,
    Business_Implication
)

ORDER BY Finding_No;




-- ============================================================
-- Step 22: Relationship Analysis Reconciliation
-- ============================================================

DECLARE @RelationshipChecks TABLE
(
    Validation_Check VARCHAR(160),
    Status VARCHAR(10)
);

INSERT INTO @RelationshipChecks
VALUES

('Total Products',
 CASE WHEN (SELECT COUNT(*) FROM raw.Products) = 500
      THEN 'PASS' ELSE 'FAIL' END),

('Total Warehouses',
 CASE WHEN (SELECT COUNT(*) FROM raw.Warehouses) = 6
      THEN 'PASS' ELSE 'FAIL' END),

('Inventory Records',
 CASE WHEN (SELECT COUNT(*) FROM raw.Inventory) = 3000
      THEN 'PASS' ELSE 'FAIL' END),

('Sales Orders',
 CASE WHEN (SELECT COUNT(*) FROM raw.Sales_Orders) = 25000
      THEN 'PASS' ELSE 'FAIL' END),

('Sales Order Items',
 CASE WHEN (SELECT COUNT(*) FROM raw.Sales_Order_Items) = 61397
      THEN 'PASS' ELSE 'FAIL' END),

('Clean Inventory Transactions',
 CASE WHEN (SELECT COUNT(*) FROM raw.Inventory_Transactions) = 110000
      THEN 'PASS' ELSE 'FAIL' END),

('Shipments',
 CASE WHEN (SELECT COUNT(*) FROM raw.Shipments) = 24798
      THEN 'PASS' ELSE 'FAIL' END),

('Purchase Orders',
 CASE WHEN (SELECT COUNT(*) FROM raw.Purchase_Orders) = 8500
      THEN 'PASS' ELSE 'FAIL' END),

('Suppliers',
 CASE WHEN (SELECT COUNT(*) FROM raw.Suppliers) = 100
      THEN 'PASS' ELSE 'FAIL' END),

('Expected Product-Warehouse Inventory Matrix',
 CASE WHEN
      (SELECT COUNT(*) FROM raw.Inventory) =
      (SELECT COUNT(*) FROM raw.Products) *
      (SELECT COUNT(*) FROM raw.Warehouses)
      THEN 'PASS' ELSE 'FAIL' END),

('Total Ordered Quantity',
 CASE WHEN
      (SELECT SUM(ordered_qty)
       FROM raw.Sales_Orders) = 501755
      THEN 'PASS' ELSE 'FAIL' END),

('Total Fulfilled Quantity',
 CASE WHEN
      (SELECT SUM(fulfilled_qty)
       FROM raw.Sales_Orders) = 440576
      THEN 'PASS' ELSE 'FAIL' END),

('Total Backlog Quantity',
 CASE WHEN
      (SELECT SUM(backlog_qty)
       FROM raw.Sales_Orders) = 61179
      THEN 'PASS' ELSE 'FAIL' END),

('Fulfillment Quantity Reconciles',
 CASE WHEN
      (SELECT SUM(ordered_qty)
       FROM raw.Sales_Orders) =
      (SELECT SUM(fulfilled_qty + backlog_qty)
       FROM raw.Sales_Orders)
      THEN 'PASS' ELSE 'FAIL' END),

('Valid Shipment Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Shipments
          WHERE actual_delivery_date >= shipment_date
      ) = 20331
      THEN 'PASS' ELSE 'FAIL' END),

('Invalid Shipment Chronology Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Shipments
          WHERE actual_delivery_date < shipment_date
      ) = 4467
      THEN 'PASS' ELSE 'FAIL' END),

('Evaluated Purchase Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Purchase_Orders
          WHERE actual_receipt_date IS NOT NULL
            AND supplier_delay_days IS NOT NULL
      ) = 8470
      THEN 'PASS' ELSE 'FAIL' END),

('Reorder Required Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Inventory
          WHERE available_qty <= reorder_point
      ) = 1311
      THEN 'PASS' ELSE 'FAIL' END),

('Reorder Records With Inbound PO',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Inventory i
          WHERE i.available_qty <= i.reorder_point
            AND EXISTS
            (
                SELECT 1
                FROM raw.Purchase_Orders po
                WHERE po.product_id = i.product_id
                  AND po.warehouse_id = i.warehouse_id
                  AND po.ordered_qty > po.received_qty
            )
      ) = 1080
      THEN 'PASS' ELSE 'FAIL' END),

('Reorder Records Without Inbound PO',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Inventory i
          WHERE i.available_qty <= i.reorder_point
            AND NOT EXISTS
            (
                SELECT 1
                FROM raw.Purchase_Orders po
                WHERE po.product_id = i.product_id
                  AND po.warehouse_id = i.warehouse_id
                  AND po.ordered_qty > po.received_qty
            )
      ) = 231
      THEN 'PASS' ELSE 'FAIL' END);

SELECT *
FROM @RelationshipChecks;

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
    END AS Relationship_Reconciliation_Status

FROM @RelationshipChecks;

-- ============================================================
-- Step 23: Final Business Insights
-- Relationship Analysis
-- ============================================================

/*
1. DEMAND IS A MAJOR BACKLOG DRIVER
   - Demand and backlog quantity show a strong positive
     correlation of 0.7755.
   - The highest-demand product-warehouse group accounts for
     67.74% of backlog quantity and 67.33% of backlog value.
   - Its backlog rate reaches 17.80%, compared with only
     6.78% for the lowest-demand group.
   - High-demand SKU-location combinations should therefore
     receive stronger forecasting and replenishment attention.

2. COMMERCIAL VALUE IS HIGHLY CONCENTRATED IN BACKLOG
   - Sales value and backlog value have a very strong positive
     correlation of 0.9199.
   - The highest-sales-value quartile generates 56.66% of sales
     but carries 68.01% of total backlog value.
   - Its backlog rate is also highest at 15.21%.
   - Backlog management should therefore prioritize commercially
     important products rather than treating all SKUs equally.

3. CURRENT INVENTORY DOES NOT EXPLAIN HISTORICAL BACKLOG ALONE
   - Available quantity and backlog quantity show a moderate
     positive correlation of 0.5308.
   - This should not be interpreted as inventory causing backlog.
   - High-demand products naturally tend to carry both higher
     inventory and higher absolute backlog.
   - Inventory Days on Hand vs backlog rate is approximately
     -0.0010, indicating virtually no linear relationship.
   - Current inventory is a snapshot, whereas backlog reflects
     historical order activity.

4. FULFILLMENT COMPLETENESS IS ASSOCIATED WITH DELIVERY QUALITY
   - Fill rate and delivery delay have a weak negative correlation
     of -0.1904.
   - Fully fulfilled orders achieve 83.05% on-time delivery and
     83.05% OTIF with only 0.15 average delay days.
   - Partially fulfilled orders achieve only approximately
     56-58% on-time delivery and have zero OTIF by definition.
   - Improving fulfillment completeness should therefore support
     stronger customer service performance.

5. BACKLOG PRESENCE MATTERS MORE THAN BACKLOG SEVERITY
   - Backlog percentage and delivery delay show only a weak
     positive correlation of 0.1904.
   - Orders without backlog achieve 83.05% on-time delivery.
   - Backlogged groups achieve only approximately 56-58%.
   - However, delivery performance does not deteriorate
     consistently as backlog percentage increases.
   - Operational focus should therefore include preventing backlog
     occurrence, not only managing severe backlog.

6. SUPPLIER RELIABILITY IS MORE INFORMATIVE THAN QUALITY RATING
   - Supplier reliability and supplier delay show a negative
     correlation of -0.2320.
   - Suppliers below 0.70 reliability achieve only 49.17%
     on-time performance with 2.92 average delay days.
   - Suppliers with reliability of 0.90+ achieve 71.44% on-time
     performance with only 0.09 average delay days.
   - Reliability factor should remain an important supplier
     performance and sourcing indicator.

7. QUALITY AND DELIVERY RELIABILITY ARE DIFFERENT DIMENSIONS
   - Supplier quality rating vs supplier delay correlation is
     only 0.0005.
   - Contract lead time vs supplier delay correlation is 0.0119.
   - Neither measure materially explains supplier lateness.
   - Supplier scorecards should therefore measure quality,
     reliability and delivery performance separately.

8. SUPPLIER DELAY DOES NOT DIRECTLY EXPLAIN CURRENT INVENTORY
   - Supplier delay vs available inventory correlation is 0.0736.
   - Supplier delay vs inventory DOH correlation is 0.0753.
   - Both relationships are negligible.
   - Current inventory position is influenced by broader demand,
     replenishment, purchasing and allocation decisions.

9. REPLENISHMENT COVERAGE REQUIRES TARGETED REVIEW
   - 1,311 product-warehouse records require reorder.
   - 1,080 of these records already have inbound purchase orders.
   - 231 reorder-required records have no inbound PO coverage.
   - These 231 records should receive immediate procurement review.
   - Inbound PO presence alone should not be interpreted as
     sufficient shortage coverage.

10. PUNE DC IS A CROSS-FUNCTIONAL PRESSURE POINT
    - Pune DC has the highest reorder-required rate at 48.20%.
    - Its fill rate is 87.12% and backlog rate is 12.88%.
    - It also has the lowest valid on-time rate at 70.54%.
    - This combination supports a cross-functional inventory,
      fulfillment and logistics review.

11. WAREHOUSE RISKS DIFFER BY DIMENSION
    - Bengaluru Central carries the largest absolute backlog value
      at approximately 54.70M.
    - Hyderabad South has the most stockout records at 50.
    - Warehouse management should therefore use multiple KPIs
      instead of ranking facilities using a single metric.

12. ELECTRONICS HAS THE LARGEST COMMERCIAL EXPOSURE
    - Electronics contributes 28.74% of sales value.
    - It also carries 28.14% of total backlog value.
    - Electronics availability and backlog should therefore receive
      enhanced commercial monitoring.

13. AUTOMOTIVE HAS THE WEAKEST CATEGORY FULFILLMENT
    - Automotive has the lowest category fill rate at 86.63%.
    - It also has the highest backlog rate at 13.37%.
    - Automotive should receive focused demand-planning,
      allocation and replenishment review.

14. RELATIONSHIPS MUST BE INTERPRETED CAREFULLY
    - Correlation identifies association, not causation.
    - Some strong relationships are mechanically influenced by
      scale, such as ordered quantity and fulfilled quantity.
    - Current inventory measures and historical order outcomes
      also represent different points in time.
    - Business decisions should combine relationship analysis
      with operational context.

15. MANAGEMENT PRIORITY
    - Prioritize high-demand and high-value products.
    - Improve complete-order fulfillment before shipment.
    - Protect high-reliability supplier capacity.
    - Review reorder-required inventory without inbound supply.
    - Investigate Pune DC as a multi-KPI pressure point.
    - Monitor Electronics for commercial exposure and Automotive
      for fulfillment weakness.
*/


-- ============================================================
-- Step 24: Final Relationship Analysis Validation
-- ============================================================

DECLARE @FinalRelationshipValidation TABLE
(
    Validation_Check VARCHAR(170),
    Status VARCHAR(10)
);

INSERT INTO @FinalRelationshipValidation
VALUES

('Total Products',
 CASE WHEN (SELECT COUNT(*) FROM raw.Products) = 500
      THEN 'PASS' ELSE 'FAIL' END),

('Total Warehouses',
 CASE WHEN (SELECT COUNT(*) FROM raw.Warehouses) = 6
      THEN 'PASS' ELSE 'FAIL' END),

('Inventory Records',
 CASE WHEN (SELECT COUNT(*) FROM raw.Inventory) = 3000
      THEN 'PASS' ELSE 'FAIL' END),

('Expected Product-Warehouse Matrix',
 CASE WHEN
      (SELECT COUNT(*) FROM raw.Inventory) =
      (SELECT COUNT(*) FROM raw.Products) *
      (SELECT COUNT(*) FROM raw.Warehouses)
      THEN 'PASS' ELSE 'FAIL' END),

('Sales Orders',
 CASE WHEN (SELECT COUNT(*) FROM raw.Sales_Orders) = 25000
      THEN 'PASS' ELSE 'FAIL' END),

('Sales Order Items',
 CASE WHEN (SELECT COUNT(*) FROM raw.Sales_Order_Items) = 61397
      THEN 'PASS' ELSE 'FAIL' END),

('Clean Inventory Transactions',
 CASE WHEN (SELECT COUNT(*) FROM raw.Inventory_Transactions) = 110000
      THEN 'PASS' ELSE 'FAIL' END),

('Shipments',
 CASE WHEN (SELECT COUNT(*) FROM raw.Shipments) = 24798
      THEN 'PASS' ELSE 'FAIL' END),

('Purchase Orders',
 CASE WHEN (SELECT COUNT(*) FROM raw.Purchase_Orders) = 8500
      THEN 'PASS' ELSE 'FAIL' END),

('Suppliers',
 CASE WHEN (SELECT COUNT(*) FROM raw.Suppliers) = 100
      THEN 'PASS' ELSE 'FAIL' END),

('Ordered Quantity',
 CASE WHEN
      (SELECT SUM(ordered_qty) FROM raw.Sales_Orders) = 501755
      THEN 'PASS' ELSE 'FAIL' END),

('Fulfilled Quantity',
 CASE WHEN
      (SELECT SUM(fulfilled_qty) FROM raw.Sales_Orders) = 440576
      THEN 'PASS' ELSE 'FAIL' END),

('Backlog Quantity',
 CASE WHEN
      (SELECT SUM(backlog_qty) FROM raw.Sales_Orders) = 61179
      THEN 'PASS' ELSE 'FAIL' END),

('Fulfillment Quantity Reconciles',
 CASE WHEN
      (SELECT SUM(ordered_qty) FROM raw.Sales_Orders) =
      (SELECT SUM(fulfilled_qty + backlog_qty)
       FROM raw.Sales_Orders)
      THEN 'PASS' ELSE 'FAIL' END),

('Valid Shipment Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Shipments
          WHERE actual_delivery_date >= shipment_date
      ) = 20331
      THEN 'PASS' ELSE 'FAIL' END),

('Invalid Shipment Chronology Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Shipments
          WHERE actual_delivery_date < shipment_date
      ) = 4467
      THEN 'PASS' ELSE 'FAIL' END),

('Evaluated Purchase Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Purchase_Orders
          WHERE actual_receipt_date IS NOT NULL
            AND supplier_delay_days IS NOT NULL
      ) = 8470
      THEN 'PASS' ELSE 'FAIL' END),

('Reorder Required Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Inventory
          WHERE available_qty <= reorder_point
      ) = 1311
      THEN 'PASS' ELSE 'FAIL' END),

('Reorder Records With Inbound PO',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Inventory AS i
          WHERE i.available_qty <= i.reorder_point
            AND EXISTS
            (
                SELECT 1
                FROM raw.Purchase_Orders AS po
                WHERE po.product_id = i.product_id
                  AND po.warehouse_id = i.warehouse_id
                  AND po.ordered_qty > po.received_qty
            )
      ) = 1080
      THEN 'PASS' ELSE 'FAIL' END),

('Reorder Records Without Inbound PO',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Inventory AS i
          WHERE i.available_qty <= i.reorder_point
            AND NOT EXISTS
            (
                SELECT 1
                FROM raw.Purchase_Orders AS po
                WHERE po.product_id = i.product_id
                  AND po.warehouse_id = i.warehouse_id
                  AND po.ordered_qty > po.received_qty
            )
      ) = 231
      THEN 'PASS' ELSE 'FAIL' END),

('Inventory Product Foreign Keys Valid',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Inventory AS i
          LEFT JOIN raw.Products AS p
              ON i.product_id = p.product_id
          WHERE p.product_id IS NULL
      )
      THEN 'PASS' ELSE 'FAIL' END),

('Inventory Warehouse Foreign Keys Valid',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Inventory AS i
          LEFT JOIN raw.Warehouses AS w
              ON i.warehouse_id = w.warehouse_id
          WHERE w.warehouse_id IS NULL
      )
      THEN 'PASS' ELSE 'FAIL' END),

('Sales Item Product Foreign Keys Valid',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Sales_Order_Items AS soi
          LEFT JOIN raw.Products AS p
              ON soi.product_id = p.product_id
          WHERE p.product_id IS NULL
      )
      THEN 'PASS' ELSE 'FAIL' END),

('Shipment Order Foreign Keys Valid',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Shipments AS s
          LEFT JOIN raw.Sales_Orders AS so
              ON s.order_id = so.order_id
          WHERE so.order_id IS NULL
      )
      THEN 'PASS' ELSE 'FAIL' END);

SELECT *
FROM @FinalRelationshipValidation;

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
    END AS Final_Relationship_Analysis_Status

FROM @FinalRelationshipValidation;