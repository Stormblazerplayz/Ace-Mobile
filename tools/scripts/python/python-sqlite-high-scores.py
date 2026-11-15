# @title High Score Table with SQLite
# @category Files and data
# @kind Module
# @where Save as highscores.py next to your game, then: import highscores; highscores.add("Storm", 950); print(highscores.top()). Run it by itself for a demo.
# @keywords python high scores, python leaderboard, python sqlite module, python save scores
# @about A small module any game can import to save scores in a database and get the top 10.

import sqlite3
from datetime import datetime
from pathlib import Path

DB_PATH = Path(__file__).with_name("highscores.db")


def _connect():
    db = sqlite3.connect(DB_PATH)
    db.execute("CREATE TABLE IF NOT EXISTS scores (name TEXT, score INTEGER, game TEXT, played TEXT)")
    return db


def add(name, score, game="default"):
    """Save one score."""
    with _connect() as db:  # 'with' commits the changes for us
        db.execute("INSERT INTO scores VALUES (?, ?, ?, ?)",
                   (name, int(score), game, datetime.now().isoformat(timespec="seconds")))


def top(game="default", limit=10):
    """Return the best scores as a list of (name, score)."""
    with _connect() as db:
        return db.execute("SELECT name, score FROM scores WHERE game = ? ORDER BY score DESC LIMIT ?",
                          (game, limit)).fetchall()


def best_for(name, game="default"):
    with _connect() as db:
        row = db.execute("SELECT MAX(score) FROM scores WHERE name = ? AND game = ?", (name, game)).fetchone()
        return row[0] or 0


if __name__ == "__main__":
    import random
    for player in ["Storm", "Doodle", "Nova"]:
        add(player, random.randint(100, 1000), game="demo")
    print("Top scores for the demo game:")
    for rank, (name, score) in enumerate(top("demo"), start=1):
        print(f"  {rank}. {name:<8} {score}")
    print("Storm's best:", best_for("Storm", "demo"))
