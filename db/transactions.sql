/*
	db/transactions.sql
*/

BEGIN;
	-- remove mapping from source and add mapping to target in a single transaction
	WITH deleted AS (
		DELETE FROM MovieGenre
		WHERE movie_id = 'm0016' AND genre_id = 3
		RETURNING movie_id, genre_id
	)
	INSERT INTO MovieGenre(movie_id, genre_id)
	SELECT 'm0020', genre_id FROM deleted
	ON CONFLICT (movie_id, genre_id) DO NOTHING;
COMMIT;

BEGIN;
	-- Step A: preliminary change
	INSERT INTO MovieGenre(movie_id, genre_id) VALUES ('m0100', 5)
		ON CONFLICT (movie_id, genre_id) DO NOTHING;

	SAVEPOINT sp_update_related;

	-- Step B: dependent change that might fail; if it fails, we undo B but keep A
	INSERT INTO MovieTrope(movie_id, trope_id) VALUES ('m0100', 42);

	-- If some validation fails, we can rollback only Step B
	-- ROLLBACK TO SAVEPOINT sp_update_related;

COMMIT;

BEGIN;
	INSERT INTO UserLikesMovie(user_id, movie_id) VALUES (123, 'm0016')
		ON CONFLICT (user_id, movie_id) DO UPDATE
		SET liked_at = EXCLUDED.liked_at
		WHERE UserLikesMovie.liked_at IS DISTINCT FROM EXCLUDED.liked_at;
COMMIT;