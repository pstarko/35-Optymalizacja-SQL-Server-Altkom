/*
	Zapytania i plany

*/


SELECT * FROM Sales.SalesOrderDetail

-- QS: Wykonywane zapytania
SELECT * FROM sys.query_store_query

-- Kilka innych widoków - żeby dowiedzieć się o treść zapytania
-- posortowane wg liczby wykonań malejąco

SELECT qs_qt.query_sql_text, qs_run.avg_duration, qs_run.last_logical_io_reads, qs_run.count_executions, *
FROM sys.query_store_plan AS qs_p  
		JOIN sys.query_store_query AS qs_q  ON qs_p.query_id = qs_q.query_id  
		JOIN sys.query_store_query_text AS qs_qt  ON qs_q.query_text_id = qs_qt.query_text_id
		JOIN sys.query_store_runtime_stats AS qs_run ON qs_run.plan_id = qs_p.plan_id
ORDER BY qs_run.count_executions DESC



SELECT * 
FROM Sales.SalesOrderDetail
GO 10


-- lista zapytań
SELECT * FROM sys.query_store_query

-- lista planow
SELECT * FROM sys.query_store_plan

-- tresc zapytań
SELECT * FROM sys.query_store_query_text



SELECT qs_qt.query_sql_text, *
FROM sys.query_store_plan AS qs_p  JOIN sys.query_store_query AS qs_q    ON qs_p.query_id = qs_q.query_id  
								   JOIN sys.query_store_query_text AS qs_qt ON qs_q.query_text_id = qs_qt.query_text_id



-- Zapytanie na podstawie którego jest generowany raport
SELECT 
	qs_qt.query_text_id
	,qs_p.query_id
	,qs_p.plan_id
	,qs_q.object_id
	,OBJECT_NAME(qs_q.object_id) AS object_name
	,qs_qt.query_sql_text
	,CONVERT(varchar(20), qs_p.last_execution_time, 120)
	,TRY_CONVERT(XML, qs_p.query_plan) AS query_plan
FROM sys.query_store_plan AS qs_p  JOIN sys.query_store_query AS qs_q  ON qs_p.query_id = qs_q.query_id  
								   JOIN sys.query_store_query_text AS qs_qt ON qs_q.query_text_id = qs_qt.query_text_id
WHERE 
	qs_p.last_execution_time > DATEADD(MINUTE, -10, GETUTCDATE())
	AND qs_qt.query_sql_text NOT LIKE '%qs_p%' 
