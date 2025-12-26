/*
 *		TECH220712 -- Database Management														
 *		
 *		HEC Montréal, Fall 2023
 *		Practical Assignment 3	
 *		
 *		
 *		Submission instructions:
 *			- Answer the questions directly in this SQL file
 *			- Submit via ZoneCours using the Assignment Submission tool
 *
 *		Additional instructions
 *			- Use the AdventureWorks2019 database to answer the questions below.
 *			- Unless otherwise specified, you are asked for a single query that returns the requested results per question.

 */

USE AdventureWorks2019
GO

/*
=> Question 1

	It is time for a major cleanup in the AdventureWorks warehouse. There is a lot of work to do!
	The sales director asks you to extract information related to the following products:
			1. Product name;
			2. Product model name (Production.ProductModel)
			3. Product description in French (see Culture tables)
			4. The number of warehouse locations where the product is stored (Production.Location);
			5. The total quantity of this product that has been ordered by customers.
	
	He wants this information only for finished goods that can be stored in 2 or more warehouse locations.
	Knowing that there is a lot of work to do, he only asks for the 20 products that have been ordered the most by customers
	to start with.
	Note: The same product models and product descriptions may appear on multiple rows, since some products have different colors.
*/

SELECT TOP 20 -- Select 20 products
	PP.Name AS 'Product name', 
	PPM.Name AS 'Product model name', 
	PPD.Description AS 'Product description in French',
	COUNT(DISTINCT PL.LocationID) AS 'Number of warehouse locations where the product is stored',
	SUM(SOD.OrderQty) AS 'Total quantity of this product ordered by customers'

FROM Production.Product PP 
	INNER JOIN Production.ProductModel PPM ON PP.ProductModelID = PPM.ProductModelID
	INNER JOIN Production.ProductModelProductDescriptionCulture PPMPDC ON PP.ProductModelID = PPMPDC.ProductModelID
	INNER JOIN Production.ProductDescription PPD ON PPMPDC.ProductDescriptionID = PPD.ProductDescriptionID
	INNER JOIN Production.Culture PC ON PPMPDC.CultureID = PC.CultureID
	INNER JOIN Production.ProductInventory PPI ON PP.ProductID = PPI.ProductID
	INNER JOIN Production.Location PL ON PPI.LocationID = PL.LocationID
	INNER JOIN Sales.SalesOrderDetail SOD ON PP.ProductID = SOD.ProductID

WHERE 
	PC.Name = 'FRENCH' -- Product description in French
    AND FinishedGoodsFlag = 1  -- Finished products

GROUP BY PP.ProductID, PP.Name, PPM.Name, PPD.Description
HAVING COUNT(PL.LocationID) >= 2 -- Products stored in 2 or more warehouse locations

ORDER BY SUM(SOD.OrderQty) DESC -- Most ordered products



/*
=> Question 2

	Your colleagues would like to compare store performance in 2012.
	They are interested in knowing sales amounts in dollars (including taxes and shipping) per store.
	They are therefore only interested in in-store (in-person) sales.
	They want sales that were not rejected or canceled.

	The result must have the following three columns (exact names):
		- StoreID of the store
		- Store name
		- Sales in 2012
	
	In the [Sales in 2012] column, display amounts rounded to two decimal places and with a thousands separator.
	Example: 418802.4507 should be displayed as: 418,802.45 or 418 802.45. Add a dollar sign.
	
	Make sure to present the information exactly as requested and to correctly name the columns.
	The results must be sorted alphabetically by store name.
*/

SELECT
	SS.BusinessEntityID AS 'StoreID of the store',
	SS.Name AS 'Store name',
	FORMAT(SUM(SOH.TotalDue), 'N', 'en-US') + '$' AS 'Sales in 2012'

FROM Sales.SalesOrderHeader SOH
	INNER JOIN Sales.Customer SC ON SOH.CustomerID = SC.CustomerID
	INNER JOIN Sales.Store SS ON SC.StoreID = SS.BusinessEntityID
WHERE SOH.OrderDate >= '2012-01-01' AND SOH.OrderDate < '2013-01-01' -- Sales from 2012
	AND SOH.Status != 4 AND SOH.Status != 6 -- Excluding rejected or canceled sales
	AND SOH.OnlineOrderFlag = 0
GROUP BY SS.BusinessEntityID, SS.Name
ORDER BY SS.Name -- Results sorted alphabetically by store name



/*
=> Question 3

	Back to work on Monday morning, your boss comes to see you with a new request.
	He heard that you know the data related to products that were scrapped (discarded)
	and has a request concerning them.
	
	He would like the list of products (product names) that were rejected during production,
	with the explicit reason why they were scrapped and the quantity discarded.
	By explicit, he means that he does not want IDs in the list since he cannot interpret them.
	He also wants to know, per combination of product and scrap reason, the monetary loss caused
	by the production of these products, as well as the potential lost profit,
	i.e. what could have been earned if these products had been produced without defects
	and then sold at list prices.

	For columns representing monetary amounts, display amounts rounded to two decimal places
	and with a thousands separator.
	Example: 418802.4507 should be displayed as: 418,802.45 or 418 802.45. Add a dollar sign.

	He takes the time to mention that he only wants the requested information in the resulting table
	(no more, no less).

	In addition, he only wants products that were manufactured in 2013 and whose production cost loss
	is $150 or more.
*/

SELECT 
	PP.Name AS 'Product name',
	PS.Name AS 'Scrap reason',
	SUM(PW.ScrappedQty) AS 'Quantity of scrapped products',
	CONCAT(
		FORMAT(ROUND(SUM(PW.ScrappedQty * PP.StandardCost), 2), 'N', 'en-US'),
		'$'
	) AS 'Monetary loss', -- Scrapped quantity multiplied by production cost
	CONCAT(
		FORMAT(ROUND(SUM(PW.ScrappedQty * (PP.ListPrice - PP.StandardCost)), 2), 'N', 'en-US'),
		'$'
	) AS 'Potential lost profit' -- Scrapped quantity multiplied by potential profit per product
FROM Production.Product PP 
	INNER JOIN Production.WorkOrder PW ON PP.ProductID = PW.ProductID
	INNER JOIN Production.ScrapReason PS ON PW.ScrapReasonID = PS.ScrapReasonID
WHERE PW.StartDate >= '2013-01-01' AND PW.StartDate < '2014-01-01' -- Products manufactured in 2013
GROUP BY PP.Name, PS.Name
HAVING SUM(PW.ScrappedQty * PP.StandardCost) >= 150 -- Production cost loss of $150 or more



/*
=> Question 4

	Your boss would like information about the effort and costs associated with manufacturing
	the different products per work order.
	He wants the list of work orders with:
	- Work order identifier
	- Associated product names (the same product may be manufactured on multiple work orders)
	- Quantity of product to manufacture per work order
	- Total number of manufacturing hours required per work order
	- Number of steps required in the manufacturing process per work order
	- Estimated total manufacturing cost per work order
	- Actual total manufacturing cost per work order
	- Difference between estimated and actual manufacturing cost per work order
	
	Did any work orders exceed the estimated cost?
	Answer: No, the difference between estimated and actual cost is always 0.
*/ 
SELECT
	PW.WorkOrderID AS 'Work order identifier',
	PP.Name AS 'Associated product names',
	PW.OrderQty AS 'Quantity of product to manufacture',
	SUM(PWOR.ActualResourceHrs) AS 'Total manufacturing hours required',
	COUNT(PWOR.OperationSequence) AS 'Number of manufacturing steps',
	FORMAT(SUM(PWOR.PlannedCost), '00.00') + '$' AS 'Estimated total manufacturing cost',
	FORMAT(SUM(PWOR.ActualCost), '00.00') + '$' AS 'Actual total manufacturing cost',
	FORMAT(SUM(PWOR.PlannedCost - PWOR.ActualCost), '00.00') + '$' AS 'Difference between estimated and actual manufacturing cost' 
	-- Difference: Estimated cost - Actual cost

FROM Production.Product PP
	INNER JOIN Production.WorkOrder PW ON PP.ProductID = PW.ProductID
	INNER JOIN Production.WorkOrderRouting PWOR ON PW.WorkOrderID = PWOR.WorkOrderID

GROUP BY PW.WorkOrderID, PP.Name, PW.OrderQty
ORDER BY SUM(PWOR.PlannedCost - PWOR.ActualCost) -- Results sorted by difference between estimated and actual cost



/*
=> Question 5
	
	The CEO of AdventureWorks comes to see you and mentions that he would like to learn more
	about sales made in the North American territory.
	
	He asks you to produce a report presenting the total sales per North American country,
	per product category AND per product subcategory.
	In addition, he wants monetary amounts displayed with 2 decimal places followed by a '$' (e.g. 10.00$).
	Finally, he would like the report data sorted in descending order of total sales.
	
	Reminders:
	- Add descriptive column names to your report, you will present it to your CEO!
	- We want FULL country names (not codes) for North American countries, not territory names.
	- The absence of an "official" subcategory is considered a subcategory itself.
	- Split the monetary formatting into two parts: the numeric portion (1.00) and the dollar sign ($).
	- AdventureWorks records its sales in US dollars regardless of country; no currency conversion is required.
	- Make sure to choose the correct column to calculate total sales based on joins; otherwise results will be incorrect!
*/

SELECT
	FORMAT(SUM(SSOH.TotalDue), '0,000.00') + '$' AS 'Total sales',
	REPLACE(REPLACE(SST.CountryRegionCode, 'US', 'United States'), 'CA', 'Canada') AS 'Country',
	PPC.Name AS 'Category',
	ISNULL(PPS.Name, 'Missing Subcategory') AS 'Subcategory' -- Absence of an official subcategory
FROM Sales.SalesOrderHeader SSOH
	INNER JOIN Sales.SalesTerritory SST ON SSOH.TerritoryID = SST.TerritoryID
	INNER JOIN Sales.SalesOrderDetail SSOD ON SSOH.SalesOrderID = SSOD.SalesOrderID
	INNER JOIN Production.Product PP ON SSOD.ProductID = PP.ProductID
	LEFT JOIN Production.ProductSubcategory PPS ON PP.ProductSubcategoryID = PPS.ProductSubcategoryID
	LEFT JOIN Production.ProductCategory PPC ON PPS.ProductCategoryID = PPC.ProductCategoryID
WHERE SST.[Group] = 'North America' -- Sales made in the North American territory
GROUP BY SST.CountryRegionCode, PPS.Name, PPC.Name
ORDER BY SUM(SSOH.TotalDue) DESC -- Descending order of total sales



/*
=> Question 6

	Your new lifelong friend, the CEO of AdventureWorks, comes to see you again.
	He mentions how much he does not believe that AdventureWorks sells products at a discount.
	You want to prove him wrong, namely that there are many products sold at a discount.
	You must therefore write a query to support your point of view.
	The results must take the following form:
	
		- Discount type
		- Discount description
		- Group to whom the discount is applied (Customer or Reseller)
		- Quantity of products sold per discount type; labeled as 'Quantity of discounted products sold'
		- Amount of products sold per discount type; labeled as 'Amount of discounted products sold'.
		  Monetary amounts must be displayed with 2 decimal places followed by a '$' (e.g. 10.00$).
	
	Sort the results in ascending order by discount type and discount description.
*/

SELECT 
	SSO.Type AS 'Discount type',
	SSO.Description AS 'Discount description',
	SSO.Category AS 'Group to whom the discount is applied',
	SUM(SSOD.OrderQty) AS 'Quantity of discounted products sold', 
	-- Sum of quantities of discounted products sold per discount type
	FORMAT(SUM(SSOD.LineTotal), 'N', 'en-US') + '$' AS 'Amount of discounted products sold'
	-- LineTotal: UnitPrice * (1 - UnitPriceDiscount) * OrderQty

FROM Sales.SalesOrderDetail SSOD
	INNER JOIN Sales.SpecialOfferProduct SSOP ON SSOD.ProductID = SSOP.ProductID
	INNER JOIN Sales.SpecialOffer SSO ON SSOP.SpecialOfferID = SSO.SpecialOfferID

GROUP BY SSO.Type, SSO.Description, SSO.Category
ORDER BY 
    SSO.Type ASC, -- Sort by discount type ascending
	SSO.Description ASC; -- Then sort by discount description ascending
