-- Temporarily disable constraint checks
SET session_replication_role = replica;


COPY Tropes(trope_id, name)
FROM '/data/tropes.csv'
DELIMITER ',' CSV HEADER;

COPY Genres(genre_id, name)
FROM '/data/genres.csv'
DELIMITER ',' CSV HEADER;


COPY Users(user_id, username, firstname, lastname, birthday)
FROM '/data/users.csv' 
DELIMITER ',' CSV HEADER;

COPY UserFavouriteGenre(user_id, genre_id)
FROM '/data/userfavouritegenre.csv' 
DELIMITER ',' CSV HEADER;

COPY UserLikesMovie(user_id, movie_id, liked_at)
FROM '/data/userlikesmovie.csv' 
DELIMITER ',' CSV HEADER;

COPY UserPrefersTrope(user_id, trope_id)
FROM '/data/userpreferstrope.csv' 
DELIMITER ',' CSV HEADER;

COPY MovieGenre(movie_id, genre_id)
FROM '/data/moviegenre.csv'
DELIMITER ',' CSV HEADER;

COPY MovieTrope(movie_id, trope_id)
FROM '/data/movietrope.csv'
DELIMITER ',' CSV HEADER;

-- Text cause they might be empty strings in csv
CREATE TEMP TABLE movies_staging (
    eligibleTitle TEXT,
    oscarsYear INT,
    isAdult TEXT, 
    startYear TEXT,
    runtimeMinutes TEXT,
    winner TEXT,
    id TEXT
);

COPY movies_staging
FROM '/data/list_movies.csv'
DELIMITER ',' CSV HEADER NULL '';

-- Step 3: Insert into Movies table with column mapping
INSERT INTO Movies(movie_id, title, is_adult, runtime, winner, oscars_year, release_year)
SELECT
    id,
    eligibleTitle,
    CASE WHEN isAdult IN ('', 'NULL', NULL) THEN FALSE ELSE isAdult::BOOLEAN END,
    CASE 
        WHEN runtimeMinutes IS NULL 
          OR runtimeMinutes = '' 
          OR runtimeMinutes = 'NULL'
        THEN NULL
        ELSE runtimeMinutes::INT
    END,
    CASE 
        WHEN winner IS NULL 
          OR winner = '' 
          OR winner = 'NULL'
        THEN NULL
        ELSE winner::INT
    END,
    oscarsYear,
    CASE 
        WHEN (startYear IN ('', 'NULL') OR startYear IS NULL) THEN oscarsYear::INT
        ELSE startYear::INT
    END
FROM movies_staging;

DROP TABLE movies_staging;

-- Re-enable constraints
SET session_replication_role = DEFAULT;
