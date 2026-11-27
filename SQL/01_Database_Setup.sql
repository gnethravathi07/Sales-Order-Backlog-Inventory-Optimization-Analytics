/*
============================================================
PROJECT: Sales Order, Backlog & Inventory Analytics
FILE: 01_Database_Setup.sql
PURPOSE:
    Create and initialize the SQL database used for the
    Sales Order, Backlog & Inventory Analytics project.
============================================================
*/

-- Step 1: Create Project Database

IF DB_ID('Sales_Order_Backlog_Inventory_Analytics') IS NULL
BEGIN
    CREATE DATABASE Sales_Order_Backlog_Inventory_Analytics;
END;
GO

USE Sales_Order_Backlog_Inventory_Analytics;
GO

SELECT DB_NAME() AS Current_Database;


-- ============================================================
-- Step 2: Create Project Schemas
-- ============================================================

-- Raw/source tables
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'raw'
)
BEGIN
    EXEC('CREATE SCHEMA raw');
END;
GO


-- Analytical/reporting objects
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'analytics'
)
BEGIN
    EXEC('CREATE SCHEMA analytics');
END;
GO


-- Verify schemas

SELECT
    name AS Schema_Name
FROM sys.schemas
WHERE name IN ('raw', 'analytics')
ORDER BY name;


-- ============================================================
-- Step 3: Create Customers Table
-- ============================================================

IF OBJECT_ID('raw.Customers', 'U') IS NOT NULL
    DROP TABLE raw.Customers;
GO

CREATE TABLE raw.Customers
(
    customer_id       VARCHAR(20)   NOT NULL,
    customer_name     VARCHAR(150)  NOT NULL,
    customer_segment  VARCHAR(50)   NOT NULL,
    region            VARCHAR(50)   NOT NULL,
    credit_tier       VARCHAR(20)   NOT NULL,
    customer_since    DATE          NOT NULL,

    CONSTRAINT PK_Customers
        PRIMARY KEY (customer_id)
);
GO


-- Verify table structure

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'Customers'
ORDER BY ORDINAL_POSITION;


-- ============================================================
-- Step 4: Create Products Table
-- ============================================================

IF OBJECT_ID('raw.Products', 'U') IS NOT NULL
    DROP TABLE raw.Products;
GO

CREATE TABLE raw.Products
(
    product_id            VARCHAR(20)    NOT NULL,
    product_name          VARCHAR(150)   NOT NULL,
    category              VARCHAR(100)   NOT NULL,
    subcategory           VARCHAR(100)   NOT NULL,
    supplier_id           VARCHAR(20)    NOT NULL,
    unit_cost             DECIMAL(18,2)  NOT NULL,
    unit_price            DECIMAL(18,2)  NOT NULL,
    base_monthly_demand   DECIMAL(18,2)  NOT NULL,
    shelf_life_days       INT            NOT NULL,
    active_flag           VARCHAR(10)    NOT NULL,

    CONSTRAINT PK_Products
        PRIMARY KEY (product_id)
);
GO


-- Verify table structure

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'Products'
ORDER BY ORDINAL_POSITION;


-- ============================================================
-- Step 5: Create Suppliers Table
-- ============================================================

IF OBJECT_ID('raw.Suppliers', 'U') IS NOT NULL
    DROP TABLE raw.Suppliers;
GO

CREATE TABLE raw.Suppliers
(
    supplier_id                 VARCHAR(20)    NOT NULL,
    supplier_name               VARCHAR(150)   NOT NULL,
    supplier_region             VARCHAR(50)    NOT NULL,
    contract_lead_time_days     INT            NOT NULL,
    quality_rating              DECIMAL(5,2)   NOT NULL,
    preferred_supplier_flag     VARCHAR(10)    NOT NULL,
    reliability_factor          DECIMAL(6,3)   NOT NULL,

    CONSTRAINT PK_Suppliers
        PRIMARY KEY (supplier_id)
);
GO


-- Verify table structure

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'Suppliers'
ORDER BY ORDINAL_POSITION;

-- ============================================================
-- Step 6: Create Warehouses Table
-- ============================================================

IF OBJECT_ID('raw.Warehouses', 'U') IS NOT NULL
    DROP TABLE raw.Warehouses;
GO

CREATE TABLE raw.Warehouses
(
    warehouse_id       VARCHAR(20)    NOT NULL,
    warehouse_name     VARCHAR(150)   NOT NULL,
    city               VARCHAR(100)   NOT NULL,
    region             VARCHAR(50)    NOT NULL,
    capacity_units     INT            NOT NULL,

    CONSTRAINT PK_Warehouses
        PRIMARY KEY (warehouse_id)
);
GO


-- Verify table structure

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'Warehouses'
ORDER BY ORDINAL_POSITION;

-- ============================================================
-- Step 7: Create Sales Orders Table
-- ============================================================

IF OBJECT_ID('raw.Sales_Orders', 'U') IS NOT NULL
    DROP TABLE raw.Sales_Orders;
GO

CREATE TABLE raw.Sales_Orders
(
    order_id                  VARCHAR(20)    NOT NULL,
    customer_id               VARCHAR(20)    NOT NULL,
    order_date                DATE           NOT NULL,
    warehouse_id              VARCHAR(20)    NOT NULL,
    priority                  VARCHAR(20)    NOT NULL,
    sales_channel             VARCHAR(50)    NOT NULL,
    requested_delivery_date   DATE           NOT NULL,
    ordered_qty               INT            NOT NULL,
    fulfilled_qty             INT            NOT NULL,
    backlog_qty               INT            NOT NULL,
    order_value               DECIMAL(18,2)  NOT NULL,
    backlog_value             DECIMAL(18,2)  NOT NULL,
    order_fill_rate_pct       DECIMAL(8,2)   NOT NULL,
    order_status              VARCHAR(50)    NOT NULL,

    CONSTRAINT PK_Sales_Orders
        PRIMARY KEY (order_id)
);
GO


-- Verify table structure

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'Sales_Orders'
ORDER BY ORDINAL_POSITION;


-- ============================================================
-- Step 8: Create Sales Order Items Table
-- ============================================================

IF OBJECT_ID('raw.Sales_Order_Items', 'U') IS NOT NULL
    DROP TABLE raw.Sales_Order_Items;
GO

CREATE TABLE raw.Sales_Order_Items
(
    order_item_id       VARCHAR(30)    NOT NULL,
    order_id            VARCHAR(20)    NOT NULL,
    product_id          VARCHAR(20)    NOT NULL,
    ordered_qty         INT            NOT NULL,
    unit_price          DECIMAL(18,2)  NOT NULL,
    discount_pct        DECIMAL(8,2)   NOT NULL,
    warehouse_id        VARCHAR(20)    NOT NULL,
    order_date          DATE           NOT NULL,
    gross_value         DECIMAL(18,2)  NOT NULL,
    net_order_value     DECIMAL(18,2)  NOT NULL,
    fulfilled_qty       INT            NOT NULL,
    backlog_qty         INT            NOT NULL,
    stockout_flag       VARCHAR(10)    NOT NULL,
    backlog_value       DECIMAL(18,2)  NOT NULL,
    line_fill_rate_pct  DECIMAL(8,2)   NOT NULL,
    backlog_status      VARCHAR(50)    NOT NULL,

    CONSTRAINT PK_Sales_Order_Items
        PRIMARY KEY (order_item_id)
);
GO


-- Verify table structure

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'Sales_Order_Items'
ORDER BY ORDINAL_POSITION;

-- ============================================================
-- Step 9: Create Inventory Table
-- ============================================================

IF OBJECT_ID('raw.Inventory', 'U') IS NOT NULL
    DROP TABLE raw.Inventory;
GO

CREATE TABLE raw.Inventory
(
    product_id          VARCHAR(20)    NOT NULL,
    warehouse_id        VARCHAR(20)    NOT NULL,
    unit_cost           DECIMAL(18,2)  NOT NULL,
    avg_daily_demand    DECIMAL(18,2)  NOT NULL,
    safety_stock        INT            NOT NULL,
    reorder_point       INT            NOT NULL,
    on_hand_qty         INT            NOT NULL,
    allocated_qty       INT            NOT NULL,
    available_qty       INT            NOT NULL,
    inventory_value     DECIMAL(18,2)  NOT NULL,
    stock_status        VARCHAR(50)    NOT NULL,

    CONSTRAINT PK_Inventory
        PRIMARY KEY (product_id, warehouse_id)
);
GO


-- Verify table structure

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'Inventory'
ORDER BY ORDINAL_POSITION;

-- ============================================================
-- Step 10: Create Inventory Transactions Table
-- ============================================================

IF OBJECT_ID('raw.Inventory_Transactions', 'U') IS NOT NULL
    DROP TABLE raw.Inventory_Transactions;
GO

CREATE TABLE raw.Inventory_Transactions
(
    transaction_id      VARCHAR(30)   NOT NULL,
    transaction_date    DATE          NOT NULL,
    product_id          VARCHAR(20)   NOT NULL,
    warehouse_id        VARCHAR(20)   NOT NULL,
    transaction_type    VARCHAR(50)   NOT NULL,
    quantity            INT           NOT NULL,

    CONSTRAINT PK_Inventory_Transactions
        PRIMARY KEY (transaction_id)
);
GO


-- Verify table structure

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'Inventory_Transactions'
ORDER BY ORDINAL_POSITION;


-- ============================================================
-- Step 11: Create Shipments Table
-- ============================================================

IF OBJECT_ID('raw.Shipments', 'U') IS NOT NULL
    DROP TABLE raw.Shipments;
GO

CREATE TABLE raw.Shipments
(
    shipment_id              VARCHAR(30)    NOT NULL,
    order_id                 VARCHAR(20)    NOT NULL,
    warehouse_id             VARCHAR(20)    NOT NULL,
    shipment_date            DATE           NOT NULL,
    requested_delivery_date  DATE           NOT NULL,
    actual_delivery_date     DATE           NOT NULL,
    shipped_qty              INT            NOT NULL,
    delivery_delay_days      INT            NOT NULL,
    on_time_flag             VARCHAR(10)    NOT NULL,
    otif_flag                VARCHAR(10)    NOT NULL,

    CONSTRAINT PK_Shipments
        PRIMARY KEY (shipment_id)
);
GO


-- Verify table structure

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'Shipments'
ORDER BY ORDINAL_POSITION;

-- ============================================================
-- Step 12: Create Purchase Orders Table
-- ============================================================

IF OBJECT_ID('raw.Purchase_Orders', 'U') IS NOT NULL
    DROP TABLE raw.Purchase_Orders;
GO

CREATE TABLE raw.Purchase_Orders
(
    po_id                     VARCHAR(30)    NOT NULL,
    product_id                VARCHAR(20)    NOT NULL,
    warehouse_id              VARCHAR(20)    NOT NULL,
    po_date                   DATE           NOT NULL,
    ordered_qty               INT            NOT NULL,
    supplier_id               VARCHAR(20)    NOT NULL,
    unit_cost                 DECIMAL(18,2)  NOT NULL,
    contract_lead_time_days   INT            NOT NULL,
    expected_date             DATE           NOT NULL,
    actual_receipt_date       DATE           NULL,
    received_qty              INT            NOT NULL,
    po_value                  DECIMAL(18,2)  NOT NULL,
    supplier_delay_days       INT            NULL,
    po_status                 VARCHAR(50)    NOT NULL,

    CONSTRAINT PK_Purchase_Orders
        PRIMARY KEY (po_id)
);
GO


-- Verify table structure

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_NAME = 'Purchase_Orders'
ORDER BY ORDINAL_POSITION;

-- ============================================================
-- Step 13: Verify All Core Tables
-- ============================================================

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- ============================================================
-- Step 14: Create Foreign Key Relationships
-- ============================================================

-- Products → Suppliers
ALTER TABLE raw.Products
ADD CONSTRAINT FK_Products_Suppliers
FOREIGN KEY (supplier_id)
REFERENCES raw.Suppliers(supplier_id);


-- Sales Orders → Customers
ALTER TABLE raw.Sales_Orders
ADD CONSTRAINT FK_SalesOrders_Customers
FOREIGN KEY (customer_id)
REFERENCES raw.Customers(customer_id);


-- Sales Orders → Warehouses
ALTER TABLE raw.Sales_Orders
ADD CONSTRAINT FK_SalesOrders_Warehouses
FOREIGN KEY (warehouse_id)
REFERENCES raw.Warehouses(warehouse_id);


-- Sales Order Items → Sales Orders
ALTER TABLE raw.Sales_Order_Items
ADD CONSTRAINT FK_SalesOrderItems_Orders
FOREIGN KEY (order_id)
REFERENCES raw.Sales_Orders(order_id);


-- Sales Order Items → Products
ALTER TABLE raw.Sales_Order_Items
ADD CONSTRAINT FK_SalesOrderItems_Products
FOREIGN KEY (product_id)
REFERENCES raw.Products(product_id);


-- Sales Order Items → Warehouses
ALTER TABLE raw.Sales_Order_Items
ADD CONSTRAINT FK_SalesOrderItems_Warehouses
FOREIGN KEY (warehouse_id)
REFERENCES raw.Warehouses(warehouse_id);


-- Inventory → Products
ALTER TABLE raw.Inventory
ADD CONSTRAINT FK_Inventory_Products
FOREIGN KEY (product_id)
REFERENCES raw.Products(product_id);


-- Inventory → Warehouses
ALTER TABLE raw.Inventory
ADD CONSTRAINT FK_Inventory_Warehouses
FOREIGN KEY (warehouse_id)
REFERENCES raw.Warehouses(warehouse_id);


-- Inventory Transactions → Products
ALTER TABLE raw.Inventory_Transactions
ADD CONSTRAINT FK_InventoryTransactions_Products
FOREIGN KEY (product_id)
REFERENCES raw.Products(product_id);


-- Inventory Transactions → Warehouses
ALTER TABLE raw.Inventory_Transactions
ADD CONSTRAINT FK_InventoryTransactions_Warehouses
FOREIGN KEY (warehouse_id)
REFERENCES raw.Warehouses(warehouse_id);


-- Shipments → Sales Orders
ALTER TABLE raw.Shipments
ADD CONSTRAINT FK_Shipments_Orders
FOREIGN KEY (order_id)
REFERENCES raw.Sales_Orders(order_id);


-- Shipments → Warehouses
ALTER TABLE raw.Shipments
ADD CONSTRAINT FK_Shipments_Warehouses
FOREIGN KEY (warehouse_id)
REFERENCES raw.Warehouses(warehouse_id);


-- Purchase Orders → Products
ALTER TABLE raw.Purchase_Orders
ADD CONSTRAINT FK_PurchaseOrders_Products
FOREIGN KEY (product_id)
REFERENCES raw.Products(product_id);


-- Purchase Orders → Warehouses
ALTER TABLE raw.Purchase_Orders
ADD CONSTRAINT FK_PurchaseOrders_Warehouses
FOREIGN KEY (warehouse_id)
REFERENCES raw.Warehouses(warehouse_id);


-- Purchase Orders → Suppliers
ALTER TABLE raw.Purchase_Orders
ADD CONSTRAINT FK_PurchaseOrders_Suppliers
FOREIGN KEY (supplier_id)
REFERENCES raw.Suppliers(supplier_id);
GO

SELECT
    fk.name AS Foreign_Key_Name,
    OBJECT_SCHEMA_NAME(fk.parent_object_id)
        + '.'
        + OBJECT_NAME(fk.parent_object_id)
        AS Child_Table,
    OBJECT_SCHEMA_NAME(fk.referenced_object_id)
        + '.'
        + OBJECT_NAME(fk.referenced_object_id)
        AS Parent_Table
FROM sys.foreign_keys AS fk
WHERE OBJECT_SCHEMA_NAME(fk.parent_object_id) = 'raw'
ORDER BY Child_Table, Foreign_Key_Name;

-- ============================================================
-- Step 15: Verify Primary Keys
-- ============================================================

SELECT
    s.name AS Schema_Name,
    t.name AS Table_Name,
    kc.name AS Primary_Key_Name,
    c.name AS Primary_Key_Column,
    ic.key_ordinal AS Key_Position
FROM sys.key_constraints AS kc
JOIN sys.tables AS t
    ON kc.parent_object_id = t.object_id
JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
JOIN sys.index_columns AS ic
    ON kc.parent_object_id = ic.object_id
   AND kc.unique_index_id = ic.index_id
JOIN sys.columns AS c
    ON ic.object_id = c.object_id
   AND ic.column_id = c.column_id
WHERE kc.type = 'PK'
  AND s.name = 'raw'
ORDER BY
    t.name,
    ic.key_ordinal;

    -- ============================================================
-- Step 16: Final Database Structure Validation
-- ============================================================

DECLARE @TableCount INT;
DECLARE @PrimaryKeyCount INT;
DECLARE @ForeignKeyCount INT;

-- Count raw tables
SELECT @TableCount = COUNT(*)
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'raw'
  AND TABLE_TYPE = 'BASE TABLE';


-- Count primary key constraints
SELECT @PrimaryKeyCount = COUNT(*)
FROM sys.key_constraints kc
JOIN sys.tables t
    ON kc.parent_object_id = t.object_id
JOIN sys.schemas s
    ON t.schema_id = s.schema_id
WHERE kc.type = 'PK'
  AND s.name = 'raw';


-- Count foreign key constraints
SELECT @ForeignKeyCount = COUNT(*)
FROM sys.foreign_keys fk
WHERE OBJECT_SCHEMA_NAME(fk.parent_object_id) = 'raw';


-- Final validation output
SELECT
    @TableCount AS Total_Raw_Tables,
    @PrimaryKeyCount AS Total_Primary_Keys,
    @ForeignKeyCount AS Total_Foreign_Keys,
    CASE
        WHEN @TableCount = 10
         AND @PrimaryKeyCount = 10
         AND @ForeignKeyCount = 15
        THEN 'PASSED'
        ELSE 'REVIEW REQUIRED'
    END AS Database_Structure_Status;

    -- ============================================================
-- Step 17: Verify Tables Are Empty Before Data Import
-- ============================================================

SELECT 'Customers' AS Table_Name, COUNT(*) AS Row_Count
FROM raw.Customers

UNION ALL

SELECT 'Products', COUNT(*)
FROM raw.Products

UNION ALL

SELECT 'Suppliers', COUNT(*)
FROM raw.Suppliers

UNION ALL

SELECT 'Warehouses', COUNT(*)
FROM raw.Warehouses

UNION ALL

SELECT 'Sales_Orders', COUNT(*)
FROM raw.Sales_Orders

UNION ALL

SELECT 'Sales_Order_Items', COUNT(*)
FROM raw.Sales_Order_Items

UNION ALL

SELECT 'Inventory', COUNT(*)
FROM raw.Inventory

UNION ALL

SELECT 'Inventory_Transactions', COUNT(*)
FROM raw.Inventory_Transactions

UNION ALL

SELECT 'Shipments', COUNT(*)
FROM raw.Shipments

UNION ALL

SELECT 'Purchase_Orders', COUNT(*)
FROM raw.Purchase_Orders;

-- Step 18A: Validate imported Customers staging table

SELECT COUNT(*) AS Imported_Customer_Rows
FROM dbo.customers_featured;

SELECT TOP 5 *
FROM dbo.customers_featured;

-- ============================================================
-- Step 18C: Load Customers into Final Raw Table
-- ============================================================

INSERT INTO raw.Customers
(
    customer_id,
    customer_name,
    customer_segment,
    region,
    credit_tier,
    customer_since
)
SELECT
    customer_id,
    customer_name,
    customer_segment,
    region,
    credit_tier,
    CAST(customer_since AS DATE)
FROM dbo.customers_featured;
GO


-- Verify final load

SELECT
    COUNT(*) AS Final_Customer_Rows
FROM raw.Customers;

-- ============================================================
-- Step 18D: Remove Customers Staging Table
-- ============================================================

DROP TABLE dbo.customers_featured;
GO

-- Verify staging table was removed

SELECT
    CASE
        WHEN OBJECT_ID('dbo.customers_featured', 'U') IS NULL
            THEN 'REMOVED'
        ELSE 'STILL EXISTS'
    END AS Customer_Staging_Status;

    -- Step 19A: Validate Products staging table

SELECT COUNT(*) AS Imported_Product_Rows
FROM dbo.products_featured;

SELECT TOP 5 *
FROM dbo.products_featured;

-- ============================================================
-- Step 19B: Load Products into Final Raw Table
-- ============================================================

INSERT INTO raw.Products
(
    product_id,
    product_name,
    category,
    subcategory,
    supplier_id,
    unit_cost,
    unit_price,
    base_monthly_demand,
    shelf_life_days,
    active_flag
)
SELECT
    product_id,
    product_name,
    category,
    subcategory,
    supplier_id,
    CAST(unit_cost AS DECIMAL(18,2)),
    CAST(unit_price AS DECIMAL(18,2)),
    CAST(base_monthly_demand AS DECIMAL(18,2)),
    shelf_life_days,
    active_flag
FROM dbo.products_featured;
GO


-- Verify final load

SELECT
    COUNT(*) AS Final_Product_Rows
FROM raw.Products;

-- ============================================================
-- Step 19B: Verify Products Insert Was Rolled Back
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM raw.Products)
        AS Raw_Product_Rows,

    (SELECT COUNT(*) FROM raw.Suppliers)
        AS Raw_Supplier_Rows,

    (SELECT COUNT(*) FROM dbo.products_featured)
        AS Product_Staging_Rows;

        -- Step 19C: Validate Suppliers staging table

SELECT COUNT(*) AS Imported_Supplier_Rows
FROM dbo.suppliers_featured;

SELECT TOP 5 *
FROM dbo.suppliers_featured;

-- ============================================================
-- Step 19D: Load Suppliers into Final Raw Table
-- ============================================================

INSERT INTO raw.Suppliers
(
    supplier_id,
    supplier_name,
    supplier_region,
    contract_lead_time_days,
    quality_rating,
    preferred_supplier_flag,
    reliability_factor
)
SELECT
    supplier_id,
    supplier_name,
    supplier_region,
    contract_lead_time_days,
    CAST(quality_rating AS DECIMAL(5,2)),
    CAST(preferred_supplier_flag AS VARCHAR(10)),
    CAST(reliability_factor AS DECIMAL(6,3))
FROM dbo.suppliers_featured;
GO


-- Verify final load

SELECT COUNT(*) AS Final_Supplier_Rows
FROM raw.Suppliers;

-- ============================================================
-- Step 19E: Load Products After Suppliers
-- ============================================================

INSERT INTO raw.Products
(
    product_id,
    product_name,
    category,
    subcategory,
    supplier_id,
    unit_cost,
    unit_price,
    base_monthly_demand,
    shelf_life_days,
    active_flag
)
SELECT
    product_id,
    product_name,
    category,
    subcategory,
    supplier_id,
    CAST(unit_cost AS DECIMAL(18,2)),
    CAST(unit_price AS DECIMAL(18,2)),
    CAST(base_monthly_demand AS DECIMAL(18,2)),
    shelf_life_days,
    active_flag
FROM dbo.products_featured;
GO


-- Verify both parent tables

SELECT
    (SELECT COUNT(*) FROM raw.Products)
        AS Final_Product_Rows,

    (SELECT COUNT(*) FROM raw.Suppliers)
        AS Final_Supplier_Rows;

-- ============================================================
-- Step 19F: Remove Products and Suppliers Staging Tables
-- ============================================================

DROP TABLE dbo.products_featured;
DROP TABLE dbo.suppliers_featured;
GO


-- Verify removal

SELECT
    CASE
        WHEN OBJECT_ID('dbo.products_featured', 'U') IS NULL
        THEN 'REMOVED'
        ELSE 'STILL EXISTS'
    END AS Products_Staging_Status,

    CASE
        WHEN OBJECT_ID('dbo.suppliers_featured', 'U') IS NULL
        THEN 'REMOVED'
        ELSE 'STILL EXISTS'
    END AS Suppliers_Staging_Status;

-- ============================================================
-- Step 20A: Validate Warehouses Staging Table
-- ============================================================

SELECT COUNT(*) AS Imported_Warehouse_Rows
FROM dbo.warehouses_featured;

SELECT TOP 5 *
FROM dbo.warehouses_featured;

-- ============================================================
-- Step 20B: Load Warehouses into Final Raw Table
-- ============================================================

INSERT INTO raw.Warehouses
(
    warehouse_id,
    warehouse_name,
    city,
    region,
    capacity_units
)
SELECT
    warehouse_id,
    warehouse_name,
    city,
    region,
    capacity_units
FROM dbo.warehouses_featured;
GO


-- Verify final load

SELECT COUNT(*) AS Final_Warehouse_Rows
FROM raw.Warehouses;

-- ============================================================
-- Step 20C: Remove Warehouses Staging Table
-- ============================================================

DROP TABLE dbo.warehouses_featured;
GO

SELECT
    CASE
        WHEN OBJECT_ID('dbo.warehouses_featured', 'U') IS NULL
        THEN 'REMOVED'
        ELSE 'STILL EXISTS'
    END AS Warehouse_Staging_Status;

    -- ============================================================
-- Step 21A: Validate Sales Orders Staging Table
-- ============================================================

SELECT COUNT(*) AS Imported_Sales_Order_Rows
FROM dbo.sales_orders_featured;

SELECT TOP 5 *
FROM dbo.sales_orders_featured;


-- ============================================================
-- Step 21B: Load Sales Orders into Final Raw Table
-- ============================================================

INSERT INTO raw.Sales_Orders
(
    order_id,
    customer_id,
    order_date,
    warehouse_id,
    priority,
    sales_channel,
    requested_delivery_date,
    ordered_qty,
    fulfilled_qty,
    backlog_qty,
    order_value,
    backlog_value,
    order_fill_rate_pct,
    order_status
)
SELECT
    order_id,
    customer_id,
    CAST(order_date AS DATE),
    warehouse_id,
    priority,
    sales_channel,
    CAST(requested_delivery_date AS DATE),
    ordered_qty,
    fulfilled_qty,
    backlog_qty,
    CAST(order_value AS DECIMAL(18,2)),
    CAST(backlog_value AS DECIMAL(18,2)),
    CAST(order_fill_rate_pct AS DECIMAL(8,2)),
    order_status
FROM dbo.sales_orders_featured;
GO


-- Verify final load

SELECT COUNT(*) AS Final_Sales_Order_Rows
FROM raw.Sales_Orders;

-- ============================================================
-- Step 21C: Remove Sales Orders Staging Table
-- ============================================================

DROP TABLE dbo.sales_orders_featured;
GO

SELECT
    CASE
        WHEN OBJECT_ID('dbo.sales_orders_featured', 'U') IS NULL
        THEN 'REMOVED'
        ELSE 'STILL EXISTS'
    END AS Sales_Orders_Staging_Status;

-- ============================================================
-- Step 22A: Validate Sales Order Items Staging Table
-- ============================================================

SELECT COUNT(*) AS Imported_Sales_Orders_Item_Rows
FROM dbo.sales_orders_items_featured;

SELECT TOP 5 *
FROM dbo.sales_orders_items_featured;


-- ============================================================
-- Step 22B: Load Sales Order Items into Final Raw Table
-- ============================================================

INSERT INTO raw.Sales_Orders_Items
(
    order_item_id,
    order_id,
    product_id,
    ordered_qty,
    unit_price,
    discount_pct,
    warehouse_id,
    order_date,
    gross_value,
    net_order_value,
    fulfilled_qty,
    backlog_qty,
    stockout_flag,
    backlog_value,
    line_fill_rate_pct,
    backlog_status
)
SELECT
    order_item_id,
    order_id,
    product_id,
    ordered_qty,
    CAST(unit_price AS DECIMAL(18,2)),
    CAST(discount_pct AS DECIMAL(8,2)),
    warehouse_id,
    CAST(order_date AS DATE),
    CAST(gross_value AS DECIMAL(18,2)),
    CAST(net_order_value AS DECIMAL(18,2)),
    fulfilled_qty,
    backlog_qty,
    CAST(stockout_flag AS VARCHAR(10)),
    CAST(backlog_value AS DECIMAL(18,2)),
    CAST(line_fill_rate_pct AS DECIMAL(8,2)),
    backlog_status
FROM dbo.sales_orders_items_featured;
GO


-- Verify final load

SELECT COUNT(*) AS Final_Sales_Order_Item_Rows
FROM raw.Sales_Orders_Items;

SELECT
    OBJECT_ID('raw.Sales_Order_Items', 'U') AS Correct_Table,
    OBJECT_ID('raw.Sales_Orders_Items', 'U') AS Wrong_Table;

    -- ============================================================
-- Step 22B: Load Sales Order Items into Final Raw Table
-- ============================================================

INSERT INTO raw.Sales_Order_Items
(
    order_item_id,
    order_id,
    product_id,
    ordered_qty,
    unit_price,
    discount_pct,
    warehouse_id,
    order_date,
    gross_value,
    net_order_value,
    fulfilled_qty,
    backlog_qty,
    stockout_flag,
    backlog_value,
    line_fill_rate_pct,
    backlog_status
)
SELECT
    order_item_id,
    order_id,
    product_id,
    ordered_qty,
    CAST(unit_price AS DECIMAL(18,2)),
    CAST(discount_pct AS DECIMAL(8,2)),
    warehouse_id,
    CAST(order_date AS DATE),
    CAST(gross_value AS DECIMAL(18,2)),
    CAST(net_order_value AS DECIMAL(18,2)),
    fulfilled_qty,
    backlog_qty,
    CAST(stockout_flag AS VARCHAR(10)),
    CAST(backlog_value AS DECIMAL(18,2)),
    CAST(line_fill_rate_pct AS DECIMAL(8,2)),
    backlog_status
FROM dbo.sales_order_items_featured;
GO


-- Verify final load

SELECT COUNT(*) AS Final_Sales_Order_Item_Rows
FROM raw.Sales_Order_Items;

-- Find Sales Order Item staging table

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
  AND (
        TABLE_NAME LIKE '%order%item%'
        OR TABLE_NAME LIKE '%sales%item%'
      )
ORDER BY TABLE_NAME;

-- ============================================================
-- Step 22B: Load Sales Order Items into Final Raw Table
-- ============================================================

INSERT INTO raw.Sales_Order_Items
(
    order_item_id,
    order_id,
    product_id,
    ordered_qty,
    unit_price,
    discount_pct,
    warehouse_id,
    order_date,
    gross_value,
    net_order_value,
    fulfilled_qty,
    backlog_qty,
    stockout_flag,
    backlog_value,
    line_fill_rate_pct,
    backlog_status
)
SELECT
    order_item_id,
    order_id,
    product_id,
    ordered_qty,
    CAST(unit_price AS DECIMAL(18,2)),
    CAST(discount_pct AS DECIMAL(8,2)),
    warehouse_id,
    CAST(order_date AS DATE),
    CAST(gross_value AS DECIMAL(18,2)),
    CAST(net_order_value AS DECIMAL(18,2)),
    fulfilled_qty,
    backlog_qty,
    CAST(stockout_flag AS VARCHAR(10)),
    CAST(backlog_value AS DECIMAL(18,2)),
    CAST(line_fill_rate_pct AS DECIMAL(8,2)),
    backlog_status
FROM dbo.sales_orders_items_featured;
GO


-- Verify final load

SELECT COUNT(*) AS Final_Sales_Order_Item_Rows
FROM raw.Sales_Order_Items;


-- ============================================================
-- Step 22C: Remove Sales Order Items Staging Table
-- ============================================================

DROP TABLE dbo.sales_orders_items_featured;
GO

SELECT
    CASE
        WHEN OBJECT_ID(
            'dbo.sales_orders_items_featured',
            'U'
        ) IS NULL
        THEN 'REMOVED'
        ELSE 'STILL EXISTS'
    END AS Sales_Order_Items_Staging_Status;

-- ============================================================
-- Step 23A: Validate Inventory Staging Table
-- ============================================================

SELECT COUNT(*) AS Imported_Inventory_Rows
FROM dbo.inventory_featured;

SELECT TOP 5 *
FROM dbo.inventory_featured;

-- ============================================================
-- Step 23B: Load Inventory into Final Raw Table
-- ============================================================

INSERT INTO raw.Inventory
(
    product_id,
    warehouse_id,
    unit_cost,
    avg_daily_demand,
    safety_stock,
    reorder_point,
    on_hand_qty,
    allocated_qty,
    available_qty,
    inventory_value,
    stock_status
)
SELECT
    product_id,
    warehouse_id,
    CAST(unit_cost AS DECIMAL(18,2)),
    CAST(avg_daily_demand AS DECIMAL(18,2)),
    safety_stock,
    reorder_point,
    on_hand_qty,
    allocated_qty,
    available_qty,
    CAST(inventory_value AS DECIMAL(18,2)),
    stock_status
FROM dbo.inventory_featured;
GO


-- Verify final load

SELECT COUNT(*) AS Final_Inventory_Rows
FROM raw.Inventory;

-- ============================================================
-- Step 23C: Remove Inventory Staging Table
-- ============================================================

DROP TABLE dbo.inventory_featured;
GO

SELECT
    CASE
        WHEN OBJECT_ID('dbo.inventory_featured', 'U') IS NULL
        THEN 'REMOVED'
        ELSE 'STILL EXISTS'
    END AS Inventory_Staging_Status;

-- ============================================================
-- Step 24A: Validate Inventory Transactions Staging Table
-- ============================================================

SELECT COUNT(*) AS Imported_Inventory_Transaction_Rows
FROM dbo.inventory_transactions_featured;

SELECT TOP 5 *
FROM dbo.inventory_transactions_featured;

-- ============================================================
-- Step 24B: Load Inventory Transactions into Final Raw Table
-- ============================================================

INSERT INTO raw.Inventory_Transactions
(
    transaction_id,
    transaction_date,
    product_id,
    warehouse_id,
    transaction_type,
    quantity
)
SELECT
    transaction_id,
    CAST(transaction_date AS DATE),
    product_id,
    warehouse_id,
    transaction_type,
    quantity
FROM dbo.inventory_transactions_featured;
GO


-- Verify final load

SELECT COUNT(*) AS Final_Inventory_Transaction_Rows
FROM raw.Inventory_Transactions;

-- ============================================================
-- Step 24C: Remove Inventory Transactions Staging Table
-- ============================================================

DROP TABLE dbo.inventory_transactions_featured;
GO

SELECT
    CASE
        WHEN OBJECT_ID(
            'dbo.inventory_transactions_featured',
            'U'
        ) IS NULL
        THEN 'REMOVED'
        ELSE 'STILL EXISTS'
    END AS Inventory_Transactions_Staging_Status;

-- ============================================================
-- Step 25A: Validate Shipments Staging Table
-- ============================================================

SELECT COUNT(*) AS Imported_Shipment_Rows
FROM dbo.shipments_featured;

SELECT TOP 5 *
FROM dbo.shipments_featured;

-- ============================================================
-- Step 25B: Load Shipments into Final Raw Table
-- ============================================================

INSERT INTO raw.Shipments
(
    shipment_id,
    order_id,
    warehouse_id,
    shipment_date,
    requested_delivery_date,
    actual_delivery_date,
    shipped_qty,
    delivery_delay_days,
    on_time_flag,
    otif_flag
)
SELECT
    shipment_id,
    order_id,
    warehouse_id,
    CAST(shipment_date AS DATE),
    CAST(requested_delivery_date AS DATE),
    CAST(actual_delivery_date AS DATE),
    shipped_qty,
    delivery_delay_days,
    CAST(on_time_flag AS VARCHAR(10)),
    CAST(otif_flag AS VARCHAR(10))
FROM dbo.shipments_featured;
GO


-- Verify final load

SELECT COUNT(*) AS Final_Shipment_Rows
FROM raw.Shipments;

-- ============================================================
-- Step 25C: Remove Shipments Staging Table
-- ============================================================

DROP TABLE dbo.shipments_featured;
GO

SELECT
    CASE
        WHEN OBJECT_ID('dbo.shipments_featured', 'U') IS NULL
        THEN 'REMOVED'
        ELSE 'STILL EXISTS'
    END AS Shipments_Staging_Status;

-- ============================================================
-- Step 26A: Validate Purchase Orders Staging Table
-- ============================================================

SELECT COUNT(*) AS Imported_Purchase_Order_Rows
FROM dbo.purchase_orders_featured;

SELECT TOP 5 *
FROM dbo.purchase_orders_featured;

-- ============================================================
-- Step 26B: Load Purchase Orders into Final Raw Table
-- ============================================================

INSERT INTO raw.Purchase_Orders
(
    po_id,
    product_id,
    warehouse_id,
    po_date,
    ordered_qty,
    supplier_id,
    unit_cost,
    contract_lead_time_days,
    expected_date,
    actual_receipt_date,
    received_qty,
    po_value,
    supplier_delay_days,
    po_status
)
SELECT
    po_id,
    product_id,
    warehouse_id,
    CAST(po_date AS DATE),
    ordered_qty,
    supplier_id,
    CAST(unit_cost AS DECIMAL(18,2)),
    contract_lead_time_days,
    CAST(expected_date AS DATE),

    CASE
        WHEN actual_receipt_date IS NULL
             OR LTRIM(RTRIM(CAST(actual_receipt_date AS VARCHAR(50)))) = ''
        THEN NULL
        ELSE CAST(actual_receipt_date AS DATE)
    END,

    received_qty,
    CAST(po_value AS DECIMAL(18,2)),

    CASE
        WHEN supplier_delay_days IS NULL
             OR LTRIM(RTRIM(CAST(supplier_delay_days AS VARCHAR(50)))) = ''
        THEN NULL
        ELSE CAST(supplier_delay_days AS INT)
    END,

    po_status

FROM dbo.purchase_orders_featured;
GO


-- Verify final load

SELECT
    COUNT(*) AS Final_Purchase_Order_Rows,
    SUM(CASE WHEN actual_receipt_date IS NULL THEN 1 ELSE 0 END)
        AS Null_Actual_Receipt_Dates,
    SUM(CASE WHEN supplier_delay_days IS NULL THEN 1 ELSE 0 END)
        AS Null_Supplier_Delay_Days
FROM raw.Purchase_Orders;

-- ============================================================
-- Step 26C: Remove Purchase Orders Staging Table
-- ============================================================

DROP TABLE dbo.purchase_orders_featured;
GO

SELECT
    CASE
        WHEN OBJECT_ID(
            'dbo.purchase_orders_featured',
            'U'
        ) IS NULL
        THEN 'REMOVED'
        ELSE 'STILL EXISTS'
    END AS Purchase_Orders_Staging_Status;


-- ============================================================
-- Step 27: Validate Final Row Counts
-- ============================================================

SELECT
    'Customers' AS Table_Name,
    COUNT(*) AS Actual_Rows,
    2500 AS Expected_Rows,
    CASE WHEN COUNT(*) = 2500 THEN 'PASS' ELSE 'FAIL' END AS Status
FROM raw.Customers

UNION ALL

SELECT
    'Products',
    COUNT(*),
    500,
    CASE WHEN COUNT(*) = 500 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Products

UNION ALL

SELECT
    'Suppliers',
    COUNT(*),
    100,
    CASE WHEN COUNT(*) = 100 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Suppliers

UNION ALL

SELECT
    'Warehouses',
    COUNT(*),
    6,
    CASE WHEN COUNT(*) = 6 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Warehouses

UNION ALL

SELECT
    'Sales_Orders',
    COUNT(*),
    25000,
    CASE WHEN COUNT(*) = 25000 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Sales_Order_Items',
    COUNT(*),
    61397,
    CASE WHEN COUNT(*) = 61397 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Order_Items

UNION ALL

SELECT
    'Inventory',
    COUNT(*),
    3000,
    CASE WHEN COUNT(*) = 3000 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory

UNION ALL

SELECT
    'Inventory_Transactions',
    COUNT(*),
    110000,
    CASE WHEN COUNT(*) = 110000 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory_Transactions

UNION ALL

SELECT
    'Shipments',
    COUNT(*),
    24798,
    CASE WHEN COUNT(*) = 24798 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Shipments

UNION ALL

SELECT
    'Purchase_Orders',
    COUNT(*),
    8500,
    CASE WHEN COUNT(*) = 8500 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Purchase_Orders;

-- ============================================================
-- Step 28: Validate Primary Key Uniqueness
-- ============================================================

SELECT
    'Customers' AS Table_Name,
    COUNT(*) AS Total_Rows,
    COUNT(DISTINCT customer_id) AS Unique_Keys,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT customer_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS Status
FROM raw.Customers

UNION ALL

SELECT
    'Products',
    COUNT(*),
    COUNT(DISTINCT product_id),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT product_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Products

UNION ALL

SELECT
    'Suppliers',
    COUNT(*),
    COUNT(DISTINCT supplier_id),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT supplier_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Suppliers

UNION ALL

SELECT
    'Warehouses',
    COUNT(*),
    COUNT(DISTINCT warehouse_id),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT warehouse_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Warehouses

UNION ALL

SELECT
    'Sales_Orders',
    COUNT(*),
    COUNT(DISTINCT order_id),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT order_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Sales_Order_Items',
    COUNT(*),
    COUNT(DISTINCT order_item_id),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT order_item_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Sales_Order_Items

UNION ALL

SELECT
    'Inventory_Transactions',
    COUNT(*),
    COUNT(DISTINCT transaction_id),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT transaction_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Inventory_Transactions

UNION ALL

SELECT
    'Shipments',
    COUNT(*),
    COUNT(DISTINCT shipment_id),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT shipment_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Shipments

UNION ALL

SELECT
    'Purchase_Orders',
    COUNT(*),
    COUNT(DISTINCT po_id),
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT po_id)
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Purchase_Orders;

-- ============================================================
-- Step 29: Validate Inventory Composite Primary Key
-- ============================================================

SELECT
    COUNT(*) AS Total_Inventory_Rows,
    COUNT(*) - COUNT(DISTINCT CONCAT(product_id, '|', warehouse_id))
        AS Duplicate_Product_Warehouse_Keys,
    CASE
        WHEN COUNT(*) =
             COUNT(DISTINCT CONCAT(product_id, '|', warehouse_id))
        THEN 'PASS'
        ELSE 'FAIL'
    END AS Status
FROM raw.Inventory;

-- ============================================================
-- Step 30: Validate Foreign Key Integrity
-- ============================================================

SELECT
    'Products → Suppliers' AS Relationship,
    COUNT(*) AS Orphan_Rows,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status
FROM raw.Products p
LEFT JOIN raw.Suppliers s
    ON p.supplier_id = s.supplier_id
WHERE s.supplier_id IS NULL

UNION ALL

SELECT
    'Sales Orders → Customers',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders so
LEFT JOIN raw.Customers c
    ON so.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT
    'Sales Orders → Warehouses',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders so
LEFT JOIN raw.Warehouses w
    ON so.warehouse_id = w.warehouse_id
WHERE w.warehouse_id IS NULL

UNION ALL

SELECT
    'Sales Order Items → Orders',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Order_Items soi
LEFT JOIN raw.Sales_Orders so
    ON soi.order_id = so.order_id
WHERE so.order_id IS NULL

UNION ALL

SELECT
    'Sales Order Items → Products',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Order_Items soi
LEFT JOIN raw.Products p
    ON soi.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'Inventory → Products',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory i
LEFT JOIN raw.Products p
    ON i.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'Inventory → Warehouses',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory i
LEFT JOIN raw.Warehouses w
    ON i.warehouse_id = w.warehouse_id
WHERE w.warehouse_id IS NULL

UNION ALL

SELECT
    'Inventory Transactions → Products',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory_Transactions it
LEFT JOIN raw.Products p
    ON it.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'Inventory Transactions → Warehouses',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory_Transactions it
LEFT JOIN raw.Warehouses w
    ON it.warehouse_id = w.warehouse_id
WHERE w.warehouse_id IS NULL

UNION ALL

SELECT
    'Shipments → Orders',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Shipments sh
LEFT JOIN raw.Sales_Orders so
    ON sh.order_id = so.order_id
WHERE so.order_id IS NULL

UNION ALL

SELECT
    'Purchase Orders → Products',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Purchase_Orders po
LEFT JOIN raw.Products p
    ON po.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT
    'Purchase Orders → Suppliers',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Purchase_Orders po
LEFT JOIN raw.Suppliers s
    ON po.supplier_id = s.supplier_id
WHERE s.supplier_id IS NULL;

-- ============================================================
-- Step 31: Validate Critical NULL Values
-- ============================================================

SELECT
    'Customers - customer_id' AS Validation_Check,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS Null_Count,
    CASE
        WHEN SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END AS Status
FROM raw.Customers

UNION ALL

SELECT
    'Products - product_id',
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END),
    CASE
        WHEN SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END
FROM raw.Products

UNION ALL

SELECT
    'Sales Orders - order_id',
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END),
    CASE
        WHEN SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Sales Order Items - order_item_id',
    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END),
    CASE
        WHEN SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END
FROM raw.Sales_Order_Items

UNION ALL

SELECT
    'Inventory Transactions - transaction_id',
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END),
    CASE
        WHEN SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END
FROM raw.Inventory_Transactions

UNION ALL

SELECT
    'Shipments - shipment_id',
    SUM(CASE WHEN shipment_id IS NULL THEN 1 ELSE 0 END),
    CASE
        WHEN SUM(CASE WHEN shipment_id IS NULL THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END
FROM raw.Shipments

UNION ALL

SELECT
    'Purchase Orders - po_id',
    SUM(CASE WHEN po_id IS NULL THEN 1 ELSE 0 END),
    CASE
        WHEN SUM(CASE WHEN po_id IS NULL THEN 1 ELSE 0 END) = 0
        THEN 'PASS' ELSE 'FAIL'
    END
FROM raw.Purchase_Orders

UNION ALL

SELECT
    'PO - actual_receipt_date',
    SUM(CASE WHEN actual_receipt_date IS NULL THEN 1 ELSE 0 END),
    CASE
        WHEN SUM(CASE WHEN actual_receipt_date IS NULL THEN 1 ELSE 0 END) = 30
        THEN 'PASS' ELSE 'FAIL'
    END
FROM raw.Purchase_Orders

UNION ALL

SELECT
    'PO - supplier_delay_days',
    SUM(CASE WHEN supplier_delay_days IS NULL THEN 1 ELSE 0 END),
    CASE
        WHEN SUM(CASE WHEN supplier_delay_days IS NULL THEN 1 ELSE 0 END) = 30
        THEN 'PASS' ELSE 'FAIL'
    END
FROM raw.Purchase_Orders;

-- ============================================================
-- Step 32: Validate Core Business Rules
-- ============================================================

SELECT
    'Sales Orders: Ordered = Fulfilled + Backlog' AS Validation_Check,
    COUNT(*) AS Violation_Count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS Status
FROM raw.Sales_Orders
WHERE ordered_qty <> fulfilled_qty + backlog_qty

UNION ALL

SELECT
    'Sales Order Items: Ordered = Fulfilled + Backlog',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Order_Items
WHERE ordered_qty <> fulfilled_qty + backlog_qty

UNION ALL

SELECT
    'Inventory: Available = On Hand - Allocated',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory
WHERE available_qty <> on_hand_qty - allocated_qty

UNION ALL

SELECT
    'Sales Orders: No Negative Quantities',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders
WHERE ordered_qty < 0
   OR fulfilled_qty < 0
   OR backlog_qty < 0

UNION ALL

SELECT
    'Inventory: No Negative Core Quantities',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory
WHERE on_hand_qty < 0
   OR allocated_qty < 0
   OR available_qty < 0

UNION ALL

SELECT
    'Purchase Orders: Received <= Ordered',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Purchase_Orders
WHERE received_qty > ordered_qty

UNION ALL

SELECT
    'Sales Orders: Non-Negative Values',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Sales_Orders
WHERE order_value < 0
   OR backlog_value < 0

UNION ALL

SELECT
    'Inventory: Non-Negative Value',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Inventory
WHERE inventory_value < 0

UNION ALL

SELECT
    'Purchase Orders: Non-Negative Value',
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END
FROM raw.Purchase_Orders
WHERE po_value < 0;

-- ============================================================
-- Step 33: Validate Shipment Chronology
-- ============================================================

SELECT
    COUNT(*) AS Total_Shipments,

    SUM(
        CASE
            WHEN actual_delivery_date >= shipment_date
            THEN 1
            ELSE 0
        END
    ) AS Valid_Chronology_Rows,

    SUM(
        CASE
            WHEN actual_delivery_date < shipment_date
            THEN 1
            ELSE 0
        END
    ) AS Invalid_Chronology_Rows,

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
    ) AS Invalid_Chronology_Pct,

    CASE
        WHEN COUNT(*) = 24798
         AND SUM(
                CASE
                    WHEN actual_delivery_date < shipment_date
                    THEN 1
                    ELSE 0
                END
             ) = 4467
        THEN 'PASS'
        ELSE 'FAIL'
    END AS Status

FROM raw.Shipments;

-- ============================================================
-- Step 34: Validate Core KPI Reconciliation
-- ============================================================

SELECT
    'Total Sales Value' AS KPI,
    CAST(SUM(order_value) AS DECIMAL(18,2)) AS SQL_Value,
    CAST(2068495699.27 AS DECIMAL(18,2)) AS Expected_Value,
    CASE
        WHEN ABS(
            SUM(order_value) - 2068495699.27
        ) <= 1.00
        THEN 'PASS'
        ELSE 'FAIL'
    END AS Status
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Total Ordered Quantity',
    CAST(SUM(ordered_qty) AS DECIMAL(18,2)),
    CAST(501755 AS DECIMAL(18,2)),
    CASE
        WHEN SUM(ordered_qty) = 501755
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Total Fulfilled Quantity',
    CAST(SUM(fulfilled_qty) AS DECIMAL(18,2)),
    CAST(440576 AS DECIMAL(18,2)),
    CASE
        WHEN SUM(fulfilled_qty) = 440576
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Total Backlog Quantity',
    CAST(SUM(backlog_qty) AS DECIMAL(18,2)),
    CAST(61179 AS DECIMAL(18,2)),
    CASE
        WHEN SUM(backlog_qty) = 61179
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Total Backlog Value',
    CAST(SUM(backlog_value) AS DECIMAL(18,2)),
    CAST(257349919.69 AS DECIMAL(18,2)),
    CASE
        WHEN ABS(
            SUM(backlog_value) - 257349919.69
        ) <= 1.00
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Sales_Orders

UNION ALL

SELECT
    'Total Inventory Value',
    CAST(SUM(inventory_value) AS DECIMAL(18,2)),
    CAST(285985182.04 AS DECIMAL(18,2)),
    CASE
        WHEN ABS(
            SUM(inventory_value) - 285985182.04
        ) <= 1.00
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Inventory

UNION ALL

SELECT
    'Total Procurement Value',
    CAST(SUM(po_value) AS DECIMAL(18,2)),
    CAST(6715682357.79 AS DECIMAL(18,2)),
    CASE
        WHEN ABS(
            SUM(po_value) - 6715682357.79
        ) <= 1.00
        THEN 'PASS'
        ELSE 'FAIL'
    END
FROM raw.Purchase_Orders;

-- ============================================================
-- Step 34A: Diagnose Monetary Rounding Differences
-- ============================================================

SELECT
    'Sales Orders' AS Dataset,

    CAST(SUM(order_value) AS DECIMAL(18,2))
        AS Stored_SQL_Total,

    CAST(2068495699.27 AS DECIMAL(18,2))
        AS Python_Original_Total,

    CAST(
        SUM(order_value) - 2068495699.27
        AS DECIMAL(18,2)
    ) AS Difference,

    COUNT(*) AS Row_Count

FROM raw.Sales_Orders

UNION ALL

SELECT
    'Purchase Orders',

    CAST(SUM(po_value) AS DECIMAL(18,2)),

    CAST(6715682357.79 AS DECIMAL(18,2)),

    CAST(
        SUM(po_value) - 6715682357.79
        AS DECIMAL(18,2)
    ),

    COUNT(*)

FROM raw.Purchase_Orders;

-- ============================================================
-- Step 34B: Increase Monetary Precision
-- ============================================================

ALTER TABLE raw.Sales_Orders
ALTER COLUMN order_value DECIMAL(18,6) NOT NULL;
GO

ALTER TABLE raw.Sales_Orders
ALTER COLUMN backlog_value DECIMAL(18,6) NOT NULL;
GO

ALTER TABLE raw.Purchase_Orders
ALTER COLUMN unit_cost DECIMAL(18,6) NOT NULL;
GO

ALTER TABLE raw.Purchase_Orders
ALTER COLUMN po_value DECIMAL(18,6) NOT NULL;
GO


-- Verify updated precision

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw'
  AND (
        (TABLE_NAME = 'Sales_Orders'
         AND COLUMN_NAME IN ('order_value', 'backlog_value'))
        OR
        (TABLE_NAME = 'Purchase_Orders'
         AND COLUMN_NAME IN ('unit_cost', 'po_value'))
      )
ORDER BY TABLE_NAME, COLUMN_NAME;

-- ============================================================
-- Step 34C: Validate Sales Orders Precision Staging Table
-- ============================================================

SELECT
    COUNT(*) AS Staging_Rows,
    COUNT(DISTINCT order_id) AS Unique_Order_IDs
FROM dbo.sales_orders_featured;

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME LIKE '%sales%order%'
ORDER BY TABLE_NAME;

-- ============================================================
-- Step 34D: Restore Sales Order Monetary Precision
-- ============================================================

UPDATE so
SET
    so.order_value =
        CAST(stg.order_value AS DECIMAL(18,6)),

    so.backlog_value =
        CAST(stg.backlog_value AS DECIMAL(18,6))

FROM raw.Sales_Orders AS so

INNER JOIN dbo.sales_orders_featured AS stg
    ON so.order_id = stg.order_id;
GO


-- Verify restored totals

SELECT
    COUNT(*) AS Sales_Order_Rows,

    CAST(
        SUM(order_value)
        AS DECIMAL(18,2)
    ) AS Total_Sales_Value,

    CAST(
        SUM(backlog_value)
        AS DECIMAL(18,2)
    ) AS Total_Backlog_Value

FROM raw.Sales_Orders;

-- ============================================================
-- Step 34E: Increase Source Monetary Precision Further
-- ============================================================

ALTER TABLE raw.Sales_Orders
ALTER COLUMN order_value DECIMAL(24,10) NOT NULL;
GO

ALTER TABLE raw.Sales_Orders
ALTER COLUMN backlog_value DECIMAL(24,10) NOT NULL;
GO


-- Reload original precision from staging

UPDATE so
SET
    so.order_value =
        CAST(stg.order_value AS DECIMAL(24,10)),

    so.backlog_value =
        CAST(stg.backlog_value AS DECIMAL(24,10))
FROM raw.Sales_Orders AS so
JOIN dbo.sales_orders_featured AS stg
    ON so.order_id = stg.order_id;
GO


-- Verify

SELECT
    COUNT(*) AS Sales_Order_Rows,

    CAST(SUM(order_value) AS DECIMAL(18,2))
        AS Total_Sales_Value,

    CAST(SUM(backlog_value) AS DECIMAL(18,2))
        AS Total_Backlog_Value

FROM raw.Sales_Orders;

-- ============================================================
-- Step 34F: Check Source Staging Totals
-- ============================================================

SELECT
    COUNT(*) AS Staging_Rows,

    CAST(
        SUM(CAST(order_value AS DECIMAL(24,10)))
        AS DECIMAL(24,2)
    ) AS Staging_Sales_Total,

    CAST(
        SUM(CAST(backlog_value AS DECIMAL(24,10)))
        AS DECIMAL(24,2)
    ) AS Staging_Backlog_Total

FROM dbo.sales_orders_featured;

-- ============================================================
-- Step 34G: Check Purchase Order Source Staging Total
-- ============================================================

SELECT
    COUNT(*) AS Staging_Rows,

    CAST(
        SUM(CAST(po_value AS DECIMAL(24,10)))
        AS DECIMAL(24,2)
    ) AS Staging_Procurement_Total

FROM dbo.purchase_orders_featured;