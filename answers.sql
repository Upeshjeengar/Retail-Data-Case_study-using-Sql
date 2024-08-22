-- Create the database
CREATE DATABASE Business_Context;
USE Business_Context;

-- Create tables and load CSV data

-- Customer Table
CREATE TABLE Customer (
    customer_Id INT PRIMARY KEY,
    DOB DATE,
    Gender CHAR(1),
    city_code INT
);

LOAD DATA INFILE 'C:\Users\upesh\Downloads\Retail-Data-Case_study-using-Sql-main\Customer.csv'
INTO TABLE Customer
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(customer_Id, DOB, Gender, city_code);

-- prod_cat_info Table
CREATE TABLE prod_cat_info (
    prod_cat_code INT,
    prod_cat VARCHAR(50),
    prod_subcat_code INT,
    prod_subcat VARCHAR(50)
);

-- Load data from prod_cat_info.csv
LOAD DATA INFILE '/path/to/prod_cat_info.csv'
INTO TABLE prod_cat_info
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(prod_cat_code, prod_cat, prod_subcat_code, prod_subcat);

-- Transactions Table
CREATE TABLE Transactions (
    transaction_id INT PRIMARY KEY,
    cust_id INT,
    tran_date DATE,
    prod_subcat_code INT,
    prod_cat_code INT,
    store_type VARCHAR(50),
    Qty INT,
    total_amt DECIMAL(10,2)
);

-- Load data from Transactions.csv
LOAD DATA INFILE '/path/to/Transactions.csv'
INTO TABLE Transactions
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(transaction_id, cust_id, tran_date, prod_subcat_code, prod_cat_code, store_type, Qty, total_amt);

-- Now we can proceed with the queries

-- 01. What is the total number of rows in each of the 3 tables in the database?
SELECT
    (SELECT COUNT(*) FROM Customer) AS Customer_row_count,
    (SELECT COUNT(*) FROM prod_cat_info) AS prod_cat_info_row_count,
    (SELECT COUNT(*) FROM Transactions) AS Transactions_row_count;

-- 02. What is the total number of transactions that have a return?
SELECT COUNT(*) AS total_returned_transactions
FROM Transactions
WHERE total_amt < 0;

-- 03. Convert the date variables into valid date formats
SELECT DATE_FORMAT(DOB,'%d-%m-%Y') AS formatted_date FROM Customer;
SELECT DATE_FORMAT(tran_date,'%d-%m-%Y') AS formatted_date FROM Transactions;

-- 04. What is the time range of the transaction data available for analysis?
SELECT 
    DATEDIFF(MAX(tran_date), MIN(tran_date)) AS days,
    TIMESTAMPDIFF(MONTH, MIN(tran_date), MAX(tran_date)) AS months,
    TIMESTAMPDIFF(YEAR, MIN(tran_date), MAX(tran_date)) AS years
FROM Transactions;

-- 05. Which product category does the sub-category 'DIY' belong to?
SELECT prod_cat FROM prod_cat_info WHERE prod_subcat = 'DIY';

-- DATA ANALYSIS
-- 01. Which channel is most frequently used for transactions?
SELECT store_type, COUNT(store_type) AS channel 
FROM Transactions
GROUP BY store_type
ORDER BY channel DESC
LIMIT 1;

-- 02. What is the count of Male and Female customers in the database?
SELECT Gender, COUNT(Gender) AS count 
FROM Customer 
WHERE Gender IN ('M', 'F')
GROUP BY Gender;

-- 03. From which city do we have the maximum number of customers and how many?
SELECT city_code, COUNT(city_code) AS no_of_cus 
FROM Customer
GROUP BY city_code
ORDER BY no_of_cus DESC
LIMIT 1;

-- 04. How many sub-categories are there under the Books category?
SELECT prod_cat, COUNT(prod_subcat) AS no_subcat 
FROM prod_cat_info 
WHERE prod_cat = 'Books'
GROUP BY prod_cat;

-- 05. What is the maximum quantity of products ever ordered?
SELECT MAX(Qty) AS maximum_qty
FROM Transactions;

-- 06. What is the net total revenue generated in categories Electronics and Books?
SELECT prod_cat, SUM(total_amt) AS tot_revenue 
FROM prod_cat_info p
INNER JOIN Transactions t ON p.prod_cat_code = t.prod_cat_code AND t.prod_subcat_code = p.prod_subcat_code
WHERE prod_cat IN ('Electronics', 'Books')
GROUP BY prod_cat;

-- 07. How many customers have >10 transactions with us, excluding returns?
SELECT COUNT(customer_Id) AS cust_count
FROM Customer 
WHERE customer_Id IN (
    SELECT cust_id 
    FROM Transactions
    WHERE total_amt >= 0
    GROUP BY cust_id
    HAVING COUNT(transaction_id) > 10
);

-- 08. What is the combined revenue earned from the 'Electronics' & 'Clothing' categories, from 'Flagship stores'?
SELECT SUM(total_amt) AS CombinedRevenue
FROM Transactions t
INNER JOIN prod_cat_info p ON t.prod_cat_code = p.prod_cat_code AND t.prod_subcat_code = p.prod_subcat_code
WHERE prod_cat IN ('Electronics', 'Clothing') AND store_type = 'Flagship store';

-- 09. What is the total revenue generated from 'Male' customers in 'Electronics' category? Output should display total revenue by prod sub-cat.
SELECT c.Gender, p.prod_cat, p.prod_subcat, SUM(total_amt) AS TotalRevenue_Male
FROM Transactions t
INNER JOIN prod_cat_info p ON t.prod_cat_code = p.prod_cat_code AND t.prod_subcat_code = p.prod_subcat_code
INNER JOIN Customer c ON t.cust_id = c.customer_Id
WHERE p.prod_cat = 'Electronics' AND c.Gender = 'M'
GROUP BY c.Gender, p.prod_cat, p.prod_subcat;

-- 10. What is the percentage of sales and returns by product subcategory? Display only top 5 subcategories in terms of sales.
SELECT p.prod_subcat,
    (SUM(total_amt) / (SELECT SUM(total_amt) FROM Transactions)) * 100 AS percentage_of_sales,
    (COUNT(CASE WHEN total_amt < 0 THEN total_amt END) / SUM(total_amt)) * 100 AS percent_of_return
FROM Transactions t
INNER JOIN prod_cat_info p ON t.prod_subcat_code = p.prod_subcat_code AND t.prod_cat_code = p.prod_cat_code
GROUP BY p.prod_subcat
ORDER BY SUM(total_amt) DESC
LIMIT 5;

-- 11. For customers aged between 25 to 35 years, find the net total revenue generated in the last 30 days of transactions from max transaction date available in the data.
SELECT c.customer_Id, SUM(total_amt) AS TOTAL_REVENUE
FROM Transactions t
INNER JOIN Customer c ON t.cust_id = c.customer_Id
WHERE TIMESTAMPDIFF(YEAR, c.DOB, CURDATE()) BETWEEN 25 AND 35
AND t.tran_date BETWEEN DATE_SUB((SELECT MAX(tran_date) FROM Transactions), INTERVAL 30 DAY) AND (SELECT MAX(tran_date) FROM Transactions)
GROUP BY c.customer_Id;

-- 12. Which product category has seen the maximum value of returns in the last 3 months of transactions?
SELECT p.prod_cat, SUM(total_amt) AS totalamt
FROM prod_cat_info p
INNER JOIN Transactions t ON t.prod_cat_code = p.prod_cat_code AND t.prod_subcat_code = p.prod_subcat_code
WHERE total_amt < 0
AND t.tran_date BETWEEN DATE_SUB((SELECT MAX(tran_date) FROM Transactions), INTERVAL 3 MONTH) AND (SELECT MAX(tran_date) FROM Transactions)
GROUP BY p.prod_cat
ORDER BY totalamt DESC
LIMIT 1;

-- 13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?
SELECT store_type, SUM(total_amt) AS sales_amt, SUM(Qty) AS qty
FROM Transactions
GROUP BY store_type
ORDER BY qty DESC
LIMIT 1;

-- 14. What are the categories for which average revenue is above the overall average?
SELECT prod_cat, AVG(total_amt) AS total_rev
FROM Transactions t
INNER JOIN prod_cat_info p ON t.prod_subcat_code = p.prod_subcat_code AND t.prod_cat_code = p.prod_cat_code
GROUP BY prod_cat
HAVING AVG(total_amt) > (SELECT AVG(total_amt) FROM Transactions);

-- 15. Find the average and total revenue by each subcategory for the categories which are among top 5 categories in terms of quantity sold.
SELECT p.prod_cat, p.prod_subcat, AVG(total_amt) AS avg_revenue, SUM(total_amt) AS total_quantity_sold
FROM Transactions t
INNER JOIN prod_cat_info p ON t.prod_cat_code = p.prod_cat_code AND t.prod_subcat_code = p.prod_subcat_code
WHERE p.prod_cat IN (
    SELECT prod_cat
    FROM Transactions t
    INNER JOIN prod_cat_info p ON t.prod_cat_code = p.prod_cat_code AND t.prod_subcat_code = p.prod_subcat_code
    GROUP BY prod_cat
    ORDER BY SUM(Qty) DESC
    LIMIT 5
)
GROUP BY p.prod_cat, p.prod_subcat;
