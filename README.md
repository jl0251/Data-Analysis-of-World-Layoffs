# Data-Analysis-of-World-Layoffs

## Dataset
The dataset `layoffs.csv` includes:
- **Company**: Name of the company.
- **Location**: Location of the company branch.
- **Industry**: Sector (e.g., Tech, Finance, Retail).
- **Total Laid Off**: Number of employees let go.
- **Percentage Laid Off**: Fraction of the company's workforce affected.
- **Date**: Date of the layoff event.
- **Stage**: Funding stage (e.g., Series B, Post-IPO).
- **Country**: Country of operation.
- **Funds Raised**: Total capital raised in millions.

## Tech Stack
- **Database Management**: MySQL
- **SQL Concepts Used**: 
  - Common Table Expressions (CTEs)
  - Window Functions (`ROW_NUMBER`, `DENSE_RANK`)
  - Data Type Conversions (`STR_TO_DATE`)
  - Joins (Self-joins for data imputation)
  - Aggregate Functions (`SUM`, `COUNT`)

## Project Workflow

### 1. Data Cleaning
- **Staging**: Created a staging table to preserve the original raw data.
- **Duplicate Removal**: Used `ROW_NUMBER()` partitioned by all columns to identify and delete exact duplicates.
- **Standardization**: 
  - Trimmed whitespaces.
  - Consolidated industry names (e.g., merged different "Crypto" entries).
  - Fixed geographic inconsistencies (e.g., "United States.").
  - Converted the `date` column from a string to a proper SQL `DATE` format.
- **Null Handling**: Populated missing `industry` values by cross-referencing entries for the same company. Removed rows that lacked both `total_laid_off` and `percentage_laid_off` data.

### 2. Exploratory Data Analysis (EDA)
- **Time Series Analysis**: Calculated rolling totals of layoffs by month to visualize the progression.
- **Industry Analysis**: Identified which sectors were hit hardest.
- **Company Rankings**: Created a Yearly Top 5 ranking for companies with the highest layoffs using CTEs and window functions.

## Key Insights
- **Peak Period**: Significant spikes in layoffs were observed in specific months during late 2022 and early 2023.
- **Top Impacted Industries**: Sectors like Consumer and Retail saw the highest volume of layoffs.
- **Company Trends**: Large tech giants (Post-IPO) contributed to the highest absolute numbers of layoffs, while startups showed higher percentage-based cuts.

## How to Run
1. Create a database in MySQL Workbench.
2. Import the `layoffs.csv` file using the Table Data Import Wizard.
3. Run the script `Data_Project.sql` to perform cleaning and view the analysis.
