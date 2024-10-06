-- 1. Check for duplicates and remove any
-- 2. Standardize data and fix errors
-- 3. Look at null values and see if we can populate them
-- 4. Remove any columns and rows that are not necessary

-- DUPLICATES CLEANING
SELECT * FROM layoffs;

CREATE TABLE layoffs_staging 
LIKE layoffs;

WITH duplicate_cte AS
(
	SELECT *,
	ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM layoffs
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

ALTER TABLE layoffs_staging
ADD row_num INT; 

INSERT layoffs_staging 
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs;

DELETE
FROM layoffs_staging
WHERE row_num > 1;

-- STANDARDIZING DATA

SELECT DISTINCT(company)
FROM layoffs_staging;

UPDATE layoffs_staging
SET company = TRIM(company);

SELECT *
FROM layoffs_staging
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

SELECT *
FROM layoffs_staging
WHERE country LIKE 'United States_';

UPDATE layoffs_staging
SET country = 'United States'
WHERE country LIKE 'United_States_';
-- OR
UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

UPDATE layoffs_staging
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging
MODIFY COLUMN `date` DATE;

UPDATE layoffs_staging
SET industry = null
WHERE industry = '';

UPDATE layoffs_staging t1
JOIN layoffs_staging t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

DELETE
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging
DROP COLUMN row_num;
