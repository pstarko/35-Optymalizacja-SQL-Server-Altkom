/*
	Wpływ indeksów na force plan w Query Store
*/

DBCC FREEPROCCACHE


ALTER DATABASE AdventureWorks2025 SET QUERY_STORE CLEAR;  
GO

SELECT sod.*
	FROM Sales.SalesOrderDetail sod
	JOIN Production.Product p ON p.ProductID = sod.ProductID

--nested
SELECT p.ProductID, UnitPrice
FROM Sales.SalesOrderDetail sod 
JOIN Production.Product p ON p.ProductID = sod.ProductID
WHERE ProductSubcategoryID = 38 -- NewBikes

--hash
SELECT p.ProductID, sod.UnitPrice
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON p.ProductID = sod.ProductID
WHERE ProductSubcategoryID = 1 -- MTB

--dodaje indeks nieklastrowy na productid z inlude sod.unitPrice
CREATE NONCLUSTERED INDEX NonClusterProductIdUnitPrice 
ON Sales.SalesOrderDetail (ProductID ) INCLUDE(UnitPrice)


--nested, ale już z wykorzystaniem nowego indeksu
SELECT p.ProductID, UnitPrice
FROM Sales.SalesOrderDetail sod 
JOIN Production.Product p ON p.ProductID = sod.ProductID
WHERE ProductSubcategoryID = 38 -- New Bikes

--nested zamiast hash, ale już z wykorzystaniem nowego indeksu
SELECT p.ProductID, sod.UnitPrice
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON p.ProductID = sod.ProductID
WHERE ProductSubcategoryID = 1 -- MTB


DBCC FREEPROCCACHE
ALTER DATABASE AdventureWorks2025 SET QUERY_STORE CLEAR;  
GO

CREATE OR ALTER PROC ShowOrdersForSubCategory @SubCategoryID int
AS

	SELECT p.ProductID, sod.UnitPrice
	FROM Sales.SalesOrderDetail sod
	JOIN Production.Product p ON p.ProductID = sod.ProductID
	WHERE ProductSubcategoryID = @SubCategoryID 
GO

EXEC ShowOrdersForSubCategory 38 
GO 

-- Nested Loop (dzięki parameter sniffing używa tego samego planu z wykorzystaniem indeksu)
EXEC ShowOrdersForSubCategory 1
GO 

--ustawiam force plan z Nested Loopsem
--następnie usuwam stworzony indeks nieklastrowy
DROP INDEX NonClusterProductIdUnitPrice ON Sales.SalesOrderDetail

EXEC ShowOrdersForSubCategory 38 
EXEC ShowOrdersForSubCategory 1 

/*
Tworzy się nowy plan mimo ustawień FORCE - Query Store Plan inteligentnie unika zablokowania zapytania
Poniższe zapytanie pokaże, że mimo ustawienia pola is_forced_plan = 1, mamy rownież force_failure_count=1 co oznacza ilość 
uruchomień zapytań gdy force plan nie mógł być zastosowany
*/

SELECT qsqt.query_sql_text,
       OBJECT_NAME(qsq.object_id) AS ProcedureName,
       qsp.query_plan_hash,
       CAST(qsp.query_plan AS XML) AS query_plan,
       qsp.is_forced_plan,
       qsp.is_natively_compiled,
       qsp.force_failure_count,
       qsp.last_force_failure_reason_desc
FROM sys.query_store_query qsq 
		INNER JOIN sys.query_store_query_text qsqt ON qsqt.query_text_id = qsq.query_text_id
		INNER JOIN sys.query_store_plan qsp ON qsp.query_id = qsq.query_id
	WHERE qsp.is_forced_plan = 1
		AND qsp.force_failure_count > 0


--usuwam stary force plan i ustawiam nowy force plan dla planu BEZ indeksu
--a teraz dodaje indeks... product_id z includem unit price

--dodaje indeks nieklastrowy na productid z inlude sod.unitPrice
CREATE NONCLUSTERED INDEX NonClusterProductIdUnitPrice ON Sales.SalesOrderDetail(ProductID ) INCLUDE(UnitPrice)


EXEC ShowOrdersForSubCategory 38 
EXEC ShowOrdersForSubCategory 1 

--niestety tutaj Query Store nie sprawdzi, czy użycie nowego indeksu mogłoby polepszyć optymalizację, będzie używał starego planu z FORCE PLAN

DROP INDEX NonClusterProductIdUnitPrice ON Sales.SalesOrderDetail