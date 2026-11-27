# Data Preparation and Methodology

## 1. Introduction

This document describes the data preparation and analytical methodology followed in the **Sales Order, Backlog & Inventory Optimization Analytics** project.

The project uses operational datasets covering customers, products, sales orders, order items, inventory, inventory transactions, warehouses, shipments, suppliers, and purchase orders.

The objective of data preparation was to establish a reliable analytical foundation for SQL-based analysis, Python analysis, and the Power BI dashboard connected to SQL Server.

## 2. Dataset Overview

The project includes 10 datasets:

| Dataset | Records |
|---|---:|
| Customers | 2,500 |
| Products | 500 |
| Sales Orders | 25,000 |
| Sales Order Items | 61,397 |
| Inventory | 3,000 |
| Inventory Transactions — Raw | 110,045 |
| Warehouses | 6 |
| Shipments | 24,798 |
| Suppliers | 100 |
| Purchase Orders | 8,500 |

The inventory transaction dataset contained 110,045 raw records. After removing 45 exact duplicate records, the cleaned dataset contained 110,000 records.

## 3. Data Preparation Workflow

The preparation process followed a structured sequence:

1. Dataset inspection and structural understanding
2. Data profiling and quality auditing
3. Data cleaning and duplicate handling
4. Data type and business-rule validation
5. Feature engineering
6. Analytical validation and reconciliation
7. Preparation of data for SQL analysis and reporting

Each stage was performed to improve consistency and reduce the risk of misleading business conclusions.

## 4. Data Understanding and Profiling

The initial profiling stage focused on understanding the structure and content of each dataset.

The following aspects were examined:

- Dataset dimensions and record counts
- Column names and data types
- Missing or null values
- Duplicate records
- Identifier fields and relationships
- Numeric ranges and distribution
- Date fields and chronological consistency
- Business status and category values

This stage helped identify data quality concerns and understand how the operational tables could be connected for analysis.

## 5. Data Quality Audit

A data quality audit was conducted to identify potential issues before analytical calculations were performed.

### 5.1 Structural checks

The datasets were reviewed for:

- Expected columns
- Appropriate data types
- Valid identifiers
- Consistent table structure
- Record-count consistency

### 5.2 Duplicate checks

Duplicate records were investigated to determine whether they could affect analytical results.

The inventory transaction dataset contained 45 exact duplicate records. These duplicates were removed, resulting in 110,000 cleaned transaction records.

### 5.3 Missing-value checks

Missing values were examined to understand their distribution and potential impact.

Missing values were not automatically treated as zero. Their interpretation depended on the meaning of the field and the associated business process.

### 5.4 Business-rule checks

Business rules were used to review the consistency of operational fields, including:

- Ordered, fulfilled, and backlog quantities
- Inventory availability and allocation
- Shipment dates
- Purchase order receipt dates
- Supplier delivery performance
- Order and purchase order statuses

## 6. Data Cleaning

The cleaning stage addressed identified data quality issues while preserving the meaning of the original operational records.

### 6.1 Duplicate removal

The 45 exact duplicate records identified in the raw inventory transaction dataset were removed.

| Metric | Value |
|---|---:|
| Raw transaction records | 110,045 |
| Exact duplicates removed | 45 |
| Cleaned transaction records | 110,000 |

### 6.2 Data consistency

Data consistency checks were performed across operational fields to support reliable calculations and comparisons.

Particular attention was given to quantity fields, date fields, status fields, and relationships between transactional and dimension tables.

### 6.3 Shipment chronology

Shipment records were checked for chronological validity.

A shipment was considered chronologically invalid when its actual delivery date occurred before its shipment date.

| Shipment chronology | Records |
|---|---:|
| Valid chronology | 20,331 |
| Invalid chronology | 4,467 |
| Total shipments | 24,798 |

The 4,467 records with invalid chronology were treated separately from valid delivery-performance calculations. This helped prevent incorrect delivery-delay and on-time performance conclusions.

## 7. Feature Engineering

Feature engineering was used to support business analysis and reporting.

The project included analytical fields and measures related to:

- Sales value
- Fulfilled quantity
- Backlog quantity
- Backlog value
- Order fill rate
- Line fill rate
- Inventory availability
- Inventory value
- Stock status
- Inventory days on hand
- Shipment delay
- On-time delivery
- OTIF performance
- Supplier delay
- Purchase order status
- ABC-XYZ inventory classification

Derived metrics were used to examine operational performance at different levels, including order, product, warehouse, supplier, and time period.

## 8. Analytical Data Preparation

After the quality audit and cleaning stages, the datasets were prepared for integrated analysis.

The analytical work included:

- Connecting sales orders with order items
- Linking products with inventory and supplier information
- Comparing order demand with fulfillment and backlog
- Evaluating inventory availability and stock status
- Linking shipments to orders for delivery analysis
- Linking purchase orders with supplier performance
- Comparing inventory replenishment requirements with inbound purchase orders

These relationships enabled cross-functional analysis of sales, fulfillment, inventory, logistics, and procurement.

## 9. Validation and Reconciliation

Validation was performed to check the consistency of analytical results and business recommendations.

The project completed the following validation checks:

| Validation activity | Result |
|---|---:|
| Final SQL validation checks passed | 24 |
| Final SQL validation checks failed | 0 |
| Business recommendation reconciliation checks passed | 11 |
| Business recommendation reconciliation checks failed | 0 |

The checks supported the reliability of the final analytical outputs and recommendation calculations.

## 10. Data Quality Considerations

Although data preparation improved analytical consistency, several limitations remained important when interpreting results.

- Invalid shipment chronology affects delivery-performance analysis.
- Operational metrics depend on the quality and consistency of source fields.
- Correlation results indicate association and should not be interpreted as proof of causation.
- Business recommendations should be reviewed against operational constraints before implementation.

## 11. Outcome

The data preparation and methodology process established a structured foundation for the project's SQL analysis, Python analysis, and Power BI reporting.

The resulting analytical datasets supported the investigation of sales performance, backlog, order fulfillment, inventory health, warehouse operations, shipment performance, and supplier procurement.

The methodology emphasizes data quality, business-rule validation, transparent treatment of anomalies, and reconciliation of analytical results.

---

**Project:** Sales Order, Backlog & Inventory Optimization Analytics  
**Tools:** Python, SQL Server, Power BI  
**Documentation:** Data Preparation and Methodology
