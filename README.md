# Global Layoffs: SQL Data Cleaning & Exploratory Data Analysis

A SQL-based project that takes a raw dataset of global tech and corporate layoffs (2020–2023) and turns it into an analysis-ready table, then explores it to surface where and when the biggest layoffs happened.

## Dataset

Raw data on company layoffs, including company, location, industry, number and percentage of staff laid off, date, funding stage, country, and total funds raised (in millions USD).

## Tools

MySQL — window functions (`ROW_NUMBER`, `DENSE_RANK`), CTEs, joins, and aggregate queries.

## Setup

Import `layoffs_raw.csv` into your MySQL database as a table named `layoffs` (e.g. via MySQL Workbench's Table Data Import Wizard).

## Data Cleaning Process

Working from a staging copy of the raw table (`layoffs_staging`) to keep the original data untouched, the cleaning covered:

1. **Removing duplicates** — Used `ROW_NUMBER()` partitioned over every column that should make a row unique (company, location, industry, layoff figures, date, stage, country, funds raised) to flag true duplicate rows, then deleted every row after the first occurrence via a second staging table (`layoffs_staging2`).
2. **Standardizing the data** — Trimmed stray whitespace from company names, collapsed inconsistent `industry` entries (e.g. `Crypto`, `Crypto Currency`, `CryptoCurrency`) into a single `Crypto` category, and stripped a trailing period from `United States.` in the `country` column so it matched `United States`.
3. **Fixing data types** — Converted the `date` column from text (`MM/DD/YYYY`) to a proper SQL `DATE` type using `STR_TO_DATE`, enabling time-based analysis.
4. **Handling nulls and blanks** — Converted blank `industry` values to `NULL`, then used a self-join on `company` to backfill missing `industry` values from other rows for the same company. Rows with no usable data in *both* `total_laid_off` and `percentage_laid_off` were removed, since they carried no analytical value.
5. **Removing helper columns** — Dropped the `row_num` column once deduplication was complete, leaving a clean, analysis-ready table.

## Exploratory Data Analysis

With the clean table in place, the analysis looked at:

- **Scale of layoffs** — Largest single layoff events, and companies that laid off 100% of their workforce, ranked by funds previously raised (highlighting well-funded startups that still shut down entirely).
- **Layoffs by company, industry, country, and funding stage** — Aggregate totals to identify which companies, industries, countries, and startup stages were hit hardest.
- **Layoffs over time** — Annual totals and a month-by-month rolling total (via a window function) to trace the trajectory of layoffs across the period covered.
- **Year-on-year rankings** — For each year, the top 5 companies and top 5 industries by total layoffs, using `DENSE_RANK()` partitioned by year.

## Key Findings

- The dataset covers **March 2020 to March 2023** and records **~193,000** total layoffs across 1,000 logged events.
- **Amazon, Google, Ericsson, Dell, and Booking.com** were the top 5 companies by total staff laid off.
- **Retail, Consumer, Food, Hardware, and Transportation** were the hardest-hit industries overall.
- The **United States** accounted for the large majority of layoffs recorded, followed by India and Sweden.
- **2022** was the peak year for layoffs, with 2023 already trending high in its first quarter alone; 2021 was comparatively quiet.
- Layoffs were concentrated among **Post-IPO** companies — established, publicly traded firms — rather than early-stage startups.
- Several companies that laid off their **entire workforce** had previously raised significant funding (e.g. Britishvolt at $2.4B, Katerra at $1.6B), showing that heavy funding didn't guarantee survival.

## Files

| File | Description |
|---|---|
| `data_cleaning_and_eda.sql` | Full SQL script: staging tables, deduplication, standardization, null handling, and all EDA queries |
| `layoffs_raw.csv` | The original, uncleaned dataset (2,361 rows) — import this as the `layoffs` table before running the script |
| `layoffs_cleaned.csv` | The cleaned dataset (1,000 rows) after deduplication and null handling, ready for further analysis or visualization |
