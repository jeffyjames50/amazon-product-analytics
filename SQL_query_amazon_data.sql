CREATE DATABASE amazon_products;

CREATE TABLE category (
    id SERIAL PRIMARY KEY,
    category_name TEXT NOT NULL UNIQUE
);

CREATE TABLE product (
    asin VARCHAR(20) PRIMARY KEY,
    title TEXT NOT NULL,
    imgUrl TEXT,
    productURL TEXT,
    stars NUMERIC(3,2),
    reviews INTEGER,
    price NUMERIC(10,2),
    listPrice NUMERIC(10,2),
    category_id INTEGER REFERENCES category(id),
    isBestSeller BOOLEAN,
    boughtInLastMonth INTEGER
);

--Data Cleaning & Transformation
--Handling NULL values

UPDATE product SET listPrice = price WHERE listPrice IS NULL;

--Removing duplicates using CTEs

WITH duplicate_cte AS (
    SELECT asin, ROW_NUMBER() OVER (PARTITION BY title ORDER BY asin) AS row_num
    FROM product
)
DELETE FROM product
WHERE asin IN (SELECT asin FROM duplicate_cte WHERE row_num > 1);

--Checking missing categories

SELECT * FROM product WHERE category_id IS NULL;

--Product Performance Analysis

--Top 10 Best-Selling Products using Window Functions

SELECT title, category_id, boughtInLastMonth, 
       RANK() OVER (PARTITION BY category_id ORDER BY boughtInLastMonth DESC) AS rank
FROM product
WHERE boughtInLastMonth IS NOT NULL
LIMIT 10;

--Top 5 Best-Selling Categories using GROUP BY

SELECT c.category_name, SUM(p.boughtInLastMonth) AS total_sales
FROM product p
JOIN category c ON p.category_id = c.id
GROUP BY c.category_name
ORDER BY total_sales DESC
LIMIT 5;

--Price Trend Analysis
--Discount Percentage Calculation

SELECT title, price, listPrice, 
       ((listPrice - price) / listPrice) * 100 AS discount_percent
FROM product
WHERE listPrice > price
ORDER BY discount_percent DESC;

--Customer Buying Behavior
--Frequently Bought Products

SELECT title, boughtInLastMonth
FROM product
WHERE boughtInLastMonth > 500
ORDER BY boughtInLastMonth DESC;

--Review-to-Sales Ratio

SELECT title, reviews, boughtInLastMonth,
       (CAST(reviews AS FLOAT) / NULLIF(boughtInLastMonth, 0)) AS review_to_sales_ratio
FROM product
WHERE boughtInLastMonth > 50
ORDER BY review_to_sales_ratio DESC;


--Recommendation System
--Suggesting Products from the Same Category

SELECT p1.title AS main_product, p2.title AS recommended_product
FROM product p1
JOIN product p2 ON p1.category_id = p2.category_id
WHERE p1.asin <> p2.asin
ORDER BY p1.stars DESC, p2.boughtInLastMonth DESC
LIMIT 10;


--Top 10 Best-Selling Products(JOIN, ORDER BY, LIMIT)

SELECT p.title, p.stars, p.reviews, p.price, c.category_name, p.boughtInLastMonth
FROM product p
JOIN category c ON p.category_id = c.id
WHERE p.isBestSeller = TRUE
ORDER BY p.boughtInLastMonth DESC
LIMIT 10;

--Categorywise Average Rating & Total Sales(Uses: AVG(), SUM(), GROUP BY)

SELECT c.category_name, 
       ROUND(AVG(p.stars), 2) AS avg_rating, 
       SUM(p.boughtInLastMonth) AS total_sales
FROM product p
JOIN category c ON p.category_id = c.id
GROUP BY c.category_name
ORDER BY total_sales DESC;


--Ranking Products Using Window Functions
SELECT p.title, p.stars, p.reviews, p.price, c.category_name,
       RANK() OVER (PARTITION BY c.category_name ORDER BY p.reviews DESC) AS rank_in_category
FROM product p
JOIN category c ON p.category_id = c.id;


-- Finding Outlier Products (Highly Rated but Few Sales)

SELECT title, stars, reviews, boughtInLastMonth
FROM product
WHERE stars >= 4.5 AND boughtInLastMonth < 50
ORDER BY stars DESC, boughtInLastMonth ASC;

