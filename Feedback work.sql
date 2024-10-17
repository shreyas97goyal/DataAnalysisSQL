-- Q2 Find the top-selling tracks and top artist in the USA and identify their most famous genres.
-- top selling tracks in the USA
select t.track_id, name, sum(total) as total
from track t
join invoice_line il
on t.track_id = il.track_id
join invoice i
on i.invoice_id = il.invoice_id
join customer c 
on c.customer_id = i.customer_id
where lower(c.country)='usa'
group by t.track_id, name
order by total desc;


-- top artist in the usa
with top_tracks as
(select t.track_id, name, sum(total) as total
from track t
join invoice_line il
on t.track_id = il.track_id
join invoice i
on i.invoice_id = il.invoice_id
join customer c 
on c.customer_id = i.customer_id
where lower(c.country)='usa'
group by t.track_id, name
order by total desc),
tracksAndArtist as
(select tt.track_id, tt.name as track_name, total, aa.artist_id, aa.name as artist_name from 
top_tracks tt join track t 
on tt.track_id = t.track_id
join album a on t.album_id = a.album_id
join artist aa on aa.artist_id = a.artist_id
order by total desc)
select artist_id, artist_name, sum(total) as total 
from tracksAndArtist
group by artist_id, artist_name
order by total desc;


-- most famous genre for the top selling tracks in the USA
-- most famous genre will be the genre of the top most sold track in the USA
with top_tracks as
(select t.track_id, name, sum(total) as total
from track t
join invoice_line il
on t.track_id = il.track_id
join invoice i
on i.invoice_id = il.invoice_id
join customer c 
on c.customer_id = i.customer_id
where lower(c.country)='usa'
group by t.track_id, name
order by total desc),
trackandgenre as
(select g.genre_id, g.name as genre_name, tt.track_id, tt.name as track_name, total
from top_tracks tt join track t
on tt. track_id=t.track_id
join genre g on g.genre_id = t.genre_id)
select genre_name, sum(total) as total
from trackandgenre
group by genre_name
order by total desc;


-- 3.What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
select * from customer;
-- customer in various countries
SELECT country, COUNT(*) AS customer_count
FROM customer
GROUP BY country
ORDER BY customer_count DESC;

-- customers in various cities
SELECT country,city, COUNT(*) AS customer_count
FROM customer
GROUP BY country,city
ORDER BY customer_count DESC;


-- 4.Calculate the total revenue and number of invoices for each country, state, and city:
-- a) total revenue for each country
select c.country, sum(total) as total,
count(i.invoice_Id) as number_of_invoices
from customer c join invoice i 
on c.customer_id = i.customer_id
-- join invoice i
-- on i.invoice_id = il.invoice_id
-- join customer c 
-- on c.customer_id = i.customer_id
group by c.country
order by total desc;


-- b) total revenue from each state
select country,
case when c.state is not null then c.state else 'Others' end as state, sum(total) as total, count(invoice_id) as Num_invoice
from customer c join invoice i on c.customer_id = i.invoice_Id-- track t
-- join invoice_line il
-- on t.track_id = il.track_id
-- join invoice i
-- on i.invoice_id = il.invoice_id
-- join customer c 
-- on c.customer_id = i.customer_id
group by country,state
order by total desc;


-- a) total revenue from each city
select country,
case when c.state is not null then c.state else 'Others' end as state,
city, sum(total) as total, count(invoice_id) as num_invoice
from invoice i-- track t
-- join invoice_line il
-- on t.track_id = il.track_id
-- join invoice i
-- on i.invoice_id = il.invoice_id
join customer c 
on c.customer_id = i.customer_id
group by country,state,city
order by total desc;

-- 5.Find the top 5 customers by total revenue in each country
with countryandcustomers as
(select c.country,c.customer_id, c.first_name, c.last_name, sum(total) as total
from -- track t
-- join invoice_line il
-- on t.track_id = il.track_id
-- join invoice i
-- on i.invoice_id = il.invoice_id
-- join customer c 
customer c join invoice i on  c.customer_id = i.customer_id
-- where lower(c.country)='usa'
group by c.country,c.customer_id, c.first_name, c.last_name
order by total desc ),
rankedData as
(select country, customer_id, first_name, last_name, total,
rank()over(partition by country order by total desc) as rnk
from countryandcustomers order by country)
select  country, customer_id, first_name, last_name, total
from rankedDAta where rnk <=5
order by 
 total desc;


-- 6.	Identify the top-selling track for each customer
with customerAndTrack as
(select c.customer_id, c.first_name, c.last_name,t.track_id, t.name as track_name,
 sum(total) as total
from track t
join invoice_line il
on t.track_id = il.track_id
join invoice i
on i.invoice_id = il.invoice_id
join customer c 
on c.customer_id = i.customer_id
-- where lower(c.country)='usa'
group by t.track_id, track_name, c.customer_id, c.first_name, c.last_name
order by total desc ),
rankedData as
(select customer_id, first_name, last_name, track_id, track_name, total,
rank()over(partition by customer_id order by total desc) as rnk 
from customerAndTrack)
select customer_id, first_name, last_name, track_id, track_name, total
from rankedData 
where rnk <=1 order by total desc;

-- top selling tracks for each customer using row_number
with customerAndTrack as
(select c.customer_id, c.first_name, c.last_name,t.track_id, t.name as track_name,
 sum(total) as total
from track t
join invoice_line il
on t.track_id = il.track_id
join invoice i
on i.invoice_id = il.invoice_id
join customer c 
on c.customer_id = i.customer_id
-- where lower(c.country)='usa'
group by t.track_id, track_name, c.customer_id, c.first_name, c.last_name
order by total desc ),
rankedData as
(select customer_id, first_name, last_name, track_id, track_name, total,
row_number()over(partition by customer_id order by total desc) as rnk 
from customerAndTrack)
select customer_id, first_name, last_name, track_id, track_name, total
from rankedData 
where rnk <=1 order by total desc;


-- 7.	Are there any patterns or trends in customer purchasing behavior 
-- (e.g., frequency of purchases, preferred payment methods, average order value)?
-- frequency of purchases by customer
WITH InvoiceDates AS (
    SELECT customer_id, invoice_date,
           LEAD(invoice_date) OVER (PARTITION BY customer_id ORDER BY invoice_date) AS next_invoice_date
    FROM invoice
),
 avg_reord_time as
 (SELECT customer_id, round(AVG(DATEDIFF(next_invoice_date, invoice_date)),0) AS average_reorder_time_days
FROM InvoiceDates
WHERE next_invoice_date IS NOT NULL
GROUP BY customer_id order by average_reorder_time_days),
total_tracks as
(SELECT c.customer_id, c.first_name, c.last_name, count(il.track_id) as total_track_purchased
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
GROUP BY c.customer_id),
total_revenue as
(select sum(total) as all_total from invoice)
SELECT c.customer_id, c.first_name, c.last_name, COUNT(i.invoice_id) AS freq_of_purchase,
sum(i.total) as Total_purchase, round(sum(i.total)*100/(select all_total from total_revenue),2) as percentage_of_total
,round(avg(i.total),2) AS average_order_value
,average_reorder_time_days, total_track_purchased
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
join avg_reord_time art on art.customer_id=c.customer_id
join total_tracks tt on tt.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY freq_of_purchase  DESC;

-- average number of tracks purchased
select avg(total_track_purchased) from 
(SELECT c.customer_id, c.first_name, c.last_name, count(il.track_id) as total_track_purchased
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
GROUP BY c.customer_id) tab1;

-- average order value,total_purchase, total_customers for each country and city
SELECT c.country, c.city,sum(i.total)as total_purchase,
round(sum(i.total)*100/(select sum(total) from invoice),2) as percentage_of_total
 ,AVG(i.total) AS average_order_value
,count(distinct c.customer_id) as total_customers, count(invoice_id) as purchase_freq
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country, c.city
order by average_order_value desc;

-- average order value, total_purchase, total_customers for each country
SELECT c.country,sum(i.total)as total_purchase
,round(sum(i.total)*100/(select sum(total) from invoice),2) as percentage_of_total
, AVG(i.total) AS average_order_value
,count(distinct c.customer_id) as total_customers, count(invoice_id) as purchase_freq
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.country
order by average_order_value desc;


-- 8.	What is the customer churn rate?
-- to find the churned customers
-- to find the churn rate
-- RAte at which customers stop doing business with a company.
-- Churn rate formula: Churn rate is calculated by dividing the number of customers lost during a time period 
-- by the total number of customers at the start of that period, then multiplying by 100 to get a percentage.

-- This is the query to get only the churn rate year wise.
  with customer_counts AS (
    SELECT
      YEAR (invoice_date) AS year,
      COUNT(distinct customer_id) AS customer_count
    FROM
      invoice
    GROUP BY
      YEAR(invoice_date)
      ),
  churn_data AS (
    SELECT
      year,
      customer_count AS this_year_cust_count,
      LAG (customer_count) OVER (
        ORDER BY
          year
      ) AS last_year_cust_count
    FROM
      customer_counts
  )
SELECT
  year,
  this_year_cust_count,
  last_year_cust_count,
  COALESCE(last_year_cust_count - this_year_cust_count, 0) AS churned_customer,
  CASE
    WHEN last_year_cust_count IS NOT NULL
    AND last_year_cust_count > 0 THEN (last_year_cust_count - this_year_cust_count) * 100.0 / last_year_cust_count
    ELSE 0
  END AS churn_rate
FROM
  churn_data;
  
  
-- ---------------------------- ---------- monthly churn rate
with cte1 as
(select DATE_FORMAT (invoice_date, '%Y-%m') AS month, 
	count(distinct customer_id) as this_month_cust_count,
	lag(count(distinct customer_id))over(order by DATE_FORMAT (invoice_date, '%Y-%m')) as last_month_cust_count
	from invoice 
	group by DATE_FORMAT (invoice_date, '%Y-%m') 
)
select month, this_month_cust_count,last_month_cust_count,
last_month_cust_count - this_month_cust_count as churned_customer,
(last_month_cust_count - this_month_cust_count)*100/last_month_cust_count as churn_rate 
from cte1;



-- 9.	Calculate the percentage of total sales contributed by each genre in the USA 
-- and identify the best-selling genres and artists.

with totalTable as
(select sum(il.unit_price*quantity) as all_total 
from invoice_line il join invoice i on i.invoice_id = il.invoice_id
where billing_country='USA'),
 genre_analyse as
(select genre_id , sum(il.unit_price*quantity) as total,
sum(il.unit_price*quantity)*100/(select all_total from totalTable) as percent_of_total
from invoice_line il join track t on il.track_id = t.track_id
join invoice i on i.invoice_id=il.invoice_id
where billing_country='USA'
group by genre_id
order by total desc)
select a.genre_id, g.name ,total, percent_of_total
from genre_analyse a join genre g
on a.genre_id = g.genre_id
order by percent_of_total desc;









-- best selling artist
with totalTable as
(select sum(il.unit_price*quantity) as all_total 
from invoice_line il join invoice i on i.invoice_id = il.invoice_id
where billing_country='USA'),
 album_analyse as
(select album_id , sum(il.unit_price*quantity) as total,
sum(il.unit_price*quantity)*100/(select all_total from totalTable) as percent_of_total
from invoice_line il join track t on il.track_id = t.track_id
join invoice i on i.invoice_id=il.invoice_id
where billing_country='USA'
group by album_id
order by total desc),
 artist_analyse as
(select a.album_id, a.artist_id ,total, percent_of_total
from album_analyse aa join album a
on a.album_id = aa.album_id
order by percent_of_total desc)
select ar.artist_id, ar.name , sum(total) as total,
sum(total)*100/(select all_total from totalTable) as percent_of_total
from artist_analyse ara join artist ar 
on ara.artist_id = ar.artist_id
group by ar.artist_id, ar.name ;







-- 10.	Find customers who have purchased tracks from at least 3 different genres

SELECT first_name,  last_name,  COUNT(DISTINCT g.name) as no_of_genre_purchased
FROM customer c JOIN invoice i on i.customer_id = c.customer_id
JOIN invoice_line il on il.invoice_id = i.invoice_id
JOIN track t on t.track_id = il.track_id
JOIN genre g on g.genre_id = t.genre_id
GROUP BY 1,2 HAVING COUNT(DISTINCT g.name) >= 3
ORDER BY COUNT(DISTINCT g.name) DESC;


-- 11.	Rank genres based on their sales performance in the USA
with totalTable as
(select sum(il.unit_price*quantity) as all_total 
from invoice_line il join invoice i on i.invoice_id = il.invoice_id
where billing_country='USA'),
 genre_analyse as
(select genre_id , sum(il.unit_price*quantity) as total,
sum(il.unit_price*quantity)*100/(select all_total from totalTable) as percent_of_total
from invoice_line il join track t on il.track_id = t.track_id
join invoice i on i.invoice_id=il.invoice_id
where billing_country='USA'
group by genre_id
order by total desc),
genre_total as 
(select a.genre_id, g.name ,total, percent_of_total
from genre_analyse a join genre g
on a.genre_id = g.genre_id
order by percent_of_total desc)
select name, total, rank() over(order by total desc) as genre_rank
from genre_total;






-- Q12. Identify customers who have not made a purchase in the last 3 months
WITH last_3_month_cust as
(
SELECT * from invoice
WHERE invoice_date > (SELECT MAX(invoice_date) FROM invoice) - INTERVAL 3 MONTH
)
SELECT first_name, last_name FROM 
customer c left join last_3_month_cust l3m 
on l3m.customer_id = c.customer_id
WHERE invoice_id is NULL
;

-- ------------------------------------------------------------------------
-- ---------------------------------------------------------------------
-- Subjective Question

-- 1.	Recommend the three albums from the new record label that should be prioritised 
-- for advertising and promotion in the USA based on genre sales analysis.
-- To effectively prioritize album advertisements, you need to consider various factors 
-- such as album popularity, artist popularity, genre preferences, and target market demographics.
-- that album with the popular artist should be prioritized for ads
-- Consider factors like album release date, artist popularity, and genre trends
-- The genre should be the top genre
-- so we will be identifying the album from the top most genre, and top most artist 
-- which has done moderate sales and as scope to increase further more 
with data1 as
(select t.album_id,t.genre_id, sum(il.unit_price*quantity) as total
from track t
join invoice_line il
on t.track_id = il.track_id
join invoice i on i.invoice_id = il.invoice_id
where lower(i.billing_country)='usa'
group by 1,2
order by total desc)
select g.name,a.title, ar.name ,sum(total) as total
from data1 d join genre g on d.genre_id=g.genre_id
join album a on a.album_id=d.album_id
join artist ar on ar.artist_id=a.artist_id
group by 1,2,3
order by total desc;













-- 2.	Determine the top-selling genres in countries other than the USA 
-- and identify any commonalities or differences.

-- top 3 track in countries other than usa
with countryandtrack as
(select c.country, t.track_id, name, sum(total) as total
from track t
join invoice_line il
on t.track_id = il.track_id
join invoice i
on i.invoice_id = il.invoice_id
join customer c 
on c.customer_id = i.customer_id
where lower(c.country)<>'usa'
group by c.country, t.track_id, name
order by total desc),
rankedData as
(select country, track_id, name, total, row_number()over(partition by country order by total desc) as rnk
from countryandtrack)
select * from rankedData where rnk<=3;


-- top 5 artists in the countries other than usa
with top_tracks as
(select c.country, t.track_id, name, sum(total) as total
from track t
join invoice_line il
on t.track_id = il.track_id
join invoice i
on i.invoice_id = il.invoice_id
join customer c 
on c.customer_id = i.customer_id
where lower(c.country)<>'usa'
group by c.country, t.track_id, name
order by total desc),
tracksAndArtistandcountry as
(select tt.country,tt.track_id, tt.name as track_name, total, aa.artist_id, aa.name as artist_name from 
top_tracks tt join track t 
on tt.track_id = t.track_id
join album a on t.album_id = a.album_id
join artist aa on aa.artist_id = a.artist_id
order by total desc),
countryAndArtist as
(select country, artist_id, artist_name, sum(total) as total 
from tracksAndArtistandcountry
group by country,artist_id, artist_name
order by total desc),
rankeddata as 
(select country, artist_id, artist_name, total, 
row_number()over (partition by country order by total desc) as rnk from countryAndArtist )
select * from rankeddata where rnk<=5;


-- top 3 famous genre in all the countries except usa
with top_tracks as
(select c.country,t.track_id, name, sum(total) as total
from track t
join invoice_line il
on t.track_id = il.track_id
join invoice i
on i.invoice_id = il.invoice_id
join customer c 
on c.customer_id = i.customer_id
where lower(c.country)<>'usa'
group by c.country, t.track_id, name
order by total desc),
trackandgenreandcountry as
(select tt.country, g.genre_id, g.name as genre_name, tt.track_id, tt.name as track_name, total
from top_tracks tt join track t
on tt. track_id=t.track_id
join genre g on g.genre_id = t.genre_id),
countryandgenre as
(select country,genre_name, sum(total) as total
from trackandgenreandcountry
group by country, genre_name
order by total desc),
rankeddata as 
(select country, genre_name, total,
row_number()over(partition by country order by total desc)as rnk from trackandgenreandcountry )
select * from rankeddata where rnk<=3;
  


-- top 1 famous genre in all the countries except usa
with top_tracks as
(select c.country,t.track_id, name, sum(total) as total
from track t
join invoice_line il
on t.track_id = il.track_id
join invoice i
on i.invoice_id = il.invoice_id
join customer c 
on c.customer_id = i.customer_id
where lower(c.country)<>'usa'
group by c.country, t.track_id, name
order by total desc),
trackandgenreandcountry as
(select tt.country, g.genre_id, g.name as genre_name, tt.track_id, tt.name as track_name, total
from top_tracks tt join track t
on tt. track_id=t.track_id
join genre g on g.genre_id = t.genre_id),
countryandgenre as
(select country,genre_name, sum(total) as total
from trackandgenreandcountry
group by country, genre_name
order by total desc),
rankeddata as 
(select country, genre_name, total,
row_number()over(partition by country order by total desc)as rnk from trackandgenreandcountry )
select * from rankeddata where rnk<=1;
  
  
 -- 3.	Customer Purchasing Behavior Analysis: How do the purchasing habits 
 -- (frequency, basket size, spending amount) of long-term customers differ from those 
 -- of new customers? What insights can these patterns provide about customer loyalty 
 -- and retention strategies?
 WITH InvoiceDates AS (
    SELECT customer_id, invoice_date,
           LEAD(invoice_date) OVER (PARTITION BY customer_id ORDER BY invoice_date) AS next_invoice_date
    FROM invoice
),
 avg_reord_time as
 (SELECT customer_id, round(AVG(DATEDIFF(next_invoice_date, invoice_date)),0) AS average_reorder_time_days
FROM InvoiceDates
WHERE next_invoice_date IS NOT NULL
GROUP BY customer_id order by average_reorder_time_days),
total_tracks as
(SELECT c.customer_id, c.first_name, c.last_name, count(il.track_id) as total_track_purchased
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
join invoice_line il on il.invoice_id=i.invoice_id
GROUP BY c.customer_id),
total_revenue as
(select sum(total) as all_total from invoice),
final_cte as
(SELECT c.customer_id, c.first_name, c.last_name, COUNT(i.invoice_id) AS freq_of_purchase,
sum(i.total) as Total_purchase, round(sum(i.total)*100/(select all_total from total_revenue),2) as percentage_of_total
,round(avg(i.total),2) AS average_order_value
,average_reorder_time_days, total_track_purchased
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
join avg_reord_time art on art.customer_id=c.customer_id
join total_tracks tt on tt.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY freq_of_purchase  DESC)
select *,
case when  ntile(2)over(order by freq_of_purchase desc) =1  
then 'Long-Term Customer' else 'Short-Term customer' end as Customer_Category
 from final_cte;

-- 4.	Product Affinity Analysis: Which music genres, artists, or albums are frequently 
-- purchased together by customers? How can this information guide product recommendations
--  and cross-selling initiatives?

--    artists that are sold together frequentlyl
   with all_data as
(   SELECT  distinct i.invoice_id, a.artist_id AS artist1_id, ar.name as artist_name
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN album a ON t.album_id = a.album_id
    join artist ar on a.artist_id = ar.artist_id
    )
select a1.artist_name as artist1, a2.artist_name as artist2, count(*) as purchase_freq
from all_data a1 inner join all_data a2 on 
a1.invoice_id=a2.invoice_id and
a1.artist_name <> a2.artist_name
group by a1.artist_name, a2.artist_name
order by purchase_freq desc;


-- albumns that are sold together frequently
   with all_data as
(   SELECT  distinct i.invoice_id, a.album_id AS artist1_id, a.title as album_name
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN album a ON t.album_id = a.album_id
    join artist ar on a.artist_id = ar.artist_id
    )
select a1.album_name as album1, a2.album_name as album2, count(*) as purchase_freq
from all_data a1 inner join all_data a2 on 
a1.invoice_id=a2.invoice_id and
a1.album_name <> a2.album_name
group by a1.album_name, a2.album_name
order by purchase_freq desc;


-- genres that are sold together
   with all_data as
(   SELECT  distinct i.invoice_id, g.genre_id AS genre1_id, g.name as genre_name
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    )
select a1.genre_name as genre1, a2.genre_name as genre2, count(*) as purchase_freq
from all_data a1 inner join all_data a2 on 
a1.invoice_id=a2.invoice_id and
a1.genre_name <> a2.genre_name
group by a1.genre_name, a2.genre_name
order by purchase_freq desc;




-- Q5. Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across 
-- different geographic regions or store locations? How might these correlate with local demographic or 
-- economic factors?


-- Overall churn rate countrywise without distinct
WITH initial_customers AS (
    SELECT billing_country,Year(invoice_date) as year, COUNT( customer_id) AS total_customers_initially
    FROM invoice where year(invoice_date) = (select min(year(invoice_date)) from invoice)
    group by billing_country, year(invoice_date)
    ),
  final_customers AS (
    SELECT billing_country, year(invoice_date) as year, COUNT( customer_id) AS total_customers_finally
    FROM invoice WHERE year(invoice_date) = ( SELECT MAX(year(invoice_date)) FROM invoice )
    group by billing_country,year(invoice_date)
  )
SELECT ic.billing_country, total_customers_initially, total_customers_finally,
	(total_customers_initially-total_customers_finally) as churned_customers,
    (total_customers_initially - total_customers_finally)*100 / total_customers_initially AS overall_churn_rate
FROM initial_customers ic join final_customers fc
on ic.billing_country = fc.billing_country;


-- year by year churn rate countryWise
with customer_counts AS (
    SELECT
		billing_country,
      YEAR (invoice_date) AS year,
      COUNT(distinct customer_id) AS customer_count
    FROM
      invoice
    GROUP BY
      billing_country,
      YEAR(invoice_date)
      ),
  churn_data AS (
    SELECT
    billing_country,
      year,
      customer_count AS this_year_cust_count,
      LAG (customer_count) OVER ( partition by billing_country
        ORDER BY
          year
      ) AS last_year_cust_count
    FROM
      customer_counts
  )
SELECT
	billing_country,
  year,
  this_year_cust_count,
  last_year_cust_count,
  COALESCE(last_year_cust_count - this_year_cust_count, 0) AS churned_customer,
  CASE
    WHEN last_year_cust_count IS NOT NULL
    AND last_year_cust_count > 0 THEN (last_year_cust_count - this_year_cust_count) * 100.0 / last_year_cust_count
    ELSE 0
  END AS churn_rate
FROM
  churn_data;
  
-- average number of orders
SELECT billing_country, COUNT(invoice_id) num_invoices, AVG(total) avg_sales FROM invoice
GROUP BY 1
ORDER BY COUNT(invoice_id) DESC, AVG(total) DESC;



-- Q6. Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), 
-- which customer segments are more likely to churn or pose a higher risk of reduced spending? 
-- What factors contribute to this risk?
with all_data as
(SELECT i.customer_id, CONCAT(first_name, " ", last_name) name, billing_country, invoice_date, 
SUM(total) as total, COUNT(invoice_id) as num_of_orders 
FROM invoice i LEFT JOIN customer c 
on c.customer_id = i.customer_id
GROUP BY 1,2,3,4
ORDER BY name ),
InvoiceDates AS (
    SELECT customer_id, invoice_date,
           LEAD(invoice_date) OVER (PARTITION BY customer_id ORDER BY invoice_date) AS next_invoice_date
    FROM invoice
),
 avg_reord_time as
 (SELECT customer_id, round(AVG(DATEDIFF(next_invoice_date, invoice_date)),0) AS average_reorder_time_days
FROM InvoiceDates
WHERE next_invoice_date IS NOT NULL
GROUP BY customer_id order by average_reorder_time_days),
latest_date_table as
(select max(invoice_date) as latest_date from invoice),
all_cte as
(select ad.customer_id, name, billing_country, min(invoice_date) as first_purchase,
max(invoice_date) as last_purchase, (select latest_date from latest_date_table) as todaysDAte,
datediff((select latest_date from latest_date_table),max(invoice_date)) as daysincelastpurchase,
average_reorder_time_days,
sum(num_of_orders) as total_orders,
 sum(total) as total_purchase, 
avg(total) as avg_purchase 
from all_data ad join avg_reord_time art
on ad.customer_id = art.customer_id
group by 1,2,3 
order by total_purchase desc, total_orders desc, avg_purchase desc,daysincelastpurchase) 
select *,
CASE WHEN daysincelastpurchase - average_reorder_time_days > 0 THEN 'No Risk'
     WHEN daysincelastpurchase - average_reorder_time_days = 0 THEN 'Low Risk'
     WHEN daysincelastpurchase - average_reorder_time_days BETWEEN -30 AND 0 THEN 'Medium Risk'
     ELSE 'High Risk'
END AS risk_category from all_cte;

-- Q7 7.	Customer Lifetime Value Modeling: How can you leverage customer data (tenure, purchase history, engagement) 
-- to predict the lifetime value of different customer segments? This could inform targeted marketing and loyalty program 
-- strategies. Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?
With all_data as
(select c.customer_id, c.first_name as name, min(invoice_date) as start_date, 
max(invoice_date) as end_date, 
round(datediff(max(invoice_date),min(invoice_date))/365.25,1) as Duration, 
sum(total) as total, avg(total) as average_value,
count(i.invoice_id) as num_Trnx
from customer c join invoice i
on c.customer_id = i.customer_id
group by c.customer_id, c.first_name)
select *, 
average_value*num_Trnx*Duration as lifetime_Value
from all_data;




-- Q11. Chinook is interested in understanding the purchasing behavior of customers based on their 
-- geographical location. They want to know the average total amount spent by customers from each country, 
-- along with the number of customers and the average number of tracks purchased per customer. 
-- Write an SQL query to provide this information.



-- total amount and average no of customer for each country
select c.country , avg(total) as average, 
count(distinct c.customer_id) as noOfcutomers,
count(track_id) as countOftracks
from customer c join invoice i 
on c.customer_id = i.customer_id
join invoice_line il on 
il.invoice_id = i.invoice_id
group by c.country
order by average desc, noOfcutomers desc;


-- average number of tracks per customer
select c.customer_id, count(distinct track_id) as numberoftracks
from customer c join invoice i 
on c.customer_id = i.customer_id
join invoice_line il on 
il.invoice_id = i.invoice_id
group by c.customer_id order by numberoftracks desc;



-- average number of tracks per customer_id
SELECT customer_id, COUNT(DISTINCT track_id) num_of_tracks_per_customer FROM invoice i
LEFT JOIN invoice_line il on il.invoice_id = i.invoice_id
GROUP BY 1;
 
 
 
select c.country, count(distinct i.invoice_id) as number_of_invoice
from track t
join invoice_line il
on t.track_id = il.track_id
join invoice i
on i.invoice_id = il.invoice_id
join customer c 
on c.customer_id = i.customer_id
group by c.country
order by number_of_invoice desc;
