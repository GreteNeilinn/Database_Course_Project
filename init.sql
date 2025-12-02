
DROP TABLE IF EXISTS UserLikesMovie CASCADE;
DROP TABLE IF EXISTS UserFavouriteGenre CASCADE;
DROP TABLE IF EXISTS UserPrefersTrope CASCADE;
DROP TABLE IF EXISTS MovieTrope CASCADE;
DROP TABLE IF EXISTS MovieGenre CASCADE;

DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Movies CASCADE;
DROP TABLE IF EXISTS Genre CASCADE;
DROP TABLE IF EXISTS Tropes CASCADE;


CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    firstname TEXT NOT NULL,
    lastname TEXT NOT NULL,
    birthday DATE
);


CREATE TABLE Genres (
    genre_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL 
);


CREATE TABLE Tropes (
    trope_id TEXT PRIMARY KEY,
    name TEXT NOT NULL 
);


CREATE TABLE Movies (
    movie_id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    is_adult BOOLEAN NOT NULL DEFAULT FALSE,
    runtime INT CHECK (runtime > 0),
    winner INT,
    oscars_year INT,
    release_year INT CHECK (release_year > 1900)
);


CREATE TABLE UserLikesMovie (
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    movie_id TEXT REFERENCES Movies(movie_id) ON DELETE CASCADE,
    liked_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, movie_id)
);


CREATE TABLE UserFavouriteGenre (
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    genre_id INT REFERENCES Genres(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, genre_id)
);


CREATE TABLE MovieTrope (
    movie_id TEXT REFERENCES Movies(movie_id) ON DELETE CASCADE,
    trope_id TEXT REFERENCES Tropes(trope_id) ON DELETE CASCADE,
    PRIMARY KEY (movie_id, trope_id)
);

CREATE TABLE MovieGenre (
    movie_id TEXT REFERENCES Movies(movie_id) ON DELETE CASCADE,
    genre_id INT REFERENCES Genres(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (movie_id, genre_id)
);


CREATE TABLE UserPrefersTrope (
    user_id INT REFERENCES Users(user_id) ON DELETE CASCADE,
    trope_id TEXT REFERENCES Tropes(trope_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, trope_id)
);

