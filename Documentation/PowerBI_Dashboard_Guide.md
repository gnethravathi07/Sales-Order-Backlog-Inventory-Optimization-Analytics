# Power BI Dashboard Guide

## 1. Dashboard Overview

The **Sales Order, Backlog & Inventory Optimization Analytics** Power BI report provides an interactive view of supply chain performance.

The report connects to SQL Server and presents business metrics across sales, order fulfillment, backlog, inventory, warehouse operations, logistics, suppliers, and procurement.

The dashboard is designed to help users monitor performance, identify operational gaps, and explore business patterns through interactive filtering.

## 2. Dashboard Structure

The completed report contains six pages:

1. Executive Overview
2. Sales & Order Performance
3. Backlog & Fulfilment Analysis
4. Inventory Health & Stock Optimization
5. Warehouse & Logistics Performance
6. Supplier & Procurement Performance

Each page focuses on a specific business area while contributing to the overall supply chain performance analysis.

## 3. Power BI and SQL Server Connection

SQL Server was used as the data source for the Power BI report.

The connection allows the dashboard to use structured data and analytical results prepared in SQL Server.

### Connection workflow

1. Open Power BI Desktop.
2. Select **Get Data**.
3. Choose **SQL Server**.
4. Enter the SQL Server server name and database details.
5. Select the required tables or views.
6. Load or transform the selected data as required.
7. Build the report using the connected data.

The actual connection mode—Import or DirectQuery—should be documented according to the setting used in the PBIX file.

Do not publish server credentials, passwords, or other sensitive connection information in the GitHub repository.

## 4. Dashboard Design

The report uses a light blue-grey background (`#EAF1F5`), dark navy text, teal accents, and gold/orange highlights.

The design provides a consistent visual style across the six pages.

The report includes interactive elements such as:

- KPI cards
- Slicers
- Charts and data visuals
- Interactive filtering
- Page navigation

## 5. Dashboard Page Guide

### Page 1: Executive Overview

Purpose: Provide a high-level summary of overall business and supply chain performance.

This page serves as the starting point for users to understand the main performance indicators before exploring detailed business areas.

Users can use the overview to identify areas requiring further investigation.

### Page 2: Sales & Order Performance

Purpose: Analyze sales and order-related performance.

This page supports investigation of sales value, order volume, and order performance across relevant business dimensions.

Users can explore sales and order patterns to understand how performance varies across products, warehouses, and other available categories.

### Page 3: Backlog & Fulfilment Analysis

Purpose: Evaluate unfulfilled demand and order fulfillment performance.

This page supports analysis of backlog quantity, backlog value, and fulfillment metrics.

Users can investigate where backlog is concentrated and identify business areas that may require operational attention.

### Page 4: Inventory Health & Stock Optimization

Purpose: Evaluate inventory availability and stock health.

This page supports analysis of inventory value, stock status, replenishment requirements, and inventory optimization opportunities.

Users can investigate stockout, overstock, and reorder-related patterns to support inventory planning.

### Page 5: Warehouse & Logistics Performance

Purpose: Examine warehouse and logistics performance.

This page supports analysis of warehouse operations and shipment-related performance.

Users can explore operational differences across warehouses and investigate delivery performance patterns.

### Page 6: Supplier & Procurement Performance

Purpose: Analyze supplier performance and procurement operations.

This page supports investigation of supplier reliability, purchase order performance, and procurement-related metrics.

Users can identify supplier and replenishment areas that may require additional monitoring.

## 6. Dashboard Navigation

The report includes page navigation to move between the six dashboard sections.

Recommended navigation sequence:

1. Start with Executive Overview.
2. Review Sales & Order Performance.
3. Investigate Backlog & Fulfilment Analysis.
4. Examine Inventory Health & Stock Optimization.
5. Review Warehouse & Logistics Performance.
6. Explore Supplier & Procurement Performance.

This sequence moves from overall performance to detailed operational analysis.

## 7. Using Slicers and Interactive Visuals

The report includes slicers and interactive visuals to support exploration.

Recommended usage:

1. Select a relevant slicer value to filter the report.
2. Observe how KPI cards and charts respond.
3. Select a data point in a visual to explore related information where interactions are enabled.
4. Clear or reset filters when returning to the overall view.
5. Compare business areas using consistent filter selections.

Slicer fields and visual interactions depend on the configuration of the individual report page.

## 8. Key Metrics Covered

The report supports analysis of major supply chain metrics, including:

- Sales value
- Ordered quantity
- Fulfilled quantity
- Backlog quantity
- Backlog value
- Order fill rate
- Inventory value
- Reorder requirements
- Stockout and overstock records
- Shipment on-time performance
- OTIF performance
- Average delivery delay
- Supplier on-time performance
- Purchase order performance

Refer to `KPI_Glossary.md` for metric definitions and calculation details.

## 9. Dashboard Interpretation

The dashboard should be used as an analytical decision-support tool.

When interpreting results:

- Review KPI values together with their relevant business dimensions.
- Investigate high backlog values alongside demand and fulfillment.
- Consider inventory availability and replenishment requirements when evaluating stock issues.
- Interpret delivery metrics using valid shipment chronology.
- Compare supplier performance using the defined evaluation population.
- Treat statistical relationships as associations rather than proof of causation.

## 10. Dashboard Limitations

Dashboard results depend on the quality and completeness of the underlying operational datasets.

Shipment records with invalid chronology were treated separately from valid delivery-performance calculations.

The dashboard provides analytical visibility but does not automatically execute inventory replenishment, procurement, or operational changes.

## 11. Conclusion

The Power BI dashboard provides an integrated view of supply chain performance through six interactive report pages.

By connecting SQL Server analysis with visual reporting, the dashboard helps users explore sales, backlog, fulfillment, inventory, logistics, and procurement performance.

The report supports business monitoring, operational investigation, and data-driven decision-making.

---

**Project:** Sales Order, Backlog & Inventory Optimization Analytics  
**Reporting Tool:** Power BI  
**Data Source:** SQL Server  
**Report Pages:** 6
