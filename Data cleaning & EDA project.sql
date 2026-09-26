-- Data cleaning
SELECT * FROM layoffs;
-- Remove duplicates
-- Standardize the data
-- handle null values
-- Remove unnecessary columns

-- create a working table
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * 
FROM layoffs;

SELECT *
FROM layoffs_staging;
-- removing duplicates 
SELECT *,
ROW_NUMBER() OVER (PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
FROM layoffs_staging;

WITH duplicates AS
(SELECT *,
ROW_NUMBER() OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * 
FROM duplicates
WHERE row_num>1;

-- create a copy to remove duplicates
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

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER()OVER(PARTITION BY company,location,industry,total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT * 
From layoffs_staging2
WHERE row_num>1;

DELETE 
FROM layoffs_staging2
WHERE row_num>1;

-- Standardizing Data
SELECT company,TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company=TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE'Crypto%';

UPDATE layoffs_staging2
SET industry='Crypto'
WHERE industry LIKE'Crypto%';

SELECT DISTINCT location 
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country,TRIM(TRAILING '.' FROM country )
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country=TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT `date`,STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date`=STR_TO_DATE(`date`,'%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Handling Nulls and missing values
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

UPDATE layoffs_staging2
SET industry=NULL 
WHERE industry ='';

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

SELECT *
FROM layoffs_staging2
WHERE company='Airbnb';

SELECT t1.industry,t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
ON t1.company=t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL; 

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
     ON t1.company=t2.company
SET t1.industry=t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Removing columns/rows 
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT * FROM layoffs_staging2;

-- Exploratory Data Analysis
--  max total laid of & companies that laid off their whole workforce
SELECT MAX(total_laid_off),MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off=1
ORDER BY total_laid_off DESC;

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off=1
ORDER BY funds_raised_millions DESC;
-- Total layoffs per company/industry/country/year/stage

SELECT company,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

SELECT industry,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

SELECT country,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

SELECT YEAR(`date`),SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 1 DESC;

SELECT stage,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- layoffs period 
SELECT MIN(`date`),MAX(`date`)
FROM layoffs_staging2;

-- month rolling total
SELECT SUBSTRING(`date`,1,7)AS `month`,SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC;

WITH Rolling_total AS 
(
SELECT SUBSTRING(`date`,1,7) AS `month`,SUM(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`,1,7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC
)
SELECT `month`,total_off,SUM(total_off) OVER(ORDER BY `month`) AS rolling_total
FROM Rolling_total;

-- company ranking by year
SELECT company,YEAR(`date`)AS year,SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company,YEAR(`date`)
ORDER BY 3 DESC;

WITH company_year(company,years,total_laid_off) AS
(SELECT company,YEAR(`date`),SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company,YEAR(`date`)
),
company_Year_rank AS
(SELECT *,
DENSE_RANK()OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM company_year
WHERE years IS NOT NULL
)
SELECT * 
FROM company_year_rank
WHERE Ranking<=5;

-- indusrty ranking
WITH industry_year(industry,years,total_laid_off) AS
(
SELECT industry,YEAR(`date`),SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry,YEAR(`date`)
),
industry_year_ranking AS 
(SELECT *,
DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off) AS Ranking
FROM industry_year
WHERE years IS NOT NULL
)
SELECT *
FROM industry_year_ranking
WHERE ranking<=5;
 
