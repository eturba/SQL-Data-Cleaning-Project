-- Data Cleaning Project

Select *
from layoffs;

-- Step 1. Remove Duplicates
-- Step 2. Standardize the Data
-- Step 3. Populate Null/Blank Values if Possible
-- Step 4. Remove Any Columns 

-- Before we begin, a staging table will be set up to ensure that no data is lost during the transformation process.

Create table layoffs_staging 
Like layoffs;

select *
from layoffs_staging;

Insert layoffs_staging
Select *
From layoffs;

select *,
Row_number() Over (
Partition by company, industry, total_laid_off, percentage_laid_off, `date`) As row_num
from layoffs_staging;

-- Now we place this into a CTE, which allows us to create a temporary query within the context of a larger query.
-- Before identifying duplicates, we need to confirm that they are true duplicates, as some records may look very similar but are actually different.

With duplicate_cte as
(
select *,
Row_number() Over (
Partition by company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage,
country,funds_raised_millions) As row_num
from layoffs_staging
)
Select *
From duplicate_cte
where row_num > 1;

-- Let's take a look if there are any duplicates in the data.

Select *
From layoffs_staging
where company = 'Casper';

-- We can see that there is a duplicate for the company 'Casper'.
-- We are unable to delete data directly from a CTE.
-- So we will create a duplicate table so we can filter on the row numbers.

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

Select *
From layoffs_staging2;

-- Add all data into new table 

Insert into layoffs_staging2
select *,
Row_number() Over (
Partition by company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage,
country,funds_raised_millions) As row_num
from layoffs_staging

Select *
From layoffs_staging2
Where row_num > 1;

-- Delete the duplicate data 

Delete
From layoffs_staging2
Where row_num > 1;

-- Standardizing Data
-- first we will remove spaces before the start of the company name

Select distinct(trim(company))
from layoffs_staging2;

Update layoffs_staging2
set company = trim(company);

-- Now we will check to see if there are any alterations in the industry names

Select distinct industry
from layoffs_staging2
Order by 1;

-- It appears that Crypto has three different namings. We will want to standarize that. 

Select *
from layoffs_staging2
Where industry Like 'Crypto%';

Update layoffs_staging2
Set industry = 'Crypto'
Where industry Like 'Crypto%';

-- Now let's take a look at country

Select distinct country
from layoffs_staging2
Order by 1;

-- The 'United States' has two entries, one with a period at the end. We will want to standarize this.

Select *
from layoffs_staging2
Where country like 'United States%'
Order by 1;

Select distinct country, trim(trailing '.' From country)
from layoffs_staging2
Order by 1;

Update layoffs_staging2
Set country = Trim(trailing '.' From country)
Where country like 'United States%';

-- Now we will change the data type and the data format in the date column 

Select `date`,
STR_TO_Date(`date`, '%m/%d/%Y')
from layoffs_staging2;

Update layoffs_staging2
Set `date` = STR_TO_Date(`date`, '%m/%d/%Y');

Alter table layoffs_staging2
Modify Column `date` Date;

-- Removing Null Values
-- We will first look at the industry column for null values. 
-- If the same company appears multiple times in the dataset and one row has a value in the industry column and the other does not,
-- Then we will update the row with the null value to match the row which does have a value. 

Update layoffs_staging2
Set industry = Null 
Where industry = '';

Select distinct industry 
From layoffs_staging2
Where industry is null;

-- We can see that 4 companies have null values in the industry collumn. 
-- We will check if Airbnb appears multiple times in the dataset

Select *
From layoffs_staging2
Where company = 'Airbnb';

-- Airbnb appears multiple times in the dataset. In one row, it lists 'travel' as the industry 
-- While the other row has a null value. We will join the rows to remove the null values

Select *
From layoffs_staging2 t1
Join layoffs_staging2 t2
	On t1.company = t2.company
    And t1.location = t2.location
Where t1.industry Is Null
And t2.industry Is Not Null;

Update layoffs_staging2 t1
Join layoffs_staging2 t2
	On t1.company = t2.company
Set t1.industry = t2.industry 
Where t1.industry Is Null 
And t2.industry Is Not Null;

-- Lastly, we will drop the row_num column because we dont need it

Alter Table layoffs_staging2
Drop Column row_num;