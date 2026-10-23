/*
	Widoki Funkcje Procedury
	https://docs.microsoft.com/en-us/sql/relational-databases/performance/monitoring-performance-by-using-the-query-store?view=sql-server-2017	
*/


USE AdventureWorks2025

SELECT count(*) FROM Sales.SalesOrderDetail

/*

	Widoki

*/

-- sys.database_query_store_options
-- ustawienia Query Store, rozmiar bazy
SELECT actual_state, actual_state_desc, current_storage_size_mb, max_storage_size_mb, * 
FROM sys.database_query_store_options


-- sys.query_store_plan
-- Informacje o każdym wykonaniu zapytania
SELECT * FROM sys.query_store_plan ORDER BY initial_compile_start_time DESC


-- sys.query_store_query
-- Zapytania i zagregowane statystyki; sredni/ ostatni czas kompilacji etc
SELECT * FROM sys.query_store_query



-- sys.query_context_settings
-- ustawienia sesji - ktore wplywaja na wykonywanie zapytan
SELECT * FROM sys.query_context_settings

SET datefirst 1

SELECT * FROM sys.query_context_settings

SET datefirst 7

SELECT * FROM sys.query_context_settings
SELECT DISTINCT context_settings_id FROM sys.query_store_query 



-- sys.query_store_query_text
-- Treść (tekst) wykonywanych zapytań 
SELECT * FROM sys.query_store_query_text

SELECT * FROM sys.query_store_query_text WHERE query_sql_text LIKE '% FROM Sales.SalesOrderDetail%'


--SELECT count(*) FROM Sales.SalesOrderDetail

-- sys.query_store_runtime_stats 
-- Statystyki uruchomieniowe zapytań (planów)


SELECT query_sql_text, avg_duration, last_duration, max_duration, avg_logical_io_reads, last_logical_io_reads, max_logical_io_reads
FROM sys.query_store_runtime_stats AS qs_rs
JOIN sys.query_store_plan AS qs_p ON qs_p.plan_id = qs_rs.plan_id
JOIN sys.query_store_query AS qs_q ON qs_q.query_id = qs_p.query_id
JOIN sys.query_store_query_text AS qs_qt ON qs_qt.query_text_id = qs_q.query_text_id
WHERE query_sql_text LIKE '%SELECT count(*) FROM Sales.SalesOrderDetail%'
ORDER BY avg_logical_io_reads DESC



-- sys.query_store_wait_stats -- SQL Server 2017+
-- typy oczekiwania dla 

--pogrupowane
SELECT *FROM sys.query_store_wait_stats


SELECT query_sql_text, qs_ws.*
FROM sys.query_store_wait_stats AS qs_ws
JOIN sys.query_store_plan AS qs_p ON qs_p.plan_id = qs_ws.plan_id
JOIN sys.query_store_query AS qs_q ON qs_q.query_id = qs_p.query_id
JOIN sys.query_store_query_text AS qs_qt ON qs_qt.query_text_id = qs_q.query_text_id
WHERE query_sql_text LIKE '%SELECT count(*) FROM Sales.SalesOrderDetail%'
ORDER BY qs_q.query_id, avg_query_wait_time_ms DESC




-- sys.query_store_runtime_stats_interval 
-- Okresy zbierania statystyk (bazujące na konfiguracji: INTERVAL_LENGTH_MINUTES)
-- dane w query storze będą powiązane z kolumną runtime_stats_interval_id
SELECT * FROM sys.query_store_runtime_stats_interval 


/*
	Funkcje
*/


-- zwraca uchwyt zapytania (statement_sql_handle) na podstawie treści zapytania
SELECT * FROM sys.fn_stmt_sql_handle_from_sql_stmt('SELECT count(*) FROM Sales.SalesOrderDetail', NULL)

-- dla wszystkich zapytan w Query Store
SELECT qt.query_text_id, q.query_id, qt.query_sql_text, qt.statement_sql_handle,  
q.context_settings_id, qs.statement_context_id   
FROM sys.query_store_query_text AS qt JOIN sys.query_store_query AS q  ON qt.query_text_id = q.query_id  
									  CROSS APPLY sys.fn_stmt_sql_handle_from_sql_stmt (qt.query_sql_text, null) AS fn_handle_from_stmt  
									  JOIN sys.dm_exec_query_stats AS qs  ON fn_handle_from_stmt.statement_sql_handle = qs.statement_sql_handle;  


/*

	Procedury

*/



-- sp_query_store_flush_db;  
-- Zapisuje dane QS w pamięci na dysk

EXEC sp_query_store_flush_db;  


-- sp_query_store_reset_exec_stats
-- Czyści statystyki dla wybranego planu

-- wyszukać plan_id...
SELECT query_sql_text, qs_p.plan_id, avg_duration, last_duration, max_duration, avg_logical_io_reads, last_logical_io_reads, max_logical_io_reads
FROM sys.query_store_runtime_stats AS qs_rs
JOIN sys.query_store_plan AS qs_p ON qs_p.plan_id = qs_rs.plan_id
JOIN sys.query_store_query AS qs_q ON qs_q.query_id = qs_p.query_id
JOIN sys.query_store_query_text AS qs_qt ON qs_qt.query_text_id = qs_q.query_text_id
WHERE query_sql_text LIKE '%SELECT count(*) FROM Sales.SalesOrderDetail%'
ORDER BY avg_logical_io_reads DESC

SELECT * FROM sys.query_store_runtime_stats WHERE plan_id  = 85
SELECT * FROM sys.query_store_wait_stats WHERE plan_id = 85

EXEC sp_query_store_reset_exec_stats 85

--usunąłem dane, zatem puste wyniki
SELECT * FROM sys.query_store_runtime_stats WHERE plan_id  = 85
SELECT * FROM sys.query_store_wait_stats WHERE plan_id = 85
GO

-- sp_query_store_force_plan
-- wymusza plan dla zapytania

-- wyszukac zapytania które mają więcej niż 1 plan...

EXEC ShowOrdersForSubCategory 38 WITH RECOMPILE
EXEC ShowOrdersForSubCategory 1 WITH RECOMPILE
GO 


SELECT qs_q.query_id, qs_q.query_text_id, OBJECT_NAME(object_id), qs_qt.query_sql_text
FROM sys.query_store_query AS qs_q
JOIN sys.query_store_plan AS qs_p
ON qs_p.query_id = qs_q.query_id
JOIN sys.query_store_query_text AS qs_qt
ON qs_qt.query_text_id = qs_q.query_text_id
WHERE OBJECT_NAME(object_id) = 'ShowOrdersForSubCategory'
GROUP BY qs_q.query_id, qs_q.query_text_id, OBJECT_NAME(object_id), qs_qt.query_sql_text
HAVING COUNT(*) > 1 --więcej niż jeden plan

--kopiuje query_id i wrzucam do zapytania poniżej
SELECT plan_id, query_id, is_forced_plan, CONVERT(XML, query_plan), *
FROM sys.query_store_plan WHERE query_id = 1

--dla zapytania 1 chcę by był zawsze wykonany plan 14
EXEC sp_query_store_force_plan @query_id = 1, @plan_id = 19

-- kolumna is_forced_plan
SELECT plan_id, query_id, is_forced_plan, CONVERT(XML, query_plan), *
FROM sys.query_store_plan WHERE query_id = 1


-- sp_query_store_unforce_plan 
-- Usuwa wymuszenie plany  
EXEC sp_query_store_unforce_plan @query_id = 1, @plan_id = 19



SELECT plan_id, query_id, is_forced_plan, CONVERT(XML, query_plan), *
FROM sys.query_store_plan WHERE query_id = 1



-- sp_query_store_remove_query
-- Usuwa zapytanie z Query Store i wszystkie powiązane plany
EXEC sp_query_store_remove_query @query_id = 1

