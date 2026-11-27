-- ============================================================
-- SALES ORDER, BACKLOG & INVENTORY ANALYTICS
-- File: 09_Order_Fulfillment_Analysis.sql
-- Purpose: Order Fulfillment Analysis
-- ============================================================

USE Sales_Order_Backlog_Inventory_Analytics;
GO

-- ============================================================
-- Step 1: Order Fulfillment Baseline
-- ============================================================

SELECT
    COUNT(*) AS Total_Orders,

    COUNT(DISTINCT order_id) AS Unique_Orders,

    COUNT(DISTINCT customer_id) AS Unique_Customers,

    SUM(ordered_qty) AS Total_Ordered_Qty,

    SUM(fulfilled_qty) AS Total_Fulfilled_Qty,

    SUM(backlog_qty) AS Total_Backlog_Qty,

    CAST(
        100.0 * SUM(fulfilled_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Overall_Quantity_Fill_Rate_Pct,

    SUM(
        CASE
            WHEN backlog_qty = 0
             AND fulfilled_qty = ordered_qty
            THEN 1 ELSE 0
        END
    ) AS Fully_Fulfilled_Orders,

    SUM(
        CASE
            WHEN backlog_qty > 0
            THEN 1 ELSE 0
        END
    ) AS Orders_With_Backlog,

    CAST(
        AVG(1.0 * order_fill_rate_pct)
        AS DECIMAL(8,2)
    ) AS Avg_Order_Fill_Rate_Pct

FROM raw.Sales_Orders;


-- ============================================================
-- Step 2: Fulfillment Status Distribution
-- ============================================================

SELECT
    CASE
        WHEN backlog_qty = 0
         AND fulfilled_qty = ordered_qty
            THEN 'Fully Fulfilled'

        WHEN backlog_qty > 0
            THEN 'Backlogged'

        ELSE 'Other'
    END AS Fulfillment_Status,

    COUNT(*) AS Total_Orders,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(fulfilled_qty) AS Fulfilled_Qty,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Order_Share_Pct,

    CAST(
        100.0 * SUM(fulfilled_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Quantity_Fill_Rate_Pct

FROM raw.Sales_Orders

GROUP BY
    CASE
        WHEN backlog_qty = 0
         AND fulfilled_qty = ordered_qty
            THEN 'Fully Fulfilled'

        WHEN backlog_qty > 0
            THEN 'Backlogged'

        ELSE 'Other'
    END

ORDER BY Total_Orders DESC;



-- ============================================================
-- Step 3: Fulfillment Performance by Order Priority
-- ============================================================

SELECT
    priority,

    COUNT(*) AS Total_Orders,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(fulfilled_qty) AS Fulfilled_Qty,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(fulfilled_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Quantity_Fill_Rate_Pct,

    CAST(
        100.0 * SUM(backlog_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Rate_Pct,

    SUM(
        CASE
            WHEN backlog_qty > 0
            THEN 1 ELSE 0
        END
    ) AS Backlogged_Orders,

    CAST(
        100.0 *
        SUM(CASE WHEN backlog_qty > 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Backlogged_Order_Rate_Pct

FROM raw.Sales_Orders

GROUP BY priority

ORDER BY
    CASE priority
        WHEN 'Urgent' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Normal' THEN 3
        WHEN 'Low' THEN 4
        ELSE 5
    END;




-- ============================================================
-- Step 4: Fulfillment Performance by Sales Channel
-- ============================================================

SELECT
    sales_channel,

    COUNT(*) AS Total_Orders,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(fulfilled_qty) AS Fulfilled_Qty,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(fulfilled_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Quantity_Fill_Rate_Pct,

    CAST(
        100.0 * SUM(backlog_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Rate_Pct,

    SUM(
        CASE
            WHEN backlog_qty > 0
            THEN 1 ELSE 0
        END
    ) AS Backlogged_Orders,

    CAST(
        100.0 *
        SUM(CASE WHEN backlog_qty > 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Backlogged_Order_Rate_Pct

FROM raw.Sales_Orders

GROUP BY sales_channel

ORDER BY Quantity_Fill_Rate_Pct DESC;



-- ============================================================
-- Step 5: Fulfillment Performance by Customer Segment
-- ============================================================

SELECT
    c.customer_segment,

    COUNT(*) AS Total_Orders,

    COUNT(DISTINCT so.customer_id) AS Customers,

    SUM(so.ordered_qty) AS Ordered_Qty,

    SUM(so.fulfilled_qty) AS Fulfilled_Qty,

    SUM(so.backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(so.fulfilled_qty)
        / NULLIF(SUM(so.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Quantity_Fill_Rate_Pct,

    CAST(
        100.0 * SUM(so.backlog_qty)
        / NULLIF(SUM(so.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Rate_Pct,

    SUM(
        CASE
            WHEN so.backlog_qty > 0
            THEN 1 ELSE 0
        END
    ) AS Backlogged_Orders,

    CAST(
        100.0 *
        SUM(CASE WHEN so.backlog_qty > 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Backlogged_Order_Rate_Pct

FROM raw.Sales_Orders AS so

INNER JOIN raw.Customers AS c
    ON so.customer_id = c.customer_id

GROUP BY c.customer_segment

ORDER BY Quantity_Fill_Rate_Pct DESC;




-- ============================================================
-- Step 6: Fulfillment Performance by Customer Region
-- ============================================================

SELECT
    c.region,

    COUNT(*) AS Total_Orders,

    COUNT(DISTINCT so.customer_id) AS Customers,

    SUM(so.ordered_qty) AS Ordered_Qty,

    SUM(so.fulfilled_qty) AS Fulfilled_Qty,

    SUM(so.backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(so.fulfilled_qty)
        / NULLIF(SUM(so.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Quantity_Fill_Rate_Pct,

    CAST(
        100.0 * SUM(so.backlog_qty)
        / NULLIF(SUM(so.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Rate_Pct,

    SUM(
        CASE
            WHEN so.backlog_qty > 0
            THEN 1 ELSE 0
        END
    ) AS Backlogged_Orders,

    CAST(
        100.0 *
        SUM(CASE WHEN so.backlog_qty > 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Backlogged_Order_Rate_Pct

FROM raw.Sales_Orders AS so

INNER JOIN raw.Customers AS c
    ON so.customer_id = c.customer_id

GROUP BY c.region

ORDER BY Quantity_Fill_Rate_Pct DESC;



-- ============================================================
-- Step 7: Fulfillment Performance by Warehouse
-- ============================================================

SELECT
    so.warehouse_id,
    w.warehouse_name,

    COUNT(*) AS Total_Orders,

    SUM(so.ordered_qty) AS Ordered_Qty,

    SUM(so.fulfilled_qty) AS Fulfilled_Qty,

    SUM(so.backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(so.fulfilled_qty)
        / NULLIF(SUM(so.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Quantity_Fill_Rate_Pct,

    CAST(
        100.0 * SUM(so.backlog_qty)
        / NULLIF(SUM(so.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Rate_Pct,

    SUM(
        CASE
            WHEN so.backlog_qty > 0
            THEN 1 ELSE 0
        END
    ) AS Backlogged_Orders,

    CAST(
        100.0 *
        SUM(CASE WHEN so.backlog_qty > 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Backlogged_Order_Rate_Pct

FROM raw.Sales_Orders AS so

INNER JOIN raw.Warehouses AS w
    ON so.warehouse_id = w.warehouse_id

GROUP BY
    so.warehouse_id,
    w.warehouse_name

ORDER BY Quantity_Fill_Rate_Pct DESC;




-- ============================================================
-- Step 8: Fulfillment Performance by Product Category
-- ============================================================

SELECT
    p.category,

    COUNT(*) AS Order_Lines,

    COUNT(DISTINCT soi.order_id) AS Orders,

    SUM(soi.ordered_qty) AS Ordered_Qty,

    SUM(soi.fulfilled_qty) AS Fulfilled_Qty,

    SUM(soi.backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * SUM(soi.fulfilled_qty)
        / NULLIF(SUM(soi.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Quantity_Fill_Rate_Pct,

    CAST(
        100.0 * SUM(soi.backlog_qty)
        / NULLIF(SUM(soi.ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Rate_Pct,

    SUM(
        CASE
            WHEN soi.backlog_qty > 0
            THEN 1 ELSE 0
        END
    ) AS Backlogged_Lines,

    CAST(
        100.0 *
        SUM(CASE WHEN soi.backlog_qty > 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Backlogged_Line_Rate_Pct

FROM raw.Sales_Order_Items AS soi

INNER JOIN raw.Products AS p
    ON soi.product_id = p.product_id

GROUP BY
    p.category

ORDER BY
    Quantity_Fill_Rate_Pct DESC;





-- ============================================================
-- Step 9: Shipment Coverage of Sales Orders
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
-- Step 10: Orders Without Shipment Analysis
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

LEFT JOIN
(
    SELECT DISTINCT order_id
    FROM raw.Shipments
) AS s
    ON so.order_id = s.order_id

WHERE s.order_id IS NULL

GROUP BY so.order_status

ORDER BY Orders_Without_Shipment DESC;



-- ============================================================
-- Step 11: Fulfilled Quantity vs Shipped Quantity Reconciliation
-- ============================================================

WITH ShipmentQty AS
(
    SELECT
        order_id,
        SUM(shipped_qty) AS Shipped_Qty
    FROM raw.Shipments
    GROUP BY order_id
),

OrderShipment AS
(
    SELECT
        so.order_id,
        so.fulfilled_qty,

        ISNULL(s.Shipped_Qty, 0)
            AS Shipped_Qty

    FROM raw.Sales_Orders AS so

    LEFT JOIN ShipmentQty AS s
        ON so.order_id = s.order_id
)

SELECT
    SUM(fulfilled_qty) AS Total_Fulfilled_Qty,

    SUM(Shipped_Qty) AS Total_Shipped_Qty,

    SUM(fulfilled_qty) - SUM(Shipped_Qty)
        AS Quantity_Difference,

    SUM(
        CASE
            WHEN fulfilled_qty <> Shipped_Qty
            THEN 1 ELSE 0
        END
    ) AS Orders_With_Qty_Mismatch

FROM OrderShipment;



-- ============================================================
-- Step 12: Order Processing Time Analysis
-- Order Date → Shipment Date
-- ============================================================

WITH OrderShipment AS
(
    SELECT
        so.order_id,
        so.order_date,
        MIN(s.shipment_date) AS shipment_date

    FROM raw.Sales_Orders AS so

    INNER JOIN raw.Shipments AS s
        ON so.order_id = s.order_id

    GROUP BY
        so.order_id,
        so.order_date
),

ProcessingTime AS
(
    SELECT
        order_id,

        DATEDIFF(
            DAY,
            order_date,
            shipment_date
        ) AS Processing_Days

    FROM OrderShipment
)

SELECT
    COUNT(*) AS Shipped_Orders,

    CAST(
        AVG(1.0 * Processing_Days)
        AS DECIMAL(8,2)
    ) AS Avg_Processing_Days,

    MIN(Processing_Days)
        AS Min_Processing_Days,

    MAX(Processing_Days)
        AS Max_Processing_Days,

    CAST(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY Processing_Days)
        OVER ()
        AS DECIMAL(8,2)
    ) AS Median_Processing_Days

FROM ProcessingTime

GROUP BY Processing_Days;


-- ============================================================
-- Step 12: Order Processing Time Analysis
-- Corrected Version
-- ============================================================

WITH OrderShipment AS
(
    SELECT
        so.order_id,
        so.order_date,
        MIN(s.shipment_date) AS shipment_date

    FROM raw.Sales_Orders AS so

    INNER JOIN raw.Shipments AS s
        ON so.order_id = s.order_id

    GROUP BY
        so.order_id,
        so.order_date
),

ProcessingTime AS
(
    SELECT
        order_id,

        DATEDIFF(
            DAY,
            order_date,
            shipment_date
        ) AS Processing_Days

    FROM OrderShipment
),

ProcessingStats AS
(
    SELECT
        *,

        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY Processing_Days)
        OVER () AS Median_Processing_Days

    FROM ProcessingTime
)

SELECT
    COUNT(*) AS Shipped_Orders,

    CAST(
        AVG(1.0 * Processing_Days)
        AS DECIMAL(8,2)
    ) AS Avg_Processing_Days,

    MIN(Processing_Days)
        AS Min_Processing_Days,

    MAX(Processing_Days)
        AS Max_Processing_Days,

    CAST(
        MAX(Median_Processing_Days)
        AS DECIMAL(8,2)
    ) AS Median_Processing_Days

FROM ProcessingStats;



-- ============================================================
-- Step 13: Order Processing Time Distribution
-- ============================================================

WITH OrderShipment AS
(
    SELECT
        so.order_id,
        so.order_date,
        MIN(s.shipment_date) AS shipment_date

    FROM raw.Sales_Orders AS so

    INNER JOIN raw.Shipments AS s
        ON so.order_id = s.order_id

    GROUP BY
        so.order_id,
        so.order_date
),

ProcessingTime AS
(
    SELECT
        order_id,

        DATEDIFF(
            DAY,
            order_date,
            shipment_date
        ) AS Processing_Days

    FROM OrderShipment
),

ProcessingBands AS
(
    SELECT
        order_id,
        Processing_Days,

        CASE
            WHEN Processing_Days <= 2
                THEN '1-2 Days'

            WHEN Processing_Days = 3
                THEN '3 Days'

            WHEN Processing_Days BETWEEN 4 AND 5
                THEN '4-5 Days'

            ELSE '6+ Days'
        END AS Processing_Time_Band

    FROM ProcessingTime
)

SELECT
    Processing_Time_Band,

    COUNT(*) AS Orders,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Order_Share_Pct,

    CAST(
        AVG(1.0 * Processing_Days)
        AS DECIMAL(8,2)
    ) AS Avg_Processing_Days

FROM ProcessingBands

GROUP BY Processing_Time_Band

ORDER BY
    CASE Processing_Time_Band
        WHEN '1-2 Days' THEN 1
        WHEN '3 Days' THEN 2
        WHEN '4-5 Days' THEN 3
        WHEN '6+ Days' THEN 4
    END;



-- ============================================================
-- Step 14: Processing Time by Order Priority
-- ============================================================

WITH OrderShipment AS
(
    SELECT
        so.order_id,
        so.priority,
        so.order_date,
        MIN(s.shipment_date) AS shipment_date

    FROM raw.Sales_Orders AS so

    INNER JOIN raw.Shipments AS s
        ON so.order_id = s.order_id

    GROUP BY
        so.order_id,
        so.priority,
        so.order_date
),

ProcessingTime AS
(
    SELECT
        order_id,
        priority,

        DATEDIFF(
            DAY,
            order_date,
            shipment_date
        ) AS Processing_Days

    FROM OrderShipment
)

SELECT
    priority,

    COUNT(*) AS Shipped_Orders,

    CAST(
        AVG(1.0 * Processing_Days)
        AS DECIMAL(8,2)
    ) AS Avg_Processing_Days,

    SUM(
        CASE
            WHEN Processing_Days <= 2
            THEN 1 ELSE 0
        END
    ) AS Orders_Processed_Within_2_Days,

    CAST(
        100.0 *
        SUM(CASE WHEN Processing_Days <= 2 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Within_2_Days_Pct,

    SUM(
        CASE
            WHEN Processing_Days >= 4
            THEN 1 ELSE 0
        END
    ) AS Orders_Processing_4Plus_Days,

    CAST(
        100.0 *
        SUM(CASE WHEN Processing_Days >= 4 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Processing_4Plus_Days_Pct

FROM ProcessingTime

GROUP BY priority

ORDER BY
    CASE priority
        WHEN 'Urgent' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Normal' THEN 3
        WHEN 'Low' THEN 4
        ELSE 5
    END;



-- ============================================================
-- Step 15: Fulfillment Completeness vs Delivery Performance
-- Valid shipment chronology only
-- ============================================================

SELECT
    CASE
        WHEN so.backlog_qty = 0
         AND so.fulfilled_qty = so.ordered_qty
            THEN 'Fully Fulfilled'
        ELSE 'Partially Fulfilled / Backlogged'
    END AS Fulfillment_Status,

    COUNT(*) AS Orders,

    CAST(
        AVG(1.0 * so.order_fill_rate_pct)
        AS DECIMAL(8,2)
    ) AS Avg_Fill_Rate_Pct,

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
    ) AS Avg_Delivery_Delay_Days

FROM raw.Sales_Orders AS so

INNER JOIN raw.Shipments AS s
    ON so.order_id = s.order_id

WHERE s.actual_delivery_date >= s.shipment_date

GROUP BY
    CASE
        WHEN so.backlog_qty = 0
         AND so.fulfilled_qty = so.ordered_qty
            THEN 'Fully Fulfilled'
        ELSE 'Partially Fulfilled / Backlogged'
    END

ORDER BY Avg_Fill_Rate_Pct DESC;



-- ============================================================
-- Step 16: Backlog Impact on Late-Delivery Risk
-- Valid shipment chronology only
-- ============================================================

WITH DeliveryBase AS
(
    SELECT
        so.order_id,

        CASE
            WHEN so.backlog_qty > 0
                THEN 'Backlogged'
            ELSE 'No Backlog'
        END AS Backlog_Status,

        s.on_time_flag

    FROM raw.Sales_Orders AS so

    INNER JOIN raw.Shipments AS s
        ON so.order_id = s.order_id

    WHERE s.actual_delivery_date >= s.shipment_date
),

RiskSummary AS
(
    SELECT
        Backlog_Status,

        COUNT(*) AS Orders,

        SUM(
            CASE
                WHEN on_time_flag = 0
                THEN 1 ELSE 0
            END
        ) AS Late_Orders,

        CAST(
            100.0 *
            SUM(CASE WHEN on_time_flag = 0 THEN 1 ELSE 0 END)
            / COUNT(*)
            AS DECIMAL(8,2)
        ) AS Late_Order_Rate_Pct

    FROM DeliveryBase

    GROUP BY Backlog_Status
)

SELECT
    Backlog_Status,
    Orders,
    Late_Orders,
    Late_Order_Rate_Pct,

    CAST(
        Late_Order_Rate_Pct /
        NULLIF(
            MAX(
                CASE
                    WHEN Backlog_Status = 'No Backlog'
                    THEN Late_Order_Rate_Pct
                END
            ) OVER (),
            0
        )
        AS DECIMAL(8,2)
    ) AS Late_Risk_Ratio_vs_No_Backlog

FROM RiskSummary

ORDER BY
    CASE Backlog_Status
        WHEN 'No Backlog' THEN 1
        WHEN 'Backlogged' THEN 2
    END;





-- ============================================================
-- Step 17: End-to-End Fulfillment Outcome
-- ============================================================

WITH OrderOutcome AS
(
    SELECT
        so.order_id,
        so.ordered_qty,
        so.fulfilled_qty,
        so.backlog_qty,

        CASE
            WHEN s.order_id IS NULL
                THEN 'Not Shipped'

            WHEN s.actual_delivery_date < s.shipment_date
                THEN 'Invalid Delivery Chronology'

            WHEN so.backlog_qty = 0
                 AND so.fulfilled_qty = so.ordered_qty
                 AND s.on_time_flag = 1
                THEN 'Fully Fulfilled & On-Time'

            WHEN so.backlog_qty = 0
                 AND so.fulfilled_qty = so.ordered_qty
                 AND s.on_time_flag = 0
                THEN 'Fully Fulfilled but Late'

            WHEN so.backlog_qty > 0
                 AND s.on_time_flag = 1
                THEN 'Backlogged but On-Time'

            WHEN so.backlog_qty > 0
                 AND s.on_time_flag = 0
                THEN 'Backlogged & Late'

            ELSE 'Other'
        END AS Fulfillment_Outcome

    FROM raw.Sales_Orders AS so

    LEFT JOIN raw.Shipments AS s
        ON so.order_id = s.order_id
)

SELECT
    Fulfillment_Outcome,

    COUNT(*) AS Orders,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(fulfilled_qty) AS Fulfilled_Qty,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Order_Share_Pct

FROM OrderOutcome

GROUP BY Fulfillment_Outcome

ORDER BY Orders DESC;



-- ============================================================
-- Step 18: End-to-End Fulfillment Outcome by Priority
-- Valid shipment chronology only
-- ============================================================

WITH ValidOrders AS
(
    SELECT
        so.order_id,
        so.priority,
        so.backlog_qty,
        so.fulfilled_qty,
        so.ordered_qty,
        s.on_time_flag,
        s.otif_flag

    FROM raw.Sales_Orders AS so

    INNER JOIN raw.Shipments AS s
        ON so.order_id = s.order_id

    WHERE s.actual_delivery_date >= s.shipment_date
)

SELECT
    priority,

    COUNT(*) AS Valid_Shipped_Orders,

    SUM(
        CASE
            WHEN backlog_qty = 0
             AND fulfilled_qty = ordered_qty
             AND on_time_flag = 1
            THEN 1 ELSE 0
        END
    ) AS Successful_Orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN backlog_qty = 0
                 AND fulfilled_qty = ordered_qty
                 AND on_time_flag = 1
                THEN 1 ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(8,2)
    ) AS End_to_End_Success_Rate_Pct,

    SUM(
        CASE
            WHEN backlog_qty > 0
             AND on_time_flag = 0
            THEN 1 ELSE 0
        END
    ) AS Backlogged_Late_Orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN backlog_qty > 0
                 AND on_time_flag = 0
                THEN 1 ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Backlogged_Late_Rate_Pct,

    CAST(
        100.0 * SUM(CASE WHEN otif_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS OTIF_Rate_Pct

FROM ValidOrders

GROUP BY priority

ORDER BY
    CASE priority
        WHEN 'Urgent' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Normal' THEN 3
        WHEN 'Low' THEN 4
        ELSE 5
    END;



-- ============================================================
-- Step 19: High-Risk Fulfillment Orders
-- ============================================================

WITH OrderRisk AS
(
    SELECT
        so.order_id,
        so.priority,
        so.ordered_qty,
        so.fulfilled_qty,
        so.backlog_qty,
        so.backlog_value,

        CASE
            WHEN s.order_id IS NULL
                THEN 1

            WHEN s.actual_delivery_date >= s.shipment_date
                 AND s.on_time_flag = 0
                THEN 1

            WHEN so.backlog_qty > 0
                THEN 1

            ELSE 0
        END AS Fulfillment_Risk_Flag

    FROM raw.Sales_Orders AS so

    LEFT JOIN raw.Shipments AS s
        ON so.order_id = s.order_id
)

SELECT
    COUNT(*) AS High_Risk_Orders,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(fulfilled_qty) AS Fulfilled_Qty,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * COUNT(*)
        / 25000.0
        AS DECIMAL(8,2)
    ) AS Share_of_All_Orders_Pct

FROM OrderRisk

WHERE priority IN ('High', 'Urgent')
  AND Fulfillment_Risk_Flag = 1;





-- ============================================================
-- Step 20: High-Risk Fulfillment by Priority
-- ============================================================

WITH OrderRisk AS
(
    SELECT
        so.order_id,
        so.priority,
        so.ordered_qty,
        so.fulfilled_qty,
        so.backlog_qty,
        so.backlog_value,

        CASE
            WHEN s.order_id IS NULL
                THEN 1

            WHEN s.actual_delivery_date >= s.shipment_date
                 AND s.on_time_flag = 0
                THEN 1

            WHEN so.backlog_qty > 0
                THEN 1

            ELSE 0
        END AS Fulfillment_Risk_Flag

    FROM raw.Sales_Orders AS so

    LEFT JOIN raw.Shipments AS s
        ON so.order_id = s.order_id
)

SELECT
    priority,

    COUNT(*) AS High_Risk_Orders,

    SUM(ordered_qty) AS Ordered_Qty,

    SUM(fulfilled_qty) AS Fulfilled_Qty,

    SUM(backlog_qty) AS Backlog_Qty,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * SUM(backlog_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Backlog_Rate_Pct

FROM OrderRisk

WHERE priority IN ('High', 'Urgent')
  AND Fulfillment_Risk_Flag = 1

GROUP BY priority

ORDER BY
    CASE priority
        WHEN 'Urgent' THEN 1
        WHEN 'High' THEN 2
    END;




-- ============================================================
-- Step 21: High-Risk Fulfillment by Warehouse
-- ============================================================

WITH OrderRisk AS
(
    SELECT
        so.order_id,
        so.warehouse_id,
        so.priority,
        so.ordered_qty,
        so.fulfilled_qty,
        so.backlog_qty,
        so.backlog_value,

        CASE
            WHEN s.order_id IS NULL
                THEN 1

            WHEN s.actual_delivery_date >= s.shipment_date
                 AND s.on_time_flag = 0
                THEN 1

            WHEN so.backlog_qty > 0
                THEN 1

            ELSE 0
        END AS Fulfillment_Risk_Flag

    FROM raw.Sales_Orders AS so

    LEFT JOIN raw.Shipments AS s
        ON so.order_id = s.order_id
)

SELECT
    r.warehouse_id,
    w.warehouse_name,

    COUNT(*) AS High_Risk_Orders,

    SUM(r.ordered_qty) AS Ordered_Qty,

    SUM(r.fulfilled_qty) AS Fulfilled_Qty,

    SUM(r.backlog_qty) AS Backlog_Qty,

    CAST(
        SUM(r.backlog_value)
        AS DECIMAL(18,2)
    ) AS Backlog_Value,

    CAST(
        100.0 * COUNT(*)
        / 4549.0
        AS DECIMAL(8,2)
    ) AS High_Risk_Order_Share_Pct

FROM OrderRisk AS r

INNER JOIN raw.Warehouses AS w
    ON r.warehouse_id = w.warehouse_id

WHERE r.priority IN ('High', 'Urgent')
  AND r.Fulfillment_Risk_Flag = 1

GROUP BY
    r.warehouse_id,
    w.warehouse_name

ORDER BY Backlog_Value DESC;



-- ============================================================
-- Step 22: Order Fulfillment KPI Summary
-- ============================================================

SELECT
    COUNT(*) AS Total_Orders,

    SUM(ordered_qty) AS Total_Ordered_Qty,

    SUM(fulfilled_qty) AS Total_Fulfilled_Qty,

    SUM(backlog_qty) AS Total_Backlog_Qty,

    CAST(
        100.0 * SUM(fulfilled_qty)
        / NULLIF(SUM(ordered_qty), 0)
        AS DECIMAL(8,2)
    ) AS Overall_Fill_Rate_Pct,

    SUM(
        CASE
            WHEN backlog_qty = 0
             AND fulfilled_qty = ordered_qty
            THEN 1 ELSE 0
        END
    ) AS Fully_Fulfilled_Orders,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN backlog_qty = 0
                 AND fulfilled_qty = ordered_qty
                THEN 1 ELSE 0
            END
        ) / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Fully_Fulfilled_Order_Rate_Pct,

    SUM(
        CASE
            WHEN backlog_qty > 0
            THEN 1 ELSE 0
        END
    ) AS Backlogged_Orders,

    CAST(
        100.0 *
        SUM(CASE WHEN backlog_qty > 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Backlogged_Order_Rate_Pct,

    CAST(
        AVG(1.0 * order_fill_rate_pct)
        AS DECIMAL(8,2)
    ) AS Avg_Order_Fill_Rate_Pct

FROM raw.Sales_Orders;



-- ============================================================
-- Step 23: Order Fulfillment Reconciliation
-- ============================================================

DECLARE @FulfillmentChecks TABLE
(
    Validation_Check VARCHAR(150),
    Status VARCHAR(10)
);

INSERT INTO @FulfillmentChecks
VALUES

('Total Orders',
 CASE WHEN (SELECT COUNT(*) FROM raw.Sales_Orders) = 25000
      THEN 'PASS' ELSE 'FAIL' END),

('Unique Order IDs',
 CASE WHEN (SELECT COUNT(DISTINCT order_id) FROM raw.Sales_Orders) = 25000
      THEN 'PASS' ELSE 'FAIL' END),

('Total Ordered Quantity',
 CASE WHEN (SELECT SUM(ordered_qty) FROM raw.Sales_Orders) = 501755
      THEN 'PASS' ELSE 'FAIL' END),

('Total Fulfilled Quantity',
 CASE WHEN (SELECT SUM(fulfilled_qty) FROM raw.Sales_Orders) = 440576
      THEN 'PASS' ELSE 'FAIL' END),

('Total Backlog Quantity',
 CASE WHEN (SELECT SUM(backlog_qty) FROM raw.Sales_Orders) = 61179
      THEN 'PASS' ELSE 'FAIL' END),

('Quantity Reconciliation',
 CASE WHEN
      (SELECT SUM(ordered_qty) FROM raw.Sales_Orders) =
      (SELECT SUM(fulfilled_qty + backlog_qty) FROM raw.Sales_Orders)
      THEN 'PASS' ELSE 'FAIL' END),

('Fully Fulfilled Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders
          WHERE backlog_qty = 0
            AND fulfilled_qty = ordered_qty
      ) = 14150
      THEN 'PASS' ELSE 'FAIL' END),

('Backlogged Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders
          WHERE backlog_qty > 0
      ) = 10850
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
          FROM raw.Sales_Orders so
          WHERE NOT EXISTS
          (
              SELECT 1
              FROM raw.Shipments s
              WHERE s.order_id = so.order_id
          )
      ) = 202
      THEN 'PASS' ELSE 'FAIL' END),

('Fulfilled Equals Shipped Quantity',
 CASE WHEN
      (SELECT SUM(fulfilled_qty) FROM raw.Sales_Orders) =
      (SELECT SUM(shipped_qty) FROM raw.Shipments)
      THEN 'PASS' ELSE 'FAIL' END),

('Invalid Shipment Chronology Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Shipments
          WHERE actual_delivery_date < shipment_date
      ) = 4467
      THEN 'PASS' ELSE 'FAIL' END),

('Valid Shipment Chronology Records',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Shipments
          WHERE actual_delivery_date >= shipment_date
      ) = 20331
      THEN 'PASS' ELSE 'FAIL' END),

('Fully Fulfilled On-Time Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders so
          INNER JOIN raw.Shipments s
              ON so.order_id = s.order_id
          WHERE s.actual_delivery_date >= s.shipment_date
            AND so.backlog_qty = 0
            AND so.fulfilled_qty = so.ordered_qty
            AND s.on_time_flag = 1
      ) = 9404
      THEN 'PASS' ELSE 'FAIL' END),

('Backlogged Late Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders so
          INNER JOIN raw.Shipments s
              ON so.order_id = s.order_id
          WHERE s.actual_delivery_date >= s.shipment_date
            AND so.backlog_qty > 0
            AND s.on_time_flag = 0
      ) = 3932
      THEN 'PASS' ELSE 'FAIL' END),

('High Risk High-Urgent Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders so
          LEFT JOIN raw.Shipments s
              ON so.order_id = s.order_id
          WHERE so.priority IN ('High','Urgent')
            AND
            (
                s.order_id IS NULL
                OR so.backlog_qty > 0
                OR
                (
                    s.actual_delivery_date >= s.shipment_date
                    AND s.on_time_flag = 0
                )
            )
      ) = 4549
      THEN 'PASS' ELSE 'FAIL' END),

('No Negative Fulfilled Quantity',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Sales_Orders
          WHERE fulfilled_qty < 0
      )
      THEN 'PASS' ELSE 'FAIL' END),

('No Negative Backlog Quantity',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Sales_Orders
          WHERE backlog_qty < 0
      )
      THEN 'PASS' ELSE 'FAIL' END),

('Fulfilled Quantity Does Not Exceed Ordered',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Sales_Orders
          WHERE fulfilled_qty > ordered_qty
      )
      THEN 'PASS' ELSE 'FAIL' END),

('Backlog Quantity Does Not Exceed Ordered',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Sales_Orders
          WHERE backlog_qty > ordered_qty
      )
      THEN 'PASS' ELSE 'FAIL' END);

SELECT *
FROM @FulfillmentChecks;

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
    END AS Fulfillment_Reconciliation_Status

FROM @FulfillmentChecks;

-- ============================================================
-- Step 24: Final Business Insights
-- ============================================================

/*
1. OVERALL FULFILLMENT PERFORMANCE
   - Total orders: 25,000.
   - Total ordered quantity: 501,755 units.
   - Total fulfilled quantity: 440,576 units.
   - Overall quantity fill rate: 87.81%.
   - 14,150 orders (56.60%) were fully fulfilled.
   - 10,850 orders (43.40%) experienced backlog.

2. PRIORITY FULFILLMENT
   - Urgent orders have the weakest quantity fill rate at 86.97%.
   - High-priority orders achieve an 88.23% fill rate.
   - Priority classification is therefore not consistently translating
     into stronger fulfillment performance.

3. CUSTOMER AND REGIONAL PERFORMANCE
   - Customer-segment differences are relatively small.
   - Distributor customers have the strongest fill rate at 88.24%.
   - North is the weakest region with an 86.90% fill rate and
     the highest backlogged-order rate at 44.59%.

4. WAREHOUSE PERFORMANCE
   - Mumbai West has the strongest fill rate at 88.27%.
   - Chennai Hub and Pune DC have the lowest fill rate at 87.12%.
   - Pune DC also has the highest warehouse backlogged-order rate
     at 44.15%.

5. PRODUCT CATEGORY PERFORMANCE
   - Home & Kitchen has the strongest category fill rate at 88.84%.
   - Automotive is the weakest category at 86.63%.
   - Automotive also has the highest category backlog rate at 13.37%
     and backlogged-line rate at 23.01%.

6. SHIPMENT COVERAGE
   - 24,798 of 25,000 orders have shipment records.
   - Shipment coverage is 99.19%.
   - The remaining 202 unshipped orders consist of
     198 Backordered and 4 Cancelled orders.
   - These orders have zero fulfilled quantity.

7. FULFILLMENT-SHIPMENT RECONCILIATION
   - Total fulfilled quantity exactly equals total shipped quantity
     at 440,576 units.
   - No order-level fulfilled-versus-shipped quantity mismatch exists.

8. ORDER PROCESSING TIME
   - Average processing time from order to shipment is 3.52 days.
   - Median processing time is 4 days.
   - Processing time ranges from 1 to 6 days.
   - 33.03% of shipped orders are processed within 1-2 days.
   - 33.53% require 4-5 days.

9. URGENT ORDER PROCESSING
   - Urgent orders average 3.56 processing days.
   - Only 31.48% are processed within 2 days.
   - 51.92% require 4 or more days.
   - Urgent orders are therefore not receiving visibly faster
     processing than lower-priority orders.

10. FULFILLMENT AND DELIVERY PERFORMANCE
    - Fully fulfilled orders achieve 83.05% on-time delivery
      and 83.05% OTIF.
    - Their average delivery delay is only 0.15 days.
    - Backlogged orders achieve only 56.35% on-time delivery,
      0% OTIF, and average 1.92 delay days.

11. BACKLOG-RELATED DELIVERY RISK
    - Orders without backlog have a 16.95% late-delivery rate.
    - Backlogged orders have a 43.65% late-delivery rate.
    - Backlogged orders therefore show approximately 2.58 times
      the late-delivery risk of non-backlogged orders.

12. END-TO-END SERVICE PERFORMANCE
    - 9,404 orders (37.62%) are fully fulfilled and on time.
    - 5,076 orders (20.30%) are backlogged but delivered on time.
    - 3,932 orders (15.73%) are both backlogged and late.
    - 1,919 orders (7.68%) are fully fulfilled but late.
    - 4,467 orders (17.87%) are affected by the known shipment
      chronology data-quality issue.
    - 202 orders (0.81%) are not shipped.

13. PRIORITY SERVICE RISK
    - Urgent orders have the lowest valid end-to-end success rate
      at 41.96%.
    - High-priority orders follow at 43.20%.
    - Urgent orders also have the highest backlogged-and-late rate
      at 22.72%.

14. HIGH-RISK ORDER EXPOSURE
    - 4,549 High/Urgent orders meet the fulfillment-risk definition.
    - These represent 18.20% of all orders.
    - They contain 20,435 backlog units and approximately
      87.35M in backlog value.
    - High-priority orders contribute approximately 65.06M of this
      backlog exposure.
    - Urgent orders have the higher backlog rate at 21.90%.

15. HIGH-RISK WAREHOUSE EXPOSURE
    - Bengaluru Central has the largest high-risk exposure:
      982 orders, 4,366 backlog units and approximately 19.04M
      in backlog value.

16. MANAGEMENT RECOMMENDATION
    - Strengthen service controls for High and Urgent orders.
    - Reduce partial fulfillment because incomplete fulfillment is
      strongly associated with weaker delivery performance.
    - Prioritize backlog reduction in North, Pune DC, Bengaluru Central
      and Automotive-related fulfillment flows.
    - Monitor order-to-shipment processing time by priority.
    - Resolve the shipment chronology data-quality issue before using
      all shipment records for delivery-performance decisions.
*/


-- ============================================================
-- Step 25: Final Order Fulfillment Validation
-- ============================================================

DECLARE @FinalFulfillmentValidation TABLE
(
    Validation_Check VARCHAR(160),
    Status VARCHAR(10)
);

INSERT INTO @FinalFulfillmentValidation
VALUES

('Total Orders',
 CASE WHEN (SELECT COUNT(*) FROM raw.Sales_Orders) = 25000
      THEN 'PASS' ELSE 'FAIL' END),

('Unique Order IDs',
 CASE WHEN (SELECT COUNT(DISTINCT order_id)
            FROM raw.Sales_Orders) = 25000
      THEN 'PASS' ELSE 'FAIL' END),

('Total Ordered Quantity',
 CASE WHEN (SELECT SUM(ordered_qty)
            FROM raw.Sales_Orders) = 501755
      THEN 'PASS' ELSE 'FAIL' END),

('Total Fulfilled Quantity',
 CASE WHEN (SELECT SUM(fulfilled_qty)
            FROM raw.Sales_Orders) = 440576
      THEN 'PASS' ELSE 'FAIL' END),

('Total Backlog Quantity',
 CASE WHEN (SELECT SUM(backlog_qty)
            FROM raw.Sales_Orders) = 61179
      THEN 'PASS' ELSE 'FAIL' END),

('Ordered Qty Reconciles',
 CASE WHEN
      (SELECT SUM(ordered_qty) FROM raw.Sales_Orders) =
      (SELECT SUM(fulfilled_qty + backlog_qty)
       FROM raw.Sales_Orders)
      THEN 'PASS' ELSE 'FAIL' END),

('Overall Quantity Fill Rate',
 CASE WHEN ABS(
      (
          SELECT
              100.0 * SUM(fulfilled_qty)
              / NULLIF(SUM(ordered_qty),0)
          FROM raw.Sales_Orders
      ) - 87.81) < 0.01
      THEN 'PASS' ELSE 'FAIL' END),

('Fully Fulfilled Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders
          WHERE backlog_qty = 0
            AND fulfilled_qty = ordered_qty
      ) = 14150
      THEN 'PASS' ELSE 'FAIL' END),

('Backlogged Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders
          WHERE backlog_qty > 0
      ) = 10850
      THEN 'PASS' ELSE 'FAIL' END),

('Shipment Coverage',
 CASE WHEN
      (SELECT COUNT(DISTINCT order_id)
       FROM raw.Shipments) = 24798
      THEN 'PASS' ELSE 'FAIL' END),

('Orders Without Shipment',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders so
          WHERE NOT EXISTS
          (
              SELECT 1
              FROM raw.Shipments s
              WHERE s.order_id = so.order_id
          )
      ) = 202
      THEN 'PASS' ELSE 'FAIL' END),

('Fulfilled Qty Equals Shipped Qty',
 CASE WHEN
      (SELECT SUM(fulfilled_qty)
       FROM raw.Sales_Orders) =
      (SELECT SUM(shipped_qty)
       FROM raw.Shipments)
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

('Fully Fulfilled On-Time Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders so
          INNER JOIN raw.Shipments s
              ON so.order_id = s.order_id
          WHERE s.actual_delivery_date >= s.shipment_date
            AND so.backlog_qty = 0
            AND so.fulfilled_qty = so.ordered_qty
            AND s.on_time_flag = 1
      ) = 9404
      THEN 'PASS' ELSE 'FAIL' END),

('Backlogged On-Time Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders so
          INNER JOIN raw.Shipments s
              ON so.order_id = s.order_id
          WHERE s.actual_delivery_date >= s.shipment_date
            AND so.backlog_qty > 0
            AND s.on_time_flag = 1
      ) = 5076
      THEN 'PASS' ELSE 'FAIL' END),

('Backlogged Late Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders so
          INNER JOIN raw.Shipments s
              ON so.order_id = s.order_id
          WHERE s.actual_delivery_date >= s.shipment_date
            AND so.backlog_qty > 0
            AND s.on_time_flag = 0
      ) = 3932
      THEN 'PASS' ELSE 'FAIL' END),

('Fully Fulfilled Late Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders so
          INNER JOIN raw.Shipments s
              ON so.order_id = s.order_id
          WHERE s.actual_delivery_date >= s.shipment_date
            AND so.backlog_qty = 0
            AND so.fulfilled_qty = so.ordered_qty
            AND s.on_time_flag = 0
      ) = 1919
      THEN 'PASS' ELSE 'FAIL' END),

('High Risk High-Urgent Orders',
 CASE WHEN
      (
          SELECT COUNT(*)
          FROM raw.Sales_Orders so
          LEFT JOIN raw.Shipments s
              ON so.order_id = s.order_id
          WHERE so.priority IN ('High','Urgent')
            AND
            (
                s.order_id IS NULL
                OR so.backlog_qty > 0
                OR
                (
                    s.actual_delivery_date >= s.shipment_date
                    AND s.on_time_flag = 0
                )
            )
      ) = 4549
      THEN 'PASS' ELSE 'FAIL' END),

('No Negative Fulfilled Qty',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Sales_Orders
          WHERE fulfilled_qty < 0
      )
      THEN 'PASS' ELSE 'FAIL' END),

('No Negative Backlog Qty',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Sales_Orders
          WHERE backlog_qty < 0
      )
      THEN 'PASS' ELSE 'FAIL' END),

('Fulfilled Qty Within Ordered Qty',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Sales_Orders
          WHERE fulfilled_qty > ordered_qty
      )
      THEN 'PASS' ELSE 'FAIL' END),

('Backlog Qty Within Ordered Qty',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Sales_Orders
          WHERE backlog_qty > ordered_qty
      )
      THEN 'PASS' ELSE 'FAIL' END),

('Shipment Order Foreign Keys Valid',
 CASE WHEN NOT EXISTS
      (
          SELECT 1
          FROM raw.Shipments s
          LEFT JOIN raw.Sales_Orders so
              ON s.order_id = so.order_id
          WHERE so.order_id IS NULL
      )
      THEN 'PASS' ELSE 'FAIL' END);

SELECT *
FROM @FinalFulfillmentValidation;

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
    END AS Final_Order_Fulfillment_Status

FROM @FinalFulfillmentValidation;


