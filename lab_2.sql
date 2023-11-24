Uppgift 1:

SELECT title, STRING_AGG(genre, ', ') AS genres
FROM books INNER JOIN genre ON books.bookID = genre.bookID
GROUP BY title
ORDER BY title;

Uppgift 2:

SELECT title, rank
FROM (
SELECT title, RANK() OVER(ORDER BY COUNT(*) DESC) AS rank
FROM books 
INNER JOIN resources ON books.bookid = resources.bookid 
INNER JOIN borrowing ON borrowing.physicalid = resources.physicalID
INNER JOIN genre ON books.bookID = genre.bookID
WHERE genre = 'RomCom'
GROUP BY title
) AS ranked
WHERE rank < 6;

Uppgift 3:

SELECT dob.weeknr, dob_count, dor_count, late_count
FROM (
SELECT dob.weeknr, dob_count, dor_count, late_count
FROM 
(SELECT date_part('week', borrowing.dob) AS weeknr, COUNT(*) as dob_count
FROM borrowing
GROUP BY date_part('week', borrowing.dob)
ORDER BY date_part('week', borrowing.dob)) dob 
FULL OUTER JOIN 
(SELECT date_part('week', borrowing.dor) AS weeknr, COUNT(*) as dor_count
FROM borrowing
GROUP BY date_part('week', borrowing.dor)
ORDER BY date_part('week', borrowing.dor)) dor ON dob.weeknr = dor.weeknr
FULL OUTER JOIN 
(SELECT date_part('week', borrowing.dor) AS weeknr, COUNT(*) as late_count
FROM borrowing
WHERE dor > doe
GROUP BY date_part('week', borrowing.dor)
ORDER BY date_part('week', borrowing.dor)) late ON dob.weeknr = late.weeknr
) result
WHERE dob.weeknr < 31

Uppgift 4:

SELECT title, prequelid IS NOT NULL, dob
FROM books 
INNER JOIN resources ON books.bookid = resources.bookid 
INNER JOIN borrowing ON borrowing.physicalid = resources.physicalID
LEFT JOIN prequels ON books.bookid = prequels.bookid
WHERE date_part('month', borrowing.dob) = 2
ORDER BY title collate "C";

Uppgift 5:

WITH RECURSIVE find_prequels AS (
    SELECT title, books.bookid, prequelid
    FROM books 
    LEFT JOIN prequels ON books.bookid = prequels.bookid
    WHERE books.bookID = 8713
    UNION
        SELECT e.title, e.bookid, e.prequelid
        FROM (
            SELECT title, books.bookid as bookid, prequelid
            FROM books
            LEFT JOIN prequels ON books.bookid = prequels.bookid
        ) e
        INNER JOIN find_prequels s ON s.prequelid = e.bookid
) SELECT *
FROM find_prequels;