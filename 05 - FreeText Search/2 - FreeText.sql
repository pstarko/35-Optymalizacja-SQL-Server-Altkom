/*
	FREETEXT / FREETEXTTABLE

*/


USE FullTextSearchTraining
GO

set statistics io on

/* Funkcja FREETEXT  */

--logical reads 10, rows:5
SELECT * FROM InfoPL WHERE FREETEXT(Title, 'europa')

--logical reads 61, rows: 26
SELECT * FROM InfoPL WHERE FREETEXT(Body, 'europa')

--logical reads 66, rows: 28
SELECT * FROM InfoPL WHERE FREETEXT((Title, Body), 'europa')

--logical reads 66, rows: 28
SELECT * FROM InfoPL WHERE FREETEXT(*, 'europa')


--występuje pierwsze lub drugie słowo
SELECT * FROM InfoPL 
WHERE FREETEXT(Title, 'studia podyplomowe') 


/*  Funkcja tabelaryczna FREETEXTTABLE  */

--nazwa tabeli, kolumny, tekst, ograniczenie wyniku do 50 rekordów 
--w wyniku ranking od 1-1000  (im wyższy nr tym bardziej pasuje)
SELECT * FROM FREETEXTTABLE(dbo.InfoPL, *, '"studia podyplomowe"', 50)

--logical reads 112, rows:50
SELECT *
	FROM FREETEXTTABLE(dbo.InfoPL, *, '"studia podyplomowe"', 50) AS free
		INNER JOIN InfoPL AS a ON free.[KEY] = a.ID
ORDER BY RANK DESC

--czy na tej kolumnie jest oparty FTS?
SELECT INDEXPROPERTY( OBJECT_ID('InfoPL'), 'PK_InfoPL',  'IsFulltextKey')

-- How Search Query Results Are Ranked
-- https://docs.microsoft.com/en-us/sql/relational-databases/search/limit-search-results-with-rank




/*  Niezależne wyszukiwanie po dwóch różnych kolumnach (wskazanie w której kolumnie są dane) */

SELECT *, 1 AS TitleSearch FROM InfoPL AS a
INNER JOIN FREETEXTTABLE(dbo.InfoPL, Title, '"studia podyplomowe"', 20) AS free
ON free.[KEY] = a.ID
UNION ALL
SELECT *, 0 AS TitleSearch FROM InfoPL AS a
INNER JOIN FREETEXTTABLE(dbo.InfoPL, Body, '"studia podyplomowe"', 20) AS free
ON free.[KEY] = a.ID
-- ORDER BY TitleSearch DESC, free.[RANK] DESC
ORDER BY ID -- ID 1146 -- 18




/*  Wyszukiwanie po kilku kolumnach jednocześnie - tak by nie powtarzać wierszy (tego samego id np. 1158)*/
DECLARE @szukaj nvarchar(50) = 'studia podyplomowe'

SELECT TOP 20 * 
FROM 
(
	SELECT ArticleID, SUM([RANK])AS [Rank]
	FROM (
		SELECT
			t.[KEY] AS ArticleID,
			t.[RANK] AS [RANK]
		FROM FREETEXTTABLE(dbo.InfoPL, Title, @szukaj) AS t
		UNION ALL
		SELECT 
			c.[KEY],
			c.[RANK]
		FROM FREETEXTTABLE(dbo.InfoPL, Body, @szukaj) AS c
	) AS ResultUnion
	GROUP BY ArticleID
) AS ResultGrouped
INNER JOIN InfoPL 
ON InfoPL.ID = ResultGrouped.ArticleID
ORDER BY [Rank] DESC


