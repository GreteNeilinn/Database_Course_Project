import csv
import random
from faker import Faker

fake = Faker()

NUM_USERS = 50  
MOVIES_FILE = "list_movies.csv" 
GENRES_FILE = "genres.csv"
TROPES_FILE = "tropes.csv"

# Load movie IDs 
movie_ids = []
with open(MOVIES_FILE, newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        movie_ids.append(row["id"]) 

# Load genre IDs
genre_ids = []
with open(GENRES_FILE, newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        genre_ids.append(int(row["genre_id"]))

# Load trope IDs
trope_ids = []
with open(TROPES_FILE, newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        trope_ids.append(row["tropeid"])


# Generate Users.csv
with open("Users.csv", "w", newline='', encoding='utf-8') as f:
    writer = csv.DictWriter(f, fieldnames=["user_id","username","firstname","lastname","birthday"], quoting=csv.QUOTE_ALL)
    writer.writeheader()
    for uid in range(1, NUM_USERS + 1):
        writer.writerow({
            "user_id": uid,
            "username": fake.user_name(),
            "firstname": fake.first_name(),
            "lastname": fake.last_name(),
            "birthday": fake.date_of_birth(minimum_age=18, maximum_age=70).isoformat()
        })

# Generate UserFavouriteGenre.csv
with open("UserFavouriteGenre.csv", "w", newline='', encoding='utf-8') as f:
    writer = csv.DictWriter(f, fieldnames=["user_id","genre_id"], quoting=csv.QUOTE_ALL)
    writer.writeheader()
    for uid in range(1, NUM_USERS + 1):
        fav_genres = random.sample(genre_ids, random.randint(1, 3))
        for gid in fav_genres:
            writer.writerow({"user_id": uid, "genre_id": gid})

# Generate UserLikesMovie.csv
with open("UserLikesMovie.csv", "w", newline='', encoding='utf-8') as f:
    writer = csv.DictWriter(f, fieldnames=["user_id","movie_id","liked_at"], quoting=csv.QUOTE_ALL)
    writer.writeheader()
    for uid in range(1, NUM_USERS + 1):
        liked_movies = random.sample(movie_ids, random.randint(5, 20))
        for mid in liked_movies:
            liked_at = fake.date_time_between(start_date='-3y', end_date='now').isoformat(sep=' ')
            writer.writerow({"user_id": uid, "movie_id": mid, "liked_at": liked_at})

# Generate UserPrefersTrope.csv
with open("UserPrefersTrope.csv", "w", newline='', encoding='utf-8') as f:
    writer = csv.DictWriter(f, fieldnames=["user_id","trope_id"], quoting=csv.QUOTE_ALL)
    writer.writeheader()
    for uid in range(1, NUM_USERS + 1):
        preferred_tropes = random.sample(trope_ids, random.randint(3, 10))
        for tid in preferred_tropes:
            writer.writerow({"user_id": uid, "trope_id": tid})

