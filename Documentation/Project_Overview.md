# Sales Order, Backlog & Inventory Optimization Analytics

## 1. Project Overview

**Sales Order, Backlog & Inventory Optimization Analytics** is an end-to-end supply chain analytics project focused on understanding sales performance, order fulfillment, backlog, inventory health, warehouse operations, shipment performance, and supplier procurement.

The project uses operational datasets to identify business performance gaps, investigate the factors associated with order backlogs, evaluate inventory availability, and develop data-driven recommendations for improving operational efficiency.

The analytical workflow combines Python for data preparation and analysis, SQL Server for structured querying and business analysis, and Power BI for interactive business reporting.

The completed Power BI dashboard is connected to SQL Server and contains six report pages designed to provide an integrated view of supply chain performance.

## 2. Business Problem

Organizations managing sales orders, inventory, warehouses, shipments, and procurement need visibility into how effectively customer demand is fulfilled.

Operational challenges such as incomplete order fulfillment, inventory shortages, excess stock, delivery delays, and supplier performance issues can affect customer service and working capital.

This project investigates these challenges by analyzing operational data across multiple business functions.

The analysis focuses on questions such as:

- How much sales demand is fulfilled, and how much remains in backlog?
- Which products and warehouses contribute most to backlog?
- Where are inventory shortages, stockouts, and overstock conditions occurring?
- How effectively are shipments meeting requested delivery dates?
- Which suppliers demonstrate stronger or weaker delivery performance?
- How can inventory replenishment and procurement decisions be improved?

## 3. Project Objectives

The main objectives of this project are to:

1. Analyze sales and order performance across customers, products, and warehouses.
2. Measure order fulfillment and identify backlog quantity and value.
3. Evaluate inventory availability, stock status, and inventory optimization opportunities.
4. Analyze warehouse and logistics performance.
5. Examine shipment delays, on-time delivery, and OTIF performance.
6. Evaluate supplier reliability and purchase order performance.
7. Identify business patterns through statistical and cross-functional analysis.
8. Develop actionable recommendations supported by analytical findings.
9. Present key business metrics through an interactive Power BI dashboard.

## 4. Dataset Overview

The project uses 10 operational datasets.

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

The datasets cover customer and product information, sales transactions, inventory positions, inventory movements, warehouse operations, shipments, supplier details, and purchase orders.

Refer to `Data_Dictionary.md` for detailed table and column definitions.

## 5. Technology Stack

| Technology | Purpose |
|---|---|
| Python | Data profiling, preparation, feature engineering, exploratory analysis, and statistical analysis |
| SQL Server | Data storage, SQL analysis, business calculations, validation, and analytical querying |
| Power BI | Interactive dashboards, KPI reporting, visual analysis, and business performance monitoring |
| GitHub | Project version control and documentation |

## 6. Project Workflow

The project followed an end-to-end analytical workflow:

1. Data understanding and dataset inspection
2. Data quality audit
3. Data cleaning and duplicate handling
4. Feature engineering
5. Exploratory data analysis
6. SQL-based business analysis
7. Backlog and order fulfillment analysis
8. Inventory health and optimization analysis
9. Shipment and delivery performance analysis
10. Supplier and procurement analysis
11. ABC-XYZ classification and relationship analysis
12. Business recommendations and validation
13. Power BI dashboard development

## 7. SQL Server and Power BI Integration

SQL Server was used as the structured data source for the Power BI report.

The dashboard connects to SQL Server to support business reporting based on the project's analytical data and SQL calculations.

The Power BI report brings together sales, backlog, inventory, warehouse, logistics, and procurement metrics in a single interactive reporting experience.

## 8. Power BI Dashboard

The completed Power BI report contains six pages:

### 1. Executive Overview
Provides a high-level view of overall supply chain and business performance.

### 2. Sales & Order Performance
Focuses on sales and order-related performance metrics.

### 3. Backlog & Fulfilment Analysis
Examines backlog and order fulfillment performance.

### 4. Inventory Health & Stock Optimization
Presents inventory health and stock optimization analysis.

### 5. Warehouse & Logistics Performance
Focuses on warehouse and logistics performance.

### 6. Supplier & Procurement Performance
Examines supplier and procurement-related performance.

The report uses a light blue-grey background (`#EAF1F5`), dark navy text, teal accents, and gold/orange highlights. It includes KPI cards, slicers, interactive visuals, and page navigation.

## 9. Key Project Metrics

The project analyzed the following major business metrics:

- Total sales value
- Ordered quantity
- Fulfilled quantity
- Backlog quantity and value
- Order fill rate
- Inventory value
- Reorder-required inventory
- Stockout and overstock records
- Shipment on-time performance
- OTIF performance
- Average delivery delay
- Supplier on-time performance
- Purchase order performance

These metrics support the assessment of customer demand, fulfillment efficiency, inventory health, logistics performance, and supplier reliability.

## 10. Analytical Areas

The project includes analysis across the following areas:

- Sales and order intelligence
- Backlog and fulfillment analytics
- Inventory health and optimization
- Warehouse and logistics performance
- Supplier and procurement intelligence
- ABC-XYZ inventory classification
- Statistical and relationship analysis
- Business recommendations and validation

## 11. Key Analytical Findings

The analysis identified several important operational patterns:

- Overall order fill rate was 87.81%.
- Backlogged orders represented 43.40% of total sales orders.
- Inventory analysis identified 1,311 reorder-required records.
- Shipment chronology checks identified 4,467 records with actual delivery dates earlier than shipment dates; these were treated separately from valid delivery-performance calculations.
- Supplier on-time performance was 65.35% across 8,470 evaluated purchase orders.
- Higher supplier reliability was associated with better on-time performance and lower average supplier delay in the analyzed data.

These findings highlight opportunities to improve fulfillment, inventory replenishment, shipment data quality, and supplier performance management.

## 12. Validation

The project included analytical validation and reconciliation.

| Validation | Result |
|---|---:|
| SQL validation checks passed | 24 |
| SQL validation checks failed | 0 |
| Business recommendation reconciliation checks passed | 11 |
| Business recommendation reconciliation checks failed | 0 |

Validation helped ensure that key analytical calculations and recommendation outputs were consistent with the project's defined checks.

## 13. Business Value

This project demonstrates how operational data can be transformed into business insights that support:

- Improved order fulfillment visibility
- Better backlog monitoring
- More informed inventory replenishment
- Identification of stockout and overstock risks
- Warehouse performance assessment
- Delivery and logistics monitoring
- Supplier performance evaluation
- Data-driven operational recommendations

## 14. Project Limitations

The analysis depends on the quality and completeness of the supplied operational datasets.

Shipment records with invalid chronology were separated from valid delivery-performance calculations. Statistical relationships should be interpreted as associations rather than causal evidence.

The project provides analytical recommendations; operational implementation would require business validation and consideration of actual operational constraints.

Further details are documented in `Limitations_and_Future_Enhancements.md`.

## 15. Conclusion

Sales Order, Backlog & Inventory Optimization Analytics demonstrates an end-to-end approach to supply chain analytics using Python, SQL Server, and Power BI.

By integrating sales, fulfillment, inventory, logistics, and procurement analysis, the project provides a structured view of operational performance and identifies opportunities for improvement.

The completed Power BI dashboard presents the analysis through six interactive pages, while the supporting documentation explains the data, methodology, analysis, findings, and recommendations.

---

**Project Title:** Sales Order, Backlog & Inventory Optimization Analytics  
**Tools:** Python | SQL Server | Power BI  
**Project Type:** End-to-End Supply Chain Analytics  
**Dashboard:** 6-page interactive Power BI report
