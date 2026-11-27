# KPI Glossary

## 1. Introduction

This document defines the key performance indicators (KPIs) used in the **Sales Order, Backlog & Inventory Optimization Analytics** project.

The glossary provides the business meaning and calculation logic for the major metrics used to analyze sales, order fulfillment, backlog, inventory, logistics, suppliers, and procurement.

Metric definitions should be interpreted using the project's source fields and the relevant analytical population.

## 2. Sales and Order KPIs

### Total Sales Value

**Definition:** Total monetary value of sales orders included in the analysis.

**Calculation:**

Total Sales Value = Sum of Sales Value

**Business purpose:** Measures the overall sales value represented in the dataset.

**Project result:** 2,068,495,698.91

### Total Sales Orders

**Definition:** Total number of sales orders recorded.

**Calculation:**

Total Sales Orders = Count of distinct order IDs

**Business purpose:** Measures order volume and provides a baseline for order performance analysis.

**Project result:** 25,000

### Ordered Quantity

**Definition:** Total quantity requested through sales orders.

**Calculation:**

Ordered Quantity = Sum of Ordered Quantity

**Project result:** 501,755

### Fulfilled Quantity

**Definition:** Total quantity fulfilled against sales demand.

**Calculation:**

Fulfilled Quantity = Sum of Fulfilled Quantity

**Project result:** 440,576

## 3. Backlog and Fulfillment KPIs

### Backlog Quantity

**Definition:** Total quantity that remains unfulfilled against sales demand.

**Calculation:**

Backlog Quantity = Sum of Backlog Quantity

**Project result:** 61,179

### Backlog Value

**Definition:** Monetary value associated with unfulfilled sales demand.

**Calculation:**

Backlog Value = Sum of Backlog Value

**Project result:** 257,349,919.66

### Order Fill Rate

**Definition:** Percentage of ordered quantity that has been fulfilled.

**Calculation:**

Order Fill Rate = Fulfilled Quantity ÷ Ordered Quantity × 100

**Project result:** 87.81%

**Business purpose:** Measures the extent to which customer demand has been fulfilled.

### Backlogged Orders

**Definition:** Number of sales orders with a positive backlog.

**Calculation:**

Backlogged Orders = Count of distinct orders with backlog quantity greater than zero

**Project result:** 10,850

### Backlogged Orders Percentage

**Definition:** Percentage of sales orders that have a backlog.

**Calculation:**

Backlogged Orders Percentage = Backlogged Orders ÷ Total Sales Orders × 100

**Project result:** 43.40%

### Line Fill Rate

**Definition:** Percentage of ordered quantity fulfilled at the sales order item level.

**Calculation:**

Line Fill Rate = Fulfilled Quantity ÷ Ordered Quantity × 100

**Business purpose:** Supports detailed fulfillment analysis at the order-line level.

## 4. Inventory KPIs

### Inventory Value

**Definition:** Monetary value of inventory held across the analyzed inventory records.

**Calculation:**

Inventory Value = Sum of Inventory Value

**Project result:** 285,985,182.32

### Reorder-Required Records

**Definition:** Number of inventory records identified as requiring replenishment.

**Calculation:**

Count of inventory records classified as reorder-required

**Project result:** 1,311

### Stockout Records

**Definition:** Number of inventory records classified as stockout.

**Calculation:**

Count of inventory records classified as stockout

**Project result:** 240

### Overstock Records

**Definition:** Number of inventory records classified as overstock.

**Calculation:**

Count of inventory records classified as overstock

**Project result:** 478

### Available Quantity

**Definition:** Quantity available for use or fulfillment after accounting for allocated stock.

**Calculation:**

Available Quantity = On-Hand Quantity − Allocated Quantity

### Inventory Days on Hand (DOH)

**Definition:** Estimated number of days of demand that current inventory can cover.

**Calculation:**

Inventory DOH = Available Inventory Quantity ÷ Average Daily Demand

**Business purpose:** Helps evaluate inventory coverage and identify potential stock risks.

The calculation should use the project's defined inventory quantity and demand fields consistently.

## 5. Shipment and Logistics KPIs

### Total Shipments

**Definition:** Total number of shipment records.

**Calculation:**

Total Shipments = Count of distinct shipment IDs

**Project result:** 24,798

### Valid Chronology Shipments

**Definition:** Shipment records where actual delivery date is not earlier than shipment date.

**Project result:** 20,331

### Invalid Chronology Shipments

**Definition:** Shipment records where actual delivery date occurs before shipment date.

**Project result:** 4,467

These records were treated separately from valid delivery-performance calculations.

### On-Time Delivery Percentage

**Definition:** Percentage of valid evaluated shipments delivered on or before the requested delivery date.

**Calculation:**

On-Time Delivery Percentage = On-Time Valid Shipments ÷ Valid Evaluated Shipments × 100

**Project result:** 71.22%

### OTIF Percentage

**Definition:** Percentage of valid evaluated shipments meeting the project's On-Time In-Full condition.

**Calculation:**

OTIF Percentage = OTIF-Qualified Valid Shipments ÷ Valid Evaluated Shipments × 100

**Project result:** 46.25%

### Average Delivery Delay

**Definition:** Average delivery delay across the valid shipment population.

**Calculation:**

Average Delivery Delay = Sum of Delivery Delay Days ÷ Valid Evaluated Shipments

**Project result:** 0.93 days

## 6. Supplier and Procurement KPIs

### Evaluated Purchase Orders

**Definition:** Purchase orders included in the supplier performance evaluation.

**Project result:** 8,470

### Supplier On-Time Performance

**Definition:** Percentage of evaluated purchase orders meeting the project's on-time condition.

**Calculation:**

Supplier On-Time Performance = On-Time Evaluated Purchase Orders ÷ Evaluated Purchase Orders × 100

**Project result:** 65.35%

### Reorder-Required Records with Inbound Purchase Orders

**Definition:** Number of reorder-required inventory records with inbound purchase order coverage.

**Project result:** 1,080

### Reorder-Required Records without Inbound Purchase Orders

**Definition:** Number of reorder-required inventory records without identified inbound purchase order coverage.

**Project result:** 231

**Business purpose:** Helps identify replenishment gaps that may require procurement attention.

## 7. Inventory Classification KPIs

### ABC Classification

**Definition:** Inventory classification based on relative value contribution, using the project's defined ABC method.

**Business purpose:** Helps prioritize inventory management based on value significance.

### XYZ Classification

**Definition:** Inventory classification based on demand variability or demand behavior, using the project's defined XYZ method.

**Business purpose:** Helps distinguish products with different demand patterns for inventory planning.

### ABC-XYZ Classification

**Definition:** Combined classification that considers both inventory value importance and demand characteristics.

**Business purpose:** Supports differentiated inventory management and replenishment strategies.

## 8. Relationship Analysis Metrics

### Correlation

**Definition:** A statistical measure describing the direction and strength of a relationship between two variables.

Correlation values range from -1 to +1.

- Positive correlation: variables tend to increase together.
- Negative correlation: one variable tends to decrease as the other increases.
- Near-zero correlation: little or no linear relationship is observed.

Correlation does not establish causation.

## 9. KPI Interpretation Notes

When interpreting project KPIs:

- Use the relevant business population and filters.
- Distinguish order-level metrics from order-line-level metrics.
- Use valid shipment chronology for delivery-performance analysis.
- Interpret inventory record counts separately from product counts.
- Avoid comparing metrics with different evaluation populations.
- Confirm whether a metric is calculated from quantity, value, records, or distinct business entities.

## 10. Conclusion

The KPI glossary provides consistent definitions for the key metrics used throughout the project.

It supports accurate interpretation of SQL results, Python analysis, and Power BI visuals, helping ensure that business performance is measured and communicated consistently.

---

**Project:** Sales Order, Backlog & Inventory Optimization Analytics  
**Domains:** Sales | Fulfillment | Backlog | Inventory | Logistics | Procurement
