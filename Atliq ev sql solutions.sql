Create table electric_vehicle_sales_by_state
( date date,
state varchar(50),
vehicle_category varchar(50),	
electric_vehicles_sold integer,
total_vehicles_sold integer
);

select * from electric_vehicle_sales_by_state;

Create table electric_vehicle_sales_by_makers
(date date,
vehicle_category varchar(50),
maker varchar(50),
electric_vehicles_sold integer
);

select * from electric_vehicle_sales_by_makers;

Create table dim_date
(date date,
fiscal_year integer,
quarter varchar(50)
);

select * from dim_date;

--Primary_And_Secondary_Analysis 
--Preliminary Research Questions:  
--1. List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold.

--Top 3
Select m.vehicle_category, m.maker, sum(m.electric_vehicles_sold) as total_vehicles_sold
from electric_vehicle_sales_by_makers m
join dim_date d on m.date = d.date
where fiscal_year in (2023, 2024)
and vehicle_category = '2-Wheelers'
group by m.vehicle_category, m.maker
order by total_vehicles_sold desc
limit 3;

--Bottom 3
Select m.vehicle_category, m.maker, sum(m.electric_vehicles_sold) as total_vehicles_sold
from electric_vehicle_sales_by_makers m
join dim_date d on m.date = d.date
where fiscal_year in (2023, 2024)
and vehicle_category = '2-Wheelers'
group by m.vehicle_category, m.maker
order by total_vehicles_sold asc
limit 3;

--2. Identify the top 5 states with the highest penetration rate in 2-wheeler and 4-wheeler EV sales in FY 2024.

--For 2-Wheelers
with state_sales_2024 as(
select 
 s.state, s.vehicle_category, 
 SUM(s.electric_vehicles_sold) * 100. / SUM(s.total_vehicles_sold) AS penetration_rate
 from electric_vehicle_sales_by_state s
 join dim_date d on s.date = d.date
 where d.fiscal_year = 2024 
 and s.vehicle_category = '2-Wheelers'
 group by s.state, s.vehicle_category
 )
select state, vehicle_category, penetration_rate
from state_sales_2024
order by penetration_rate desc
limit 5;

--For 4-Wheelers
with state_sales_2024 as(
select 
 s.state, s.vehicle_category, 
 SUM(s.electric_vehicles_sold) * 100. / SUM(s.total_vehicles_sold) AS penetration_rate
 from electric_vehicle_sales_by_state s
 join dim_date d on s.date = d.date
 where d.fiscal_year = 2024 
 and s.vehicle_category = '4-Wheelers'
 group by s.state, s.vehicle_category
)
select state, vehicle_category, penetration_rate
from state_sales_2024
order by penetration_rate desc
limit 5;

--3. List the states with negative penetration (decline) in EV sales from 2022 to 2024?

with cte as (
	select state,
	sum(electric_vehicles_sold)*100.00 / sum(total_vehicles_sold) as penetration_rate22 
	from electric_vehicle_sales_by_state
	where date between '2022-01-01' and '2022-12-31'
	group by state
	), 
cte1 as 
   (select state,
	sum(electric_vehicles_sold)*100.00 / sum(total_vehicles_sold) as penetration_rate24 
	from electric_vehicle_sales_by_state
	where date between '2024-01-01' and '2024-12-31'
	group by state
	)
select  cte1.state ,  cte1.penetration_rate24, cte.penetration_rate22
from cte1 
join cte
on cte1.state = cte.state
where cte1.penetration_rate24 > cte.penetration_rate22
order by cte1.penetration_rate24 desc;

--4. What are the quarterly trends based on sales volume for the top 5 EV makers (4-wheelers) from 2022 to 2024?

with MakerSales as (
  select 
  m.maker,
  d.fiscal_year,
  d.quarter,
  sum(m.electric_vehicles_sold) as total_sales
  from electric_vehicle_sales_by_makers m
  join dim_date d on m.date = d.date
  where m.vehicle_category = '4-Wheelers'
  and d.fiscal_year between 2022 and 2024
  group by m.maker, d.fiscal_year, d.quarter
),
Top5Makers as (
    select maker
    from MakerSales
    group by maker
    order by sum(total_sales) desc
    limit 5
)
select m.maker, m.fiscal_year, m.quarter, m.total_sales
from MakerSales m
join Top5Makers t on  m.maker = t.maker
order by m.maker, m.fiscal_year, m.quarter, total_sales;

--5. How do the EV sales and penetration rates in Delhi compare to Karnataka for 2024?

select s.state,
sum(s.electric_vehicles_sold) as total_ev_sales,
sum(s.electric_vehicles_sold) * 100. / sum(s.total_vehicles_sold) as penetration_rate
from electric_vehicle_sales_by_state s
join dim_date d on s.date = d.date
where fiscal_year = 2024
and s.state in ('Delhi', 'Karnataka')
group by s.state;

--6. List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024.

with Top5makers as (
select m.maker,
sum(m.electric_vehicles_sold) as total_ev_sales
from electric_vehicle_sales_by_makers m
join dim_date d on m.date = d.date
where vehicle_category = '4-Wheelers'
and fiscal_year between 2022 and 2024
group by m.maker
order by total_ev_sales desc
limit 5
)
select t5.maker,
sum(case when d.fiscal_year = 2022 then m.electric_vehicles_sold else 0 end) as sales_2022,
sum(case when d.fiscal_year = 2024 then m.electric_vehicles_sold else 0 end) as sales_2024,
 round(
 (power(
    nullif(sum(case when d.fiscal_year = 2024 then m.electric_vehicles_sold else 0 end), 0) * 1.0 /
    nullif(sum(case when d.fiscal_year = 2022 then m.electric_vehicles_sold else 0 end), 0), 
    1.0 / 2) - 1) * 100, 
2) as cagr_percentage
from electric_vehicle_sales_by_makers m
join dim_date d on m.date = d.date
join Top5makers t5 on m.maker = t5.maker
where vehicle_category = '4-Wheelers'
and fiscal_year in (2022, 2024)
group by t5.maker
order by cagr_percentage desc;

--7. List down the top 10 states that had the highest compounded annual growth rate (CAGR) from 2022 to 2024 in total vehicles sold.

select s.state,
sum(case when d.fiscal_year = 2022 then s.total_vehicles_sold else 0 end) as sales_2022,
sum(case when d.fiscal_year = 2024 then s.total_vehicles_sold else 0 end) as sales_2024,
 round(
 (power(
    nullif(sum(case when d.fiscal_year = 2024 then s.total_vehicles_sold else 0 end), 0) * 1.0 /
    nullif(sum(case when d.fiscal_year = 2022 then s.total_vehicles_sold else 0 end), 0), 
    1.0 / 2) - 1) * 100, 
2) as cagr_percentage
from electric_vehicle_sales_by_state s
join dim_date d on s.date = d.date
where fiscal_year in (2022, 2024)
group by s.state
having sum(case when d.fiscal_year = 2022 then s.total_vehicles_sold else 0 end) > 0
order by cagr_percentage desc
limit 10;

--8. What are the peak and low season months for EV sales based on the data from 2022 to 2024? 

with RankedSales as (
  select to_char(d.date, 'month') as months,
  d.fiscal_year,
  sum(s.electric_vehicles_sold) as electric_sold,
  rank() over (order by sum(s.electric_vehicles_sold) desc) as top_rank,
  rank() over (order by sum(s.electric_vehicles_sold) asc) as bottom_rank
  from dim_date as d
  join electric_vehicle_sales_by_state as s
  on d.date = s.date
  where d.fiscal_year between 2022 and 2024
  group by months, d.fiscal_year
)
select months,fiscal_year,electric_sold,
'Peak' as sales_status
from RankedSales
where top_rank <= 1 
union all
select months,fiscal_year,electric_sold,
'Low' as sales_status
from RankedSales
where bottom_rank <= 1 
order by  sales_status, electric_sold ;

--9. What is the projected number of EV sales (including 2-wheelers and 4wheelers) for the top 10 states by penetration rate in 2030, based on the compounded annual growth rate (CAGR) from previous years?

with cagr_calculation as (
  select s.state,
  sum(case when d.fiscal_year = 2022 then s.electric_vehicles_sold else 0 end) as ev_sales_2022,
  sum(case when  d.fiscal_year = 2024 then s.electric_vehicles_sold else 0 end) as ev_sales_2024,
  case when sum(case when  d.fiscal_year = 2022 then s.electric_vehicles_sold else 0 end) = 0 then 0
  else power(sum(case when  d.fiscal_year = 2024 then s.electric_vehicles_sold else 0 end) * 1.0 /
  NULLIF(sum(case when  d.fiscal_year = 2022 then s.electric_vehicles_sold else 0 end), 0), 1.0 / 2
  ) - 1 end as cagr
  from electric_vehicle_sales_by_state s
  join dim_date d 
  on s.date = d.date
  where d.fiscal_year in (2022, 2024)
  group by s.state),
projected_sales as (
  select state, ev_sales_2024,
  ROUND( ev_sales_2024 * power(1 + cagr, 2030 - 2024), 0) as projected_ev_sales_2030
  from cagr_calculation
  where ev_sales_2024 > 0
  order by cagr desc)
select  state, ev_sales_2024, projected_ev_sales_2030
from projected_sales
order by projected_ev_sales_2030 desc
limit 10;

--10.Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India for 2022 vs 2024 and 2023 vs 2024, assuming an average unit price. 
	
WITH EVRevenue AS (
  SELECT d.fiscal_year, m.vehicle_category,
  SUM(m.electric_vehicles_sold * 
  CASE WHEN m.vehicle_category = '4-Wheelers' THEN 30000
       WHEN m.vehicle_category = '2-Wheelers' THEN 100 ELSE 0 END ) AS total_revenue
  FROM electric_vehicle_sales_by_makers m
  JOIN dim_date d
  ON m.date = d.date
  WHERE d.fiscal_year IN (2022, 2023, 2024)
  GROUP BY d.fiscal_year, m.vehicle_category
),
Revenue_2022 AS (
  SELECT vehicle_category, COALESCE(SUM(total_revenue), 0) AS revenue_2022
  FROM EVRevenue
  WHERE fiscal_year = 2022
  GROUP BY vehicle_category
),
Revenue_2023 AS (
  SELECT vehicle_category, COALESCE(SUM(total_revenue), 0) AS revenue_2023
  FROM EVRevenue
  WHERE fiscal_year = 2023
  GROUP BY vehicle_category
),
Revenue_2024 AS (
   SELECT vehicle_category, COALESCE(SUM(total_revenue), 0) AS revenue_2024
   FROM EVRevenue
   WHERE fiscal_year = 2024
   GROUP BY vehicle_category
)
SELECT 
  er2022.vehicle_category,
  er2022.revenue_2022,
  er2023.revenue_2023,
  er2024.revenue_2024,
  ROUND(CASE WHEN er2022.revenue_2022 = 0 THEN NULL
        ELSE ((er2024.revenue_2024 - er2022.revenue_2022) / er2022.revenue_2022) * 100 END, 2
) AS growth_rate_2022_vs_2024,
    ROUND(CASE WHEN er2023.revenue_2023 = 0 THEN NULL
          ELSE ((er2024.revenue_2024 - er2023.revenue_2023) / er2023.revenue_2023) * 100 END, 2
) AS growth_rate_2023_vs_2024
FROM Revenue_2022 er2022
LEFT JOIN Revenue_2023 er2023 
ON er2022.vehicle_category = er2023.vehicle_category
LEFT JOIN Revenue_2024 er2024 
ON er2022.vehicle_category = er2024.vehicle_category;

