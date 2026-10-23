/*
	CONTAINS / CONTAINSTABLE
*/



USE FullTextSearchTraining
GO

set statistics io on

/* pojedyncze slowa */
--logical reads 69, rows: 23
SELECT * FROM InfoPL 
WHERE FREETEXT(Title, 'rektor')

--logical reads 4, rows: 2
SELECT * FROM InfoPL
WHERE CONTAINS(Title, 'rektor') --contains będzie szybszy


/* frazy */
--logical reads 298, rows: 75
SELECT * FROM InfoPL
WHERE FREETEXT(Title, 'studia podyplomowe')

--logical reads 40, rows: 20
SELECT * FROM InfoPL
WHERE CONTAINS(Title, '"studia podyplomowe"')



/* Boolean searches 

Możliwość wskazania w dokładnym wyszukiwaniu (CONTAINS)- że 
wyniki mają zawierać wszystkie z wymienionych slow- nie ma znaczenia kolejnosc 
i jak są blisko siebie. 
*/

--logical reads 2, rows: 1
SELECT * FROM InfoEN 
WHERE CONTAINS(Title, '"Enrolment" and "courses" and "CISCO"')


/* 
Można używac: AND (&), OR (|), AND NOT (&!)
OR NOT nie jest wspierany przez iFTS
*/

--logical reads 10, rows: 5
SELECT * FROM InfoPL
WHERE CONTAINS(Title, '"inauguracja" and "podyplomowych"')

--logical reads 89, rows: 43
SELECT * FROM InfoPL 
WHERE CONTAINS(Title, '"inauguracja" or "podyplomowych"')

-- taki sam wynik
--logical reads 97, rows: 43
SELECT * FROM InfoPL
WHERE CONTAINS(Title, '"inauguracja" | "podyplomowych"')

--logical reads 36, rows: 18
SELECT * FROM InfoPL AS a
WHERE CONTAINS(a.Title, '"inauguracja" AND NOT "roku"') -- inauguracja nie-roku


/* Prefix searches - słowa zaczynające się kurs*/
--logical reads 48, rows: 24
SELECT * FROM InfoPL 
WHERE CONTAINS(Title, '"kurs*"') 


/* Suffix search niewspierane (w Oracle/DB2 owszem) */
SELECT * FROM InfoPL
WHERE CONTAINS(Title, '"*rs"')




/* INFLECTIONAL

FREETEXT automatycznie wyszukuje wszystkie odmiany wyszukiwanej frazy;
wykorzystujac thezaurus i slowa wynikajace. CONTAINS tego NIE robi.
Mozemy go jednak zachecic- uzywajac operatora FORMSOF i wskazujac, czy chcemy uzyc
INFLECTIONAL czy THESAURUS
*/

--logical reads 28, rows: 14
SELECT * FROM InfoPL 
WHERE CONTAINS(Title, 'kurs')

--logical reads 57, rows: 24
SELECT * FROM InfoPL
WHERE CONTAINS(Title, 'FORMSOF(INFLECTIONAL, kurs)')

--logical reads 28, rows: 14
SELECT * FROM InfoPL
WHERE CONTAINS(Title, 'FORMSOF(THESAURUS, kurs)') --wyrazy bliskoznaczne



/* THESAURUS 

EXPANSION - 
jeśli zostanie napotkane któregolwiek z poniższych słów, 
wyszukiwanie jest rozszerzone o wszystkie słowa wymienione w tagu expansion
Używane na potrzeby definiowania synonimów lub wyrazów bliskoznacznych

--C:\Program Files\Microsoft SQL Server\MSSQL17.SQLSERVER2025\MSSQL\DATA
PLIK: C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\FTData\tsplk.xml

        <expansion>
            <sub>kurs</sub>
            <sub>szkolenie</sub>
			<sub>trening</sub>
        </expansion>

*/ 

--po zmianie w pliku, ale przed przeładowaniem
--logical reads 28, rows: 14
SELECT * FROM InfoPL
WHERE CONTAINS(Title, 'FORMSOF(THESAURUS, kurs)')

-- przeładowanie Thesaurus na podstawie pliku xml, dla wskazanego języka (pamiętaj o usunięciu komentarzy w pliku)
EXEC sp_fulltext_load_thesaurus_file @lcid = 1045

SELECT * FROM sys.dm_fts_parser ( 'FORMSOF(THESAURUS, kurs)', 1045, null, 0 )

--logical reads 66, rows: 28
SELECT * FROM InfoPL
WHERE CONTAINS(Title, 'FORMSOF(THESAURUS, kurs)')

--Zapytanie powyżej działa teraz jak zapytanie poniżej

--logical reads 66, rows: 28
SELECT * FROM InfoPL
WHERE CONTAINS(Title, '"kurs" OR "szkolenie" OR "trening"')



-- logical reads 87, rows: 38
SELECT * FROM InfoPL
WHERE CONTAINS(Title, 'FORMSOF(THESAURUS, kurs) OR FORMSOF(INFLECTIONAL, kurs)')

/* REPLACEMENT

- jeśli zostanie napotkane któreś z wymienionych słów w tagu <replacement><pat>...
- zostaje zamienione na słowo w tagu <sub> i takie jest wyszukiwane

        <replacement>
            <pat>dzik</pat>
            <sub>student</sub>
        </replacement>
*/


--brak danych
SELECT * FROM dbo.InfoPL WHERE CONTAINS ( Title, 'dzik')

SELECT * FROM dbo.InfoPL WHERE CONTAINS ( Title, 'FORMSOF(THESAURUS, dzik)')


--przeladowanie pliku
EXEC sp_fulltext_load_thesaurus_file @lcid = 1045

--thesaurus już zwróci wynik
SELECT * FROM dbo.InfoPL WHERE CONTAINS ( Title, 'FORMSOF(THESAURUS, dzik)')


-- EXPANSION: szkolenie jest zamieniane na kurs i trening
SELECT * FROM sys.dm_fts_parser ( 'FORMSOF(THESAURUS, szkolenie)', 1045, NULL, 0)

-- REPLACEMENT: student NIE jest zamieniany na uczen
SELECT * FROM sys.dm_fts_parser ( 'FORMSOF(THESAURUS, student)', 1045, NULL, 0)



/* Proximity searches

	Wyszukiwanie słów znajdujących się blisko siebie

*/


--stara składnia
SELECT * FROM InfoPL
WHERE CONTAINS(*, '"azure" NEAR "microsoft"')

--ile słów maksymalnie ich dzieli
SELECT * FROM InfoPL 
WHERE CONTAINS(*, 'NEAR(("azure", "microsoft"),4)')

SELECT * FROM InfoPL 
WHERE CONTAINS(*, 'NEAR(("azure", "microsoft"),10)')



/*  Funkcja tabelaryczna CONTAINSTABLE  */

SELECT * 
FROM dbo.InfoPL AS a
JOIN CONTAINSTABLE(dbo.InfoPL, Body, 'student', 10) AS cont
ON cont.[KEY] = a.ID




