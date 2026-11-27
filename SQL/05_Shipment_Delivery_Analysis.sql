-- ============================================================
-- SALES ORDER, BACKLOG & INVENTORY ANALYTICS
-- File: 05_Shipment_Delivery_Analysis.sql
-- Purpose: Analyze shipment performance, delivery delays,
--          on-time delivery and OTIF performance
-- ============================================================

USE Sales_Order_Backlog_Inventory_Analytics;
GO

-- ============================================================
-- Step 1: Validate Shipment Analysis Source Data
-- ============================================================

SELECT
    COUNT(*) AS Total_Shipments,

    SUM(
        CASE
            WHEN actual_delivery_date >= shipment_date
            THEN 1
            ELSE 0
        END
    ) AS Valid_Chronology_Shipments,

    SUM(
        CASE
            WHEN actual_delivery_date < shipment_date
            THEN 1
            ELSE 0
        END
    ) AS Invalid_Chronology_Shipments,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN actual_delivery_date >= shipment_date
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Valid_Chronology_Pct,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN actual_delivery_date < shipment_date
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Invalid_Chronology_Pct

FROM raw.Shipments;



-- ============================================================
-- Step 2: Overall Delivery Performance KPIs
-- Valid chronology shipments only
-- ============================================================

SELECT
    COUNT(*) AS Valid_Shipments,

    SUM(shipped_qty) AS Total_Shipped_Qty,

    SUM(
        CASE
            WHEN on_time_flag = 1
            THEN 1 ELSE 0
        END
    ) AS On_Time_Shipments,

    SUM(
        CASE
            WHEN on_time_flag = 0
            THEN 1 ELSE 0
        END
    ) AS Late_Shipments,

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
    ) AS Late_Rate_Pct,

    SUM(
        CASE
            WHEN otif_flag = 1
            THEN 1 ELSE 0
        END
    ) AS OTIF_Shipments,

    CAST(
        100.0 *
        SUM(CASE WHEN otif_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS OTIF_Rate_Pct,

    CAST(
        AVG(1.0 * delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delivery_Delay_Days

FROM raw.Shipments

WHERE actual_delivery_date >= shipment_date;



-- ============================================================
-- Step 3: Delivery Delay Distribution
-- Valid chronology shipments only
-- ============================================================

WITH DeliveryBands AS
(
    SELECT
        shipped_qty,
        delivery_delay_days,

        CASE
            WHEN delivery_delay_days < 0
                THEN 'Early'

            WHEN delivery_delay_days = 0
                THEN 'On Time'

            WHEN delivery_delay_days BETWEEN 1 AND 2
                THEN '1-2 Days Late'

            WHEN delivery_delay_days BETWEEN 3 AND 5
                THEN '3-5 Days Late'

            ELSE '6+ Days Late'
        END AS Delivery_Status,

        CASE
            WHEN delivery_delay_days < 0 THEN 1
            WHEN delivery_delay_days = 0 THEN 2
            WHEN delivery_delay_days BETWEEN 1 AND 2 THEN 3
            WHEN delivery_delay_days BETWEEN 3 AND 5 THEN 4
            ELSE 5
        END AS Sort_Order

    FROM raw.Shipments

    WHERE actual_delivery_date >= shipment_date
),

DeliverySummary AS
(
    SELECT
        Delivery_Status,
        Sort_Order,
        COUNT(*) AS Shipments,
        SUM(shipped_qty) AS Shipped_Qty,
        AVG(1.0 * delivery_delay_days) AS Avg_Delay_Days

    FROM DeliveryBands

    GROUP BY
        Delivery_Status,
        Sort_Order
)

SELECT
    Delivery_Status,
    Shipments,

    CAST(
        100.0 * Shipments
        / SUM(Shipments) OVER ()
        AS DECIMAL(8,2)
    ) AS Shipment_Share_Pct,

    Shipped_Qty,

    CAST(
        Avg_Delay_Days
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days

FROM DeliverySummary

ORDER BY Sort_Order;




-- ============================================================
-- Step 4: Late Shipment Severity Analysis
-- Valid chronology shipments only
-- ============================================================

WITH LateShipments AS
(
    SELECT
        shipment_id,
        shipped_qty,
        delivery_delay_days,

        CASE
            WHEN delivery_delay_days BETWEEN 1 AND 2
                THEN '1-2 Days Late'

            WHEN delivery_delay_days BETWEEN 3 AND 5
                THEN '3-5 Days Late'

            ELSE '6+ Days Late'
        END AS Delay_Severity

    FROM raw.Shipments

    WHERE actual_delivery_date >= shipment_date
      AND delivery_delay_days > 0
)

SELECT
    Delay_Severity,

    COUNT(*) AS Late_Shipments,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Late_Shipment_Share_Pct,

    SUM(shipped_qty) AS Shipped_Qty,

    CAST(
        AVG(1.0 * delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    MAX(delivery_delay_days) AS Max_Delay_Days

FROM LateShipments

GROUP BY
    Delay_Severity

ORDER BY
    CASE Delay_Severity
        WHEN '1-2 Days Late' THEN 1
        WHEN '3-5 Days Late' THEN 2
        WHEN '6+ Days Late' THEN 3
    END;



-- ============================================================
-- Step 5: Yearly Delivery Performance
-- Valid chronology shipments only
-- ============================================================

SELECT
    YEAR(shipment_date) AS Shipment_Year,

    COUNT(*) AS Total_Shipments,

    SUM(shipped_qty) AS Shipped_Qty,

    SUM(
        CASE WHEN on_time_flag = 1
        THEN 1 ELSE 0 END
    ) AS On_Time_Shipments,

    CAST(
        100.0 *
        SUM(CASE WHEN on_time_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS On_Time_Rate_Pct,

    SUM(
        CASE WHEN otif_flag = 1
        THEN 1 ELSE 0 END
    ) AS OTIF_Shipments,

    CAST(
        100.0 *
        SUM(CASE WHEN otif_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS OTIF_Rate_Pct,

    CAST(
        AVG(1.0 * delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days

FROM raw.Shipments

WHERE actual_delivery_date >= shipment_date

GROUP BY
    YEAR(shipment_date)

ORDER BY
    Shipment_Year;

-- ============================================================
-- Step 6: Delivery Performance by Warehouse
-- Valid chronology shipments only
-- ============================================================

SELECT
    w.warehouse_id,
    w.warehouse_name,

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

INNER JOIN raw.Warehouses AS w
    ON s.warehouse_id = w.warehouse_id

WHERE s.actual_delivery_date >= s.shipment_date

GROUP BY
    w.warehouse_id,
    w.warehouse_name

ORDER BY
    On_Time_Rate_Pct DESC;


-- ============================================================
-- Step 7: Delivery Performance by Order Priority
-- Valid chronology shipments only
-- ============================================================

SELECT
    so.priority,

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
        SUM(CASE WHEN s.on_time_flag = 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Late_Rate_Pct,

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
    so.priority

ORDER BY
    CASE so.priority
        WHEN 'Urgent' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Normal' THEN 3
        WHEN 'Low' THEN 4
        ELSE 5
    END;


-- ============================================================
-- Step 8: Delivery Performance by Sales Channel
-- Valid chronology shipments only
-- ============================================================

SELECT
    so.sales_channel,

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
        SUM(CASE WHEN s.on_time_flag = 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Late_Rate_Pct,

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
    so.sales_channel

ORDER BY
    On_Time_Rate_Pct DESC;


-- ============================================================
-- Step 9: Delivery Performance by Customer Region
-- Valid chronology shipments only
-- ============================================================

SELECT
    c.region,

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
        SUM(CASE WHEN s.on_time_flag = 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Late_Rate_Pct,

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

INNER JOIN raw.Customers AS c
    ON so.customer_id = c.customer_id

WHERE s.actual_delivery_date >= s.shipment_date

GROUP BY
    c.region

ORDER BY
    On_Time_Rate_Pct DESC;



-- ============================================================
-- Step 10: OTIF Performance Breakdown
-- Valid chronology shipments only
-- ============================================================

SELECT
    CASE
        WHEN s.on_time_flag = 1
             AND s.otif_flag = 1
            THEN 'On-Time & In-Full'

        WHEN s.on_time_flag = 1
             AND s.otif_flag = 0
            THEN 'On-Time but Not In-Full'

        ELSE 'Late & Not OTIF'
    END AS OTIF_Status,

    COUNT(*) AS Shipments,

    SUM(s.shipped_qty) AS Shipped_Qty,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Shipment_Share_Pct

FROM raw.Shipments AS s

WHERE s.actual_delivery_date >= s.shipment_date

GROUP BY
    CASE
        WHEN s.on_time_flag = 1
             AND s.otif_flag = 1
            THEN 'On-Time & In-Full'

        WHEN s.on_time_flag = 1
             AND s.otif_flag = 0
            THEN 'On-Time but Not In-Full'

        ELSE 'Late & Not OTIF'
    END

ORDER BY
    Shipment_Share_Pct DESC;



-- ============================================================
-- Step 11: In-Full Performance Among On-Time Shipments
-- Valid chronology + On-Time shipments only
-- ============================================================

SELECT
    COUNT(*) AS On_Time_Shipments,

    SUM(
        CASE
            WHEN otif_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS On_Time_And_In_Full,

    SUM(
        CASE
            WHEN otif_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS On_Time_But_Not_In_Full,

    CAST(
        100.0 *
        SUM(CASE WHEN otif_flag = 1 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS In_Full_Rate_Among_On_Time_Pct,

    CAST(
        100.0 *
        SUM(CASE WHEN otif_flag = 0 THEN 1 ELSE 0 END)
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Not_In_Full_Rate_Among_On_Time_Pct

FROM raw.Shipments

WHERE actual_delivery_date >= shipment_date
  AND on_time_flag = 1;

-- ============================================================
-- Step 12: Severe Delay Analysis by Warehouse
-- Severe Delay = 6+ Days Late
-- Valid chronology shipments only
-- ============================================================

SELECT
    w.warehouse_id,
    w.warehouse_name,

    COUNT(*) AS Severe_Delay_Shipments,

    SUM(s.shipped_qty) AS Shipped_Qty,

    CAST(
        AVG(1.0 * s.delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Severe_Delay_Days,

    MAX(s.delivery_delay_days) AS Max_Delay_Days,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Severe_Delay_Share_Pct

FROM raw.Shipments AS s

INNER JOIN raw.Warehouses AS w
    ON s.warehouse_id = w.warehouse_id

WHERE s.actual_delivery_date >= s.shipment_date
  AND s.delivery_delay_days >= 6

GROUP BY
    w.warehouse_id,
    w.warehouse_name

ORDER BY
    Severe_Delay_Shipments DESC;



-- ============================================================
-- Step 13: Severe Delay Analysis by Order Priority
-- Severe Delay = 6+ Days Late
-- Valid chronology shipments only
-- ============================================================

SELECT
    so.priority,

    COUNT(*) AS Severe_Delay_Shipments,

    SUM(s.shipped_qty) AS Shipped_Qty,

    CAST(
        AVG(1.0 * s.delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Severe_Delay_Days,

    MAX(s.delivery_delay_days) AS Max_Delay_Days,

    CAST(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER ()
        AS DECIMAL(8,2)
    ) AS Severe_Delay_Share_Pct

FROM raw.Shipments AS s

INNER JOIN raw.Sales_Orders AS so
    ON s.order_id = so.order_id

WHERE s.actual_delivery_date >= s.shipment_date
  AND s.delivery_delay_days >= 6

GROUP BY
    so.priority

ORDER BY
    CASE so.priority
        WHEN 'Urgent' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Normal' THEN 3
        WHEN 'Low' THEN 4
        ELSE 5
    END;


-- ============================================================
-- Step 14: Severe Delay Rate by Order Priority
-- Severe Delay = 6+ Days Late
-- Valid chronology shipments only
-- ============================================================

SELECT
    so.priority,

    COUNT(*) AS Total_Shipments,

    SUM(
        CASE
            WHEN s.delivery_delay_days >= 6
            THEN 1
            ELSE 0
        END
    ) AS Severe_Delay_Shipments,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN s.delivery_delay_days >= 6
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Severe_Delay_Rate_Pct,

    CAST(
        AVG(1.0 * s.delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days

FROM raw.Shipments AS s

INNER JOIN raw.Sales_Orders AS so
    ON s.order_id = so.order_id

WHERE s.actual_delivery_date >= s.shipment_date

GROUP BY
    so.priority

ORDER BY
    Severe_Delay_Rate_Pct DESC;



-- ============================================================
-- Step 15: Monthly Delivery Performance Trend
-- Valid chronology shipments only
-- ============================================================

SELECT
    YEAR(shipment_date) AS Shipment_Year,

    MONTH(shipment_date) AS Month_No,

    DATENAME(MONTH, shipment_date) AS Month_Name,

    COUNT(*) AS Total_Shipments,

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
    ) AS OTIF_Rate_Pct,

    CAST(
        AVG(1.0 * delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    SUM(
        CASE
            WHEN delivery_delay_days >= 6
            THEN 1
            ELSE 0
        END
    ) AS Severe_Delay_Shipments

FROM raw.Shipments

WHERE actual_delivery_date >= shipment_date

GROUP BY
    YEAR(shipment_date),
    MONTH(shipment_date),
    DATENAME(MONTH, shipment_date)

ORDER BY
    Shipment_Year,
    Month_No;




-- ============================================================
-- Step 16: Comparable Jan-Sep Delivery Performance
-- Valid chronology shipments only
-- ============================================================

SELECT
    YEAR(shipment_date) AS Shipment_Year,

    COUNT(*) AS Total_Shipments,

    SUM(shipped_qty) AS Shipped_Qty,

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
    ) AS OTIF_Rate_Pct,

    CAST(
        AVG(1.0 * delivery_delay_days)
        AS DECIMAL(8,2)
    ) AS Avg_Delay_Days,

    SUM(
        CASE
            WHEN delivery_delay_days >= 6
            THEN 1
            ELSE 0
        END
    ) AS Severe_Delay_Shipments,

    CAST(
        100.0 *
        SUM(
            CASE
                WHEN delivery_delay_days >= 6
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*)
        AS DECIMAL(8,2)
    ) AS Severe_Delay_Rate_Pct

FROM raw.Shipments

WHERE actual_delivery_date >= shipment_date
  AND MONTH(shipment_date) BETWEEN 1 AND 9

GROUP BY
    YEAR(shipment_date)

ORDER BY
    Shipment_Year;