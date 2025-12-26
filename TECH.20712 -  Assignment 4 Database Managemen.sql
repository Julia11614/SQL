/*
 *		TECH.20712 -- Database Management
 *		
 *		HEC Montréal,
 *		Practical Assignment 4
 *		
 */
USE AdventureWorks2019
/*
	Question #1:
		Your new lifelong friend, Mr. Sales Director, is now interested in the details of the largest sale recorded by
		AdventureWorks in the first quarter of 2014. He wants the following details:
			- the order number
			- the total amount due, including taxes, shipping, etc.
			- the order date
			- the ID of the salesperson who made the sale
			- the last name and first name of the salesperson who made the sale, all in a single cell!
			- the total quantity (OrderQty) of products included in the order

		He takes the time to mention that he only wants the details of this specific sale (the largest recorded by
		AdventureWorks in Q1 2014). He therefore expects a single row as the result.

		Note: you remember that at HEC you learned that to find transactions by quarter you can use
		built-in functions. For example,

		YEAR(SalesOrderHeader.OrderDate)=2014 AND DATEPART(QUARTER, SalesOrderHeader.OrderDate)=1

		Note: You notice that there are multiple ways to answer this query, but you are asked to do it using subqueries.
*/

-- I assume that the largest recorded sale means the sale with the highest total due
SELECT
    soh.SalesOrderID AS 'Order Number',
    soh.TotalDue AS 'Total Due',
    soh.OrderDate AS 'Order Date',
    soh.SalesPersonID AS 'Salesperson ID',
    CONCAT(pp.LastName, ' ', pp.FirstName) AS 'Salesperson Full Name',
    SUM(sod.OrderQty) AS 'Product Quantity'

FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Person.Person pp ON pp.BusinessEntityID = soh.SalesPersonID

GROUP BY soh.SalesOrderID, soh.TotalDue, soh.OrderDate, soh.SalesPersonID, pp.LastName, pp.FirstName

HAVING soh.SalesOrderID = (
	-- Subquery
    SELECT TOP 1 
		soh2.SalesOrderID -- Largest recorded sale
    FROM Sales.SalesOrderHeader soh2
    WHERE YEAR(soh2.OrderDate) = 2014 AND DATEPART(QUARTER, soh2.OrderDate) = 1 -- First quarter of 2014
    GROUP BY soh2.SalesOrderID
    ORDER BY SUM(soh2.TotalDue) DESC
)


/*
	Question #2:
		The sales director would also like to know which stores have an ordered amount
		(before taxes and shipping) (SubTotal) in the first quarter of 2014 that is greater
		than the average ordered amount (before taxes and shipping) of the last quarter of 2013.
		Obviously, this concerns in-store sales only.

		He mentions that he wants to retrieve only the store ID and store name,
		ordered from the smallest to the largest store ID.

		The top of the resulting table looks like this:

		Store ID	|	Store Name
		-----------------------------------------------
		294			|	Professional Sales and Service
		296			|	Riders Company
		300			|	Nationwide Supply
*/

SELECT
	ss.BusinessEntityID AS 'Store ID',
	ss.Name AS 'Store Name'
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.Customer sc ON soh.CustomerID = sc.CustomerID
INNER JOIN Sales.Store ss ON sc.StoreID = ss.BusinessEntityID
WHERE YEAR(soh.OrderDate) = 2014 AND DATEPART(QUARTER, soh.OrderDate) = 1 -- First quarter of 2014
GROUP BY ss.BusinessEntityID, ss.Name, soh.SubTotal
HAVING soh.SubTotal >
	(SELECT AVG(SubQ.SubTotalSales)
	FROM
	(SELECT
		soh2.SubTotal AS 'SubTotalSales'
	FROM Sales.SalesOrderHeader soh2
	WHERE YEAR(soh2.OrderDate) = 2013 AND DATEPART(QUARTER, soh2.OrderDate) = 4 -- Last quarter of 2013
	) AS SubQ
)



-- Question 3:
/*
AdventureWorks knows that its product documentation needs to be improved.
The production director asks you to extract the names of employees responsible
for products that have associated documents.
The query should return each employee’s name (last name from the Person table)
and the number of products under their responsibility for which documentation exists.
*/

SELECT
	pp.LastName AS 'Employee Name',
	COUNT(DISTINCT ppd.ProductID) AS 'Number of Products' 
	-- I assume that a product with two related documents should be counted as a single product
FROM Person.Person pp
INNER JOIN Production.Document pd ON pp.BusinessEntityID = pd.Owner
INNER JOIN Production.ProductDocument ppd ON pd.DocumentNode = ppd.DocumentNode
WHERE pd.DocumentNode IS NOT NULL -- Verify that documentation exists
GROUP BY pp.LastName



-- Question 4:

/*
AdventureWorks plans to become a global company next year.
It must now prepare to deliver anywhere on the planet.
The delivery department will divide the planet into 5 sections:
	1. North East (NE)
	2. North West (NW)
	3. South East (SE)
	4. South West (SW)
	5. Equator (Equator)

You are asked to create a function called TrouveCaridalite that returns the globe section as text
based on the input coordinates.

If latitude is equal to 0, the function returns 'Equator'
If latitude is greater than 0 and less than 90, the function returns North
If longitude is between 0 and 180, the function returns East
If longitude is between 0 (inclusive) and -180, the function returns West
...
If latitude values are less than -90 or greater than 90, return Error
If longitude values are less than -180 or greater than 180, return Error
*/
DROP FUNCTION IF EXISTS dbo.TrouveCaridalite
GO

CREATE FUNCTION dbo.TrouveCaridalite (@Latitude INT, @Longitude INT)
RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @SectionGlobe VARCHAR(20)

	IF (@Latitude < -90 OR @Latitude > 90)
		SET @SectionGlobe = 'Error'
	ELSE IF (@Longitude < -180 OR @Longitude > 180)
		SET @SectionGlobe = 'Error'
	ELSE IF (@Latitude = 0)
		SET @SectionGlobe = 'Equator'

	ELSE
	BEGIN
		DECLARE @directionLatitude VARCHAR(20)
		DECLARE @directionLongitude VARCHAR(20)

		IF (@Latitude > 0 AND @Latitude < 90)
			SET @directionLatitude = 'North'
		ELSE 
			SET @directionLatitude = 'South '

		IF (@Longitude BETWEEN 0 AND 180)
			SET @directionLongitude = 'East'
		ELSE IF (@Longitude <= 0 AND @Longitude > -180) -- I assume 180 is excluded
			SET @directionLongitude = 'West'

		SET @SectionGlobe = @directionLatitude + @directionLongitude
	END

	RETURN @SectionGlobe
END
GO

-- Here are examples to test your code
SELECT dbo.TrouveCaridalite(0,10)      -- returns 'Equator'
SELECT dbo.TrouveCaridalite(0,-210)    -- returns 'Error'
SELECT dbo.TrouveCaridalite(923,10)    -- returns 'Error'
SELECT dbo.TrouveCaridalite(50.59,110) -- returns 'NE'
SELECT dbo.TrouveCaridalite(-30,-178)  -- returns 'SW'
SELECT dbo.TrouveCaridalite(45.54,-70) -- returns 'NW'
SELECT dbo.TrouveCaridalite(-60,50)    -- returns 'SE'



/*
Question 5 - View creation: vTotalWebSalesPerCustomer
	For online orders, create a view that displays the total amount sold per customer
	(before taxes and shipping) (Subtotal) in the first quarter of 2014.

	Keep only the following attributes:
	- CustomerID
	- Full customer name in the following format (single cell):
		- Title LastName, FirstName
		  *Be careful to remove any extra spaces before or after the text*
	- Total amount purchased per customer (web)
	- Add a column "Customer Importance" with the following values:
	  If total amount purchased is                     <= 1000 --> "Unimportant customer"
	  If total amount purchased is > 1000 and <= 2000 --> "Low importance customer"
	  If total amount purchased is > 2000 and <= 3000 --> "Very important customer"
	  If total amount purchased is > 3000              --> "VIP customer"
*/

DROP VIEW IF EXISTS vTotalWebSalesPerCustomer
GO

CREATE VIEW vTotalWebSalesPerCustomer AS
SELECT
	sc.CustomerID AS [Customer ID],
	CONCAT(pp.Title, ' ', TRIM(pp.LastName), ' ', TRIM(pp.FirstName)) AS [Full Name],
	SUM(soh.SubTotal) AS [TotalSumPerWebCustomer],
	CASE 
        WHEN SUM(soh.SubTotal) <= 1000 THEN 'Unimportant customer'
        WHEN SUM(soh.SubTotal) > 1000 AND SUM(soh.SubTotal) <= 2000 THEN 'Low importance customer'
        WHEN SUM(soh.SubTotal) > 2000 AND SUM(soh.SubTotal) <= 3000 THEN 'Very important customer'
        ELSE 'VIP customer'
    END AS 'Customer Importance'

FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.Customer sc ON soh.CustomerID = sc.CustomerID
INNER JOIN Person.Person pp ON sc.PersonID = pp.BusinessEntityID

WHERE soh.OnlineOrderFlag = 1
  AND YEAR(soh.OrderDate) = 2014
  AND DATEPART(QUARTER, soh.OrderDate) = 1
GROUP BY sc.CustomerID, pp.Title, pp.LastName, pp.FirstName
GO



/*
-- View validation
	When validating your view, you are asked to keep only VIP customers in your query
	on your new view. Your query should look like this:

	Customer ID | Full Name           | TotalSumPerWebCustomer | Customer Importance
	17192       | He, Warren          | 4796.02                | VIP customer
	17199       | Zhou, Dennis        | 4816.00                | VIP customer
	17209       | James, Jacqueline   | 4739.05                | VIP customer
	17220       | Wang, Glenn         | 4733.29                | VIP customer
*/
SELECT *
FROM vTotalWebSalesPerCustomer
WHERE [Customer Importance] = 'VIP customer'
