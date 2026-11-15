# @title SQLite Database Basics
# @category Files and data
# @kind Console program
# @where Save as db_basics.py and run: python3 db_basics.py. It makes games.db next to it.
# @keywords python sqlite, python database, python sql select insert, python sqlite3 module
# @about Makes a real database file with sqlite3, adds rows, and asks it questions with SQL.

import sqlite3
from pathlib import Path

db = sqlite3.connect(Path(__file__).with_name("games.db"))
db.execute("DROP TABLE IF EXISTS games")  # start fresh each time for this demo
db.execute("""
    CREATE TABLE games (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        genre TEXT,
        rating INTEGER
    )
""")

games = [("Minecraft", "sandbox", 10), ("Rocket League", "sports", 8), ("Terraria", "sandbox", 9),
         ("Mario Kart", "racing", 9), ("Tetris", "puzzle", 8)]
# The ? marks are filled in safely by sqlite (never glue values into SQL with + !)
db.executemany("INSERT INTO games (title, genre, rating) VALUES (?, ?, ?)", games)
db.commit()

print("All games:")
for row in db.execute("SELECT id, title, genre, rating FROM games"):
    print("  ", row)

print("\nSandbox games, best first:")
for title, rating in db.execute("SELECT title, rating FROM games WHERE genre = ? ORDER BY rating DESC", ("sandbox",)):
    print(f"   {title} ({rating}/10)")

count, average = db.execute("SELECT COUNT(*), AVG(rating) FROM games").fetchone()
print(f"\n{count} games, average rating {average:.1f}")

db.execute("UPDATE games SET rating = 10 WHERE title = ?", ("Terraria",))
db.execute("DELETE FROM games WHERE rating < 9")
db.commit()
print("After update and delete:", [r[0] for r in db.execute("SELECT title FROM games")])
db.close()
