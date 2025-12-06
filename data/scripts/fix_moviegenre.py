#!/usr/bin/env python3
"""
fix_moviegenre.py

Creates two CSVs to help fix `moviegenre.csv` mismatches:

- `data/moviegenre_fixed.csv`: original `moviegenre.csv` rows where `movie_id` exists in
  `list_movies.csv` (drops rows with unknown movie_id).
- `data/moviegenre_random.csv`: for every movie in `list_movies.csv`, assigns one random
  `genre_id` (useful as a dummy mapping to test joins).

Run from project root:
  python .\data\scripts\fix_moviegenre.py

This script is safe — it does not modify existing files, it writes new CSVs.
"""
import csv
import random
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'data'

MOVIES_CSV = DATA / 'list_movies.csv'
GENRES_CSV = DATA / 'genres.csv'
MOVIEGENRE_CSV = DATA / 'moviegenre.csv'

OUT_FIXED = DATA / 'moviegenre_fixed.csv'
OUT_RANDOM = DATA / 'moviegenre_random.csv'
LOG = DATA / 'moviegenre_fix_log.txt'


def read_movie_ids(path):
    ids = []
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        # header contains 'id' column
        for r in reader:
            if 'id' in r and r['id']:
                ids.append(r['id'].strip())
    return ids


def read_genre_ids(path):
    ids = []
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            # genre_id column may be quoted
            gid = r.get('genre_id') or r.get('genreid')
            if gid:
                ids.append(gid.strip())
    return ids


def read_moviegenre_rows(path):
    rows = []
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for r in reader:
            rows.append({
                'movie_id': r.get('movie_id') and r['movie_id'].strip(),
                'genre_id': r.get('genre_id') and r['genre_id'].strip()
            })
    return rows


def write_csv(path, fieldnames, rows):
    with open(path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)


def main():
    random.seed(42)

    print('Reading movie ids...')
    movie_ids = read_movie_ids(MOVIES_CSV)
    movie_set = set(movie_ids)
    print(f'Found {len(movie_ids)} movies')

    print('Reading genre ids...')
    genre_ids = read_genre_ids(GENRES_CSV)
    if not genre_ids:
        raise SystemExit('No genres found in genres.csv')
    print(f'Found {len(genre_ids)} genres')

    print('Reading original moviegenre rows...')
    mg_rows = read_moviegenre_rows(MOVIEGENRE_CSV)
    print(f'Original moviegenre rows: {len(mg_rows)}')

    # Keep only rows with movie_id present in movies list
    fixed_rows = [r for r in mg_rows if r['movie_id'] in movie_set]
    dropped_rows = [r for r in mg_rows if r['movie_id'] not in movie_set]

    print(f'Keeping {len(fixed_rows)} rows; dropping {len(dropped_rows)} rows (ids not found)')

    # Write fixed CSV (only valid rows)
    write_csv(OUT_FIXED, ['movie_id', 'genre_id'], fixed_rows)
    print(f'Wrote fixed CSV: {OUT_FIXED}')

    # Create random mapping: assign each valid movie one random genre
    random_rows = []
    for mid in movie_ids:
        gid = random.choice(genre_ids)
        random_rows.append({'movie_id': mid, 'genre_id': gid})

    write_csv(OUT_RANDOM, ['movie_id', 'genre_id'], random_rows)
    print(f'Wrote random CSV: {OUT_RANDOM}')

    # Log dropped rows (sample up to 100)
    with open(LOG, 'w', encoding='utf-8') as f:
        f.write(f'Original moviegenre rows: {len(mg_rows)}\n')
        f.write(f'Kept rows: {len(fixed_rows)}\n')
        f.write(f'Dropped rows: {len(dropped_rows)}\n\n')
        f.write('Sample dropped rows (up to 100):\n')
        for r in dropped_rows[:100]:
            f.write(str(r) + '\n')

    print('Log written to', LOG)


if __name__ == '__main__':
    main()
