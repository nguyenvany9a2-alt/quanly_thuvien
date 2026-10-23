"""Explicit, repeatable catalogue update. Run with the server stopped."""
import argparse
import json
import re
import sqlite3
import unicodedata
from datetime import datetime
from pathlib import Path
from app import DB, initialize


def key(value):
    value = unicodedata.normalize('NFD', value.casefold().replace('đ', 'd'))
    return re.sub(r'[^a-z0-9]', '', ''.join(c for c in value if not unicodedata.combining(c)))


def apply_updates(c, records, copies=0):
    result = {'updated': 0, 'added': 0, 'copies_added': 0}
    for b in records:
        matches = [r for r in c.execute('SELECT id,title,author FROM books')
                   if key(r[1]) == key(b['title']) and key(r[2]) == key(b['author'])]
        if matches:
            for row in matches:
                c.execute('UPDATE books SET cover=? WHERE id=?', (b['cover'], row[0]))
                result['updated'] += 1
            continue
        bid = c.execute('INSERT INTO books(title,author,category,description,cover,source) VALUES(?,?,?,?,?,?)',
                        tuple(b[k] for k in ['title','author','category','description','cover','source'])).lastrowid
        result['added'] += 1
        for j in range(1, copies + 1):
            c.execute("INSERT INTO copies(book_id,code,shelf,status) VALUES(?,?,?,'available')",
                      (bid, f'MOT-IMPORT-{bid}-{j}', 'NEW'))
            result['copies_added'] += 1
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--copies', type=int, default=0, help='Demo copies per newly inserted title (default: 0).')
    args = parser.parse_args()
    if not 0 <= args.copies <= 100:
        parser.error('--copies must be between 0 and 100')
    records = json.loads(Path(__file__).with_name('book_cover_updates.json').read_text(encoding='utf-8'))
    if DB.exists():
        backup = DB.with_name('mot_before_covers_' + datetime.now().strftime('%Y%m%d_%H%M%S_%f') + '.db')
        with sqlite3.connect(DB) as source, sqlite3.connect(backup) as target:
            source.backup(target)
        print('Database backup:', backup)
    initialize()
    with sqlite3.connect(DB) as c:
        c.execute('PRAGMA foreign_keys=ON')
        c.execute('BEGIN IMMEDIATE')
        result = apply_updates(c, records, args.copies)
    print('Update complete:', result)
    print('Existing copies, accounts, loans and reading content were preserved.')


if __name__ == '__main__':
    main()
