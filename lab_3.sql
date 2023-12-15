SELECT COUNT(*), title
FROM (
    SELECT title, physicalid
    FROM books INNER JOIN resources ON books.bookID = resources.bookID
    EXCEPT 
    SELECT title, resources.physicalid
    FROM books INNER JOIN resources ON books.bookID = resources.bookID
    INNER JOIN borrowing on resources.physicalid = borrowing.physicalid
    WHERE dor IS NULL
) books
GROUP BY title

SELECT COUNT(*), title
FROM books INNER JOIN resources ON books.bookID = resources.bookID
GROUP BY title