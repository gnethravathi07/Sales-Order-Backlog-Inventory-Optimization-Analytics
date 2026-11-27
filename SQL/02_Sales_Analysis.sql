-- ============================================================
-- SALES ORDER, BACKLOG & INVENTORY ANALYTICS
-- File: 02_Sales_Analysis.sql
-- Purpose: Analyze sales performance, trends, customers,
--          products, categories, channels and profitability
-- ============================================================

USE Sales_Order_Backlog_Inventory_Analytics;
GO

-- ============================================================
-- Step 1: Validate Sales Analysis Source Tables
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM raw.Sales_Orders)
        AS Sales_Order_Rows,

    (SELECT COUNT(*) FROM raw.Sales_Order_Items)
        AS Sales_Order_Item_Rows,

    (SELECT COUNT(*) FROM raw.Customers)
        AS Customer_Rows,

    (SELECT COUNT(*) FROM raw.Products)
        AS Product_Rows;


-- ============================================================
-- Step 2: Overall Sales KPI Summary
-- ============================================================

SELECT
    COUNT(*) AS Total_Orders,
    COUNT(DISTINCT customer_id) AS Unique_Customers,
    SUM(ordered_qty) AS Total_Units_Ordered,
    CAST(SUM(order_value) AS DECIMAL(18,2)) AS Total_Sales_Value,

    CAST(
        AVG(order_value)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value,

    CAST(
        AVG(CAST(ordered_qty AS DECIMAL(18,2)))
        AS DECIMAL(18,2)
    ) AS Average_Units_Per_Order

FROM raw.Sales_Orders;


-- ============================================================
-- Step 3: Yearly Sales Performance
-- ============================================================

SELECT
    YEAR(order_date) AS Sales_Year,

    COUNT(*) AS Total_Orders,

    SUM(ordered_qty) AS Total_Units,

    CAST(
        SUM(order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        AVG(order_value)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value

FROM raw.Sales_Orders

GROUP BY
    YEAR(order_date)

ORDER BY
    Sales_Year;

-- ============================================================
-- Step 4: Comparable Jan–Sep Sales Performance
-- ============================================================

SELECT
    YEAR(order_date) AS Sales_Year,

    COUNT(*) AS Total_Orders,

    SUM(ordered_qty) AS Total_Units,

    CAST(
        SUM(order_value)
        AS DECIMAL(18,2)
    ) AS Jan_Sep_Sales_Value,

    CAST(
        AVG(order_value)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value

FROM raw.Sales_Orders

WHERE MONTH(order_date) BETWEEN 1 AND 9

GROUP BY
    YEAR(order_date)

ORDER BY
    Sales_Year;

-- ============================================================
-- Step 5: Jan–Sep Year-over-Year Sales Growth
-- ============================================================

WITH JanSepSales AS
(
    SELECT
        YEAR(order_date) AS Sales_Year,
        SUM(order_value) AS Sales_Value
    FROM raw.Sales_Orders
    WHERE MONTH(order_date) BETWEEN 1 AND 9
    GROUP BY YEAR(order_date)
),

SalesGrowth AS
(
    SELECT
        Sales_Year,
        Sales_Value,

        LAG(Sales_Value) OVER (
            ORDER BY Sales_Year
        ) AS Previous_Year_Sales

    FROM JanSepSales
)

SELECT
    Sales_Year,

    CAST(Sales_Value AS DECIMAL(18,2))
        AS Jan_Sep_Sales,

    CAST(Previous_Year_Sales AS DECIMAL(18,2))
        AS Previous_Year_Sales,

    CAST(
        ((Sales_Value - Previous_Year_Sales)
        / NULLIF(Previous_Year_Sales, 0)) * 100
        AS DECIMAL(8,2)
    ) AS YoY_Growth_Pct

FROM SalesGrowth

ORDER BY Sales_Year;

-- ============================================================
-- Step 6: Monthly Sales Trend
-- ============================================================

SELECT
    YEAR(order_date) AS Sales_Year,
    MONTH(order_date) AS Month_No,
    DATENAME(MONTH, order_date) AS Month_Name,

    COUNT(*) AS Total_Orders,

    SUM(ordered_qty) AS Total_Units,

    CAST(
        SUM(order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        AVG(order_value)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value

FROM raw.Sales_Orders

GROUP BY
    YEAR(order_date),
    MONTH(order_date),
    DATENAME(MONTH, order_date)

ORDER BY
    Sales_Year,
    Month_No;


-- ============================================================
-- Step 7: Top 10 Sales Months
-- ============================================================

WITH MonthlySales AS
(
    SELECT
        YEAR(order_date) AS Sales_Year,
        MONTH(order_date) AS Month_No,
        DATENAME(MONTH, order_date) AS Month_Name,
        COUNT(*) AS Total_Orders,
        SUM(ordered_qty) AS Total_Units,
        SUM(order_value) AS Total_Sales_Value
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
        RANK() OVER (
            ORDER BY Total_Sales_Value DESC
        ) AS Sales_Rank
    FROM MonthlySales
)

SELECT TOP 10
    Sales_Rank,
    Sales_Year,
    Month_No,
    Month_Name,
    Total_Orders,
    Total_Units,
    CAST(Total_Sales_Value AS DECIMAL(18,2))
        AS Total_Sales_Value
FROM RankedMonths
ORDER BY Sales_Rank;


-- ============================================================
-- Step 8: Sales Performance by Sales Channel
-- ============================================================

SELECT
    sales_channel,

    COUNT(*) AS Total_Orders,

    SUM(ordered_qty) AS Total_Units,

    CAST(
        SUM(order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        AVG(order_value)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value,

    CAST(
        100.0 * SUM(order_value)
        / SUM(SUM(order_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Sales_Share_Pct

FROM raw.Sales_Orders

GROUP BY sales_channel

ORDER BY Total_Sales_Value DESC;

-- ============================================================
-- Step 9: Sales Performance by Customer Segment
-- ============================================================

SELECT
    c.customer_segment,

    COUNT(DISTINCT so.order_id) AS Total_Orders,

    COUNT(DISTINCT so.customer_id) AS Unique_Customers,

    SUM(so.ordered_qty) AS Total_Units,

    CAST(
        SUM(so.order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        AVG(so.order_value)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value,

    CAST(
        100.0 * SUM(so.order_value)
        / SUM(SUM(so.order_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Sales_Share_Pct

FROM raw.Sales_Orders AS so

INNER JOIN raw.Customers AS c
    ON so.customer_id = c.customer_id

GROUP BY
    c.customer_segment

ORDER BY
    Total_Sales_Value DESC;


-- ============================================================
-- Step 10: Sales Performance by Region
-- ============================================================

SELECT
    c.region,

    COUNT(DISTINCT so.order_id) AS Total_Orders,

    COUNT(DISTINCT so.customer_id) AS Unique_Customers,

    SUM(so.ordered_qty) AS Total_Units,

    CAST(
        SUM(so.order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        AVG(so.order_value)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value,

    CAST(
        100.0 * SUM(so.order_value)
        / SUM(SUM(so.order_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Sales_Share_Pct

FROM raw.Sales_Orders AS so

INNER JOIN raw.Customers AS c
    ON so.customer_id = c.customer_id

GROUP BY
    c.region

ORDER BY
    Total_Sales_Value DESC;

-- ============================================================
-- Step 11: Sales Performance by Product Category
-- ============================================================

SELECT
    p.category,

    COUNT(DISTINCT soi.order_id) AS Total_Orders,

    COUNT(DISTINCT soi.product_id) AS Unique_Products,

    SUM(soi.ordered_qty) AS Total_Units,

    CAST(
        SUM(soi.net_order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        100.0 * SUM(soi.net_order_value)
        / SUM(SUM(soi.net_order_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Sales_Share_Pct

FROM raw.Sales_Order_Items AS soi

INNER JOIN raw.Products AS p
    ON soi.product_id = p.product_id

GROUP BY
    p.category

ORDER BY
    Total_Sales_Value DESC;


-- ============================================================
-- Step 12: Top 10 Products by Sales Value
-- ============================================================

WITH ProductSales AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(soi.ordered_qty) AS Total_Units,

        SUM(soi.net_order_value) AS Total_Sales_Value

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
            ORDER BY Total_Sales_Value DESC
        ) AS Sales_Rank

    FROM ProductSales
)

SELECT TOP 10
    Sales_Rank,
    product_id,
    product_name,
    category,
    Total_Units,

    CAST(
        Total_Sales_Value
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value

FROM RankedProducts

ORDER BY
    Sales_Rank,
    product_id;


-- ============================================================
-- Step 13: Category Profitability Analysis
-- ============================================================

SELECT
    p.category,

    CAST(
        SUM(soi.net_order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        SUM(soi.fulfilled_qty * p.unit_cost)
        AS DECIMAL(18,2)
    ) AS Total_Cost,

    CAST(
        SUM(
            soi.net_order_value
            - (soi.fulfilled_qty * p.unit_cost)
        )
        AS DECIMAL(18,2)
    ) AS Gross_Profit,

    CAST(
        100.0 *
        SUM(
            soi.net_order_value
            - (soi.fulfilled_qty * p.unit_cost)
        )
        / NULLIF(SUM(soi.net_order_value), 0)
        AS DECIMAL(8,2)
    ) AS Profit_Margin_Pct

FROM raw.Sales_Order_Items AS soi

INNER JOIN raw.Products AS p
    ON soi.product_id = p.product_id

GROUP BY
    p.category

ORDER BY
    Gross_Profit DESC;

-- ============================================================
-- Step 13A: Correct Category Profitability Analysis
-- ============================================================

SELECT
    p.category,

    CAST(
        SUM(soi.net_order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        SUM(soi.ordered_qty * p.unit_cost)
        AS DECIMAL(18,2)
    ) AS Total_Cost,

    CAST(
        SUM(
            soi.net_order_value
            - (soi.ordered_qty * p.unit_cost)
        )
        AS DECIMAL(18,2)
    ) AS Gross_Profit,

    CAST(
        100.0 *
        SUM(
            soi.net_order_value
            - (soi.ordered_qty * p.unit_cost)
        )
        / NULLIF(SUM(soi.net_order_value), 0)
        AS DECIMAL(8,2)
    ) AS Profit_Margin_Pct

FROM raw.Sales_Order_Items AS soi

INNER JOIN raw.Products AS p
    ON soi.product_id = p.product_id

GROUP BY
    p.category

ORDER BY
    Gross_Profit DESC;


-- ============================================================
-- Step 14: Overall Profitability KPIs
-- ============================================================

SELECT
    CAST(
        SUM(soi.net_order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        SUM(soi.ordered_qty * p.unit_cost)
        AS DECIMAL(18,2)
    ) AS Total_Cost,

    CAST(
        SUM(
            soi.net_order_value
            - (soi.ordered_qty * p.unit_cost)
        )
        AS DECIMAL(18,2)
    ) AS Total_Gross_Profit,

    CAST(
        100.0 *
        SUM(
            soi.net_order_value
            - (soi.ordered_qty * p.unit_cost)
        )
        / NULLIF(SUM(soi.net_order_value), 0)
        AS DECIMAL(8,2)
    ) AS Gross_Profit_Margin_Pct

FROM raw.Sales_Order_Items AS soi

INNER JOIN raw.Products AS p
    ON soi.product_id = p.product_id;

-- ============================================================
-- Step 15: Profitability by Discount Level
-- ============================================================

SELECT
    CAST(discount_pct * 100 AS DECIMAL(8,0))
        AS Discount_Pct,

    COUNT(*) AS Total_Order_Lines,

    CAST(
        SUM(net_order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        SUM(
            net_order_value -
            (ordered_qty * p.unit_cost)
        )
        AS DECIMAL(18,2)
    ) AS Gross_Profit,

    CAST(
        100.0 *
        SUM(
            net_order_value -
            (ordered_qty * p.unit_cost)
        )
        / NULLIF(SUM(net_order_value), 0)
        AS DECIMAL(8,2)
    ) AS Profit_Margin_Pct

FROM raw.Sales_Order_Items AS soi

INNER JOIN raw.Products AS p
    ON soi.product_id = p.product_id

GROUP BY
    discount_pct

ORDER BY
    discount_pct;


-- ============================================================
-- Step 16: Identify Loss-Making Sales Lines
-- ============================================================

WITH LineProfit AS
(
    SELECT
        soi.order_item_id,
        soi.order_id,
        soi.product_id,
        soi.discount_pct,
        soi.net_order_value,

        (soi.ordered_qty * p.unit_cost)
            AS Line_Cost,

        soi.net_order_value
        - (soi.ordered_qty * p.unit_cost)
            AS Gross_Profit

    FROM raw.Sales_Order_Items AS soi

    INNER JOIN raw.Products AS p
        ON soi.product_id = p.product_id
)

SELECT
    COUNT(*) AS Loss_Making_Lines,

    CAST(
        SUM(Gross_Profit)
        AS DECIMAL(18,2)
    ) AS Total_Gross_Loss,

    CAST(
        AVG(Gross_Profit)
        AS DECIMAL(18,2)
    ) AS Average_Loss_Per_Line

FROM LineProfit

WHERE Gross_Profit < 0;


-- ============================================================
-- Step 17: Loss-Making Lines by Discount Level
-- ============================================================

WITH LineProfit AS
(
    SELECT
        soi.order_item_id,
        soi.discount_pct,

        soi.net_order_value
        - (soi.ordered_qty * p.unit_cost)
            AS Gross_Profit

    FROM raw.Sales_Order_Items AS soi

    INNER JOIN raw.Products AS p
        ON soi.product_id = p.product_id
)

SELECT
    CAST(discount_pct * 100 AS DECIMAL(8,0))
        AS Discount_Pct,

    COUNT(*) AS Loss_Making_Lines,

    CAST(
        SUM(Gross_Profit)
        AS DECIMAL(18,2)
    ) AS Total_Gross_Loss,

    CAST(
        AVG(Gross_Profit)
        AS DECIMAL(18,2)
    ) AS Average_Loss_Per_Line

FROM LineProfit

WHERE Gross_Profit < 0

GROUP BY
    discount_pct

ORDER BY
    discount_pct;


-- ============================================================
-- Step 18: Top 10 Customers by Sales Value
-- ============================================================

WITH CustomerSales AS
(
    SELECT
        c.customer_id,
        c.customer_name,
        c.customer_segment,
        c.region,

        COUNT(so.order_id) AS Total_Orders,

        SUM(so.order_value) AS Total_Sales_Value

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
            ORDER BY Total_Sales_Value DESC
        ) AS Sales_Rank,

        100.0 * Total_Sales_Value
        / SUM(Total_Sales_Value) OVER ()
            AS Sales_Share_Pct

    FROM CustomerSales
)

SELECT TOP 10
    Sales_Rank,
    customer_id,
    customer_name,
    customer_segment,
    region,
    Total_Orders,

    CAST(Total_Sales_Value AS DECIMAL(18,2))
        AS Total_Sales_Value,

    CAST(Sales_Share_Pct AS DECIMAL(8,2))
        AS Sales_Share_Pct

FROM RankedCustomers

ORDER BY
    Sales_Rank,
    customer_id;


-- ============================================================
-- Step 19: Top 10 Customer Sales Concentration
-- ============================================================

WITH CustomerSales AS
(
    SELECT
        customer_id,
        SUM(order_value) AS Customer_Sales
    FROM raw.Sales_Orders
    GROUP BY customer_id
),

RankedCustomers AS
(
    SELECT
        customer_id,
        Customer_Sales,

        ROW_NUMBER() OVER (
            ORDER BY Customer_Sales DESC
        ) AS Customer_Rank

    FROM CustomerSales
)

SELECT
    CAST(
        SUM(
            CASE
                WHEN Customer_Rank <= 10
                THEN Customer_Sales
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Top_10_Customer_Sales,

    CAST(
        SUM(
            CASE
                WHEN Customer_Rank <= 10
                THEN Customer_Sales
                ELSE 0
            END
        )
        * 100.0
        / SUM(Customer_Sales)
        AS DECIMAL(8,2)
    ) AS Top_10_Sales_Share_Pct

FROM RankedCustomers;

-- ============================================================
-- Step 20: Top 10 Product Sales Concentration
-- ============================================================

WITH ProductSales AS
(
    SELECT
        product_id,
        SUM(net_order_value) AS Product_Sales
    FROM raw.Sales_Order_Items
    GROUP BY product_id
),

RankedProducts AS
(
    SELECT
        product_id,
        Product_Sales,

        ROW_NUMBER() OVER (
            ORDER BY Product_Sales DESC
        ) AS Product_Rank

    FROM ProductSales
)

SELECT
    CAST(
        SUM(
            CASE
                WHEN Product_Rank <= 10
                THEN Product_Sales
                ELSE 0
            END
        )
        AS DECIMAL(18,2)
    ) AS Top_10_Product_Sales,

    CAST(
        SUM(
            CASE
                WHEN Product_Rank <= 10
                THEN Product_Sales
                ELSE 0
            END
        ) * 100.0
        / SUM(Product_Sales)
        AS DECIMAL(8,2)
    ) AS Top_10_Product_Sales_Share_Pct

FROM RankedProducts;


-- ============================================================
-- Step 21: Top 10 Products by Gross Profit
-- ============================================================

WITH ProductProfit AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(soi.net_order_value) AS Total_Sales_Value,

        SUM(
            soi.net_order_value
            - (soi.ordered_qty * p.unit_cost)
        ) AS Gross_Profit

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
            ORDER BY Gross_Profit DESC
        ) AS Profit_Rank

    FROM ProductProfit
)

SELECT TOP 10
    Profit_Rank,
    product_id,
    product_name,
    category,

    CAST(
        Total_Sales_Value
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        Gross_Profit
        AS DECIMAL(18,2)
    ) AS Gross_Profit,

    CAST(
        100.0 * Gross_Profit
        / NULLIF(Total_Sales_Value, 0)
        AS DECIMAL(8,2)
    ) AS Profit_Margin_Pct

FROM RankedProducts

ORDER BY
    Profit_Rank,
    product_id;


-- ============================================================
-- Step 22: Sales Performance by Order Priority
-- ============================================================

SELECT
    priority,

    COUNT(*) AS Total_Orders,

    SUM(ordered_qty) AS Total_Units,

    CAST(
        SUM(order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        AVG(order_value)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value,

    CAST(
        100.0 * SUM(order_value)
        / SUM(SUM(order_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Sales_Share_Pct

FROM raw.Sales_Orders

GROUP BY
    priority

ORDER BY
    Total_Sales_Value DESC;

-- ============================================================
-- Step 23: Sales Performance by Order Status
-- ============================================================

SELECT
    order_status,

    COUNT(*) AS Total_Orders,

    SUM(ordered_qty) AS Total_Units_Ordered,

    SUM(fulfilled_qty) AS Total_Units_Fulfilled,

    SUM(backlog_qty) AS Total_Backlog_Units,

    CAST(
        SUM(order_value)
        AS DECIMAL(18,2)
    ) AS Total_Order_Value,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Total_Backlog_Value,

    CAST(
        100.0 * SUM(order_value)
        / SUM(SUM(order_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Order_Value_Share_Pct

FROM raw.Sales_Orders

GROUP BY
    order_status

ORDER BY
    Total_Order_Value DESC;

-- ============================================================
-- Step 24: Yearly Sales Contribution
-- ============================================================

SELECT
    YEAR(order_date) AS Sales_Year,

    COUNT(*) AS Total_Orders,

    CAST(
        SUM(order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        100.0 * SUM(order_value)
        / SUM(SUM(order_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Sales_Contribution_Pct

FROM raw.Sales_Orders

GROUP BY
    YEAR(order_date)

ORDER BY
    Sales_Year;

-- ============================================================
-- Step 25: Category Sales Ranking
-- ============================================================

WITH CategorySales AS
(
    SELECT
        p.category,

        SUM(soi.net_order_value) AS Total_Sales_Value,

        SUM(soi.ordered_qty) AS Total_Units

    FROM raw.Sales_Order_Items AS soi

    INNER JOIN raw.Products AS p
        ON soi.product_id = p.product_id

    GROUP BY
        p.category
)

SELECT
    DENSE_RANK() OVER (
        ORDER BY Total_Sales_Value DESC
    ) AS Sales_Rank,

    category,

    Total_Units,

    CAST(
        Total_Sales_Value
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        100.0 * Total_Sales_Value
        / SUM(Total_Sales_Value) OVER ()
        AS DECIMAL(8,2)
    ) AS Sales_Share_Pct

FROM CategorySales

ORDER BY
    Sales_Rank;


-- ============================================================
-- Step 26: Bottom 10 Products by Sales Value
-- ============================================================

WITH ProductSales AS
(
    SELECT
        p.product_id,
        p.product_name,
        p.category,

        SUM(soi.ordered_qty) AS Total_Units,

        SUM(soi.net_order_value) AS Total_Sales_Value

    FROM raw.Products AS p

    INNER JOIN raw.Sales_Order_Items AS soi
        ON p.product_id = soi.product_id

    GROUP BY
        p.product_id,
        p.product_name,
        p.category
)

SELECT TOP 10
    product_id,
    product_name,
    category,
    Total_Units,

    CAST(
        Total_Sales_Value
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value

FROM ProductSales

ORDER BY
    Total_Sales_Value ASC,
    product_id;


-- ============================================================
-- Step 27: Identify Products With No Sales
-- ============================================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.subcategory

FROM raw.Products AS p

LEFT JOIN raw.Sales_Order_Items AS soi
    ON p.product_id = soi.product_id

WHERE soi.product_id IS NULL

ORDER BY
    p.product_id;


-- ============================================================
-- Step 28: Sales Performance by Warehouse
-- ============================================================

SELECT
    w.warehouse_id,
    w.warehouse_name,
    w.region,

    COUNT(so.order_id) AS Total_Orders,

    SUM(so.ordered_qty) AS Total_Units,

    CAST(
        SUM(so.order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        AVG(so.order_value)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value,

    CAST(
        100.0 * SUM(so.order_value)
        / SUM(SUM(so.order_value)) OVER ()
        AS DECIMAL(8,2)
    ) AS Sales_Share_Pct

FROM raw.Sales_Orders AS so

INNER JOIN raw.Warehouses AS w
    ON so.warehouse_id = w.warehouse_id

GROUP BY
    w.warehouse_id,
    w.warehouse_name,
    w.region

ORDER BY
    Total_Sales_Value DESC;

-- ============================================================
-- Step 29: Sales Reconciliation Validation
-- ============================================================

SELECT
    CAST(
        (SELECT SUM(order_value)
         FROM raw.Sales_Orders)
        AS DECIMAL(18,2)
    ) AS Order_Level_Sales,

    CAST(
        (SELECT SUM(net_order_value)
         FROM raw.Sales_Order_Items)
        AS DECIMAL(18,2)
    ) AS Item_Level_Sales,

    CAST(
        (SELECT SUM(order_value)
         FROM raw.Sales_Orders)
        -
        (SELECT SUM(net_order_value)
         FROM raw.Sales_Order_Items)
        AS DECIMAL(18,2)
    ) AS Sales_Difference,

    (SELECT SUM(ordered_qty)
     FROM raw.Sales_Orders)
        AS Order_Level_Units,

    (SELECT SUM(ordered_qty)
     FROM raw.Sales_Order_Items)
        AS Item_Level_Units,

    (SELECT SUM(ordered_qty)
     FROM raw.Sales_Orders)
    -
    (SELECT SUM(ordered_qty)
     FROM raw.Sales_Order_Items)
        AS Units_Difference;

-- ============================================================
-- Step 30: Final Sales Analysis Validation
-- ============================================================

DECLARE @SalesValidation TABLE
(
    Validation_Check VARCHAR(100),
    Status VARCHAR(10)
);

INSERT INTO @SalesValidation
VALUES

('Total Orders',
 CASE WHEN (SELECT COUNT(*) FROM raw.Sales_Orders) = 25000
      THEN 'PASS' ELSE 'FAIL' END),

('Unique Customers',
 CASE WHEN (SELECT COUNT(DISTINCT customer_id)
                 FROM raw.Sales_Orders) = 2500
      THEN 'PASS' ELSE 'FAIL' END),

('Total Ordered Units',
 CASE WHEN (SELECT SUM(ordered_qty)
                 FROM raw.Sales_Orders) = 501755
      THEN 'PASS' ELSE 'FAIL' END),

('Order vs Item Units',
 CASE WHEN
      (SELECT SUM(ordered_qty) FROM raw.Sales_Orders)
      =
      (SELECT SUM(ordered_qty) FROM raw.Sales_Order_Items)
      THEN 'PASS' ELSE 'FAIL' END),

('Order vs Item Sales Within Tolerance',
 CASE WHEN ABS(
      (SELECT SUM(order_value) FROM raw.Sales_Orders)
      -
      (SELECT SUM(net_order_value) FROM raw.Sales_Order_Items)
      ) <= 2.00
      THEN 'PASS' ELSE 'FAIL' END),

('All Products Have Sales',
 CASE WHEN NOT EXISTS
 (
     SELECT 1
     FROM raw.Products AS p
     LEFT JOIN raw.Sales_Order_Items AS soi
         ON p.product_id = soi.product_id
     WHERE soi.product_id IS NULL
 )
 THEN 'PASS' ELSE 'FAIL' END),

('Loss Making Lines',
 CASE WHEN
 (
     SELECT COUNT(*)
     FROM raw.Sales_Order_Items AS soi
     INNER JOIN raw.Products AS p
         ON soi.product_id = p.product_id
     WHERE soi.net_order_value
           - (soi.ordered_qty * p.unit_cost) < 0
 ) = 500
 THEN 'PASS' ELSE 'FAIL' END);

-- Detailed checks
SELECT *
FROM @SalesValidation;

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
    END AS Final_Sales_Analysis_Status

FROM @SalesValidation;

