# SQL Analysis Documentation

## 1. Introduction

SQL Server was used as the primary environment for structured business analysis in the **Sales Order, Backlog & Inventory Optimization Analytics** project.

The SQL analysis focused on transforming operational data into business metrics, identifying performance gaps, and supporting cross-functional supply chain analysis.

The queries were designed to investigate sales performance, order fulfillment, backlog, inventory health, warehouse operations, shipment performance, supplier reliability, and procurement.

## 2. SQL Environment

| Component | Description |
|---|---|
| Database platform | SQL Server |
| Query language | T-SQL |
| Data source | 10 operational datasets |
| Reporting tool | Power BI |
| Analysis purpose | Business performance analysis and decision support |

The analytical datasets were loaded into SQL Server and queried using T-SQL.

## 3. SQL Analysis Workflow

The SQL analysis followed a structured process:

1. Inspect tables and record counts
2. Audit data quality
3. Validate identifiers and relationships
4. Analyze sales and order performance
5. Analyze backlog and fulfillment
6. Evaluate inventory health
7. Analyze shipment and delivery performance
8. Evaluate supplier and procurement performance
9. Perform cross-functional analysis
10. Validate analytical results and recommendations

## 4. Data Quality and Validation

SQL was used to check data quality and business-rule consistency before calculating business KPIs.

The validation work included:

- Record-count checks
- Duplicate checks
- Identifier and relationship checks
- Quantity consistency checks
- Status validation
- Date chronology checks
- KPI reconciliation

### Shipment chronology validation

Shipment records were reviewed to identify cases where the actual delivery date occurred before the shipment date.

| Shipment records | Count |
|---|---:|
| Total shipments | 24,798 |
| Valid chronology | 20,331 |
| Invalid chronology | 4,467 |

The invalid chronology records were treated separately from valid delivery-performance calculations.

## 5. Sales and Order Analysis

The sales analysis examined overall sales value, order volume, and ordered versus fulfilled quantities.

### Business questions

- What is the total sales value?
- How many sales orders were created?
- What quantity was ordered?
- How much quantity was fulfilled?
- How does sales performance vary across products and warehouses?
- Which products contribute most to sales value?

### Key results

| Metric | Result |
|---|---:|
| Sales orders | 25,000 |
| Total sales value | 2,068,495,698.91 |
| Ordered quantity | 501,755 |
| Fulfilled quantity | 440,576 |

The analysis established the overall sales and order baseline for subsequent backlog and fulfillment analysis.

## 6. Backlog and Order Fulfillment Analysis

Backlog analysis focused on unfulfilled demand and its impact on operational performance.

### Business questions

- How much ordered quantity remains unfulfilled?
- What is the backlog value?
- What percentage of orders are backlogged?
- Which products and warehouses contribute most to backlog?
- How does order fill rate vary across business segments?

### Key results

| Metric | Result |
|---|---:|
| Backlog quantity | 61,179 |
| Backlog value | 257,349,919.66 |
| Backlogged orders | 10,850 |
| Backlogged orders as a percentage of total orders | 43.40% |
| Overall order fill rate | 87.81% |

The analysis identified backlog as a major operational performance area requiring further investigation.

## 7. Inventory Health and Optimization Analysis

Inventory analysis evaluated stock availability, inventory value, and replenishment requirements.

### Business questions

- What is the total inventory value?
- Which records require replenishment?
- Where are stockout conditions present?
- Which records indicate overstock?
- How does inventory health vary by product and warehouse?
- Which inventory records require additional procurement attention?

### Key results

| Metric | Result |
|---|---:|
| Inventory value | 285,985,182.32 |
| Reorder-required records | 1,311 |
| Stockout records | 240 |
| Overstock records | 478 |

The analysis supported inventory prioritization and replenishment planning.

## 8. Shipment and Delivery Performance Analysis

Shipment analysis evaluated delivery performance using shipment dates, requested delivery dates, actual delivery dates, and shipment quantities.

### Business questions

- How many shipments were recorded?
- What percentage of valid shipments were delivered on time?
- What percentage achieved OTIF performance?
- What was the average delivery delay?
- How does delivery performance vary by warehouse and fulfillment status?

### Key results

| Metric | Result |
|---|---:|
| Total shipments | 24,798 |
| Valid chronology shipments | 20,331 |
| On-time performance for valid shipments | 71.22% |
| OTIF performance for valid shipments | 46.25% |
| Average delivery delay for valid shipments | 0.93 days |

Shipment records with invalid chronology were excluded from valid delivery-performance calculations.

## 9. Supplier and Procurement Analysis

Supplier and procurement analysis focused on purchase order performance, supplier reliability, and replenishment coverage.

### Business questions

- How many purchase orders were evaluated?
- What is the supplier on-time performance?
- How does supplier reliability relate to delivery delay?
- Which reorder-required inventory records have inbound purchase orders?
- Where are procurement coverage gaps present?

### Key results

| Metric | Result |
|---|---:|
| Evaluated purchase orders | 8,470 |
| Supplier on-time performance | 65.35% |
| Reorder-required records with inbound purchase orders | 1,080 |
| Reorder-required records without inbound purchase orders | 231 |

The analysis highlighted the importance of supplier performance monitoring and inbound procurement visibility.

## 10. ABC-XYZ and Inventory Classification

ABC-XYZ analysis was used to support inventory prioritization.

The classification helped examine inventory from two perspectives:

- ABC: relative importance based on the project's value-based classification approach
- XYZ: demand variability and demand-pattern classification

The combined classification supported differentiated inventory management rather than applying the same replenishment approach to every product.

## 11. Cross-Functional and Relationship Analysis

SQL analysis was extended across multiple operational areas to examine relationships between demand, backlog, fulfillment, inventory, delivery, and supplier performance.

### Selected relationship findings

| Relationship | Correlation |
|---|---:|
| Demand and backlog quantity | 0.7755 |
| Sales value and backlog value | 0.9199 |
| Inventory days on hand and backlog rate | -0.0010 |
| Supplier reliability and supplier delay | -0.2320 |
| Fill rate and delivery delay | -0.1904 |
| Backlog percentage and delivery delay | 0.1904 |
| Supplier quality and supplier delay | 0.0005 |
| Contract lead time and supplier delay | 0.0119 |

Correlation values indicate statistical association in the analyzed data. They do not establish causation.

## 12. Business Recommendation Analysis

SQL analysis supported the development and reconciliation of business recommendations.

The recommendation analysis considered:

- Backlog concentration
- High-demand product and warehouse combinations
- Inventory replenishment requirements
- Stockout and overstock conditions
- Shipment and fulfillment performance
- Supplier reliability
- Inbound purchase order coverage

The findings were used to prioritize operational improvement opportunities.

## 13. SQL Validation Results

The final SQL validation process completed:

| Validation result | Count |
|---|---:|
| Checks passed | 24 |
| Checks failed | 0 |

Business recommendation reconciliation completed:

| Reconciliation result | Count |
|---|---:|
| Checks passed | 11 |
| Checks failed | 0 |

These checks supported the consistency of the final analytical results.

## 14. SQL Analysis Outcome

The SQL analysis provided a structured view of supply chain performance across sales, backlog, fulfillment, inventory, logistics, and procurement.

The results established key performance baselines, highlighted operational gaps, and supported the business recommendations presented in the project.

---

**Project:** Sales Order, Backlog & Inventory Optimization Analytics  
**Database:** SQL Server  
**Language:** T-SQL  
**Reporting:** Power BI
