# Overview of computerstoresales table
SELECT *
FROM computerstoresales
LIMIT 2000;

# Check data types
DESCRIBE computerstoresales;

# Checking for NULL entries in data
SELECT *
FROM computerstoresales
WHERE 
    Date IS NULL
    OR CustomerID IS NULL
    OR Country IS NULL
	OR Item IS NULL
    OR Category IS NULL
    OR UnitsSold IS NULL
    OR ItemPrice IS NULL
    OR ItemCost IS NULL
    OR Discount IS NULL;

# Checking for empty entries in date column
SELECT *
FROM computerstoresales
WHERE TRIM(Date) = '';

# Checking for empty entries in country column
SELECT *
FROM computerstoresales
WHERE TRIM(Country) = '';

# Preview fix by populating country column based on country from customer_table
SELECT 
    sales.CustomerID,
    sales.Country AS CurrentCountry,
    customers.Country AS CustomerCountry,
    CASE 
        WHEN sales.Country IS NULL OR TRIM(sales.Country) = ''
        THEN customers.Country
        ELSE sales.Country
    END AS UpdatedCountry
FROM computerstoresales AS sales
JOIN customer_table AS customers
    ON sales.CustomerID = customers.CustomerID;

# Notice that the country from customerstoresales (CurrentCountry) differs for the same customer (ex.CUST0004 has country India in one entry and UK in another)
# Replace country values from computerstoresales with country from customer_table to remove discrepancies
SELECT 
    sales.CustomerID,
    sales.Country AS OriginalCountry,
    customers.Country AS CustomerCountry,   
    customers.Country AS UpdatedCountry     
FROM computerstoresales AS sales
JOIN customer_table AS customers
    ON sales.CustomerID = customers.CustomerID;

# Checking for empty entries in Item column
SELECT *
FROM computerstoresales
WHERE TRIM(Item) = '';

# Attempt to populate missing items based on average item price and associated category
WITH item_avg AS (
    SELECT Item, Category, AVG(CAST(ItemPrice AS DECIMAL(10,2))) AS AvgPrice
    FROM computerstoresales
    WHERE Item IS NOT NULL AND TRIM(Item) <> '' AND ItemPrice NOT IN ('??')
    GROUP BY Item, Category
),
closest_match AS (
    SELECT sales.*, item.Item AS ImpliedItem,
           ROW_NUMBER() OVER (
               PARTITION BY sales.CustomerID, sales.Date, sales.ItemPrice
               ORDER BY ABS(CAST(sales.ItemPrice AS DECIMAL(10,2)) - item.AvgPrice)
           ) AS rn
    FROM computerstoresales AS sales
    JOIN item_avg AS item
      ON sales.Category = item.Category  -- filter by category
    WHERE sales.Item IS NULL OR TRIM(sales.Item) = ''
)
SELECT *
FROM closest_match
WHERE rn = 1;

# Checking for empty entries in ItemPrice column
SELECT *
FROM computerstoresales
WHERE TRIM(ItemPrice) = '';

# Check for entries with unknown price
SELECT *
FROM computerstoresales
WHERE TRIM(ItemPrice) = '??';

# Populating ?? entries with Implied priced based on average markup and item cost
WITH markup AS (
    SELECT Item,
           AVG((CAST(ItemPrice AS DECIMAL(10,2)) - CAST(ItemCost AS DECIMAL(10,2))) / 
                CAST(ItemCost AS DECIMAL(10,2))) AS AvgMarkup
    FROM computerstoresales
    WHERE ItemPrice NOT IN ('??')
      AND Item IS NOT NULL
      AND TRIM(Item) <> ''
      AND ItemCost NOT IN ('??')
    GROUP BY Item
)
SELECT sales.customerID, sales.Item, sales.ItemCost,
       sales.ItemPrice,
       ROUND(sales.ItemCost * (1 + m.AvgMarkup), 2) AS ImpliedPrice
FROM computerstoresales AS sales
JOIN markup AS m ON sales.Item = m.Item
WHERE sales.ItemPrice IN ('??', '', ' ');

# Checking for empty entries in Category column
SELECT *
FROM computerstoresales
WHERE TRIM(Category) = '';

# Checking for empty entries in UnitsSold column
SELECT *
FROM computerstoresales
WHERE TRIM(UnitsSold) = '';

# Checking for empty entries in ItemCost column
SELECT *
FROM computerstoresales
WHERE TRIM(ItemCost) = '';

# Checking for empty entries in Discount column
SELECT *
FROM computerstoresales
WHERE TRIM(Discount) = '';

# Replace entries in units sold such as ten with 10
SELECT UnitsSold AS OriginalUnits,
    CASE 
        WHEN TRIM(UnitsSold) = 'ten' THEN '10'
        ELSE UnitsSold
    END AS CleanedUnits
FROM computerstoresales;


    

