-- Automated Data Cleaning

SELECT *
FROM bakery.us_household_income
;


-- Creating a New table and copying the data

DELIMITER $$
DROP PROCEDURE IF EXISTS Copy_and_Clean_Data;
CREATE PROCEDURE Copy_and_Clean_Data()
BEGIN

-- Create Table
	CREATE TABLE IF NOT EXISTS `us_household_income_Cleaned` (
	  `row_id` int DEFAULT NULL,
	  `id` int DEFAULT NULL,
	  `State_Code` int DEFAULT NULL,
	  `State_Name` text,
	  `State_ab` text,
	  `County` text,
	  `City` text,
	  `Place` text,
	  `Type` text,
	  `Primary` text,
	  `Zip_Code` int DEFAULT NULL,
	  `Area_Code` int DEFAULT NULL,
	  `ALand` int DEFAULT NULL,
	  `AWater` int DEFAULT NULL,
	  `Lat` double DEFAULT NULL,
	  `Lon` double DEFAULT NULL,
	  `TimeStamp` TIMESTAMP DEFAULT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Copy Data to new table
	INSERT INTO us_household_income_Cleaned
    SELECT *, CURRENT_TIMESTAMP()
    FROM bakery.us_household_income
    ;
    
		-- Step 1. Remove Duplicates
	DELETE FROM us_household_income_Cleaned
	WHERE
		row_id IN (
		SELECT row_id
	FROM (
		SELECT row_id, id,
			ROW_NUMBER() OVER(
				PARTITION BY id, `TimeStamp`
				ORDER BY id, `TimeStamp`) AS row_num
		FROM
			us_household_income_Cleaned
	) duplicates
	WHERE
		row_num > 1
	)
	;

	-- Step 2. Standardization

	UPDATE us_household_income_Cleaned
	SET State_Name = 'Georgia'
	WHERE State_Name = 'georia';

	UPDATE us_household_income_Cleaned
	SET County = UPPER(County);

	UPDATE us_household_income_Cleaned
	SET City = UPPER(City);

	UPDATE us_household_income_Cleaned
	SET Place = UPPER(Place);

	UPDATE us_household_income_Cleaned
	SET State_Name = UPPER(State_Name);

	UPDATE us_household_income_Cleaned
	SET `Type` = 'CDP'
	WHERE `Type` = 'CPD';

	UPDATE us_household_income_Cleaned
	SET `Type` = 'Borough'
	WHERE `Type` = 'Boroughs';

END $$
DELIMITER ; 

CALL Copy_and_Clean_Data()
;

-- Create Event

DROP EVENT IF EXISTS run_data_cleaning;
CREATE EVENT run_data_cleaning
	ON SCHEDULE EVERY 24 HOUR
    DO CALL Copy_and_Clean_Data();

SHOW EVENTS;



-- Debugging Process

		SELECT row_id, id, row_num
	FROM (
		SELECT row_id, id,
			ROW_NUMBER() OVER(
				PARTITION BY id
				ORDER BY id) AS row_num
		FROM
			us_household_income_cleaned
	) duplicates
	WHERE
		row_num > 1;
    
SELECT COUNT(row_id)
FROM us_household_income_cleaned;

SELECT State_Name, COUNT(State_Name)
FROM us_household_income_cleaned
GROUP BY State_Name
;
