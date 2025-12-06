-- queries.sql
-- SQL queries for the Database_Course_Project
-- Example: docker exec -i postgres_db psql -U postgres -d movies_db -f /data/queries.sql

-- Q1: Oscar-nominated or oscar-winning movies liked by a user
SELECT m.movie_id, m.title, m.oscars_year, COALESCE(m.winner,0) AS wins,
       CASE WHEN COALESCE(m.winner,0) > 0 THEN 'Winner' ELSE 'Nominated' END AS status
FROM Users u
JOIN UserLikesMovie ul ON u.user_id = ul.user_id
JOIN Movies m ON ul.movie_id = m.movie_id
WHERE u.user_id = 1  -- OR use u.username
  AND (m.oscars_year IS NOT NULL OR COALESCE(m.winner,0) > 0)
ORDER BY m.oscars_year DESC NULLS LAST, m.title;

-- Q2: Top 10 most-liked Oscar movies overall
SELECT m.movie_id, m.title, m.oscars_year, COUNT(DISTINCT ul.user_id) AS like_count
FROM Movies m
JOIN UserLikesMovie ul ON m.movie_id = ul.movie_id
WHERE m.oscars_year IS NOT NULL
GROUP BY m.movie_id, m.title, m.oscars_year
ORDER BY like_count DESC, m.title
LIMIT 10;

-- Q3a: For a given user, how many of their liked movies belong to each trope (top-k)
SELECT t.trope_id, t.name, COUNT(DISTINCT ul.movie_id) AS liked_movie_count
FROM Users u
JOIN UserLikesMovie ul ON u.user_id = ul.user_id
JOIN MovieTrope mt ON ul.movie_id = mt.movie_id
JOIN Tropes t ON mt.trope_id = t.trope_id
WHERE u.user_id = 1 -- OR use u.username
GROUP BY t.trope_id, t.name
ORDER BY liked_movie_count DESC, t.name
LIMIT 10;

-- Q3b: For a given user, among the tropes they have suggested (UserPrefersTrope),
-- how many of their liked movies belong to each suggested trope (top-k)
SELECT t.trope_id, t.name, COUNT(DISTINCT ul.movie_id) AS liked_movie_count
FROM Users u
JOIN UserPrefersTrope upt ON u.user_id = upt.user_id
JOIN Tropes t ON upt.trope_id = t.trope_id
LEFT JOIN MovieTrope mt ON t.trope_id = mt.trope_id
LEFT JOIN UserLikesMovie ul ON mt.movie_id = ul.movie_id AND ul.user_id = u.user_id
WHERE u.user_id = 2 -- OR use u.username
GROUP BY t.trope_id, t.name
ORDER BY liked_movie_count DESC, t.name
LIMIT 10;  -- replace with your k

-- Q4: Tropes with highest total like counts across all users
SELECT t.trope_id, t.name, COUNT(ul.user_id) AS total_likes
FROM Tropes t
JOIN MovieTrope mt ON t.trope_id = mt.trope_id
JOIN UserLikesMovie ul ON mt.movie_id = ul.movie_id
GROUP BY t.trope_id, t.name
ORDER BY total_likes DESC, t.name
LIMIT 50;  

-- Optional: export results to CSV from inside container using psql meta-commands
-- Example (inside psql): \copy (SELECT ...) TO '/tmp/result.csv' CSV HEADER

-- Q5: Which genres appear most frequently among Oscar-winning movies?
SELECT g.genre_id, g.name, COUNT(*) AS win_count
FROM Genres g
JOIN MovieGenre mg ON mg.genre_id = g.genre_id
JOIN Movies m ON mg.movie_id = m.movie_id
WHERE COALESCE(m.winner,0) > 0
GROUP BY g.genre_id, g.name
ORDER BY win_count DESC, g.name
LIMIT 50;

-- Q6: For each genre, list the top 3 most-liked Oscar movies (using window/ranking)
SELECT genre_id, genre_name, movie_id, title, oscars_year, like_count
FROM (
  SELECT g.genre_id,
         g.name AS genre_name,
         m.movie_id,
         m.title,
         m.oscars_year,
         COUNT(DISTINCT ul.user_id) AS like_count,
         ROW_NUMBER() OVER (PARTITION BY g.genre_id ORDER BY COUNT(DISTINCT ul.user_id) DESC, m.title) AS rn
  FROM Movies m
  JOIN MovieGenre mg ON m.movie_id = mg.movie_id
  JOIN Genres g ON mg.genre_id = g.genre_id
  LEFT JOIN UserLikesMovie ul ON m.movie_id = ul.movie_id
  WHERE m.oscars_year IS NOT NULL
  GROUP BY g.genre_id, g.name, m.movie_id, m.title, m.oscars_year
) sub
WHERE rn <= 3
ORDER BY genre_name, rn;

-- Q7: For each user, how many Oscar-winning vs Oscar-nominated (non-winning) movies have they liked?
SELECT u.user_id, u.username,
  COUNT(DISTINCT CASE WHEN COALESCE(m.winner,0) > 0 THEN m.movie_id END) AS liked_winning_count,
  COUNT(DISTINCT CASE WHEN m.oscars_year IS NOT NULL AND COALESCE(m.winner,0) = 0 THEN m.movie_id END) AS liked_nominated_count
FROM Users u
LEFT JOIN UserLikesMovie ul ON u.user_id = ul.user_id
LEFT JOIN Movies m ON ul.movie_id = m.movie_id
GROUP BY u.user_id, u.username
ORDER BY u.user_id;

-- Q8: Average number of likes per movie for Oscar-winning movies and for Oscar-nominated (non-winning) movies
WITH movie_like_counts AS (
  SELECT m.movie_id, COALESCE(m.winner,0) AS wins, m.oscars_year,
         COUNT(ul.user_id) AS like_count
  FROM Movies m
  LEFT JOIN UserLikesMovie ul ON m.movie_id = ul.movie_id
  GROUP BY m.movie_id, COALESCE(m.winner,0), m.oscars_year
)
SELECT 'Winner' AS category,
       ROUND(AVG(like_count)::numeric,4) AS avg_likes_per_movie,
       SUM(like_count) AS total_likes,
       COUNT(*) AS movie_count
FROM movie_like_counts
WHERE wins > 0
UNION ALL
SELECT 'Nominated' AS category,
       ROUND(AVG(like_count)::numeric,4) AS avg_likes_per_movie,
       SUM(like_count) AS total_likes,
       COUNT(*) AS movie_count
FROM movie_like_counts
WHERE wins = 0 AND oscars_year IS NOT NULL;