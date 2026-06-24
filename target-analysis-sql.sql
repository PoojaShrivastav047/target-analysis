# Data type of all columns in the "customers" table.
SELECT
  column_name,
  data_type
FROM `scaler-dsml-sql-456216.Target.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'customers';


# Get the time range between which the orders were placed.
SELECT 
    min(order_purchase_timestamp) as first_order,
    max(order_purchase_timestamp) as last_order 
FROM Target.orders;


# Count the cities and states of customers who ordered during the given period.
WITH order_ranges as (
  SELECT min(order_purchase_timestamp) as first_order,
         max(order_purchase_timestamp) as last_order 
  FROM Target.orders
)

SELECT 
    c.customer_city, 
    c.customer_state, 
    count(distinct c.customer_id) as Total_count
FROM `Target.customers` as c 
INNER JOIN `Target.orders` as o 
ON c.customer_id=o.customer_id
CROSS JOIN order_ranges
where o.order_purchase_timestamp 
between order_ranges.first_order AND order_ranges.last_order
GROUP BY c.customer_city, c.customer_state
ORDER BY Total_count DESC;


# Is there a growing trend in the no. of orders placed over the past years?
SELECT 
    COUNT(order_id) as Total_orders, 
    EXTRACT(Year FROM order_purchase_timestamp) as Order_year
FROM `Target.orders`
GROUP BY Order_year
ORDER BY Order_year;


# Can we see some kind of monthly seasonality in terms of the no. of orders being placed?
SELECT 
    EXTRACT(year FROM order_purchase_timestamp) as Year_of_order,
    EXTRACT(month FROM order_purchase_timestamp) as Month_of_order,
    COUNT(order_id) as Total_orders
FROM Target.orders
GROUP BY Year_of_order,Month_of_order
ORDER BY Year_of_order,Month_of_order;


# During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
# 0-6 hrs : Dawn
# 7-12 hrs : Mornings
# 13-18 hrs : Afternoon
# 19-23 hrs : Night
SELECT 
    CASE
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6 THEN 'Dawn'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Mornings'
    WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
    ELSE 'Night'
    END AS Time_of_day,
    COUNT(order_id) as Total_count
  FROM Target.orders
  GROUP BY Time_of_day
  ORDER BY Total_count;


# Get the month on month no. of orders placed in each state.
SELECT
    COUNT(o.order_id) as Total_orders,
    EXTRACT(month from o.order_purchase_timestamp) as Month,
    EXTRACT(year from o.order_purchase_timestamp) as Year,
    c.customer_state
FROM Target.orders as o 
JOIN Target.customers as c   
  ON o.customer_id = c.customer_id
GROUP BY Year, Month, customer_state
ORDER BY c.customer_state, Year, Month;


# How are the customers distributed across all the states?
SELECT COUNT(DISTINCT customer_id) as Total_customers,
       customer_state
FROM `Target.customers`
GROUP BY customer_state
ORDER BY Total_customers DESC;


# Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only). You can use the "payment_value" column in the payments table to get the cost of orders.
SELECT Year,(LEAD(Total_amount)  OVER(ORDER BY Year) - Total_amount) /Total_amount * 100 as Perc
FROM
(
SELECT
       EXTRACT(year from o.order_purchase_timestamp) as Year,
       SUM(p.payment_value) as Total_amount
FROM `Target.orders` as o   
JOIN `Target.payments` as p    
ON o.order_id=p.order_id
WHERE EXTRACT(year from o.order_purchase_timestamp) BETWEEN 2017 AND 2018
AND EXTRACT(month from o.order_purchase_timestamp) BETWEEN 1 AND 8
GROUP BY Year
ORDER BY Year
);


#Another method

SELECT ((Cost_2018-Cost_2017)/Cost_2017)*100 as Percentage
FROM
(
SELECT SUM(CASE WHEN EXTRACT(year from o.order_purchase_timestamp)= 2017 THEN p.payment_value else 0 end) as Cost_2017,
       SUM(CASE WHEN EXTRACT(year from o.order_purchase_timestamp)= 2018 THEN p.payment_value else 0 end) as Cost_2018
FROM `Target.orders` as o   
JOIN `Target.payments` as p    
ON o.order_id=p.order_id
WHERE EXTRACT(month from o.order_purchase_timestamp) BETWEEN 1 AND 8
AND EXTRACT(year from o.order_purchase_timestamp) IN (2017,2018));


# Calculate the Total & Average value of order price for each state
SELECT c.customer_state,
       SUM(oi.price) as Total_price, 
       AVG(oi.price) as Avg_price
FROM `Target.customers` as c  
 JOIN `Target.orders` as o  
 ON c.customer_id = o.customer_id
 JOIN `Target.order_items` as oi 
 ON o.order_id=oi.order_id
GROUP BY customer_state  
ORDER BY Total_price, Avg_price;


# Calculate the Total & Average value of order freight for each state.
SELECT c.customer_state,
       SUM(oi.freight_value) as Total_freight, 
       AVG(oi.freight_value) as Avg_freight
FROM `Target.customers` as c  
 JOIN `Target.orders` as o  
 ON c.customer_id = o.customer_id
 JOIN `Target.order_items` as oi 
 ON o.order_id=oi.order_id
GROUP BY customer_state  
ORDER BY Total_freight desc;


# Find the no. of days taken to deliver each order from the order’s purchase date as delivery time. Also, calculate the difference (in days) between the estimated & actual delivery date of an order.
# Do this in a single query.

# You can calculate the delivery time and the difference between the estimated & actual delivery date using the given formula:
# time_to_deliver = order_delivered_customer_date - order_purchase_timestamp
# diff_estimated_delivery = order_delivered_customer_date - order_estimated_delivery_date
SELECT
    order_id, 
    DATE_DIFF(order_delivered_customer_date,order_purchase_timestamp,Day) as time_to_deliver,
    DATE_DIFF(order_delivered_customer_date,order_estimated_delivery_date,Day) as diff_estimated_delivery
FROM `Target.orders`;


# Find out the top 5 states with the highest & lowest average freight value.

(SELECT c.customer_state, 
      AVG(oi.freight_value) as Avg_freight_value, 'Top 5 highest' as Category
FROM `Target.customers` as c   
 JOIN `Target.orders` as o   
 ON c.customer_id = o.customer_id
 JOIN `Target.order_items` as oi  
 ON o.order_id = oi.order_id
 GROUP BY customer_state
 ORDER BY Avg_freight_value DESC
 LIMIT 5)
UNION ALL
(SELECT c.customer_state, 
      AVG(oi.freight_value) as Avg_freight_value, 'Top 5 Lowest' as Category
FROM `Target.customers` as c   
 JOIN `Target.orders` as o   
 ON c.customer_id = o.customer_id
 JOIN `Target.order_items` as oi  
 ON o.order_id = oi.order_id
 GROUP BY customer_state
 ORDER BY Avg_freight_value ASC
 LIMIT 5);


 # Find out the top 5 states with the highest & lowest average delivery time.
(SELECT c.customer_state, 
      AVG(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,Day)) as Avg_delivery_time, 'Top 5 highest' as Category
FROM `Target.customers` as c   
 JOIN `Target.orders` as o   
 ON c.customer_id = o.customer_id
 GROUP BY customer_state
 ORDER BY Avg_delivery_time DESC
 LIMIT 5)
UNION ALL
(SELECT c.customer_state, 
      AVG(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,Day)) as Avg_delivery_time, 'Top 5 Lowest' as Category
FROM `Target.customers` as c   
 JOIN `Target.orders` as o   
 ON c.customer_id = o.customer_id
 GROUP BY customer_state
 ORDER BY Avg_delivery_time ASC
 LIMIT 5);


 # Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.
# You can use the difference between the averages of actual & estimated delivery date to figure out how fast the delivery was for each state.
SELECT c.customer_state,
       ROUND(AVG(date_diff(order_estimated_delivery_date,order_delivered_customer_date,Day)),2) as Avg_delivery_date
FROM `Target.customers` as c   
JOIN `Target.orders` as o   
ON c.customer_id = o.customer_id
GROUP BY c.customer_state
ORDER By Avg_delivery_date DESC
LIMIT 5;


# Find the month on month no. of orders placed using different payment types.
SELECT COUNT(DISTINCT(o.order_id)) as Total_order,
       EXTRACT(month from o.order_purchase_timestamp) as Month,
       EXTRACT(year from o.order_purchase_timestamp) as Year,
       p.payment_type
FROM `Target.orders` as o   
 JOIN `Target.payments` as p  
 ON o.order_id = p.order_id
GROUP BY Year,Month, payment_type
ORDER BY Year,Month, payment_type;


# Find the no. of orders placed on the basis of the payment installments that have been paid.
SELECT COUNT(DISTINCT(order_id)) as Total_order,
       payment_installments
FROM `Target.payments`
WHERE payment_installments >= 1
GROUP BY payment_installments
ORDER BY payment_installments;
