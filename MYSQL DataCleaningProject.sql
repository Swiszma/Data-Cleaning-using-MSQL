-- Data Cleaning


SELECT *
FROM layoffs;

-- ACTIONS
-- 1. Remove Duplicates
-- 2. Standardize Data
-- 3. NULL/Blank Values
-- 4. Remove Any Columns


CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT COUNT(*)
FROM layoffs_staging;


INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT *
FROM layoffs_staging;


-- 1. Remove Duplicate

-- First, we're gonna create an identifyer column(as a unique row ID), since we don't have one here

SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, 
total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- to filter dublicate--let's use CTE


WITH duplicate_cte AS 
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, 
total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- so we want to create another table to insert the data and then delete the duplicates. 
-- this is because we cannot delete and update cte in mysql (a delete statement more like an update satement in cte)

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

SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, 
total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging2;

-- 2. Standardizing Data: Simply finding issues in our data and fixing em
-- trim white spaces under company

SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

SELECT DISTINCT(industry)
FROM layoffs_staging2
ORDER BY 1;


-- so we figured out that we have different company names that are in the same niche, 
-- and we want to make them bear the same name ( thats group them together)

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT DISTINCT(industry)
FROM layoffs_staging2;

-- Checking through the location section

SELECT DISTINCT(location)
FROM layoffs_staging2
ORDER BY 1;

-- Checking through the country section


SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- we have an issue here, Unite States appears twice, and one of em has a period in front

SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Checking through the date section

-- we need to put the date into time series (date), because it's currently as a text

SELECT `date`
FROM layoffs_staging2;

SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging2;


-- Taking care of the NULLs and Blanks

SELECT *
FROM layoffs_staging2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging2
WHERE industry is NULL
OR industry = '';
-- so we want to check if there similar indutry names of these blank ones, 
-- so we could populated the blank ones with em

SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb'; -- here, there're 2 Airbnb, but one has 'Travel' as industry and the other has none

-- so we're gonna find all others like the Airbnb and populate em too

SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT *
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL; -- if we look well,we'll notice that these two columns are completely NULL

DELETE
FROM layoffs_staging2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL;

SELECT *
FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;