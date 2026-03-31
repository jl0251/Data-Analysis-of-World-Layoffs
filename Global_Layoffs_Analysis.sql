-- ---------------------------------------------------------
-- Data Cleaning and Exploritory Analysis of Global Layoffs
-- By: Jason Lee
-- ---------------------------------------------------------

# Check to see if all data from layoffs.csv was imported properly
SELECT COUNT(*) FROM layoffs; -- checks if the correct number of rows was imported
SELECT * FROM layoffs; -- check to see if all data was formatted correctly


# Plan for cleaning the data
-- 1. Remove any diuplicates
-- 2. Standardize the data
-- 3. Null values or blank values
-- 4. Remove any unnecessary columns

-- ----------------------------------------
-- Data Cleaning
-- ----------------------------------------
 
 # Turn off safe updates
 # This lets tables be UPDATED/ALTERED
SET SQL_SAFE_UPDATES = 0;

# Create a copy of original table data to avoid changing the original the data 
CREATE TABLE layoffs_staging
LIKE layoffs;

# Insert data from original table into layoffs_staging
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

# Check to see if the copy worked
SELECT COUNT(*) FROM layoffs;
SELECT * FROM layoffs_staging;

-- ----------------------------------------
# 1. Removing any duplicates from the table
-- ----------------------------------------

# Seaching for rows that have EXACT duplicates
WITH duplicates_cte AS 
(
	SELECT *, 
	ROW_NUMBER() OVER(
    PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`
    ,stage,country,funds_raised_millions) AS row_num
	FROM layoffs_staging 
) SELECT *
FROM duplicates_cte 
WHERE row_num > 1;

# Create a table that will have the duplicates removed
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

# Check to see if layoffs_staging2 was made properly
SELECT *
FROM layoffs_staging2;

# Copy values from layoffs_staging1 INTO layoffs_staging2 wihtout duplicates
INSERT INTO layoffs_staging2
SELECT *, 
ROW_NUMBER() OVER(
PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`
,stage,country,funds_raised_millions) AS row_num
FROM layoffs_staging; 

# See if data from layoffs_staging1 was copied into layoffs_staging2
SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

# Delete duplicates
DELETE FROM layoffs_staging2 
WHERE row_num > 1;

# There should be no dulpicates
SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

-- ----------------------------------------
# 2. Standardizing the data
-- ----------------------------------------

SELECT company, TRIM(COMPANY) -- Show that there are white spaces on the ends of some text
FROM layoffs_staging2;

# Take white space off edges
UPDATE layoffs_staging2
SET company = TRIM(company);

# Checking industry and country columns to see if there are any repeats
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1; # There are multiple versions of 'Crypto' (CryptoCurrency, Crypto Currency, Crypto)

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1; # There are multiple versions of 'United States' (United States.)

# Changing all variations of 'Crypto' to 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

# Changing all variations of 'United States' to 'Unites States'
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

# Changing the date column from text to date format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

# Check to see if date is in proper format
SELECT `date`
FROM layoffs_staging2;

-- ----------------------------------------
# 3. NULL and blank values
-- ----------------------------------------

# Finding rows where both total_laid_off AND percentage_laid_off are NULL as they will not be useful
SELECT *
FROM layoffs_staging2 
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 

# Finding rows where the industry is no specified
SELECT *
FROM layoffs_staging2 
WHERE INDUSTRY IS NULL OR industry = '';

# Checkign to see how many rows have the company = 'Airbnb'
SELECT *
FROM layoffs_staging2 
WHERE company = 'Airbnb';

# Joining the table on itself with company to find rows where industry is not 
# specified in one row but specified in another
SELECT t1.industry, t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company= t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

# Changing all blank values in layoffs_stagign2 to NULL
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

# Filling in industry for rows that don't have it using another row that does
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company= t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

# Deleting rows where total_laid_off and percentage_laid_off are blank/NULL cause it won't be useful
DELETE
FROM layoffs_staging2 
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL; 

-- ----------------------------------------
# 4. Remove data from unused columns 
-- ----------------------------------------

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

# Turn safe updates back on
SET SQL_SAFE_UPDATES = 1;

-- ----------------------------------------
-- EXPLORATORY ANALYSIS
-- ----------------------------------------

# Checking what the largest percentage of employees laid off is and what largest amount of
# laid off employees is
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

# Companies that laid off everyone in DESC order of total laid off employees
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

# Companies that laid off everyone in DESC order of funds raised (by the millions)
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

# DESC order of total amount of employees laid off by companies 
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY COMPANY
ORDER BY 2 DESC;

# Get the timespan of the data
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

# DESC order of total amount of employees laid off by industry 
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

# DESC order of total amount of employees laid off by country 
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

# DESC order of the years with the total amount of layoffs in each year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

# DESC by total amount of people laid off grouped by stage
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 1 DESC;

# Total people laid off by the month
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1;

# Showing the increasing progression of the total amount of people laid off by the month
WITH Rolling_Total AS (
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1
) SELECT `MONTH`, total_off, SUM(total_off) OVER(ORDER BY MONTH) as rolling_total
FROM Rolling_total;

# Month where least amount of people were laid off
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, total_laid_off
FROM layoffs_staging2
WHERE `date` IS NOT NULL AND total_laid_off IS NOT NULL
ORDER BY total_laid_off
LIMIT 1;

# Tells which companies laid off the most employees in a single calendar year, ranked from highest to lowest
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

# Top 5 companies with most layoffs each year
WITH Company_Year (company, years, total_laid_off) AS # This part calculates the total layofffs per year per company
(
	SELECT company, YEAR(`date`), SUM(total_laid_off)
	FROM layoffs_staging2
	GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS ( # This part uses previous CTE to rank the top 5 companies with most layoffs per year
	SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
	FROM Company_Year
	WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
