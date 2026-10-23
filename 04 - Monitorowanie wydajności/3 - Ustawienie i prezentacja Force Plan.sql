/*
	Force Plans

*/

DBCC FREEPROCCACHE


ALTER DATABASE AdventureWorks2025 SET QUERY_STORE CLEAR;  
GO

USE AdventureWorks2025
GO

--tworzę nową podkategorię
IF NOT EXISTS(SELECT * FROM Production.ProductSubcategory WHERE name like '%New Bikes%')
	INSERT INTO Production.ProductSubcategory (ProductCategoryID, Name)
	VALUES (1, 'New Bikes')

--ustawiam constrainy i indeksy bym mógł załadować dane
IF EXISTS(SELECT * FROM sys.foreign_keys 
	WHERE name = 'FK_SalesOrderDetail_SpecialOfferProduct_SpecialOfferIDProductID')
BEGIN

	ALTER TABLE Sales.SalesOrderDetail 
	DROP CONSTRAINT FK_SalesOrderDetail_SpecialOfferProduct_SpecialOfferIDProductID

END

go

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IDX_Product_SubcategoryID')
	CREATE INDEX IDX_Product_SubcategoryID ON Production.Product (ProductSubcategoryID)

go
----------

----------PROC
DECLARE @SWorksID int
SELECT @SWorksID = ProductID FROM Production.Product WHERE name like '%New Bikes%'

IF @SWorksID IS NULL
BEGIN
	INSERT INTO Production.Product 
	(Name, Color, ProductNumber, SafetyStockLevel, ReorderPoint, ListPrice, StandardCost, ProductSubcategoryID, DaysToManufacture, SellStartDate)
	VALUES ('S-Works New Bikes', 'Red', '95219-0002', 10, 2, 12050, 6000, 38, 60, '20190101')

	SELECT @SWorksID = SCOPE_IDENTITY()
END
	PRINT 'SWORKS'
	PRINT @SWorksID
	

SELECT * FROM Sales.SalesOrderDetail WHERE ProductID = 1006

IF NOT EXISTS(SELECT * FROM Sales.SalesOrderDetail WHERE ProductID = @SWorksID)
BEGIN 

	DECLARE @ProductID_ToChange int 
	SELECT TOP 1 @ProductID_ToChange = ProductID FROM Production.Product WHERE ProductSubcategoryID = 3
	SELECT DISTINCT TOP 3  SalesOrderID INTO #SalesToChange FROM Sales.SalesOrderDetail WHERE ProductID = @ProductID_ToChange
	
	SELECT * FROM #SalesToChange
	
	UPDATE TOP(1) Sales.SalesOrderDetail SET ProductID = @SWorksID WHERE SalesOrderID IN (SELECT SalesOrderID FROM #SalesToChange)
	DROP TABLE #SalesToChange

END
GO
-----------END PROC


-- ProductSubcategoryID: 38
SELECT ProductSubcategoryID, Name FROM Production.ProductSubcategory WHERE name = 'New Bikes'

-- ProductSubcategoryID: 1
SELECT ProductSubcategoryID, Name FROM Production.ProductSubcategory WHERE name = 'Mountain Bikes'


-- Mountain Bikes - 32 wiersze
SELECT * FROM Production.Product WHERE ProductSubcategoryID = 1

-- New Bikes - 1 wiersz
SELECT * FROM Production.Product WHERE ProductSubcategoryID = 38

-- Zamówienia na New Bikes
-- execution plan
SELECT sod.*
FROM Sales.SalesOrderDetail sod 
JOIN Production.Product p ON p.ProductID = sod.ProductID
WHERE ProductSubcategoryID = 38 -- New Bikes


-- Zamówienia na MTB
-- execution plan
SELECT sod.*
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON p.ProductID = sod.ProductID
WHERE ProductSubcategoryID = 1 -- MTB
GO




-- Sprawdźmy co siedzi w QS
-- * tylko z ostatnich 5 min
-- * pomijając zapytania do Query Store
SELECT qs_qt.query_sql_text, qs_run.avg_duration, qs_run.last_logical_io_reads, qs_run.count_executions, *
FROM sys.query_store_plan AS qs_p  
JOIN sys.query_store_query AS qs_q  
  ON qs_p.query_id = qs_q.query_id  
JOIN sys.query_store_query_text AS qs_qt  
  ON qs_q.query_text_id = qs_qt.query_text_id
JOIN sys.query_store_runtime_stats AS qs_run
  ON qs_run.plan_id = qs_p.plan_id
WHERE qs_p.last_execution_time > DATEADD(MINUTE, -10, GETUTCDATE())
	AND query_sql_text NOT LIKE '%query_store%'
ORDER BY qs_run.count_executions DESC
GO


-- PROC i parameter sniffing
CREATE OR ALTER PROC ShowOrdersForSubCategory
@SubCategoryID int
AS

	SELECT sod.*
	FROM Sales.SalesOrderDetail sod
	JOIN Production.Product p ON p.ProductID = sod.ProductID
	WHERE ProductSubcategoryID = @SubCategoryID 
GO

DBCC FREEPROCCACHE


ALTER DATABASE AdventureWorks2025 SET QUERY_STORE CLEAR;  
GO

SET STATISTICS IO ON

-- execution plan
-- Nested Loop 
EXEC ShowOrdersForSubCategory 38
GO 

-- Nested Loop
EXEC ShowOrdersForSubCategory 1
GO 

--> Query Store - mam tam jeden plan dla procedury ShowOrdersForSubCategory


ALTER DATABASE AdventureWorks2025 SET QUERY_STORE CLEAR;  

DBCC FREEPROCCACHE



EXEC ShowOrdersForSubCategory 38 WITH RECOMPILE
GO 

EXEC ShowOrdersForSubCategory 1 WITH RECOMPILE
GO 

--> QS - mam już dwa plany ustawiam Force Plan
--> Query Store - Force Plan

DBCC FREEPROCCACHE


EXEC ShowOrdersForSubCategory 38 WITH RECOMPILE
GO 

EXEC ShowOrdersForSubCategory 1 WITH RECOMPILE
GO 

-- Use Plan: True

-- zeby sprawdzic ktory plan jest wymuszony
SELECT CAST(query_plan AS xml), * 
FROM sys.query_store_plan WHERE is_forced_plan = 1



/*
SSMS
  * raport Queries With Forced Plans
  * wyłączyć wymuszanie planu
*/


-- lista wymuszonych planów jest pusta
SELECT CAST(query_plan AS xml), * 
FROM sys.query_store_plan WHERE is_forced_plan = 1


-- procedury mają dwa różne plany
EXEC ShowOrdersForSubCategory 38 WITH RECOMPILE
GO 

EXEC ShowOrdersForSubCategory 1 WITH RECOMPILE
GO 

drop procedure ShowOrdersForSubCategory
