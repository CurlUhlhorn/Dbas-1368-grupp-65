import datetime
import psycopg2
from dotenv import load_dotenv
import os
from argparse import ArgumentParser
from tabulate import tabulate

"""
Note: It's essential never to include database credentials in code pushed to GitHub. 
Instead, sensitive information should be stored securely and accessed through environment variables or similar. 
However, in this particular exercise, we are allowing it for simplicity, as the focus is on a different aspect.
Remember to follow best practices for secure coding in production environments.
"""

load_dotenv()
parser = ArgumentParser()

# Acquire a connection to the database by specifying the credentials.
conn = psycopg2.connect(
    host="psql-dd1368-ht23.sys.kth.se", 
    database="ivang",
    user="ivang",
    password=os.getenv("DATABASE_PASSWORD"))
print(conn)

# Create a cursor. The cursor allows you to execute database queries.
cur = conn.cursor()

parser.add_argument("--search", '-S', action='store', nargs='+', dest='search')
parser.add_argument("--titles", '-T', action='store_true', default=False, dest='titles')
parser.add_argument("--borrow", '-B', action='store', nargs=2, dest='borrowing')


arguments = parser.parse_args()

# Simple function to get all books with a specific genre.
def get_book_title_by_genre():
    genre = input("Please enter a genre: ")
    query = f"SELECT books.title FROM books LEFT JOIN genre ON books.bookid = genre.bookid WHERE genre.genre = %(genre)'"
    cur.execute(query, {'genre': genre})
    result = cur.fetchall()
    titles = [row[0] for row in result]
    print(titles)
    
# Simple function to get all books with a specific title.
def get_book_by_title():
    title = ' '.join(arguments.search)
    query = "SELECT title, physicalid, damaged FROM books INNER JOIN resources ON books.bookID = resources.bookID WHERE title = %(title)"
    cur.execute(query, {'title': title})
    result = cur.fetchall()
    print(tabulate(result, headers=['Title', 'ID', 'Damaged'], tablefmt='fancy_grid'))
    
def get_all_titles():
    query = "SELECT COUNT(*), title FROM (SELECT title, physicalid FROM books INNER JOIN resources ON books.bookID = resources.bookID EXCEPT SELECT title, resources.physicalid FROM books INNER JOIN resources ON books.bookID = resources.bookID INNER JOIN borrowing on resources.physicalid = borrowing.physicalid WHERE dor IS NULL) books GROUP BY title ORDER BY title"
    cur.execute(query)
    result = cur.fetchall()
    print(tabulate(result, headers=['Available', 'Title'], tablefmt='fancy_grid'))
    
def borrow_book():
    email = arguments.borrowing[0]
    physicalid = arguments.borrowing[1]
    query = f"SELECT email FROM users WHERE email = %*(email)'"
    cur.execute(query, {'email': email})
    result = cur.fetchall()
    if(not result):
        raise Exception('User with given email does not exist')
    query = f"""INSERT INTO borrowing(physicalid, userid, dob) SELECT %(physicalid), userid, %(date) FROM users WHERE email = %(email);"""
    cur.execute(query, {'physicalid': physicalid, 'date': datetime.datetime.now().strftime("%Y-%m-%d"), 'email': email})
    conn.commit()
    print(f"Return the book by {(datetime.datetime.now() + datetime.timedelta(days=7)).strftime('%Y-%m-%d')}")
    

if __name__ == "__main__":
    if(arguments.search):
        get_book_by_title()
    if(arguments.titles):
        get_all_titles()
    if(arguments.borrowing):
        borrow_book()
    