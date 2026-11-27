# Data Dictionary
## Sales Order, Backlog & Inventory Optimization Analytics

## 1. Overview

This document describes the datasets used in the Sales Order, Backlog & Inventory Optimization Analytics project.

The project contains 10 operational datasets covering customer information, product details, sales orders, order items, inventory, inventory transactions, warehouses, shipments, suppliers, and purchase orders.

The data dictionary explains the purpose of each dataset, its fields, and the relationships used for Python analysis, SQL Server business analysis, and Power BI reporting.

---

## 2. Customers

**Purpose:** Contains customer master information used to analyze sales and order performance by customer segment, region, and credit tier.

| Column | Description |
|---|---|
| `customer_id` | Unique identifier for each customer |
| `customer_name` | Customer name |
| `customer_segment` | Customer business segment |
| `region` | Customer's assigned region |
| `credit_tier` | Customer credit classification |
| `customer_since` | Date the customer relationship began |

**Primary key:** `customer_id`

---

## 3. Products

**Purpose:** Contains product master data used for sales, demand, inventory, and procurement analysis.

| Column | Description |
|---|---|
| `product_id` | Unique product identifier |
| `product_name` | Product name |
| `category` | Product category |
| `subcategory` | Product subcategory |
| `supplier_id` | Supplier associated with the product |
| `unit_cost` | Product unit cost |
| `unit_price` | Product selling price |
| `base_monthly_demand` | Base monthly demand estimate |
| `shelf_life_days` | Product shelf-life duration in days |
| `active_flag` | Indicates whether the product is active |

**Primary key:** `product_id`

**Relationship:** `supplier_id` connects to the supplier dataset.

---

## 4. Sales Orders

**Purpose:** Contains order-level information used to analyze sales order performance, fulfillment, backlog, and customer demand.

| Column | Description |
|---|---|
| `order_id` | Unique sales order identifier |
| `customer_id` | Customer associated with the order |
| `order_date` | Date the order was placed |
| `warehouse_id` | Warehouse associated with the order |
| `priority` | Order priority classification |
| `sales_channel` | Channel through which the order was placed |
| `requested_delivery_date` | Customer-requested delivery date |
| `ordered_qty` | Total quantity ordered |
| `fulfilled_qty` | Quantity fulfilled |
| `backlog_qty` | Quantity remaining unfulfilled |
| `order_value` | Sales value of the order |
| `backlog_value` | Value associated with the unfulfilled quantity |
| `order_fill_rate_pct` | Percentage of ordered quantity fulfilled |
| `order_status` | Current or recorded order status |

**Primary key:** `order_id`

**Relationships:**
- `customer_id` → Customers
- `warehouse_id` → Warehouses

---

## 5. Sales Order Items

**Purpose:** Contains product-level order details used for detailed sales, backlog, fulfillment, and product performance analysis.

| Column | Description |
|---|---|
| `order_item_id` | Unique order-item identifier |
| `order_id` | Sales order associated with the item |
| `product_id` | Product included in the order |
| `ordered_qty` | Quantity ordered for the item |
| `unit_price` | Selling price per unit |
| `discount_pct` | Discount percentage applied |
| `warehouse_id` | Warehouse associated with the order item |
| `order_date` | Order date |
| `gross_value` | Gross value before applicable discounts |
| `net_order_value` | Net order value after discount |
| `fulfilled_qty` | Quantity fulfilled for the item |
| `backlog_qty` | Quantity remaining unfulfilled |
| `stockout_flag` | Indicates stockout exposure |
| `backlog_value` | Value of the unfulfilled quantity |
| `line_fill_rate_pct` | Fulfillment percentage at order-item level |
| `backlog_status` | Backlog classification for the item |

**Primary key:** `order_item_id`

**Relationships:**
- `order_id` → Sales Orders
- `product_id` → Products
- `warehouse_id` → Warehouses

---

## 6. Inventory

**Purpose:** Contains product-warehouse inventory position used for stock availability, replenishment, stockout, and inventory optimization analysis.

| Column | Description |
|---|---|
| `product_id` | Product identifier |
| `warehouse_id` | Warehouse identifier |
| `unit_cost` | Inventory unit cost |
| `avg_daily_demand` | Average daily demand |
| `safety_stock` | Minimum protective inventory level |
| `reorder_point` | Inventory threshold for replenishment |
| `on_hand_qty` | Physical inventory quantity |
| `allocated_qty` | Quantity allocated to orders |
| `available_qty` | Quantity available for use or allocation |
| `inventory_value` | Monetary value of inventory |
| `stock_status` | Inventory status classification |

**Composite key:** `product_id` + `warehouse_id`

**Relationships:**
- `product_id` → Products
- `warehouse_id` → Warehouses

---

## 7. Inventory Transactions

**Purpose:** Records inventory movements used to analyze inventory changes and transaction activity.

| Column | Description |
|---|---|
| `transaction_id` | Unique inventory transaction identifier |
| `transaction_date` | Date of the inventory transaction |
| `product_id` | Product involved in the transaction |
| `warehouse_id` | Warehouse where the transaction occurred |
| `transaction_type` | Type of inventory movement |
| `quantity` | Quantity involved in the transaction |

**Primary key:** `transaction_id`

**Relationships:**
- `product_id` → Products
- `warehouse_id` → Warehouses

**Data preparation note:** 45 duplicate transaction records were removed during cleaning, resulting in 110,000 cleaned records.

---

## 8. Warehouses

**Purpose:** Contains warehouse master information used for regional, warehouse, inventory, fulfillment, and logistics analysis.

| Column | Description |
|---|---|
| `warehouse_id` | Unique warehouse identifier |
| `warehouse_name` | Warehouse name |
| `city` | Warehouse city |
| `region` | Warehouse region |
| `capacity_units` | Warehouse storage capacity in units |

**Primary key:** `warehouse_id`

---

## 9. Shipments

**Purpose:** Contains shipment and delivery information used to evaluate delivery performance, delay, on-time delivery, and OTIF.

| Column | Description |
|---|---|
| `shipment_id` | Unique shipment identifier |
| `order_id` | Sales order associated with the shipment |
| `warehouse_id` | Warehouse responsible for the shipment |
| `shipment_date` | Date the shipment was dispatched |
| `requested_delivery_date` | Requested delivery date |
| `actual_delivery_date` | Actual delivery date |
| `shipped_qty` | Quantity shipped |
| `delivery_delay_days` | Delivery delay duration in days |
| `on_time_flag` | Indicates whether delivery was on time |
| `otif_flag` | Indicates whether the shipment met on-time and in-full criteria |

**Primary key:** `shipment_id`

**Relationships:**
- `order_id` → Sales Orders
- `warehouse_id` → Warehouses

**Data quality note:** Shipment chronology validation identified records where the actual delivery date preceded the shipment date. These records were treated separately in valid delivery-performance analysis.

---

## 10. Suppliers

**Purpose:** Contains supplier master information used to evaluate supplier reliability, quality, and procurement performance.

| Column | Description |
|---|---|
| `supplier_id` | Unique supplier identifier |
| `supplier_name` | Supplier name |
| `supplier_region` | Supplier region |
| `contract_lead_time_days` | Contractual lead time in days |
| `quality_rating` | Supplier quality rating |
| `preferred_supplier_flag` | Indicates preferred supplier status |
| `reliability_factor` | Supplier reliability measure |

**Primary key:** `supplier_id`

---

## 11. Purchase Orders

**Purpose:** Contains procurement order information used to analyze purchase order value, supplier delivery, inbound supply, and replenishment coverage.

| Column | Description |
|---|---|
| `po_id` | Unique purchase order identifier |
| `product_id` | Product being procured |
| `warehouse_id` | Warehouse receiving the purchase order |
| `po_date` | Purchase order creation date |
| `ordered_qty` | Quantity ordered from the supplier |
| `supplier_id` | Supplier associated with the purchase order |
| `unit_cost` | Purchase order unit cost |
| `contract_lead_time_days` | Contractual lead time in days |
| `expected_date` | Expected receipt date |
| `actual_receipt_date` | Actual purchase order receipt date |
| `received_qty` | Quantity received |
| `po_value` | Purchase order monetary value |
| `supplier_delay_days` | Supplier delivery delay in days |
| `po_status` | Purchase order status |

**Primary key:** `po_id`

**Relationships:**
- `product_id` → Products
- `warehouse_id` → Warehouses
- `supplier_id` → Suppliers

**Data quality note:** Open purchase orders may have missing actual receipt dates and supplier delay values because receipt has not yet occurred.

---

## 12. Relationship Summary

| Parent Dataset | Parent Key | Related Dataset | Related Key |
|---|---|---|---|
| Customers | `customer_id` | Sales Orders | `customer_id` |
| Sales Orders | `order_id` | Sales Order Items | `order_id` |
| Products | `product_id` | Sales Order Items | `product_id` |
| Products | `product_id` | Inventory | `product_id` |
| Warehouses | `warehouse_id` | Inventory | `warehouse_id` |
| Products | `product_id` | Inventory Transactions | `product_id` |
| Warehouses | `warehouse_id` | Inventory Transactions | `warehouse_id` |
| Sales Orders | `order_id` | Shipments | `order_id` |
| Warehouses | `warehouse_id` | Shipments | `warehouse_id` |
| Suppliers | `supplier_id` | Products | `supplier_id` |
| Suppliers | `supplier_id` | Purchase Orders | `supplier_id` |
| Products | `product_id` | Purchase Orders | `product_id` |
| Warehouses | `warehouse_id` | Purchase Orders | `warehouse_id` |

---

## 13. Important Analytical Definitions

| Metric | Definition |
|---|---|
| Order Fill Rate | Fulfilled quantity divided by ordered quantity |
| Backlog Quantity | Ordered quantity minus fulfilled quantity |
| Backlog Rate | Backlog quantity divided by ordered quantity |
| Inventory Days on Hand | Available quantity divided by average daily demand |
| Reorder Required | Available quantity is less than or equal to reorder point |
| Stockout | Inventory record with zero available quantity |
| On-Time Delivery | Shipment delivered on or before the requested delivery date |
| OTIF | Shipment delivered on time and in full |
| Supplier Delay | Difference between actual receipt and expected receipt timing |

*Metric calculations should follow the exact SQL and DAX definitions implemented in the project.*

---

## 14. Data Dictionary Usage

This data dictionary serves as a reference for:

- Understanding the source datasets
- Interpreting SQL queries and analytical outputs
- Building Power BI relationships
- Understanding KPI calculations
- Reviewing project methodology
- Supporting future project enhancements

The documented fields reflect the project schemas used during analysis. Confirm the final column names against the published CSV files before committing this document to GitHub.
