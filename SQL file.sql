Create Database RetailAnalytics;
Use RetailAnalytics;

CREATE TABLE Customers(
	CUSTOMER_ID INT PRIMARY KEY,
	NAME VARCHAR(255),
	AGE INT,
	GENDER VARCHAR(10),
	LOCATION VARCHAR(255),
	LOYALTY_STATUS VARCHAR(50)
);

CREATE TABLE Products(
	PRODUCT_ID INT PRIMARY KEY,
    NAME VARCHAR(255),
    CATEGORY VARCHAR(100),
    PRICE DECIMAL(10,2),
    STOCK_LEVEL int
);

CREATE TABLE Transactions(
	TRANS_ID INT PRIMARY KEY,
    CUSTOMER_ID INT,
    PRODUCT_ID INT,
    AMOUNT DECIMAL(10,2),
    PAYMENT_TYPE VARCHAR(50),
    TRANSACTION_DATE DATETIME,
    IS_FRAUD BOOLEAN,
    FOREIGN KEY (CUSTOMER_ID) REFERENCES Customers(CUSTOMER_ID),
    fOREIGN KEY (PRODUCT_ID) REFERENCES Products(PRODUCT_ID)
);
SET SQL_Safe_updates = 0;
UPDATE transactions
SET transaction_date = TIMESTAMPADD(SECOND, FLOOR(RAND() * 86400), transaction_date);

    
CREATE TABLE Sales(
	SALE_ID INT PRIMARY KEY,
    PRODUCT_ID INT,
    UNITS_SOLD INT,
    REVENUE DECIMAL(10,2),
    DATE date,
    foreign key (PRODUCT_ID) REFERENCES Products(PRODUCT_ID)
);

#FOR CHECKING DATA STRUCTURE
DESC Customers;
DESC Products;
DESC Sales;
DESC Transactions;

#TO PREVIEW DATA
SELECT * FROM Customers LIMIT 5;
SELECT * FROM Products LIMIT 5;
SELECT * FROM Sales LIMIT 5;
SELECT * FROM Transactions LIMIT 5;

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM transactions;
SELECT COUNT(*) FROM sales;

##DATE CLEANING (HANDLE NULL, DUBLICATE AND MISSING VALUES)
select * from customers where name is null;
select * from transactions where amount is null or transaction_date is null;
select * from products where stock_level is null;
select * from sales where revenue is null;
SELECT NAME, AGE, GENDER, COUNT(*)
FROM CUSTOMERS
GROUP BY NAME, AGE, GENDER
HAVING COUNT(*) >1;


##DATA VALIDATION (FOREIGN KEY & RELATIONSHIPS CHECK)
SELECT * FROM TRANSACTIONS
WHERE CUSTOMER_ID NOT IN (SELECT CUSTOMER_ID FROM CUSTOMERS);
SELECT * FROM TRANSACTIONS 
WHERE PRODUCT_ID NOT IN (SELECT PRODUCT_ID FROM PRODUCTS);
SELECT * FROM SALES
WHERE PRODUCT_ID NOT IN (SELECT PRODUCT_ID FROM PRODUCTS);


##DATA DISTRIBUTION CHECK(OUTLIERS AND INCONSISTENCIES)
SELECT MIN(STOCK_LEVEL), MAX(STOCK_LEVEL), AVG(STOCK_LEVEL) FROM PRODUCTS;
SELECT MIN(REVENUE), MAX(REVENUE), AVG(REVENUE) FROM SALES;
SELECT MIN(AMOUNT), MAX(AMOUNT), AVG(AMOUNT) FROM TRANSACTIONS;

## QUERIES FOR INSIGHTS
#1. TOP 5 MOST PURCHASED PRODUCTS.
#2. Product Categories with Top 5 Revenue.
#3. Top 10 Best-Selling Products.
#4. Category-wise Revenue Contribution.
#5. High-Value Customers (Top Spenders).
#6. Average Order Value (AOV).
#7. Peak Purchase Time (Hourly/Daily/Weekly Trends).
#8. Profit Margin per Product Category.
#9. Stock Availability & Inventory Turnover.
#10. Refund & Cancellation Rate.
#11. Total Sales, Orders & Average Order Value.
#12. Monthly Sales & Revenue.
#13. Category-wise Revenue & Profit. 
#14. Customer Satisfaction Summary.
#15. Customer Segmentation Insights (High-Value, Medium, Low).
#16. Product Performance Analysis
#17. Product Performance Analysis (Top & Worst Products).
#18. Monthly Revenue & Growth Analysis.
#19. Sales by Location (City/Region-wise Performance).
#20. Best Time to Sell (Peak Sales Hours Analysis).


#1. TOP 5 MOST PURCHASED PRODUCTS.
SELECT product_id, COUNT(*) AS TOTAL_PURCHASE
FROM TRANSACTIONS
GROUP BY PRODUCT_ID
ORDER BY TOTAL_PURCHASE DESC
LIMIT 5;


#2. Product Categories with Top 5 Revenue.
SELECT p.category, SUM(t.amount) AS total_revenue
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC
Limit 5;


#3. Top 10 Best-Selling Products.
SELECT product_id, COUNT(*) AS total_purchases
FROM transactions
GROUP BY product_id
ORDER BY total_purchases DESC
LIMIT 10;


#4. Category-wise Revenue Contribution.
SELECT p.category, SUM(t.amount) AS total_revenue
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;


#5. High-Value Customers (Top Spenders).
SELECT CUSTOMER_ID, SUM(AMOUNT) AS TOTAL_SPENT
FROM TRANSACTIONS
GROUP BY CUSTOMER_ID
ORDER BY TOTAL_SPENT DESC
LIMIT 5;


#6. Average Order Value (AOV).
SELECT AVG(AMOUNT) AS AOV
FROM TRANSACTIONS;


#7. Peak Purchase Time (Hourly/Daily/Weekly Trends).
WITH TrendAnalysis AS (
    SELECT 
        HOUR(transaction_date) AS purchase_hour,
        DAYNAME(transaction_date) AS day_of_week,
        WEEK(transaction_date) AS week_number,
        COUNT(*) AS order_count
    FROM transactions
    GROUP BY purchase_hour, day_of_week, week_number
), 
AggregatedTrend AS (
    SELECT 
        purchase_hour,
        day_of_week,
        week_number,
        order_count,
        RANK() OVER (PARTITION BY week_number ORDER BY order_count DESC) AS weekly_rank,
        RANK() OVER (PARTITION BY day_of_week ORDER BY order_count DESC) AS daily_rank,
        ROUND(100.0 * order_count / SUM(order_count) OVER (PARTITION BY week_number), 2) AS weekly_percentage,
        ROUND(100.0 * order_count / SUM(order_count) OVER (PARTITION BY day_of_week), 2) AS daily_percentage
    FROM TrendAnalysis
)
SELECT 
    purchase_hour,
    day_of_week,
    week_number,
    order_count,
    weekly_rank,
    daily_rank,
    weekly_percentage,
    daily_percentage
FROM AggregatedTrend
ORDER BY week_number DESC, day_of_week, purchase_hour
Limit 1;


#8. Profit Margin per Product Category.
SELECT p.category, SUM(t.amount - p.price) AS total_profit
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.category
ORDER BY total_profit DESC;


#9. Stock Availability & Inventory Turnover.
SELECT 
    p.PRODUCT_ID, 
    p.stock_level, 
    COUNT(t.trans_id) AS sold_quantity,
    
    -- Stock Availability Percentage
    ROUND((p.stock_level / NULLIF(p.stock_level + COUNT(t.trans_id), 0)) * 100, 2) AS stock_availability_percentage,
    
    -- Inventory Turnover Ratio
    ROUND(NULLIF(COUNT(t.trans_id), 0) / NULLIF(p.stock_level, 0), 2) AS inventory_turnover_ratio
FROM products p
LEFT JOIN transactions t ON p.product_id = t.product_id
GROUP BY p.PRODUCT_ID, p.stock_level
ORDER BY inventory_turnover_ratio DESC;


#10. Refund & Cancellation Rate.
SELECT COUNT(*) AS total_refunds 
FROM transactions 
WHERE payment_type = 'cancel';


#11. Total Sales, Orders & Average Order Value.
SELECT 
    'Total Sales' AS Metric, SUM(amount) AS Value FROM transactions
UNION
SELECT 
    'Total Orders', COUNT(trans_id) FROM transactions
UNION
SELECT 
    'Average Order Value', AVG(amount) FROM transactions;

    
#12. Monthly Sales & Revenue.
SELECT 
    DATE_FORMAT(transaction_date, '%Y-%m') AS Month, 
    COUNT(trans_id) AS Total_Orders, 
    SUM(amount) AS Total_Revenue,
    SUM(amount) / COUNT(trans_id) AS Monthly_Avg_Sale
FROM transactions
GROUP BY Month
ORDER BY Month;


#13. Category-wise Revenue, Profit & Sales.
SELECT 
    p.category AS Category, 
    SUM(t.amount) AS Total_Revenue, 
    SUM(t.amount - p.price) AS Total_Profit, 
    COUNT(t.trans_id) AS Total_Sales
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.category
ORDER BY Total_Revenue DESC;


#14. Customer Loyalty Status.
SELECT 
    Loyalty_Status, 
    COUNT(customer_id) AS Total_Customers
FROM customers
GROUP BY Loyalty_Status
ORDER BY Total_Customers DESC;


#15. Customer Segmentation Insights (High-Value, Medium, Low).
SELECT 
    Customer_Type,
    COUNT(DISTINCT customer_id) AS Total_Customers,
    SUM(Total_Spending) AS Total_Spending
FROM (
    SELECT 
        customer_id,
        SUM(amount) AS Total_Spending,
        CASE 
            WHEN SUM(amount) > 3000 THEN 'High Value Customer'
            WHEN SUM(amount) BETWEEN 1000 AND 3000 THEN 'Medium Value Customer'
            ELSE 'Low Value Customer'
        END AS Customer_Type
    FROM transactions
    GROUP BY customer_id
) AS subquery
GROUP BY Customer_Type
ORDER BY Total_Spending DESC;


#16. Product Performance Analysis.
SELECT 
    p.name, 
    p.category, 
    COUNT(t.trans_id) AS Total_Sales, 
    SUM(t.amount) AS Total_Revenue, 
    AVG(t.amount) AS Avg_Sale_Value
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.name, p.category
ORDER BY Total_Revenue DESC;


#17. Product Performance Analysis (Top & Worst Products).
(
    SELECT 
        p.name, 
        p.category, 
        COUNT(t.trans_id) AS Total_Sales, 
        SUM(t.amount) AS Total_Revenue, 
        AVG(t.amount) AS Avg_Sale_Value
    FROM transactions t
    JOIN products p ON t.product_id = p.product_id
    GROUP BY p.name, p.category
    ORDER BY Total_Revenue DESC
    LIMIT 1  -- This gets the top product by total revenue
)
UNION
(
    SELECT 
        p.name, 
        p.category, 
        COUNT(t.trans_id) AS Total_Sales, 
        SUM(t.amount) AS Total_Revenue, 
        AVG(t.amount) AS Avg_Sale_Value
    FROM transactions t
    JOIN products p ON t.product_id = p.product_id
    GROUP BY p.name, p.category
    ORDER BY Total_Revenue ASC
    LIMIT 1  -- This gets the worst product by total revenue
);


#18. Monthly Revenue & Growth Analysis.
SELECT 
    DATE_FORMAT(transaction_date, '%Y-%m') AS Month, 
    SUM(amount) AS Total_Revenue, 
    LAG(SUM(amount),1) OVER (ORDER BY DATE_FORMAT(transaction_date, '%Y-%m')) AS Previous_Month_Revenue, 
    ROUND(((SUM(amount) - LAG(SUM(amount),1) OVER (ORDER BY DATE_FORMAT(transaction_date, '%Y-%m'))) / LAG(SUM(amount),1) OVER (ORDER BY DATE_FORMAT(transaction_date, '%Y-%m'))) * 100, 2) AS Revenue_Growth_Percentage
FROM transactions
GROUP BY Month
ORDER BY Month;


#19. Sales by Location (City/Region-wise Performance).
SELECT 
    Location, 
    COUNT(trans_id) AS Total_Sales, 
    SUM(amount) AS Total_Revenue
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY Location
ORDER BY Total_Revenue DESC;


#20. Best Time to Sell (Peak Sales Hours Analysis).
SELECT 
    EXTRACT(HOUR FROM transaction_date) AS Hour_Of_Day, 
    COUNT(trans_id) AS Total_Sales, 
    SUM(amount) AS Total_Revenue
FROM transactions
GROUP BY Hour_Of_Day
ORDER BY Total_Sales DESC
Limit 1;
