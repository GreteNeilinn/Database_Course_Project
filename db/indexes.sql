-- db/indexes.sql
-- Recommended indexes for Database_Course_Project
-- Run as postgres superuser or a role with CREATE INDEX privileges.
-- Note: `CREATE INDEX CONCURRENTLY` avoids long table locks for large tables but
-- cannot be executed inside a transaction block. Use it in production for minimal locking.

-- 1) Speed up lookups of likes by movie and by user
-- Use CONCURRENTLY to avoid long exclusive locks (runs outside transactions)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_userlikemovie_movie_id ON UserLikesMovie(movie_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_userlikemovie_user_id ON UserLikesMovie(user_id);

-- 2) Speed up joins between movies and their genres/tropes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_moviegenre_movie_id ON MovieGenre(movie_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_moviegenre_genre_id ON MovieGenre(genre_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movietrope_movie_id ON MovieTrope(movie_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movietrope_trope_id ON MovieTrope(trope_id);

-- 3) Composite indexes used by grouping/partitioning queries
-- Q6 and genre-based grouping: many queries join MovieGenre -> Movies -> UserLikesMovie
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_moviegenre_genre_movie ON MovieGenre(genre_id, movie_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_userlikemovie_movie_user ON UserLikesMovie(movie_id, user_id);

-- Q3: tropes per movie and per user
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movietrope_trope_movie ON MovieTrope(trope_id, movie_id);

-- 4) Filter indexes for Movies (useful for oscars-related queries)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movies_oscars_year ON Movies(oscars_year) WHERE oscars_year IS NOT NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_movies_winner_gt0 ON Movies(winner) WHERE COALESCE(winner,0) > 0;

-- 5) Support lookups by trope or genre name
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tropes_name ON Tropes(LOWER(name));
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_genres_name ON Genres(LOWER(name));