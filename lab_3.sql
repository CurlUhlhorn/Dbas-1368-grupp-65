-- Used in python

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

-- Triggers

CREATE TRIGGER max_four_books
  BEFORE INSERT
  ON borrowing
  FOR EACH ROW
  EXECUTE PROCEDURE max_four_books_func();

CREATE OR REPLACE FUNCTION max_four_books_func()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
DECLARE _borrowing_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO _borrowing_count FROM borrowing WHERE dor is NULL GROUP BY userid HAVING userid = NEW.userid;

    IF 4 < _borrowing_count THEN
        RAISE 'User has already borrowed the maximum allowed amount of book. Return a book to be able to borrow more.';
    END IF;
	RETURN NEW;
END;
$$

CREATE TRIGGER six_loans
  AFTER INSERT 
  ON borrowing
  FOR EACH ROW
  EXECUTE PROCEDURE six_loans_func();

CREATE OR REPLACE FUNCTION six_loans_func()
  RETURNS TRIGGER
  LANGUAGE PLPGSQL
  AS
$$

    DECLARE _amount_of_times_borrowed INTEGER;
    DECLARE _isbn TEXT;
BEGIN
    SELECT isbn INTO _isbn
    FROM resources r JOIN edition e ON r.bookid = e.bookid
    WHERE r.physicalid = NEW.physicalid;

    SELECT COUNT(*)
    INTO _amount_of_times_borrowed
    FROM borrowing b
    JOIN resources r ON b.physicalid = r.physicalid
    JOIN edition e ON r.bookid = e.bookid
    WHERE b.userid = NEW.userid
    GROUP BY e.isbn
    HAVING e.isbn = _isbn;

    IF _amount_of_times_borrowed > 6 THEN
        RAISE 'User has alredy borrowed the book more than 6 times and is denied from borrowing it again';
    END IF;
    RETURN NEW;
END;
$$  

CREATE TRIGGER no_unpaid_fines
  BEFORE INSERT
  ON borrowing
  FOR EACH ROW
  EXECUTE PROCEDURE no_unpaid_fines_func();

CREATE OR REPLACE FUNCTION no_unpaid_fines_func()
  RETURNS TRIGGER 
  LANGUAGE PLPGSQL
  AS
$$
DECLARE _fines_paid BOOLEAN;
BEGIN
    SELECT (COUNT(fines.borrowingid) - COUNT(transactions.borrowingid)) = 0 INTO _fines_paid 
    FROM borrowing JOIN fines ON borrowing.borrowingID = fines.borrowingID
    LEFT JOIN transactions ON fines.borrowingID = transactions.borrowingID
    GROUP BY userid 
    HAVING userid = NEW.userid;

    IF NOT _fines_paid THEN
        RAISE 'User has unpaid fines. Pay all fines to be able to borrow more.';
    END IF;
	RETURN NEW;
END;
$$;

"SELECT * FROM books WHERE title LIKE '%" + usersearch + "%';"
usersearch =  "Trial"
"SELECT * FROM books WHERE title LIKE '%Trial%';"
usersearch = "Trial%'; DROP TABLE fines;--"
SELECT * FROM books WHERE title LIKE '%Trial%'; DROP TABLE fines;--%';
usersearch = "Trial%'; SELECT * FROM users WHERE userid = 1;--"
SELECT * FROM books WHERE title LIKE '%Trial%'; SELECT * FROM users WHERE userid = 1;--%';