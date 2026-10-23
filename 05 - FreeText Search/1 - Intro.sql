/*
	Intro 
	LIKE vs FTS
*/


USE FullTextSearchTraining
GO

SELECT * FROM InfoPL

SET STATISTICS IO ON

-- logical reads 299, rows: 11
SELECT * FROM InfoPL WHERE Title LIKE '%praktyki%'


-- logical reads 22, rows: 11
SELECT * FROM InfoPL WHERE CONTAINS(Title, 'praktyki')


-- logical reads 54, rows:23
-- wyszukuje słowo również w innych formach gramatycznych
SELECT * FROM InfoPL WHERE FREETEXT(Title, 'praktyki')


SELECT * FROM InfoPL WHERE FREETEXT(Title, 'praktyki')
EXCEPT
SELECT * FROM InfoPL WHERE Title LIKE '%praktyki%'


-- FTS jest zależny od języka (rows: 79)
SELECT * FROM InfoPL WHERE Title LIKE '%gra%' -- proGRAm, inteGRAcyjny, GRAduacja

--tylko formy gramatyczne, a nie jak w like wszystko bez ograniczeń (rows: 2)
SELECT * FROM InfoPL WHERE FREETEXT(Title, 'gra') 


-- czy aby na pewno zawsze bardziej wydajnie niż LIKE?

-- Nonclustered index - Title
CREATE INDEX IDX_Info_Title ON InfoPL(Title)


--logical reads 38, rows: 11
SELECT * FROM InfoPL WHERE Title LIKE '%praktyki%'

-- nie wrzucimy tego do klucza indeksu - za duża
CREATE INDEX IDX_News_Body ON InfoPL(Body)

--logical reads 299, rows: 46
SELECT * FROM InfoPL WHERE Body LIKE '%praktyki%'

-- logical reads 103, rows: 46
SELECT * FROM InfoPL WHERE CONTAINS(Body, 'praktyki')

-- logical reads 299, rows: 95
SELECT * FROM InfoPL WHERE FREETEXT(Body, 'praktyki')

drop index InfoPL.IDX_Info_Title




