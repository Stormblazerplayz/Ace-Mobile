# @title Contacts Book with SQLite
# @category Files and data
# @kind Console program
# @where Save as contacts.py and run: python3 contacts.py. Contacts are saved in contacts.db.
# @keywords python contacts app, python sqlite app, python address book, python search database
# @about An address book that saves contacts in a database, with add, search, list and delete.

import sqlite3
from pathlib import Path

db = sqlite3.connect(Path(__file__).with_name("contacts.db"))
db.execute("CREATE TABLE IF NOT EXISTS contacts (id INTEGER PRIMARY KEY, name TEXT, phone TEXT, email TEXT)")

while True:
    choice = input("\n(a)dd, (l)ist, (s)earch, (d)elete or (q)uit? ").strip().lower()
    if choice == "a":
        name = input("Name: ").strip()
        if name:
            phone = input("Phone: ").strip()
            email = input("Email: ").strip()
            db.execute("INSERT INTO contacts (name, phone, email) VALUES (?, ?, ?)", (name, phone, email))
            db.commit()
            print("Saved!")
    elif choice in ("l", "s"):
        word = input("Search for: ").strip() if choice == "s" else ""
        rows = db.execute("SELECT id, name, phone, email FROM contacts WHERE name LIKE ? ORDER BY name",
                          (f"%{word}%",)).fetchall()
        for cid, name, phone, email in rows:
            print(f"  #{cid} {name:<18} {phone:<14} {email}")
        print(f"  ({len(rows)} contacts)")
    elif choice == "d":
        cid = input("Number (#) of the contact to delete: ").strip()
        if cid.isdigit():
            removed = db.execute("DELETE FROM contacts WHERE id = ?", (int(cid),)).rowcount
            db.commit()
            print("Deleted." if removed else "No contact with that number.")
    elif choice == "q":
        break
db.close()
