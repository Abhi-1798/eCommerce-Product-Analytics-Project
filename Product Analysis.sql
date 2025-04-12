-- These are the data we have in the given dataset. There are 6 tables.
-- The time period is 3 years (From 19th march 2012 to 19th march 2015)
-- ====================================================================
SELECT * FROM order_item_refunds

SELECT * FROM order_items

SELECT * FROM orders

SELECT * FROM products

SELECT * FROM website_pageviews

SELECT * FROM website_sessions   -- Only table having NULL values.

--===================================================
-- New order_items table, adjesting the refund_items:
--===================================================
SELECT * FROM order_items                                   --INTO adg_ord_items 
WHERE order_item_id IN (SELECT order_item_id FROM order_items
						EXCEPT
						SELECT order_item_id FROM order_item_refunds)

--Here we get the new adg_ord_items
SELECT * FROM adg_ord_items

SELECT COUNT(DISTINCT user_id) FROM orders

--=====================
-- Dashboard for CEO --
--=====================
--===================================== KPIs to track ======================================
--1(a). Site traffic breakdown.
--=============================
SELECT
	pageview_url AS Web_pages,
	COUNT(website_session_id) PageTraffic FROM website_pageviews
GROUP BY pageview_url
ORDER BY PageTraffic DESC


--2. Average web session volume, by hour of day and by day week.
--===============================================================
--(a). By hour of day:
----------------------
SELECT    
    DATEPART(HOUR, created_at) AS hour_of_day,  
    COUNT(website_session_id) AS session_count,
	CAST(COUNT(website_session_id)*1.0/(24*1092) AS DECIMAL(10,2)) AS avg_session_per_hour
FROM website_sessions  
GROUP BY DATEPART(HOUR, created_at)  
ORDER BY hour_of_day

--(b). By day week:
-------------------
SELECT 
    DATENAME(WEEKDAY, ws.created_at) AS weekday_name, 
    COUNT(ws.website_session_id) / COUNT(DISTINCT CAST(ws.created_at AS DATE)) AS avg_sessions_per_weekday
FROM website_sessions ws
GROUP BY DATENAME(WEEKDAY, ws.created_at)
ORDER BY avg_sessions_per_weekday DESC;
--ORDER BY MIN(ws.created_at);


--3. Seasonality trends.
--=======================
--(a). Weekly Trend:
--------------------
SELECT  
    YEAR(created_at) AS year,
    DATEPART(WEEK, created_at) AS week,
    COUNT(order_id) AS total_orders,
    SUM(price_usd) AS total_revenue
FROM orders
GROUP BY YEAR(created_at), DATEPART(WEEK, created_at)
ORDER BY YEAR(created_at), DATEPART(WEEK, created_at)

--(b). Monthly Trend:
---------------------
SELECT  
    YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    COUNT(order_id) AS total_orders,
    SUM(price_usd) AS total_revenue
FROM orders
GROUP BY YEAR(created_at), MONTH(created_at)
ORDER BY YEAR(created_at), MONTH(created_at)


--4. Sales trends.
--=================
-- Total Revenue and Total Profit and Profit Percentage:
--------------------------------------------------------
--(a).
SELECT 
	ROUND(SUM(cogs_usd), 2) AS Total_Cost,
	ROUND(SUM(price_usd), 2) AS Total_Rev,
	ROUND(SUM(price_usd) - SUM(cogs_usd), 2) AS Total_Profit,
	ROUND((SUM(price_usd) - SUM(cogs_usd)) * 100/ SUM(cogs_usd), 2) AS Profit_Prct,
	COUNT(order_id) AS Total_Ord_Placed,
	SUM(items_purchased) AS Total_Item_sold
FROM orders

--(b).
SELECT 
	ROUND(SUM(cogs_usd), 2) AS Total_Cost,
	ROUND(SUM(price_usd), 2) AS Total_Rev,
	ROUND(SUM(price_usd) - SUM(cogs_usd), 2) AS Total_Profit,
	ROUND((SUM(price_usd) - SUM(cogs_usd)) * 100/ SUM(cogs_usd), 2) AS [Profit_%],
	COUNT(order_id) AS Total_Ord_Placed,
	COUNT(order_item_id) AS Total_Item_sold
FROM adg_ord_items

--(c). Aggregating sales trends by day:
---------------------------------------
SELECT 
    CAST(created_at AS DATE) AS sales_date,
    COUNT(order_id) AS total_orders,
    SUM(items_purchased) AS total_items_sold,
    SUM(price_usd) AS total_revenue,
    SUM(cogs_usd) AS total_cost,
    SUM(price_usd - cogs_usd) AS total_profit
FROM orders
GROUP BY CAST(created_at AS DATE)
ORDER BY sales_date

--(d). Aggregating sales trends by months:
------------------------------------------
SELECT 
    YEAR(created_at) AS sales_year,
	MONTH(created_at) AS sales_month,
    COUNT(order_id) AS total_orders,
    SUM(items_purchased) AS total_items_sold,
    SUM(price_usd) AS total_revenue,
    SUM(cogs_usd) AS total_cost,
    SUM(price_usd - cogs_usd) AS total_profit
FROM orders
GROUP BY YEAR(created_at), MONTH(created_at)
--ORDER BY sales_year, sales_month
ORDER BY sales_year, total_profit DESC

--(e) Aggregating sales trends by year:
---------------------------------------
SELECT 
    YEAR(created_at) AS sales_year,
    COUNT(order_id) AS total_orders,
    --SUM(items_purchased) AS total_items_sold,
    SUM(price_usd) AS total_revenue,
    SUM(cogs_usd) AS total_cost,
    SUM(price_usd - cogs_usd) AS total_profit
FROM adg_ord_items
GROUP BY YEAR(created_at)
ORDER BY sales_year

--(f) Quarterly Running total Revenue and Running total Profit:
---------------------------------------------------------------
SELECT 
    DATEPART(YEAR, created_at) AS yr,
    DATEPART(QUARTER, created_at) AS qtr,
    SUM(price_usd) AS quarterly_revenue,
    SUM(SUM(price_usd)) OVER (ORDER BY DATEPART(YEAR, created_at), DATEPART(QUARTER, created_at)) AS running_total_revenue,
	SUM(price_usd - cogs_usd) AS total_profit,
	SUM(SUM(price_usd - cogs_usd)) OVER (ORDER BY DATEPART(YEAR, created_at), DATEPART(QUARTER, created_at)) AS running_total_profit
FROM orders
GROUP BY DATEPART(YEAR, created_at), DATEPART(QUARTER, created_at)


--====================================== List of analysis to send regularly =================================

--•A1(a) Finding top traffic sources.
--===================================
SELECT 
    utm_source, utm_campaign, utm_content, device_type, 
    COUNT(website_session_id) AS session_count
FROM website_sessions
WHERE utm_content NOT IN ('NULL')
GROUP BY utm_source, utm_campaign, utm_content, device_type
ORDER BY session_count DESC

--A1(b) Traffic Through Organic Source:
---------------------------------------
SELECT 
	device_type, http_referer,
    COUNT(website_session_id) AS organic_session_count
FROM website_sessions
WHERE utm_content = 'NULL'  AND http_referer != 'NULL'
GROUP BY device_type, http_referer
ORDER BY organic_session_count DESC

--A1(c) Traffic Through free channels:
--------------------------------------
SELECT 
	device_type,
    COUNT(website_session_id) AS session_count
FROM website_sessions
WHERE utm_content = 'NULL'            -- Excluding paid search ads
GROUP BY device_type
ORDER BY session_count DESC


--=======================================================================================================
--• Analysing free channels:
--==========================
--A2(a). Session count, Orders count & Revenue generated by Organic channels:
-----------------------------------------------------------------------------
SELECT 
    YEAR(ws.created_at) AS Year,
    MONTH(ws.created_at) AS Month,
    COUNT(DISTINCT ws.website_session_id) AS session_count,
    COUNT(DISTINCT o.order_id) AS order_count,
	SUM(o.price_usd) AS tot_revenue
FROM website_sessions ws
LEFT JOIN orders o 
    ON ws.website_session_id = o.website_session_id
WHERE ws.utm_content = 'NULL'                                                   -- Excluding paid search ads
GROUP BY YEAR(ws.created_at), MONTH(ws.created_at), ws.utm_source, ws.utm_campaign
ORDER BY Year, Month, session_count DESC

--A2(b). Free channels device type conversion rate:
---------------------------------------------------
SELECT device_type, COUNT(W.website_session_id) session_count, COUNT(order_id) order_count, 
		COUNT(order_id)*100.0/COUNT(W.website_session_id) [conversion_%]
FROM website_sessions W
LEFT JOIN orders P
ON W.website_session_id=P.website_session_id
WHERE utm_content='NULL'
GROUP BY device_type

--A2(c). Free channels segregation-Yearly,Monthly basis:
--------------------------------------------------------
SELECT YEAR(w.created_at) AS year, MONTH(w.created_at) AS month, COUNT(W.website_session_id) session_count,
		COUNT(order_id) order_count, COUNT(order_id)*100.0/COUNT(W.website_session_id) [conversion_%]
FROM website_sessions w
LEFT JOIN orders o
ON W.website_session_id=O.website_session_id
WHERE utm_content='NULL'
GROUP BY YEAR(W.created_at), MONTH(W.created_at)
ORDER BY YEAR, MONTH

--A2(d). Free channels hourly analysis:
---------------------------------------
SELECT DATEPART(HOUR,W.created_at) [HOUR], COUNT(W.website_session_id) session_count,
		COUNT(order_id) order_count, COUNT(order_id)*100.0/COUNT(W.website_session_id) [conversion_%]
FROM website_sessions w
LEFT JOIN orders o
ON W.website_session_id=O.website_session_id
WHERE utm_content='NULL'
GROUP BY DATEPART(HOUR,W.created_at)
ORDER BY HOUR

--A2(e). Free channels device-type wise order_count & revenue:
--------------------------------------------------------------
SELECT device_type, 
	COUNT(DISTINCT(CASE WHEN utm_content='NULL' AND http_referer!='NULL' THEN o.order_id ELSE NULL END )) organic_ord_count,
	ROUND(SUM(CASE WHEN utm_content='NULL' AND http_referer!='NULL' THEN price_usd ELSE NULL END ), 2) organic_sale,
	COUNT(DISTINCT(CASE WHEN utm_content='NULL' AND http_referer='NULL' THEN o.order_id ELSE NULL END )) direct_search_ord_count,
	ROUND(SUM(CASE WHEN utm_content='NULL' AND http_referer='NULL' THEN price_usd ELSE NULL END ), 2) direct_search_sale	   
FROM website_sessions w
LEFT JOIN orders o ON W.website_session_id=O.website_session_id
GROUP BY device_type;


--===================================================================================================
--• Analysing seasonality:
--========================
--A3(a).
WITH SalesData AS (
	SELECT 
	       DATEPART(YEAR, o.created_at) AS sales_year,
	       DATEPART(MONTH, o.created_at) AS sales_month,
	       DATENAME(MONTH, o.created_at) AS sales_month_name,
	       DATEPART(WEEK, o.created_at) AS sales_week,
	       DATENAME(WEEKDAY, o.created_at) AS sales_weekday_name,
	       COUNT(DISTINCT o.order_id) AS total_orders,
	       SUM(oi.price_usd) AS total_revenue
	FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
	GROUP BY 
        DATEPART(YEAR, o.created_at), DATEPART(MONTH, o.created_at), 
        DATENAME(MONTH, o.created_at), DATEPART(WEEK, o.created_at), DATENAME(WEEKDAY, o.created_at)
)
SELECT sales_year, sales_month, sales_month_name, sales_week, sales_weekday_name, total_orders, total_revenue
FROM SalesData
ORDER BY sales_year


--===================================================================================================
-- Product Level Analysis:
--=========================
--A4(a). Product-Level Sales Analysis:
--------------------------------------
SELECT 
    p.product_id, 
    p.product_name,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(SUM(oi.price_usd), 2) AS total_revenue,
    ROUND(SUM(oi.cogs_usd), 2) AS total_cost,
    ROUND(SUM(oi.price_usd) - SUM(oi.cogs_usd), 2) AS total_profit,
    COUNT(DISTINCT o.user_id) AS unique_customers,
    ROUND(SUM(oi.price_usd) * 1.0 / NULLIF(COUNT(DISTINCT oi.order_id), 0), 2) AS avg_order_value
FROM order_items oi 
JOIN products p ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id 
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC


--A4(b). Sales Trend Analysis for Each Product:
-----------------------------------------
SELECT * FROM products;

SELECT 
    p.product_name, p.product_id,
    CAST(o.created_at AS DATE) AS sales_date,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    SUM(o.items_purchased) AS total_items_sold,
    ROUND(SUM(oi.price_usd), 2) AS total_revenue
FROM products p
RIGHT JOIN order_items oi 
    ON p.product_id = oi.product_id
LEFT JOIN orders o 
    ON oi.order_id = o.order_id
GROUP BY p.product_id, p.product_name, CAST(o.created_at AS DATE)
ORDER BY p.product_id, sales_date

--A4(c). Profitability and High-Performing Products:
---------------------------------------------
SELECT 
    p.product_id, p.product_name,
    SUM(oi.price_usd) AS total_revenue,
    SUM(oi.cogs_usd) AS total_cost,
    SUM(oi.price_usd) - SUM(oi.cogs_usd) AS total_profit,
    ROUND((SUM(oi.price_usd) - SUM(oi.cogs_usd)) * 100.0
	/ NULLIF(SUM(oi.price_usd), 0), 2) AS profit_margin
FROM products p
RIGHT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_profit DESC

--A4(d). Refund and Return Analysis:
-----------------------------
SELECT 
    p.product_name,
    COUNT(DISTINCT oir.order_item_refund_id) AS total_returns,
    ROUND(SUM(oir.refund_amount_usd), 2) AS total_refund_amount,
    CAST((COUNT(DISTINCT oir.order_item_refund_id)) * 100.0 
	/ COUNT(DISTINCT oi.order_item_id) AS DECIMAL(10,4)) AS return_rate
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN order_item_refunds oir ON oi.order_item_id = oir.order_item_id
GROUP BY p.product_name
ORDER BY return_rate DESC


--======================================================================================================
--• Product launch sales analysis:
--=================================
--A5(a). Query to Extract Key Metrics:
-------------------------------
SELECT 
    p.product_id, p.product_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(SUM(oi.price_usd), 2) AS total_revenue,
    COUNT(DISTINCT o.user_id) AS unique_customers,
    CAST(COUNT(DISTINCT o.user_id) * 100.0 /
	NULLIF(COUNT(DISTINCT ws.website_session_id), 0) AS DECIMAL(10,4)) AS conversion_rate
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN website_sessions ws ON o.website_session_id = ws.website_session_id
WHERE o.created_at BETWEEN p.created_at AND DATEADD(MONTH, 6, p.created_at)           -- 6-month since launch
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC

--A5(b). Trend Analysis Over Time:
---------------------------
SELECT 
    p.product_name, p.product_id,
    CAST(o.created_at AS DATE) AS sales_date,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items_sold,
    SUM(oi.price_usd) AS total_revenue
FROM products p
JOIN order_items oi 
    ON p.product_id = oi.product_id
JOIN orders o 
    ON oi.order_id = o.order_id
WHERE o.created_at BETWEEN p.created_at AND DATEADD(MONTH, 6, p.created_at)        -- 6 month since launch
GROUP BY p.product_id, p.product_name, CAST(o.created_at AS DATE)
ORDER BY p.product_id, sales_date

--A5(c). Customer Retention & Repeat Purchases:
------------------------------------------
SELECT 
    oi.product_id,
    p.product_name,
    COUNT(DISTINCT o.user_id) AS unique_customers,
    COUNT(o.user_id) AS total_purchases,
    CAST(COUNT(o.user_id) * 1.0 / COUNT(DISTINCT o.user_id) AS DECIMAL(10,4)) AS avg_purchases_per_customer
FROM order_items oi
JOIN products p 
    ON oi.product_id = p.product_id
JOIN orders o 
    ON oi.order_id = o.order_id
WHERE o.created_at BETWEEN p.created_at AND DATEADD(MONTH, 6, p.created_at)        -- 6 month since launch
GROUP BY oi.product_id, p.product_name
ORDER BY avg_purchases_per_customer DESC


--=======================================================================================================
--• Cross- sell analysis:
--=======================
--A6(a)
WITH CrossSell AS (
    SELECT oi.order_id, p.product_name
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
),
Pairs AS (
    SELECT c1.order_id, c1.product_name AS product1, c2.product_name AS product2
    FROM CrossSell c1
    JOIN CrossSell c2 ON c1.order_id = c2.order_id 
					AND c1.product_name < c2.product_name 
)
SELECT product1, product2, COUNT(*) AS frequency
FROM Pairs
GROUP BY product1, product2
ORDER BY frequency DESC



--================================================== Some Other Analysis =================================

--1. Quarterly no. of sessions and no. of orders placed:
------------------------------------------------------
SELECT
    DATEPART(YEAR, ws.created_at) AS yr,
    DATEPART(QUARTER, ws.created_at) AS qtr,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions ws
LEFT JOIN orders o
    ON ws.website_session_id = o.website_session_id
GROUP BY DATEPART(YEAR, ws.created_at), DATEPART(QUARTER, ws.created_at)
ORDER BY DATEPART(YEAR, ws.created_at), DATEPART(QUARTER, ws.created_at)

--2. Repeat buyers count:
-------------------------
SELECT COUNT(DISTINCT user_id) AS [repeat_buyer] FROM orders
WHERE user_id IN (
		SELECT user_id total_purchase FROM orders
		GROUP BY user_id
		HAVING COUNT(order_id) > 1)                        -- 591 users

--2. Repeat visiters count:
-------------------------
SELECT COUNT(DISTINCT user_id) AS [repeat_visiter] FROM website_sessions
WHERE user_id IN (
		SELECT user_id total_purchase FROM website_sessions
		GROUP BY user_id
		HAVING COUNT(website_session_id) > 1)              -- 51270 users



