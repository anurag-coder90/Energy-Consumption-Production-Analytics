use energy;

select * from customers;
select * from energy_consumption;
select * from energy_production;
select * from production_plants;
select * from sustainability_initiatives;



-- Data Cleaning
-- Changing energy_type (electricity) in production_plants and energy_production tables to 'hydro' since the column had mixed 
-- primary inputs (coal, wind, gas) with a secondary output (electricity). All entries should be primary generation sources. 

update production_plants
set energy_type = 'hydro'
where energy_type = 'electricity';

update energy_production
set energy_type = 'hydro'
where energy_type = 'electricity';


 -- Q1 Identify the top 5 production plants with the highest average carbon emissions per unit of energy produced.
 
 
with total as (
select p.plant_name, p.location, 
round(sum(ep.carbon_emission_kg), 2) as total_carbon_emissions_kg,
round(sum(ep.amount_kwh), 2) as total_energy_produced_kwh
from energy_production ep
join production_plants p on ep.production_plant_id = p.plant_id
group by p.plant_name, p.location
)
select *, round(total_carbon_emissions_kg/total_energy_produced_kwh, 5) as avg_carbon_emission_per_kwh
from total
order by avg_carbon_emission_per_kwh desc
limit 5;


-- Q2 List all energy production records along with a new column that shows the total energy production amount for each energy_type.

select production_ID, production_plant_id, date, energy_type, amount_kwh, 
round(sum(amount_kwh) over (partition by energy_type), 2) as total_energy_by_type_kwh
from energy_production 
order by energy_type, date;


-- Q3 Rank the energy production records based on the production amount within each energy type.

select production_id, production_plant_id, date, energy_type, amount_kwh, 
rank() over (partition by energy_type order by amount_kwh desc) as ranking_within_type
from energy_production;


-- Q4 List all energy consumption records while also providing a new column that displays the cumulative energy consumption for each customer over time.

select consumption_id, customer_id, date, energy_type, amount_kwh,
round(sum(amount_kwh) over (partition by customer_id order by date), 2) as cumulative_consumption
from energy_consumption;


-- Q5 List the production plant ID, energy type, date, and amount of the top 3 highest energy production records for each energy type. 
-- Ensure that you assign a unique rank to each record within its energy type category.

with ranking as (
select production_plant_id, energy_type, date, amount_kwh, 
row_number() over (partition by energy_type order by amount_kwh desc, date asc) as ranking
from energy_production
)
select production_plant_id, energy_type, date, amount_kwh, ranking
from ranking 
where ranking < 4
order by energy_type, ranking;


-- Q6 Rank the production plants based on their average monthly energy production. 

-- 1st method using CTE 

with avg_monthly_production as (
select production_plant_id, 
date_format(date, '%Y-%m-01') as month, 
round(avg(amount_kwh), 2) as avg_monthly_production
from energy_production
group by production_plant_id, date_format(date, '%Y-%m-01')
)
select production_plant_id, month, avg_monthly_production,
rank() over (partition by month order by avg_monthly_production desc) as ranking
from avg_monthly_production
order by month, ranking;


-- Q7 Rank the sustainability initiatives based on their total energy savings.

select initiative_name, start_date, end_date, 
energy_savings_kwh as total_energy_savings, 
timestampdiff(day, start_date, end_date) as duration_in_days,
rank() over (order by energy_savings_kwh desc) as initiative_rank
from sustainability_initiatives;


-- Q8 List the monthly energy production amounts for each plant along with the previous month's production amount and the next month's production amount.

with monthly_production as (
select production_plant_id, 
date_format(date, '%Y-%m-01') as month, 
sum(amount_kwh) as monthly_production
from energy_production 
group by production_plant_id, date_format(date, '%Y-%m-01')
)
select production_plant_id, month, 
round(monthly_production, 2) as monthly_production,
round(lag(monthly_production) over (partition by production_plant_id order by month), 2) as previous_month_production,
round(lead(monthly_production) over (partition by production_plant_id order by month), 2) as next_month_production
from monthly_production;


-- Q9 List each customer's ID along with their first and last total daily consumption values in 2023.

with daily_consumption as (
select customer_id, date, 
sum(amount_kwh) as daily_consumption
from energy_consumption
where year(date) = 2023
group by customer_id, date
)
select distinct customer_id,
round(first_value(daily_consumption) over 
(partition by customer_id order by date rows between unbounded preceding and unbounded following), 2) as first_consumption,
round(last_value(daily_consumption) over 
(partition by customer_id order by date rows between unbounded preceding and unbounded following), 2) as last_consumption
from daily_consumption;


-- Q10 List each customer's total energy consumption and their average monthly consumption. 

with monthly_consumption as (
select c.customer_id, c.name, 
date_format(ec.date, '%Y-%m-01') as month, 
sum(ec.amount_kwh) as monthly_consumption 
from customers c
join energy_consumption ec on c.customer_id = ec.customer_id
group by c.customer_id, c.name, date_format(ec.date, '%Y-%m-01')
)
select customer_id, name, 
round(sum(monthly_consumption), 2) as total_consumption,
round(avg(monthly_consumption), 2) as avg_monthly_consumption
from monthly_consumption
group by customer_id, name
order by customer_id;


-- Q11 Calculate both the average and total carbon emissions for each plant.

with emissions as (
select ep.production_plant_id, p.plant_name, ep.carbon_emission_kg as emissions 
from energy_production ep
join production_plants p on ep.production_plant_id = p.plant_id
)
select production_plant_id, plant_name, 
round(avg(emissions), 2) as avg_emissions,
round(sum(emissions), 2) as total_emissions
from emissions
group by production_plant_id, plant_name
order by production_plant_id;


--  Q12 List each initiative's total energy savings and the daily average energy savings.

with total_savings as (
select initiative_id, initiative_name, 
timestampdiff(day, start_date, end_date) as duration_in_days, 
energy_savings_kwh as total_savings
from sustainability_initiatives
)
select initiative_id, initiative_name, total_savings, duration_in_days, 
round(total_savings/duration_in_days, 2) as avg_daily_savings
from total_savings
order by total_savings desc;


-- Q13 Which customer segments have the highest energy consumption and energy expenditure, and how does the 
-- average consumption per customer differ across segments?

with total as (
select c.segment as customer_segment, 
count(distinct c.customer_id) as customer_count, 
round(sum(ec.amount_kwh), 2) as total_energy_consumption_kwh, 
round(sum(ec.cost_usd), 2) as total_energy_expenditure_usd
from customers c
join energy_consumption ec on c.customer_id = ec.customer_id
group by c.segment
)
select *, 
round(total_energy_consumption_kwh/customer_count, 2) as avg_consumption_per_customer,
round(total_energy_expenditure_usd/customer_count, 2) as avg_cost_per_customer, 
round(total_energy_expenditure_usd/total_energy_consumption_kwh, 2) as avg_cost_usd_per_kwh
from total
order by total_energy_consumption_kwh desc;


-- Q14 Which production plants use their available production capacity most effectively, and which have the lowest energy production cost per kWh?

with plant_metrics as (
select p.plant_id, p.plant_name, ep.energy_type, 
p.capacity_kwh as daily_capacity_kwh, 
sum(ep.amount_kwh) as total_energy_produced,
sum(ep.cost_usd) as total_production_cost_usd,
count(distinct ep.date) as production_days
from production_plants p 
join energy_production ep on p.plant_id = ep.production_plant_id
group by p.plant_id, p.plant_name, ep.energy_type, p.capacity_kwh
),

plant_performance as (
select plant_id, plant_name, energy_type, 
round(total_energy_produced, 2) as total_energy_produced, 
daily_capacity_kwh, production_days, 
daily_capacity_kwh * production_days as total_available_capacity_kwh,
round(total_energy_produced/NULLIF(daily_capacity_kwh * production_days, 0)*100, 2) as capacity_utilization_percentage, 
round(total_production_cost_usd, 2) as total_production_cost_usd, 
round(total_production_cost_usd/total_energy_produced, 5) as production_cost_per_kwh
from plant_metrics
)

select plant_id, plant_name, energy_type, daily_capacity_kwh, total_energy_produced, 
total_production_cost_usd, production_days, capacity_utilization_percentage, production_cost_per_kwh,
dense_rank() over (order by capacity_utilization_percentage desc) as capacity_utilization_rank,
dense_rank() over (order by production_cost_per_kwh) as production_cost_per_kwh_ranking
from plant_performance
order by capacity_utilization_rank, production_cost_per_kwh_ranking asc;


-- Q15 Which customers and customer segments show the largest increases or decreases in monthly energy consumption, 
-- and how has their consumption changed over time?

with monthly_consumption as (
select c.customer_id, 
c.name as customer_name, 
c.segment as customer_segment,
date_format(ec.date, '%Y-%m-01') as month, 
sum(ec.amount_kwh) as monthly_consumption
from customers c
join energy_consumption ec on c.customer_id = ec.customer_id
group by c.customer_id, c.name, c.segment, date_format(ec.date, '%Y-%m-01')
),

previous_month as (
select *, 
lag(monthly_consumption) over (partition by customer_id order by month) as previous_month_consumption
from monthly_consumption
),

monthly_trends as (
select *, 
monthly_consumption - previous_month_consumption as mom_change_kwh,
abs(monthly_consumption - previous_month_consumption) as abs_change_kwh,
round((monthly_consumption - previous_month_consumption)/nullif(previous_month_consumption, 0) * 100, 2) as mom_change_percentage
from previous_month
),

ranked as (
select *, 
row_number() over (partition by customer_id order by abs_change_kwh desc) as customer_change_rank
from monthly_trends
),

summary as (
select customer_id, customer_name, customer_segment, 
max(abs_change_kwh) as largest_monthly_change_kwh,
sum(case when mom_change_kwh > 0 then 1 else 0 end) as months_with_increased_consumption,
sum(case when mom_change_kwh < 0 then 1 else 0 end) as months_with_decreased_consumption,
sum(case when mom_change_kwh > 0 then mom_change_kwh else 0 end) as total_monthly_increases_kwh,
sum(case when mom_change_kwh < 0  then abs_change_kwh else 0 end) as total_monthly_decreases_kwh,
sum(case when mom_change_kwh is not null then 1 else 0 end) as months_compared
from monthly_trends
group by customer_id, customer_name, customer_segment
)

select s.customer_id, s.customer_name, s.customer_segment,
round(s.largest_monthly_change_kwh, 2) as largest_monthly_change_kwh,
r.month as month,
case when r.mom_change_kwh > 0 then 'Positive' when r.mom_change_kwh < 0 then 'Negative' else 'No Change' end as largest_change_direction,
s.months_with_increased_consumption, s.months_with_decreased_consumption,
round(s.total_monthly_increases_kwh, 2) as total_monthly_increases_kwh,
round(s.total_monthly_decreases_kwh, 2) as total_monthly_decreases_kwh,
s.months_compared, 
dense_rank() over (order by s.largest_monthly_change_kwh desc) as customer_rank
from summary s
join ranked r on s.customer_id = r.customer_id and r.customer_change_rank = 1
order by customer_rank;


-- CUSTOMER SEGMENT ANALYSIS

with monthly_consumption as (
select c.segment as customer_segment, 
date_format(ec.date, '%Y-%m-01') as month, 
sum(ec.amount_kwh) as monthly_consumption
from customers c 
join energy_consumption ec on c.customer_id = ec.customer_id
group by c.segment, date_format(ec.date, '%Y-%m-01')
),

previous_month_consumption as (
select *, 
lag(monthly_consumption) over (partition by customer_segment order by month) as previous_month_consumption
from monthly_consumption
),

mom_change as (
select *, 
monthly_consumption - previous_month_consumption as mom_change,
abs(monthly_consumption - previous_month_consumption) as abs_mom_change,
(monthly_consumption - previous_month_consumption)/nullif(previous_month_consumption, 0) * 100 as mom_percentage_change
from previous_month_consumption
),

change_rank as (
select *, 
row_number() over (partition by customer_segment order by abs_mom_change desc) as change_rank
from mom_change
),

summary as (
select customer_segment,
max(abs_mom_change) as largest_monthly_change,
sum(case when mom_change > 0 then 1 else 0 end) as months_with_increased_consumption,
sum(case when mom_change < 0 then 1 else 0 end) as months_with_decreased_consumption,
sum(case when mom_change > 0 then mom_change else 0 end) as total_monthly_increases,
sum(case when mom_change < 0 then abs_mom_change else 0 end) as total_monthly_decreases,
sum(case when mom_change is not null then 1 else 0 end) as months_compared
from change_rank
group by customer_segment
)

select s.customer_segment, 
round(s.largest_monthly_change, 2) as largest_monthly_change,
case when r.mom_change > 0 then 'Positive' when r.mom_change < 0 then 'Negative' else 'No Change' end as largest_change_direction,
s.months_with_increased_consumption, s.months_with_decreased_consumption,
round(s.total_monthly_increases, 2) as total_monthly_increases,
round(s.total_monthly_decreases, 2) as total_monthly_decreases,
s.months_compared,
dense_rank() over (order by s.largest_monthly_change desc) as segment_change_rank
from summary s
join change_rank r on
s.customer_segment = r.customer_segment and r.change_rank = 1
order by segment_change_rank;