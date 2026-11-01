
-- Creating partitioning in energy_production table for analyzing monthly production and carbon emissions by energy type.

-- Creating table with list partitions based on energy type.

use energy;

drop table if exists energy_production_partitioned;

create table energy_production_partitioned (
production_id int, 
production_plant_id int, 
date date,
energy_type varchar(20), 
amount_kwh double, 
cost_usd double,
carbon_emission_kg double
)
partition by list columns(energy_type) (
partition p_coal values in ('coal'),
partition p_gas values in ('gas'),
partition p_hydro values in ('hydro'),
partition p_wind values in ('wind')
);

-- Inserting values in partitioned table from energy production table.

insert into energy_production_partitioned
select * from energy_production;

-- Checking the partitioned table

select * from energy_production_partitioned;

-- Checking partition details

select partition_name, partition_method, partition_expression, table_rows
from information_schema.partitions
where table_name = 'energy_production_partitioned';

-- Checking performance before partitioning and indexing using original table energy_production.

explain analyze
select energy_type, 
date_format(date, '%Y-%m-01') as month, 
round(sum(amount_kwh), 2) as monthly_production, 
round(sum(carbon_emission_kg), 2) as monthly_emissions
from energy_production
where energy_type = 'hydro'
group by energy_type, date_format(date, '%Y-%m-01')
order by energy_type, month;


-- Checking performance after partitioning and indexing using partitioned table energy_production_partitioned.

explain analyze
select energy_type, 
date_format(date, '%Y-%m-01') as month, 
round(sum(amount_kwh), 2) as monthly_production, 
round(sum(carbon_emission_kg), 2) as monthly_emissions
from energy_production_partitioned
where energy_type = 'hydro'
group by energy_type, date_format(date, '%Y-%m-01')
order by energy_type, month;

-- PERFORMANCE ANALYSIS
-- Before Time (median value) = 77 ms (median of 0.0722, 0.0832, 0.0755, 0.0777, 0.0770)
-- After Time (median value)= 50 ms (median of 0.0528, 0.0569, 0.0501, 0.0473, 0.0485)
-- Performance Improvement (%) = ((Before time - After Time)/Before Time) * 100
-- Performance Improvement (%) = 35.06%

-- Inference - The partitioned table demostrated a 35.06% reduction in execution time. This performance optimation is strictly attributed to 
-- partition pruning, which eliminated irrelevant data segments at the planning stage amd reduced the volume of scanned blocks.


-- Creating an index that would be most optimal to speed up a query that calculates the average monthly carbon emissions for each energy type.

-- Checking performance before partitioning and indexing using original table energy_production.

explain analyze
select energy_type, 
date_format(date, '%Y-%m-01') as month, 
round(avg(carbon_emission_kg), 2) as avg_monthly_emissions
from energy_production
where energy_type = 'coal' and date >= '2022-01-01' and date < '2023-01-01'
group by energy_type, date_format(date, '%Y-%m-01')
order by energy_type, month;

-- Create a composite index on energy_type and date on the partitioned table energy_production_partitioned.

create index idx_energy_type on energy_production_partitioned (energy_type, date);

-- Check the index created

show index from energy_production_partitioned;

-- Checking performance after partitioning and indexing using partitioned table energy_production_partitioned.

explain analyze
select energy_type, 
date_format(date, '%Y-%m-01') as month, 
round(avg(carbon_emission_kg), 2) as avg_monthly_emissions
from energy_production_partitioned
where energy_type = 'coal' and date >= '2022-01-01' and date < '2023-01-01'
group by energy_type, date_format(date, '%Y-%m-01')
order by energy_type, month;

-- PERFORMANCE ANALYSIS

-- Before Time (median value) = 58 ms (median of 0.0647, 0.0584, 0.0534, 0.0524, 0.0617)
-- After Time (median value) = 21 ms (median of 0.0235, 0.0269, 0.0215, 0.0202, 0.0215)
-- Performance Improvement (%) = ((Before time - After Time)/Before Time) * 100
-- Performance Improvement (%) = 63.79%

-- INFERENCE - The EXPLAIN ANALYZE output reveals that the query optimizer opted for a sequential/parallel scan over the partition rather than 
-- utilizing the compostite index on (energy_type, date). Despite the lack of index usage, execution time improved significantly (63.79%). This indicates
-- that the optimization was achieved purely via partition elimination. where the engine narrowed the search space to the relevant partition
-- drastically reducing I/O operations compared to the full table scan on the unpartitioned variant.