// Predefined queries (populated from queries.sql). These are safe, read-only
// queries used by the UI. Add or remove entries as needed.

module.exports = {
  sample_movies: {
      label: 'Sample movies (latest 50)',
      sql: `SELECT movie_id,
       title AS primaryTitle,
       release_year AS startYear,
       runtime AS runtimeMinutes,
       winner
      FROM Movies
      ORDER BY release_year DESC NULLS LAST
      LIMIT 50`
  },

  q1_user_liked_oscars: {
    label: 'Q1: Oscar-nominated or -winning movies liked by a user',
    params: [{ name: 'user_id', type: 'int', placeholder: '1' }],
    sql: `SELECT m.movie_id, m.title, m.oscars_year, COALESCE(m.winner,0) AS wins,
       CASE WHEN COALESCE(m.winner,0) > 0 THEN 'Winner' ELSE 'Nominated' END AS status
FROM Users u
JOIN UserLikesMovie ul ON u.user_id = ul.user_id
JOIN Movies m ON ul.movie_id = m.movie_id
WHERE u.user_id = $1
  AND (m.oscars_year IS NOT NULL OR COALESCE(m.winner,0) > 0)
ORDER BY m.oscars_year DESC NULLS LAST, m.title;`
  },

  q2_top_liked_oscars: {
    label: 'Q2: Top 10 most-liked Oscar movies',
    sql: `SELECT m.movie_id, m.title, m.oscars_year, COUNT(DISTINCT ul.user_id) AS like_count
FROM Movies m
JOIN UserLikesMovie ul ON m.movie_id = ul.movie_id
WHERE m.oscars_year IS NOT NULL
GROUP BY m.movie_id, m.title, m.oscars_year
ORDER BY like_count DESC, m.title
LIMIT 10;`
  },

  q3: {
    label: "Q3: User's liked movies per trope (top-k)",
    params: [{ name: 'user_id', type: 'int', placeholder: '1' }],
    sql: `SELECT t.trope_id, t.name, COUNT(DISTINCT ul.movie_id) AS liked_movie_count
FROM Users u
JOIN UserLikesMovie ul ON u.user_id = ul.user_id
JOIN MovieTrope mt ON ul.movie_id = mt.movie_id
JOIN Tropes t ON mt.trope_id = t.trope_id
WHERE u.user_id = $1
GROUP BY t.trope_id, t.name
ORDER BY liked_movie_count DESC, t.name
LIMIT 10;`
  },

  q4_tropes_total_likes: {
    label: 'Q4: Tropes with highest total like counts',
    sql: `SELECT t.trope_id, t.name, COUNT(ul.user_id) AS total_likes
FROM Tropes t
JOIN MovieTrope mt ON t.trope_id = mt.trope_id
JOIN UserLikesMovie ul ON mt.movie_id = ul.movie_id
GROUP BY t.trope_id, t.name
ORDER BY total_likes DESC, t.name
LIMIT 50;`
  },

  q5_genres_of_winners: {
    label: 'Q5: Which genres appear most frequently among Oscar-winning movies?',
    sql: `SELECT g.genre_id, g.name, COUNT(*) AS win_count
FROM Genres g
JOIN MovieGenre mg ON mg.genre_id = g.genre_id
JOIN Movies m ON mg.movie_id = m.movie_id
WHERE COALESCE(m.winner,0) > 0
GROUP BY g.genre_id, g.name
ORDER BY win_count DESC, g.name
LIMIT 50;`
  },

  q6_top3_per_genre: {
    label: 'Q6: Top 3 most-liked Oscar movies per genre',
    sql: `SELECT genre_id, genre_name, movie_id, title, oscars_year, like_count
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
ORDER BY genre_name, rn;`
  },

  q7_user_winner_vs_nominated_counts: {
    label: 'Q7: Per-user counts of liked winning vs nominated movies',
    sql: `SELECT u.user_id, u.username,
  COUNT(DISTINCT CASE WHEN COALESCE(m.winner,0) > 0 THEN m.movie_id END) AS liked_winning_count,
  COUNT(DISTINCT CASE WHEN m.oscars_year IS NOT NULL AND COALESCE(m.winner,0) = 0 THEN m.movie_id END) AS liked_nominated_count
FROM Users u
LEFT JOIN UserLikesMovie ul ON u.user_id = ul.user_id
LEFT JOIN Movies m ON ul.movie_id = m.movie_id
GROUP BY u.user_id, u.username
ORDER BY u.user_id;`
  },

  q8_avg_likes_winner_vs_nominated: {
    label: 'Q8: Average likes per movie for winners vs nominated (non-winning)',
    sql: `WITH movie_like_counts AS (
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
WHERE wins = 0 AND oscars_year IS NOT NULL;`
  }
};
