# ***Fixing errors in data***

# Trim all entries 
UPDATE computerstoresales
SET Item = TRIM(Item),
    Category = TRIM(Category),
    Country = TRIM(Country),
    Date = TRIM(Date),
    ItemCost = TRIM(ItemCost),
    ItemPrice = TRIM(ItemPrice),
    Discount = TRIM(Discount),
    UnitsSold = TRIM(UnitsSold),
    CustomerID = TRIM(CustomerID);

# Replace entries of ten with 10
UPDATE computerstoresales
SET UnitsSold = '10'
WHERE TRIM(UnitsSold) = 'ten';

# Replace ?? prices with an estimated price based on average markup and item cost
UPDATE computerstoresales AS sales
JOIN (
    SELECT Item,
           AVG((CAST(ItemPrice AS DECIMAL(10,2)) - CAST(ItemCost AS DECIMAL(10,2))) / 
                CAST(ItemCost AS DECIMAL(10,2))) AS AvgMarkup
    FROM computerstoresales
    WHERE ItemPrice NOT IN ('??')
      AND Item IS NOT NULL
      AND TRIM(Item) <> ''
      AND ItemCost NOT IN ('??')
    GROUP BY Item
) AS markup
ON sales.Item = markup.Item
SET sales.ItemPrice = ROUND(sales.ItemCost * (1 + markup.AvgMarkup), 2)
WHERE sales.ItemPrice IN ('??', '', ' ');

# Replace country from computerstoresales with country from customer_table
UPDATE computerstoresales AS sales
JOIN customer_table AS customers
    ON sales.CustomerID = customers.CustomerID
SET sales.Country = customers.Country;

# Add SaleID column
ALTER TABLE computerstoresales
ADD COLUMN SaleID INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

# Delete rows in which Item and ItemPrice is unknown
DELETE FROM computerstoresales
WHERE (Item IS NULL OR TRIM(Item) = '')
  AND (ItemPrice = '??' OR TRIM(ItemPrice) = '');

# Populate missing items based on average item price and associated category
UPDATE computerstoresales AS sales
JOIN (
    SELECT possibleitems.SaleID, possibleitems.ImpliedItem
    FROM (
        SELECT sales.SaleID, item.Item AS ImpliedItem,
               ROW_NUMBER() OVER (
                   PARTITION BY sales.CustomerID
                   ORDER BY ABS(CAST(sales.ItemPrice AS DECIMAL(10,2)) - item.AvgPrice)
               ) AS rn
        FROM computerstoresales AS sales
        JOIN (
            SELECT Item, Category, AVG(CAST(ItemPrice AS DECIMAL(10,2))) AS AvgPrice
            FROM computerstoresales
            WHERE Item IS NOT NULL 
              AND TRIM(Item) <> '' 
              AND ItemPrice NOT IN ('??')
            GROUP BY Item, Category
        ) AS item
        ON sales.Category = item.Category
        WHERE sales.Item IS NULL OR TRIM(sales.Item) = ''
    ) AS possibleitems
    WHERE possibleitems.rn = 1
) AS closest
ON sales.SaleID = closest.SaleID
SET sales.Item = closest.ImpliedItem;

# ***Fixing Data Types***
# Convert ItemPrice, ItemCost and Discount from text to decimal
# Convert UnitsSold from text to integer
# Convert Date from text to Date

ALTER TABLE computerstoresales
ADD ItemPriceDecimal DECIMAL(10,2),
ADD ItemCostDecimal DECIMAL(10,2),
ADD DiscountDecimal DECIMAL(10,2),
ADD UnitsSoldInt INT,
ADD DateNew DATE;

UPDATE computerstoresales
SET ItemPriceDecimal = CAST(ItemPrice AS DECIMAL(10,2)),
	ItemCostDecimal = CAST(ItemCost AS DECIMAL(10,2)),
	DiscountDecimal = CAST(Discount AS DECIMAL(10,2)),
    UnitsSoldInt = CAST(UnitsSold AS SIGNED),
    DateNew = STR_TO_DATE(SUBSTRING_INDEX(Date,' ',1), '%Y-%m-%d');
    
ALTER TABLE computerstoresales
DROP COLUMN ItemPrice,
DROP COLUMN ItemCost,
DROP COLUMN Discount,
DROP COLUMN Date,
DROP COLUMN UnitsSold;

ALTER TABLE computerstoresales
RENAME COLUMN ItemPriceDecimal TO ItemPrice,
RENAME COLUMN ItemCostDecimal TO ItemCost,
RENAME COLUMN DiscountDecimal TO Discount,
RENAME COLUMN DateNew TO Date,
RENAME COLUMN UnitsSoldInt TO UnitsSold;

