CREATE SCHEMA spotify_wrap;
USE spotify_wrap;

SELECT *
FROM streaminghistory0;

SELECT *
FROM streaminghistory1;

## Fix datatypes - DATETIME

ALTER TABLE streaminghistory0
MODIFY COLUMN endTime DATETIME;

ALTER TABLE streaminghistory1
MODIFY COLUMN endTime DATETIME;

## Append Datasets 
### For those with mulitple Streaming History files follow the below steps 

DROP TABLE IF EXISTS full_streaming_history;

CREATE TABLE full_streaming_history AS
SELECT 
	endTime AS end_time, 
    artistName AS artist_name, 
	trackName AS track_name, 
	msPlayed AS ms_played
FROM streaminghistory0

UNION ALL

SELECT 
	endTime AS end_time, 
    artistName AS artist_name, 
	trackName AS track_name, 
	msPlayed AS ms_played
FROM streaminghistory1;

## Add Primary Key stream_id

ALTER TABLE full_streaming_history
ADD COLUMN stream_id INT AUTO_INCREMENT,
ADD PRIMARY KEY (stream_id);

SELECT *
FROM full_streaming_history;

## Beging HW Analysis Using Full Streaming History ##
-- Note: If you only had one streaming history file you only need to ...
	-- Import the data into MySQL
    -- Change the endTime variable to DATETIME datatype 
    -- Rename the variables to snake case 
    -- Add stream_id as INT AUTO_INCREMENT and set it to the PK for the table 
    
 /*  How many songs have you streamed? (Query 1) */
SELECT COUNT(stream_id) AS songs_count
FROM full_streaming_history;
-- 14510

/*  What are your top 5 artists of all time and how many minutes have you spent listening to each artist? List the results in ranking order. (Query 2) */
SELECT artist_name,
    RANK()
    OVER(ORDER BY COUNT(stream_id) DESC) AS artist_rank,
    SUM(ms_played/60000) AS total_time
FROM full_streaming_history
GROUP BY artist_name
LIMIT 5;
-- artist_name	artist_rank	total_time
-- Reneé Rapp	1	1407.9402
-- Chelsea Cutler	2	1226.4923
-- Noah Kahan	3	1318.2069
-- Taylor Swift	4	923.5053
-- Del Water Gap	5	805.3956


/* What are your top 5 songs of all time? Make sure to include each song’s artist. (Query 3) */
SELECT artist_name, track_name,
    RANK()
    OVER(ORDER BY COUNT(stream_id) DESC) AS song_rank
FROM full_streaming_history
GROUP BY track_name, artist_name
LIMIT 5;
-- artist_name, track_name, song_rank
-- Reneé Rapp, Too Well, 1
-- Reneé Rapp, Colorado, 2
-- Reneé Rapp, In The Kitchen, 3
-- Del Water Gap, Ode to a Conversation Stuck in Your Throat, 4
-- Chelsea Cutler, Your Bones, 5

/* How many artists have you listened to of all time? (Query 4) */
SELECT COUNT(DISTINCT artist_name) AS unique_artist
FROM full_streaming_history;
-- 1569

/* How many unique songs did you listen to in 2023? (If you have no data in 2023 you can use 2024). (Query 5) */
SELECT COUNT(DISTINCT track_name) AS unique_song
FROM full_streaming_history
WHERE YEAR(end_time) = "2023";
-- 4253

/* How much time did you spend listening to music? Round to the nearest minute. (Query 6) */
SELECT ROUND(SUM(ms_played)/60000, 0) AS time_spend
FROM full_streaming_history;

/*  What day did you listen to the most music? How many minutes of music did you listen to? (Query 7) */
SELECT DATE(end_time) AS day_most_listen, SUM(ms_played)/60000 AS time_spend
FROM full_streaming_history
GROUP BY day_most_listen
HAVING time_spend = (SELECT SUM(ms_played)/60000 AS max_time
			  FROM full_streaming_history
			  GROUP BY DATE(end_time)
              ORDER BY max_time DESC
			  LIMIT 1);
-- day_most_listen	time_spend
-- 2023-01-17	1432.4442

/* What was our peak listening month? How many minutes of music did you listen to? 
   Your query must return the name of each month (ex: 1 = January) and the time spent listening in minutes. 
   Order your query by listening time from most to least. (Query 8) */
SELECT 
CASE
	WHEN MONTH(end_time) = 1 THEN "January"
	WHEN MONTH(end_time) = 2 THEN "February"
	WHEN MONTH(end_time) = 3 THEN "March"
	WHEN MONTH(end_time) = 4 THEN "April"
	WHEN MONTH(end_time) = 5 THEN "May"
	WHEN MONTH(end_time) = 6 THEN "June"
	WHEN MONTH(end_time) = 7 THEN "July"
	WHEN MONTH(end_time) = 8 THEN "August"
	WHEN MONTH(end_time) = 9 THEN "September"
	WHEN MONTH(end_time) = 10 THEN "October"
	WHEN MONTH(end_time) = 11 THEN "November"
	WHEN MONTH(end_time) = 12 THEN "December"
	ELSE NULL 
END AS month_name, 
SUM(ms_played/60000) AS time_spend
FROM full_streaming_history
GROUP BY month_name
ORDER BY time_spend DESC
LIMIT 1;
-- month_name	time_spend
-- July	7084.0638

/* What was your peak listening month for your top artist? 
   How many minutes of music did you listen to- round to the nearest minute? 
   Your query must return the name of each month (ex: 1 = January). 
   Your outut should have the artist name, month name, and time spent listening in minutes. (Query 9) */
WITH top_rank_artist AS (
SELECT artist_name,
RANK() 
OVER(ORDER BY COUNT(stream_id) DESC) AS artist_rank
FROM full_streaming_history
GROUP BY artist_name
)

SELECT 
CASE
	WHEN MONTH(end_time) = 1 THEN "January"
	WHEN MONTH(end_time) = 2 THEN "February"
	WHEN MONTH(end_time) = 3 THEN "March"
	WHEN MONTH(end_time) = 4 THEN "April"
	WHEN MONTH(end_time) = 5 THEN "May"
	WHEN MONTH(end_time) = 6 THEN "June"
	WHEN MONTH(end_time) = 7 THEN "July"
	WHEN MONTH(end_time) = 8 THEN "August"
	WHEN MONTH(end_time) = 9 THEN "September"
	WHEN MONTH(end_time) = 10 THEN "October"
	WHEN MONTH(end_time) = 11 THEN "November"
	WHEN MONTH(end_time) = 12 THEN "December"
	ELSE NULL 
END AS month_name, 
SUM(ms_played/60000) AS time_spend,
artist_name
FROM full_streaming_history
WHERE artist_name = (SELECT artist_name 
	                 FROM top_rank_artist
                     WHERE artist_rank = 1)
GROUP BY month_name, artist_name
ORDER BY time_spend DESC
LIMIT 1;
-- month_name	time_spend	artist_name
-- April	279.1755	Reneé Rapp

/* What is the longest amount of time in minutes you have spent not listening to music? (Query 10) */
SELECT end_time, LAG(end_time) OVER(ORDER BY end_time) AS last_end_time,
DATEDIFF(end_time, (LAG(end_time) OVER(ORDER BY end_time))) AS day_not_listen
FROM full_streaming_history
ORDER BY day_not_listen DESC
LIMIT 1;