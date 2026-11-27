# Limitations and Future Enhancements

## 1. Overview

The **Sales Order, Backlog & Inventory Optimization Analytics** project integrates sales, order fulfilment, inventory, shipment, warehouse, supplier, and procurement data to evaluate operational performance and identify improvement opportunities.

Although the project provides a comprehensive analytical view of supply chain operations, certain data-quality issues, analytical assumptions, and scope limitations should be considered when interpreting the results.

This document outlines the key limitations and potential future enhancements.

## 2. Project Limitations

### 2.1 Data Quality Limitations

The project identified data-quality issues during the preparation and validation process.

- Exact duplicate records were identified in the inventory transactions dataset and removed during cleaning.
- Shipment records with invalid date chronology were identified where the actual delivery date occurred before the shipment date.
- Invalid shipment chronology affects the reliability of delivery performance calculations.
- Some records required validation before they could be included in operational KPI calculations.

These issues demonstrate the importance of data-quality controls before using operational data for business decisions.

### 2.2 Shipment and Delivery KPI Limitations

Shipment performance metrics were calculated using valid shipment chronology.

The shipment dataset contained records with invalid date chronology. These records were evaluated separately to avoid misleading delivery performance results.

Consequently, delivery KPIs such as on-time delivery, OTIF, and average delivery delay should be interpreted in the context of the validated shipment records.

### 2.3 Inventory Optimization Limitations

Inventory analysis evaluated stock availability, safety stock, reorder points, inventory value, days of inventory on hand, stockouts, and overstock conditions.

However, inventory optimization depends on the accuracy of demand and replenishment inputs.

The analysis does not guarantee that calculated reorder requirements will always represent the optimal replenishment decision under changing business conditions.

Future inventory planning should consider demand variability, supplier uncertainty, product-specific constraints, and changing service-level requirements.

### 2.4 Supplier and Procurement Limitations

Supplier performance was evaluated using available supplier attributes, purchase order records, expected dates, actual receipt dates, and delivery performance.

Supplier reliability and quality ratings provide useful analytical indicators, but they may not fully represent all aspects of supplier performance.

Additional supplier information, such as historical disruptions, capacity constraints, price changes, and contractual performance, could improve procurement analysis.

### 2.5 Analytical Interpretation Limitations

The project used descriptive analysis, KPI comparisons, segmentation, and correlation analysis to identify operational relationships.

Correlation results indicate association between variables and do not establish causation.

For example, a relationship between backlog and sales value does not independently prove that sales value causes backlog. Further investigation and operational validation would be required to determine the underlying reasons.

### 2.6 Historical Data Limitations

The project evaluates the operational data available in the provided datasets.

Historical patterns may not fully represent future business conditions, particularly when demand, supplier performance, product availability, or operational processes change.

The results should therefore be used as decision-support information rather than as guaranteed future outcomes.

## 3. Future Enhancements

### 3.1 Advanced Demand Forecasting

Develop demand forecasting models using historical sales and inventory movement data.

Potential enhancements include:

- Time-series forecasting at product and warehouse level.
- Seasonal demand analysis.
- Forecast accuracy measurement.
- Demand variability and uncertainty estimation.
- Forecast-driven inventory planning.

### 3.2 Dynamic Safety Stock and Reorder Point Optimization

Enhance inventory planning by incorporating demand variability and supplier lead-time uncertainty.

Future models could calculate:

- Dynamic safety stock.
- Service-level-based reorder points.
- Economic order quantities.
- Replenishment recommendations.
- Inventory risk alerts.

### 3.3 Predictive Backlog Analytics

Develop predictive models to identify orders at risk of delayed fulfilment.

Potential features include:

- Backlog risk classification.
- Predicted fulfilment delay.
- Product and warehouse risk scoring.
- Early-warning indicators for high-value orders.
- Prioritization of orders requiring operational attention.

### 3.4 Supplier Risk Scoring

Create a supplier risk model using historical procurement and delivery performance.

The model could combine:

- Supplier reliability.
- Delivery delay history.
- Quality ratings.
- Lead-time variability.
- Purchase order fulfilment performance.

This would support supplier comparison and risk-based procurement planning.

### 3.5 Automated Data Quality Monitoring

Introduce automated validation checks to identify data issues during future data refreshes.

Possible checks include:

- Duplicate record detection.
- Missing or invalid dates.
- Negative or inconsistent quantities.
- Invalid order and shipment chronology.
- Referential integrity checks.
- Unexpected changes in KPI values.

### 3.6 Automated Data Refresh and Reporting

Enhance the reporting workflow with scheduled data refreshes and automated reporting.

Future improvements could include:

- Automated SQL Server data updates.
- Scheduled Power BI dataset refresh.
- Refresh status monitoring.
- Exception reporting.
- Automated operational KPI summaries.

### 3.7 Expanded Power BI Analytics

The existing Power BI dashboard can be enhanced with additional analytical capabilities.

Potential improvements include:

- Drill-through pages for product, warehouse, and supplier analysis.
- Dynamic KPI comparisons.
- Backlog ageing analysis.
- Inventory risk segmentation.
- Forecast versus actual performance.
- Automated alerts for critical operational conditions.

## 4. Conclusion

This project demonstrates an end-to-end analytical approach to understanding sales order performance, backlog, inventory health, shipment operations, warehouse performance, and supplier reliability.

The identified limitations highlight the importance of data validation, careful KPI interpretation, and continuous monitoring.

Future enhancements involving forecasting, predictive analytics, dynamic inventory optimization, supplier risk scoring, and automated reporting could extend the project from operational performance analysis toward a more proactive supply chain decision-support solution.
