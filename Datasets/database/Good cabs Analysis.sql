-- Good cabs ad-hoc anaysis
-- Business request 1
-- city level fare and trip summary report

 use trips_db;
 
 select city_name, count(trip_id) as total_trips, avg(fare_amount / distance_travelled_km) as avg_fare_per_km, avg(fare_amount) as avg_fare_per_trip, concat(round((count(trip_id) / (select count(*) from fact_trips) * 100 ), 2), '%') as contribution_over_trips
 from dim_city dc
 left join fact_trips fc
 on dc.city_id = fc.city_id 
 group by city_name
 order by total_trips desc;
 
 -- Business request 2 : Monthly city level trips and target performance report  
 
with cte as (
select city_name, count(trip_id) as actual, monthname(`date`) as month_name
from dim_city dc
join fact_trips fc
on dc.city_id = fc.city_id
group by city_name,month_name)

, cte2 as (
select city_name, monthname(`month`) as month_name, sum(total_target_trips) as target_trips 
from trips_db.dim_city dc
left join targets_db.monthly_target_trips  mt
on dc.city_id = mt.city_id 
group by city_name, month_name)

select cte.city_name, cte.month_name, cte.actual, cte2.target_trips, 
(case when cte.actual > cte2.target_trips then 'Above_Target' else 'Below_Target' end ) as Performance,
concat(round(((cte.actual - cte2.target_trips) * 100 / cte2.target_trips),2),'%') as diff
from cte
join cte2
on cte.city_name = cte2.city_name 
and cte.month_name = cte2.month_name
group by diff desc;

-- Business request : city level repeat passenger trip frequency

select city_name,
concat(round(sum((case when trip_count = '2-Trips' then repeat_passenger_count end)) * 100 / (select sum(repeat_passenger_count) from dim_repeat_trip_distribution),2),'%') as `2-trips`,
concat(round(sum((case when trip_count = '3-Trips' then repeat_passenger_count end)) * 100 / (select sum(repeat_passenger_count) from dim_repeat_trip_distribution),2),'%') as `3-trips`,
concat(round(sum((case when trip_count = '4-Trips' then repeat_passenger_count end)) * 100 / (select sum(repeat_passenger_count) from dim_repeat_trip_distribution),2),'%') as `4-trips`,
concat(round(sum((case when trip_count = '5-Trips' then repeat_passenger_count end)) * 100 / (select sum(repeat_passenger_count) from dim_repeat_trip_distribution),2),'%') as `5-trips`,
concat(round(sum((case when trip_count = '6-Trips' then repeat_passenger_count end)) * 100 / (select sum(repeat_passenger_count) from dim_repeat_trip_distribution),2),'%') as `6-trips`,
concat(round(sum((case when trip_count = '7-Trips' then repeat_passenger_count end)) * 100 / (select sum(repeat_passenger_count) from dim_repeat_trip_distribution),2),'%') as `7-trips`,
concat(round(sum((case when trip_count = '8-Trips' then repeat_passenger_count end)) * 100 / (select sum(repeat_passenger_count) from dim_repeat_trip_distribution),2),'%') as `8-trips`,
concat(round(sum((case when trip_count = '9-Trips' then repeat_passenger_count end)) * 100 / (select sum(repeat_passenger_count) from dim_repeat_trip_distribution),2),'%') as `9-trips`,
concat(round(sum((case when trip_count = '10-Trips' then repeat_passenger_count end)) * 100 / (select sum(repeat_passenger_count) from dim_repeat_trip_distribution),2),'%') as `10-trips`
from dim_city dc 
join dim_repeat_trip_distribution td
on dc.city_id = td.city_id
group by city_name;

-- Business request : identify city with high and low passengers

select city_name, sum(new_passengers) as new_passengers
from dim_city dc
join fact_passenger_summary fs
on dc.city_id = fs.city_id
group by city_name
order by new_passengers desc
limit 3;

select city_name, sum(new_passengers) as new_passengers
from dim_city dc
join fact_passenger_summary fs
on dc.city_id = fs.city_id
group by city_name
order by new_passengers 
limit 3;

-- Business request : Month with Highest revenue for each city

with cte as (
select city_name, 
sum(fare_amount) as revenue, monthname(`date`) as month_name,
rank() over (partition by city_name order by sum(fare_amount) desc) as rnk
from dim_city dc
join fact_trips ft
on dc.city_id = ft.city_id
group by city_name, month_name
)

select city_name, month_name, revenue, concat(round((revenue * 100 / (select sum(fare_amount) from fact_trips)),2),'%') as contribution
from cte
where rnk = 1
order by contribution desc;

-- Business request : Repeat passengers rate analysis

-- RPR BY city

select city_name, sum(repeat_passengers) as rpr , sum(total_passengers) as total, concat(round(sum(repeat_passengers) * 100 / sum(total_passengers) , 2), '%') as contribution
from dim_city dc
join fact_passenger_summary fs
on dc.city_id = fs.city_id
group by city_name
order by contribution desc;

-- Rpr by month 

select monthname(`month`) as month_name, sum(repeat_passengers) as repeat_pass , sum(total_passengers) as total, concat(round(sum(repeat_passengers) * 100 / sum(total_passengers) , 2), '%') as contribution
from fact_passenger_summary
group by month_name
order by contribution desc;

-- rpr by city and month by overall passengers

select city_name, 
concat(round(sum(case when monthname(`month`) = 'January' then repeat_passengers end ) * 100 / (select sum(total_passengers) from fact_passenger_summary) ,2) , '%') as 'Jan',
concat(round(sum(case when monthname(`month`) = 'February' then repeat_passengers end ) * 100 / (select sum(total_passengers) from fact_passenger_summary) ,2) , '%') as 'Feb',
concat(round(sum(case when monthname(`month`) = 'March' then repeat_passengers end ) * 100 / (select sum(total_passengers) from fact_passenger_summary) ,2) , '%') as 'Mar',
concat(round(sum(case when monthname(`month`) = 'April' then repeat_passengers end ) * 100 / (select sum(total_passengers) from fact_passenger_summary) ,2) , '%') as 'Apr',
concat(round(sum(case when monthname(`month`) = 'May' then repeat_passengers end ) * 100 / (select sum(total_passengers) from fact_passenger_summary) ,2) , '%') as 'May',
concat(round(sum(case when monthname(`month`) = 'June' then repeat_passengers end ) * 100 / (select sum(total_passengers) from fact_passenger_summary) ,2) , '%') as 'Jun'
from dim_city dc
join fact_passenger_summary fs
on dc.city_id = fs.city_id
group by city_name
