/*

	https://learn.microsoft.com/en-us/sql/relational-databases/performance/best-practice-with-the-query-store?view=sql-server-ver16
	https://www.sqlskills.com/blogs/erin/query-store-settings/
	- zarządzanie opcjami przez SSMS i T-SQL (ALTER DATABASE)
	- włączenie QUERY STORE czyści cache zapytań (dla wybranej bazy danych)

*/


-- sprawdzenie dla których baz danych jest włączony
SELECT is_query_store_on, * FROM sys.databases


-- Włączenie z ustawieniami domyślnymi
ALTER DATABASE AdventureWorks2025 SET QUERY_STORE = ON
GO

ALTER DATABASE AdventureWorks2025 SET QUERY_STORE 
(
--	READ_WRITE - zbiera statystyki, udostępnia dane (raporty)
--	READ_ONLY - tylko udostępnia dane
--	domyślnie: READ_WRITE
	OPERATION_MODE = READ_WRITE,

--	jak długo przechowywać zebrane dane 
--	domyslnie 30
	CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 1),

	-- jak często zapisywać dane na dysk, 
	-- domyślnie 900 (15 minut)
	DATA_FLUSH_INTERVAL_SECONDS = 60, 

-- okres czasu z którego wyliczane się zagregowane dane - żeby zaoszczędzić miejsce na dysku 
-- domyślnie 1 godzina
	INTERVAL_LENGTH_MINUTES = 1,

--	maksymalny rozmiar na dane zebranie przez Query Store
--	kiedy zostanie osiągnięta ta wartość, QS przełączy się w tryb READ_ONLY
--	domyślnie 100MB (zwykle zbyt mało)
	MAX_STORAGE_SIZE_MB = 1024,

--	AUTO - nie wszystkie zapytania będą zbierane, 
--	np te o nietypowym czasie kompilacji będą pomijane na podstawie wewnętrznie ustalonego progu (niezalecany)
--	NONE - informacje o nowe zapytania nie będą zbierane - tylko te, które już są w cache	
--	domyślnie ALL
	QUERY_CAPTURE_MODE = ALL,


--	AUTO - przed osiągnięciem MAX_STORAGE_MB - stare dane będą oczyszczone
--	OFF - w momencie osiągnięcia MAX_STORAGE_MB - Query Store przewchodzi w tryb READ_ONLY
--	domyślnie AUTO
	SIZE_BASED_CLEANUP_MODE = AUTO,

--	domyślnie 200	
--	maksymalna liczba planów dla pojedynczego zapytania
	MAX_PLANS_PER_QUERY = 200
);


-- sprawdzenie opcji konfiguracyjnych, aktualnego rozmiaru
SELECT * FROM sys.database_query_store_options;  

-- wyczyszczenie bazy QS
ALTER DATABASE AdventureWorks2025 SET QUERY_STORE CLEAR;  




