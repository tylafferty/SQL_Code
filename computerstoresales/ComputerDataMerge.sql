# Creating final merged table with additional columns
SELECT
	sales.Date,
	sales.CustomerID, 
    sales.Country,
	sales.Item,
	sales.Category,
	sales.UnitsSold,
	sales.ItemPrice, 
	sales.ItemCost,
	sales.Discount,
    sales.SaleID,
    DATE_FORMAT(Date, '%M') AS Month,
    YEAR(Date) AS Year, 
    sales.UnitsSold*sales.ItemPrice*(1-sales.Discount) AS DiscountRevenue,
    sales.UnitsSold*sales.ItemCost as Cost,
    (sales.UnitsSold*sales.ItemPrice*(1-sales.Discount)) - (sales.UnitsSold*sales.ItemCost) as Profit,
    customers.CustomerType
FROM computerstoresales AS sales
JOIN customer_table AS customers
ON sales.CustomerID = customers.CustomerID

# Export to csv
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ComputerDataMerge.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'

