# 📦 Sales Order, Backlog & Inventory Optimization Analytics

<p align="center">

### An End-to-End Supply Chain Analytics Project

**Python • SQL Server • Power BI**

</p>

<p align="center">
  <img src="https://img.shields.io/badge/Python-Data%20Analytics-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/SQL%20Server-Database%20Analytics-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white" />
  <img src="https://img.shields.io/badge/Power%20BI-Interactive%20Dashboards-F2C811?style=for-the-badge&logo=powerbi&logoColor=black" />
  <img src="https://img.shields.io/badge/Supply%20Chain-Optimization-6A5ACD?style=for-the-badge" />
</p>

---

## 📌 Project Overview

**Sales Order, Backlog & Inventory Optimization Analytics** is an end-to-end business intelligence and supply chain analytics project developed to evaluate sales order performance, investigate backlog exposure, optimize inventory availability, and improve operational decision-making.

The project integrates multiple operational datasets covering customers, products, sales orders, order items, inventory, inventory transactions, warehouses, shipments, suppliers, and purchase orders.

Using **Python, SQL Server, and Power BI**, the project transforms raw operational data into validated analytical datasets, business KPIs, cross-functional insights, and interactive dashboards.

The objective is to understand how demand, inventory availability, order fulfillment, warehouse operations, delivery performance, and supplier reliability interact across the supply chain.

## 🎯 Business Problem

Organizations managing large order volumes may face several operational challenges:

- Customer orders are only partially fulfilled.
- Backlog quantity and backlog value continue to accumulate.
- Inventory is available in some locations but insufficient in others.
- Stockouts affect order fulfillment and service levels.
- Excess inventory increases working capital exposure.
- Warehouse performance varies across locations.
- Supplier delays affect replenishment reliability.
- Delivery performance is affected by incomplete order fulfillment.

These issues can reduce customer satisfaction, delay revenue realization, increase operating costs, and weaken supply chain performance.

This project uses data analytics to identify these challenges, measure their business impact, and recommend improvement opportunities.

## 💡 Project Objectives

1. Analyze sales order and order-item performance.
2. Measure order fulfillment, backlog quantity, backlog value, and backlog rates.
3. Identify high-demand and high-value products with significant backlog exposure.
4. Evaluate inventory availability, stockouts, reorder requirements, and excess stock.
5. Analyze inventory coverage using days of inventory on hand.
6. Assess warehouse-level inventory and fulfillment performance.
7. Evaluate shipment performance, delivery delays, on-time delivery, and OTIF.
8. Analyze supplier reliability, quality ratings, lead times, and procurement delays.
9. Identify potential inventory transfer and replenishment opportunities.
10. Perform relationship and correlation analysis across business functions.
11. Develop actionable recommendations and management KPIs.
12. Build a six-page interactive Power BI dashboard connected to SQL Server.

---

## 🛠️ Technology Stack

| Technology | Application |
|---|---|
| Python | Data understanding, cleaning, feature engineering, EDA and statistical analysis |
| Pandas | Data manipulation, transformation and aggregation |
| NumPy | Numerical calculations and analytical support |
| Matplotlib | Data visualization |
| Seaborn | Statistical visualization |
| Jupyter Notebook | Step-by-step analytical workflow |
| SQL Server | Relational data analysis, business queries, KPI calculations and validation |
| T-SQL | Joins, CTEs, aggregations, window functions, statistical calculations and reconciliation |
| Power BI Desktop | Interactive dashboard development and business reporting |
| Power Query | Data connection and transformation within Power BI |
| DAX | KPI calculations and analytical measures |
| GitHub | Project version control, documentation and portfolio presentation |

---

## 🗂️ Dataset Overview

The project uses **10 related operational datasets**.

| Dataset | Records |
|---|---:|
| Customers | 2,500 |
| Products | 500 |
| Sales Orders | 25,000 |
| Sales Order Items | 61,397 |
| Inventory | 3,000 |
| Inventory Transactions | 110,000 cleaned records |
| Warehouses | 6 |
| Shipments | 24,798 |
| Suppliers | 100 |
| Purchase Orders | 8,500 |

The datasets cover customer demand, product information, order fulfillment, inventory position, warehouse operations, shipment execution, supplier performance, and procurement activity.

### Data model and analytical relationships

The project uses related business entities to support analysis at different levels:

- Customer → Sales Orders
- Sales Order → Sales Order Items
- Product → Sales Order Items
- Product + Warehouse → Inventory
- Product + Warehouse → Inventory Transactions
- Sales Order → Shipments
- Product + Warehouse → Purchase Orders
- Supplier → Purchase Orders
- Warehouse → Inventory, Orders, Shipments and Purchase Orders

These relationships enable analysis at order, order-item, product, warehouse, supplier, and category levels.

---

## 🔄 End-to-End Project Workflow

### Phase 1 — Data Understanding and Profiling

The initial phase focused on understanding the structure and quality of the source data.

Activities performed:

- Loaded the original CSV datasets.
- Reviewed dataset dimensions and column names.
- Identified data types and field definitions.
- Examined missing values and duplicate records.
- Reviewed key identifiers and relationship columns.
- Checked numerical ranges and date fields.
- Identified data quality issues requiring investigation.

### Phase 2 — Data Quality Audit

A structured data quality audit was performed to identify potential issues before analysis.

The audit included:

- Missing value assessment
- Duplicate record checks
- Primary key and identifier validation
- Referential integrity checks
- Date chronology validation
- Numerical range validation
- Business rule checks
- Cross-table consistency checks

### Phase 3 — Data Cleaning

The cleaning process addressed data quality issues identified during profiling.

Activities included:

- Handling duplicate records
- Reviewing missing and inconsistent values
- Validating date fields
- Checking quantity and value consistency
- Standardizing data types
- Reviewing invalid chronological records
- Preserving original raw data

**Inventory transaction cleaning:** 45 duplicate transaction records were removed, resulting in 110,000 cleaned inventory transaction records.

### Phase 4 — Feature Engineering

Additional analytical features were created to support deeper business analysis.

Examples include:

- Inventory days on hand
- Reorder-required indicators
- Stockout indicators
- Inventory coverage metrics
- Backlog rate and backlog value metrics
- Fulfillment rate metrics
- Delivery performance indicators
- Supplier performance measures
- Inventory optimization and transfer indicators

### Phase 5 — Exploratory Data Analysis

Exploratory analysis was performed to understand the distribution and behavior of the operational data.

The analysis examined:

- Sales and order patterns
- Customer demand
- Product and category performance
- Backlog concentration
- Inventory availability
- Warehouse performance
- Shipment and delivery patterns
- Supplier and procurement performance

### Phase 6 — SQL Server Business Analysis

SQL Server was used to perform structured business analysis and validation.

The SQL analysis covered:

- Sales order analysis
- Backlog analysis
- Inventory analysis
- Shipment and delivery analysis
- Supplier and procurement analysis
- ABC-XYZ analysis
- Inventory optimization
- Order fulfillment analysis
- Relationship and correlation analysis
- Business recommendation and KPI development

The SQL scripts include data checks, aggregations, joins, CTEs, ranking, relationship analysis, reconciliation, and final validation.

### Phase 7 — Power BI Dashboard Development

The final analytical outputs were used to develop a six-page interactive Power BI report.

The dashboard connects to SQL Server and provides a centralized view of sales, backlog, inventory, warehouse, logistics, and procurement performance.

---

## 🔌 Power BI Connection to SQL Server

Power BI was connected to the SQL Server database using the **SQL Server database connector**.

### Data connection architecture

```text
Operational CSV Datasets
          │
          ▼
Python
Data Profiling
Data Cleaning
Feature Engineering
Exploratory Analysis
          │
          ▼
SQL Server
Relational Tables
Business Analysis
KPI Calculations
Validation
          │
          ▼
Power BI Desktop
SQL Server Connector
          │
          ▼
Interactive Six-Page Dashboard
```

### SQL Server connection process

The Power BI connection was established through the SQL Server data source.

Connection workflow:

1. Open Power BI Desktop.
2. Select **Get Data**.
3. Choose **SQL Server database**.
4. Enter the SQL Server server name.
5. Enter the database name, if applicable.
6. Select the required connection mode.
7. Authenticate using the appropriate SQL Server credentials.
8. Select the required tables or views.
9. Load or transform the selected data.
10. Build relationships, measures, visuals, and dashboard pages.

### Why SQL Server was used as the Power BI data source

Connecting Power BI to SQL Server provides:

- Centralized analytical data access
- Consistent KPI calculations
- Reusable SQL logic
- Structured data relationships
- Better separation between data preparation and reporting
- Easier maintenance of business analysis
- A practical BI workflow similar to enterprise reporting environments

**Important:** Server names, database names, usernames, passwords, and other private connection details should not be published in the GitHub repository.

---

## 📊 Power BI Dashboard — 6 Pages

The completed Power BI report contains six analytical pages designed for executive and operational decision-making.

### 1. Executive Overview

Provides a high-level summary of overall business performance.

Key areas:

- Total sales value
- Total sales orders
- Operating and fulfillment KPIs
- Order status distribution
- Sales trend
- Executive performance indicators

### 2. Sales & Order Intelligence

Focuses on sales performance and customer order activity.

Key areas:

- Sales trends
- Order volume
- Product and category performance
- Customer and regional analysis
- Sales value distribution
- Order status and demand patterns

### 3. Backlog & Fulfillment Analytics

Analyzes unfulfilled orders and fulfillment performance.

Key areas:

- Backlog quantity and value
- Backlogged order rate
- Order fill rate
- High-value backlog
- Backlog aging and severity
- Fulfillment priority
- Order completion performance

### 4. Inventory Health & Optimization

Evaluates inventory availability and optimization opportunities.

Key areas:

- Inventory value
- Available and allocated quantity
- Stockout records
- Reorder-required records
- Inventory days on hand
- Excess inventory
- Replenishment priorities
- Inventory transfer opportunities

### 5. Warehouse & Logistics Performance

Evaluates warehouse operations and delivery execution.

Key areas:

- Warehouse fulfillment performance
- Warehouse backlog exposure
- Stockout distribution
- Shipment performance
- On-time delivery
- OTIF performance
- Delivery delay analysis
- Warehouse improvement priorities

### 6. Supplier & Procurement Intelligence

Analyzes supplier performance and procurement reliability.

Key areas:

- Purchase order value
- Supplier delivery performance
- Supplier reliability
- Supplier quality rating
- Supplier delay analysis
- Outstanding purchase orders
- Procurement coverage
- Supplier improvement priorities

---

## 📈 Key Business KPIs

The following values were validated during the SQL analysis and reconciliation process.

| KPI | Result |
|---|---:|
| Total Sales Orders | 25,000 |
| Total Sales Value | 2,068,495,698.91 |
| Total Ordered Quantity | 501,755 |
| Total Fulfilled Quantity | 440,576 |
| Total Backlog Quantity | 61,179 |
| Overall Order Fill Rate | 87.81% |
| Backlogged Orders | 10,850 |
| Backlogged Order Rate | 43.40% |
| Total Backlog Value | 257,349,919.66 |
| Inventory Records | 3,000 |
| Stockout Records | 240 |
| Reorder-Required Records | 1,311 |
| Overstock Records | 478 |
| Valid Shipment Records | 20,331 |
| Evaluated Purchase Orders | 8,470 |

### KPI interpretation

- The overall order fill rate indicates that 87.81% of ordered quantity was fulfilled.
- 43.40% of orders had some backlog, highlighting an opportunity to improve order completion.
- Backlog value represents a significant commercial exposure requiring prioritization.
- Stockout and reorder-required records identify inventory availability risks.
- Overstock records highlight opportunities to review excess inventory and working capital.
- Shipment and supplier KPIs help identify delivery and procurement improvement areas.

---

## 🔍 Advanced Analytical Work

### Sales and Backlog Analysis

- Analyzed order volume, sales value, ordered quantity, fulfilled quantity, and backlog.
- Identified high-demand product-warehouse combinations.
- Evaluated backlog concentration by product and sales value.
- Compared fulfillment rates across priority, warehouse, and category.
- Examined the relationship between demand and backlog quantity.

### Inventory Optimization

- Evaluated inventory availability and inventory coverage.
- Identified stockout and reorder-required records.
- Reviewed excess inventory and potential capital optimization.
- Evaluated replenishment coverage through outstanding purchase orders.
- Identified potential inter-warehouse inventory transfer opportunities.
- Developed inventory and replenishment priorities.

### Shipment and Delivery Analysis

- Evaluated shipment coverage and delivery chronology.
- Analyzed on-time delivery and OTIF performance.
- Examined delivery delay patterns.
- Compared fulfillment completeness with delivery performance.
- Identified warehouse-level delivery improvement opportunities.

### Supplier and Procurement Analysis

- Evaluated supplier reliability and delivery delay.
- Analyzed supplier quality rating and contractual lead time.
- Reviewed purchase order status and outstanding quantities.
- Identified suppliers requiring corrective action.
- Compared supplier performance across reliability groups.

### Relationship and Correlation Analysis

Cross-functional relationships were analyzed to understand associations between business metrics.

Examples include:

- Demand vs. backlog quantity
- Sales value vs. backlog value
- Inventory availability vs. backlog
- Inventory days on hand vs. backlog rate
- Fulfillment rate vs. delivery delay
- Supplier reliability vs. supplier delay
- Supplier quality vs. supplier delay
- Contract lead time vs. supplier delay

Correlation results were interpreted as **associations, not proof of causation**. Current inventory snapshots and historical order performance may represent different time periods and should be interpreted carefully.

---

## 🧠 Major Business Insights

### 1. Demand Concentration

High-demand product-warehouse combinations account for a disproportionate share of backlog.

**Business implication:** Improve forecasting, allocation, and replenishment controls for high-demand items.

### 2. Commercial Backlog Exposure

Higher-sales-value products carry greater absolute backlog value exposure.

**Business implication:** Protect availability for commercially important products and monitor their backlog closely.

### 3. Fulfillment and Delivery Performance

Fully fulfilled orders show stronger delivery performance than partially fulfilled orders.

**Business implication:** Improve order completeness and coordinate inventory allocation with shipment execution.

### 4. Supplier Reliability

Higher supplier reliability is associated with lower supplier delivery delay.

**Business implication:** Include demonstrated reliability in supplier monitoring and sourcing decisions.

### 5. Inventory Replenishment Coverage

Some reorder-required product-warehouse records have no inbound purchase order.

**Business implication:** Prioritize uncovered replenishment requirements and validate supply needs.

### 6. Warehouse Performance

Warehouse performance differs across fulfillment, backlog, stockout, and delivery metrics.

**Business implication:** Use cross-functional warehouse scorecards to identify improvement priorities.

### 7. Category Performance

Categories differ in commercial exposure, fulfillment performance, and inventory risk.

**Business implication:** Apply category-specific forecasting, replenishment, and service-level strategies.

---

## 🚀 Business Recommendations

| Priority | Recommendation | Expected Business Benefit |
|---|---|---|
| Critical | Review reorder-required records without inbound supply | Reduce uncovered replenishment risk |
| Critical | Prioritize stockout recovery | Improve inventory availability |
| Critical | Focus on high-value and high-demand backlog | Protect commercial performance |
| High | Review supplier delivery failures | Improve procurement reliability |
| High | Improve warehouse fulfillment and delivery coordination | Increase service performance |
| High | Strengthen demand-based replenishment | Reduce backlog and stockout exposure |
| Medium | Review excess inventory | Improve working capital efficiency |
| Medium | Evaluate inter-warehouse transfers | Improve inventory utilization |
| Medium | Develop supplier scorecards | Improve supplier accountability |
| Medium | Monitor cross-functional KPIs | Support continuous improvement |

---

## ✅ Data Validation and Quality Assurance

The project includes structured data quality and validation checks.

Validation areas:

- Total orders and order items
- Product and customer records
- Warehouse and inventory records
- Inventory transaction counts
- Ordered, fulfilled, and backlog quantity reconciliation
- Order quantity consistency
- Stockout and reorder-required records
- Shipment chronology
- Valid and invalid shipment records
- Evaluated purchase orders
- Inventory product-warehouse relationships
- Final SQL project validation

The completed SQL project validation reported:

**24 checks | 24 passed | 0 failed**

The business recommendation reconciliation reported:

**11 checks | 11 passed | 0 failed**

These checks help ensure that the reported KPIs are consistent with the underlying analytical data.

---

## 📁 Suggested GitHub Repository Structure

```text
Sales-Order-Backlog-Inventory-Optimization-Analytics/
│
├── README.md
│
├── data/
│   ├── raw/
│   ├── processed/
│   └── featured/
│
├── Python/
│   └── Notebooks/
│       ├── 01_Data_Understanding.ipynb
│       ├── 02_Data_Quality_Audit.ipynb
│       ├── 03_Data_Cleaning.ipynb
│       ├── 04_Feature_Engineering.ipynb
│       ├── 05_Exploratory_Data_Analysis.ipynb
│       ├── 06_Sales_Order_Analysis.ipynb
│       ├── 07_Backlog_Analysis.ipynb
│       ├── 08_Inventory_Analysis.ipynb
│       ├── 09_Shipment_Delivery_Analysis.ipynb
│       ├── 10_Supplier_Procurement_Analysis.ipynb
│       ├── 11_ABC_XYZ_Analysis.ipynb
│       ├── 12_Inventory_Optimization.ipynb
│       ├── 13_Order_Fulfillment_Analysis.ipynb
│       └── 14_Relationship_Analysis.ipynb
│
├── SQL/
│   ├── Data_Quality/
│   ├── Data_Cleaning/
│   ├── Sales_Analysis/
│   ├── Backlog_Analysis/
│   ├── Inventory_Analysis/
│   ├── Shipment_Analysis/
│   ├── Supplier_Procurement_Analysis/
│   ├── ABC_XYZ_Analysis/
│   ├── Inventory_Optimization/
│   ├── Order_Fulfillment_Analysis/
│   └── Relationship_Analysis/
│
├── PowerBI/
│   ├── Dashboard.pbix
│   └── Screenshots/
│       ├── 01_Executive_Overview.png
│       ├── 02_Sales_Order_Intelligence.png
│       ├── 03_Backlog_Fulfillment.png
│       ├── 04_Inventory_Optimization.png
│       ├── 05_Warehouse_Logistics.png
│       └── 06_Supplier_Procurement.png
│
├── Documentation/
│   ├── Project_Overview.md
│   ├── Data_Dictionary.md
│   ├── Data_Preparation_Methodology.md
│   ├── Python_Analysis_Documentation.md
│   ├── SQL_Analysis_Documentation.md
│   ├── PowerBI_Dashboard_Guide.md
│   ├── KPI_Glossary.md
│   ├── Business_Insights.md
│   ├── Recommendations.md
│   └── Limitations_and_Future_Enhancements.md
│
└── Reports/
    └── Final_Project_Report.pdf
```

*Repository structure is a proposed organization for publishing the completed project. Adjust folder and notebook names to match the actual files before uploading.*

---

## 📚 Project Documentation

The repository will include detailed documentation covering:

- Project overview and business problem
- Dataset descriptions and data dictionary
- Data preparation and feature engineering
- Python analysis methodology
- SQL business questions, queries, and results
- SQL Server to Power BI connection
- Power BI dashboard pages and navigation
- KPI definitions and calculation formulas
- Business insights and recommendations
- Data validation and reconciliation
- Limitations and future enhancements

---

## ⚠️ Limitations

- Historical backlog and current inventory snapshots may not represent the same point in time.
- Correlation indicates association and does not establish causation.
- Shipment chronology issues were identified and invalid records were excluded from relevant delivery-performance analysis.
- Inventory transfer opportunities require operational feasibility checks before execution.
- Business recommendations should be validated against actual operational constraints before implementation.

---

## 🔮 Future Enhancements

Potential future improvements include:

- Demand forecasting
- Inventory safety stock optimization
- Automated replenishment recommendations
- Supplier risk scoring
- Predictive delivery delay modeling
- Automated KPI refresh and monitoring
- Scenario analysis for inventory allocation
- Advanced supply chain optimization

---

## 🏁 Conclusion

Sales Order, Backlog & Inventory Optimization Analytics demonstrates an end-to-end analytics workflow that transforms operational data into meaningful business insights.

By combining **Python for data preparation and analysis, SQL Server for structured business analytics and validation, and Power BI for interactive reporting**, the project provides a comprehensive view of sales performance, backlog exposure, inventory health, warehouse operations, logistics, and supplier performance.

The project demonstrates practical skills in data analytics, SQL development, business intelligence, KPI design, data validation, and operational decision support.

It showcases how analytics can help organizations improve supply chain visibility, prioritize business risks, and make informed operational decisions.

---

