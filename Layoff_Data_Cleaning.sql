# DATA CLEANING
SELECT *
FROM layoffs;

#Steps to clean the data
# 1. Remove Duplicates
# 2. Standardize the Data
# 3. Null Values or blank values
# 4. Remove Any Columns (If irrelavent)

CREATE TABLE layoffs_staging
LIKE layoffs;

# Creating a copy of the original data set to work on
INSERT layoffs_staging
SELECT *
FROM layoffs;

# 1. Removing Duplicates
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

#**Below code doesnt work with CTE**
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
DELETE
FROM duplicate_cte
WHERE row_num > 1;

# We can however create a new table from above code to manipulate
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
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * 
FROM layoffs_staging2;

#Populating new data table, similar to the CTE
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

#Check rows contain duplicates
SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;
#Removing Duplicates
DELETE
FROM layoffs_staging2
WHERE row_num > 1;
# End of duplicate removal -------------

# 2. Standardizing data
# Generaly it is good to look at distinct entries to spot anomalies then adress as needed
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

#Notice there are three seperate entries for crypto industries, these should be under one name.
#After update we should just see Crypto
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

#Ensure all crypto related industries are tagged as Crypto
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

#Locations look good
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

#Notice one of the United States entries has a period
#After update united states. should be removed from distinct country list
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

#Removing period 
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

#Date was input as text but we want it as a date
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

#Update table using above code
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

#Checking to see if update worked
SELECT `date`
FROM layoffs_staging2;

#Note the date format has been changed however the data type is still text, to change this the table must be altered
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
# End of data standardization ------------------------

# 3. Adressing null and blank values

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

#Setting blank entries to null 
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

#Check wether the industry of the corresponding company can be populated
#Notice for airbnb the industry was set to travel for one entry, we can imply null industry entries for airbnb are also travel
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

#Comparing if null entries have a corresponding populated entry to use, via a self join
SELECT *
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

#Populating null entries with known data from other entries
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

#Note some data cannot be populated as there is no way to extrapolate the needed data from what we have

#Removing rows deemed based on lack of data 
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

#Checking current table
SELECT *
FROM layoffs_staging2;

#End of null and blank value removal---------------

# 4. Removing Unessesary Columns

#Removing row_num column as it was only needed for duplicate removal
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;






