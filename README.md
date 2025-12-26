# SQL Database Management Assignments

## Course Information

**Course Code:** TECH.20712 - Database Management

**Institution:** HEC Montreal

**Term:** Fall 2023

## Overview

This repository contains practical SQL assignments completed as part of the Database Management course. All assignments utilize the AdventureWorks2019 database to demonstrate proficiency in complex SQL queries, data analysis, and database management concepts.

## Repository Contents

### Assignment 3: Database Management

**File:** `TECH.20712 - Assignment 3 Database Management.sql`

**Topics Covered:**

- **Complex Joins:** Multi-table joins involving product inventory, sales, and location data
- **Data Aggregation:** Using GROUP BY, COUNT, and SUM for analytical reporting
- **Filtering and Sorting:** Advanced WHERE clauses with HAVING conditions
- **Data Formatting:** Custom formatting of monetary values with thousands separators and currency symbols
- **Production Analysis:** Analyzing scrapped products, manufacturing costs, and work order details
- **Sales Analysis:** Territory-based sales reporting and discount analysis

**Key Questions Addressed:**

1. **Warehouse Cleanup Analysis** - Identifying top 20 most-ordered products stored in multiple warehouse locations with French product descriptions
2. **Store Performance Comparison** - Analyzing 2012 in-store sales performance with formatted monetary values
3. **Production Waste Analysis** - Calculating monetary losses and potential lost profits from scrapped products
4. **Manufacturing Cost Analysis** - Comparing estimated vs actual manufacturing costs across work orders
5. **North American Sales Report** - Comprehensive sales breakdown by country, category, and subcategory
6. **Discount Analysis** - Proving the existence and impact of discount programs on product sales

### Assignment 4: Database Management

**File:** `TECH.20712 - Assignment 4 Database Managemen.sql`

**Topics Covered:**

- **Subqueries:** Using nested queries for complex data retrieval
- **Temporal Analysis:** Quarterly sales analysis using date functions
- **User-Defined Functions:** Creating custom scalar functions with complex business logic
- **Views:** Designing and implementing database views for data abstraction
- **Conditional Logic:** CASE statements for data categorization
- **Data Concatenation:** Combining multiple fields for enhanced readability

**Key Questions Addressed:**

1. **Largest Sale Analysis (Q1 2014)** - Using subqueries to identify and analyze the largest transaction, including salesperson details and order quantities
2. **Store Performance Comparison** - Identifying stores with Q1 2014 sales exceeding Q4 2013 averages using subqueries
3. **Product Documentation Analysis** - Extracting employee information for products with associated documentation
4. **Geographic Function Development** - Creating a custom function (`TrouveCaridalite`) to determine global sections based on latitude/longitude coordinates
   - Validates coordinate ranges
   - Returns directional indicators (North/South + East/West)
   - Handles special cases (Equator, Error conditions)
5. **Customer Segmentation View** - Creating a view (`vTotalWebSalesPerCustomer`) for online customer analysis with importance categorization:
   - Unimportant customer (<=1000)
   - Low importance customer (1000-2000)
   - Very important customer (2000-3000)
   - VIP customer (>3000)

## Technical Skills Demonstrated

### SQL Techniques

- **JOIN Operations:** INNER JOIN, LEFT JOIN for multi-table queries
- **Aggregate Functions:** SUM, COUNT, AVG, MAX for data analysis
- **Subqueries:** Correlated and non-correlated subqueries for complex filtering
- **Date Functions:** YEAR, DATEPART for temporal analysis
- **String Functions:** CONCAT, TRIM, FORMAT for data presentation
- **Conditional Logic:** CASE statements, HAVING clauses
- **Window Functions:** GROUP BY with aggregation
- **User-Defined Functions:** Scalar functions with input validation
- **Views:** Creating reusable query abstractions

### Database Concepts

- Relational database design and normalization
- Query optimization strategies
- Data warehouse analysis
- Business intelligence reporting
- Customer segmentation
- Sales performance metrics
- Manufacturing and inventory management
- Cost analysis and profitability calculations

## Database Schema

The assignments work with the AdventureWorks2019 database, utilizing the following key tables:

### Sales Schema

- `Sales.SalesOrderHeader` - Order header information
- `Sales.SalesOrderDetail` - Line item details
- `Sales.Customer` - Customer records
- `Sales.Store` - Store information
- `Sales.SalesTerritory` - Geographic territories
- `Sales.SpecialOffer` - Discount and promotion data
- `Sales.SpecialOfferProduct` - Product-specific offers

### Production Schema

- `Production.Product` - Product master data
- `Production.ProductModel` - Product model information
- `Production.ProductDescription` - Multilingual descriptions
- `Production.ProductCategory` - Product categories
- `Production.ProductSubcategory` - Product subcategories
- `Production.ProductInventory` - Inventory levels
- `Production.Location` - Warehouse locations
- `Production.WorkOrder` - Manufacturing orders
- `Production.WorkOrderRouting` - Manufacturing steps
- `Production.ScrapReason` - Defect reasons
- `Production.Document` - Product documentation
- `Production.ProductDocument` - Product-document relationships

### Person Schema

- `Person.Person` - Individual person records
- `Person.BusinessEntity` - Business entity information

## Learning Outcomes

Through these assignments, the following competencies were developed:

- Designing and executing complex multi-table SQL queries
- Analyzing business data to extract meaningful insights
- Creating reusable database objects (functions, views)
- Applying data formatting for business reporting
- Understanding relational database relationships
- Implementing data validation and error handling
- Optimizing query performance
- Translating business requirements into SQL logic

## License

These files are academic coursework completed for educational purposes at HEC Montreal.
