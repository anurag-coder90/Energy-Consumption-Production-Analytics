# Methodology and Assumptions

## 1. Project Overview

This project analyzes energy consumption, energy production, customer behavior, production efficiency, carbon emissions, and sustainability initiatives using SQL and Power BI.

The objective is to demonstrate how data analytics can support business monitoring, operational efficiency, cost analysis, and sustainability reporting.

The analysis was conducted using MySQL for data extraction and transformation, and Microsoft Power BI for data visualization and reporting.

**Important:** The dataset used in this project is synthetic and is intended for analytical and portfolio demonstration purposes. The findings should not be interpreted as actual business performance or industry benchmarks.

---

## 2. Tools and Technologies

| Tool               | Purpose                                                                     |
| ------------------ | --------------------------------------------------------------------------- |
| MySQL              | Data querying, aggregation, transformation, and analysis                    |
| SQL                | Joins, CTEs, subqueries, window functions, ranking, and time-based analysis |
| Microsoft Power BI | Interactive dashboards and data visualization                               |
| DAX                | Calculated measures and KPIs                                                |
| Power Query        | Data preparation and transformation                                         |

---

## 3. Data Preparation and Validation

The following steps were considered during data preparation:

* Reviewed the database schema and identified primary and foreign key relationships.
* Examined the available tables, columns, and data types.
* Used appropriate joins to combine customer, consumption, and production information.
* Aggregated transactional data at customer, plant, energy type, and monthly levels, depending on the analytical requirement.
* Used date formatting and time-based calculations to support monthly trend analysis.
* Applied appropriate rounding to improve the readability of numerical outputs.
* Kept the Sustainability Initiatives table separate from the main customer and production analysis because it does not have a defined relationship with the other tables.

---

## 4. SQL Analysis Methodology

The SQL analysis covered the following areas:

### Customer Consumption Analysis

* Analyzed total and average energy consumption across customers and customer segments.
* Calculated cumulative consumption over time.
* Evaluated monthly consumption trends.
* Used LAG and other window functions to calculate month-over-month changes.
* Identified customers with significant increases and decreases in consumption.

### Energy Production Analysis

* Analyzed production by energy type and production plant.
* Ranked plants based on production performance.
* Evaluated average carbon emissions per unit of energy produced.
* Calculated production costs per kWh.
* Examined production capacity utilization.

### Sustainability Performance

* Evaluated energy savings and carbon reduction across sustainability initiatives.
* Compared initiatives based on their reported savings.
* Analyzed initiative budgets and duration.
* Used ranking and aggregation techniques to compare initiative performance.

### Advanced SQL Techniques

The project incorporates:

* Common Table Expressions (CTEs)
* Subqueries
* Aggregate functions
* INNER JOIN
* GROUP BY and HAVING
* Window functions
* LAG and LEAD
* FIRST_VALUE and LAST_VALUE
* ROW_NUMBER, RANK, and DENSE_RANK
* Cumulative calculations
* Table partitioning
* Indexing and query performance analysis

---

## 5. KPI Definitions and Calculation Assumptions

The following definitions provide context for interpreting the key metrics.

| KPI                              | Calculation / Definition                                                              |
| -------------------------------- | ------------------------------------------------------------------------------------- |
| Total Energy Consumption         | Sum of all recorded customer energy consumption in kWh                                |
| Total Energy Production          | Sum of all recorded energy production in kWh                                          |
| Total Energy Cost                | Sum of recorded consumption or production costs, depending on the analysis            |
| Average Consumption per Customer | Total energy consumption divided by the number of distinct customers                  |
| Average Cost per Customer        | Total customer energy expenditure divided by the number of distinct customers         |
| Cost per kWh                     | Total cost divided by total energy consumption or production, depending on the metric |
| Carbon Emissions per kWh         | Total carbon emissions divided by total energy produced                               |
| Energy Savings                   | Sum of reported energy savings across sustainability initiatives                      |
| Carbon Reduction                 | Sum of reported carbon reduction across sustainability initiatives                    |
| Month-over-Month Change          | Current month's consumption minus the previous month's consumption                    |
| Month-over-Month Change %        | Month-over-month change divided by previous month's consumption, multiplied by 100    |

### Additional Calculation Assumptions

* Average consumption per customer is calculated using distinct customers within the relevant filter context.
* Cost per kWh is calculated using total cost divided by total energy volume rather than averaging individual transaction-level rates.
* Carbon emissions per kWh are calculated using total emissions divided by total production, providing a weighted average.
* Month-over-month percentage change is not meaningful when the previous month's consumption is zero or unavailable.
* Ranking calculations use the relevant metric and ranking context defined in each SQL query or Power BI measure.

---

## 6. Capacity Utilization Assumptions

Capacity utilization measures how effectively a production plant uses its available production capacity.

The calculation depends on how the capacity field is defined.

If `capacity_kwh` represents the maximum energy a plant can produce per day, the calculation should account for the number of days in the analysis period:

**Capacity Utilization (%) =**

(Total Energy Produced / Available Production Capacity During the Period) × 100

Where:

Available Production Capacity During the Period = Daily Production Capacity × Number of Applicable Operating Days

The applicable operating days must be defined consistently. If production capacity is available every calendar day, calendar days may be used. If the plant operates only on scheduled days, actual operating days should be used.

If the dataset does not contain plant operating schedules, the calculation should clearly state the assumption used.

---

## 7. Power BI Data Modeling and Visualization

The Power BI report is organized into three analytical pages:

1. **Customer Consumption Analysis**

   * Customer consumption trends
   * Segment-level comparisons
   * Customer rankings
   * Consumption and expenditure KPIs

2. **Energy Production Analysis**

   * Energy production by type and plant
   * Production efficiency
   * Carbon emissions
   * Capacity utilization and production cost metrics

3. **Sustainability Performance**

   * Energy savings
   * Carbon reduction
   * Initiative budgets
   * Initiative duration and performance comparisons

A dedicated date table (DimDate) is used to support time-based analysis and consistent date filtering.

DAX measures are used for KPI calculations and dynamic reporting wherever appropriate.

The Sustainability Initiatives table is analyzed independently because it does not have a defined relationship with the main transactional tables.

---

## 8. Query Performance Optimization

A performance optimization exercise was conducted to explore the impact of indexing and partitioning on SQL query execution.

The 1st experiment included:

* Creating a composite index on energy type and date.
* Creating a partitioned version of the energy production table using LIST COLUMNS partitioning on energy type.
* Comparing query execution times before and after optimization.

An observed execution time comparison was:

| Measurement                   | Execution Time |
| ----------------------------- | -------------: |
| Before optimization           |          77 ms |
| After optimization            |          50 ms |
| Observed reduction            |          27 ms |
| Observed percentage reduction |         35.06% |

The 2nd experiment included:

* Creating a partitioned version of the energy production table using LIST COLUMNS partitioning on energy type.
* Creating a composite index on energy type and date.

| Measurement                   | Execution Time |
| ----------------------------- | -------------: |
| Before optimization           |          58 ms |
| After optimization            |          21 ms |
| Observed reduction            |          37 ms |
| Observed percentage reduction |         63.79% |

**Important:** These timings represent observations from a test environment using approximately 10,000 records. They are not a controlled benchmark proving that partitioning or indexing alone caused the improvement. Execution plans, caching, indexing, hardware, and database configuration can influence query performance.

---

## 9. Dataset Limitations

The following limitations should be considered:

* The dataset is synthetic and does not represent actual energy industry transactions.
* The observed trends and analytical findings are specific to the generated dataset.
* The dataset may not capture real-world seasonal patterns, operational constraints, pricing structures, or customer behavior.
* Actual production capacity and operating schedules may require additional information for precise utilization calculations.
* Sustainability initiatives are not directly linked to individual production plants or customer records.
* Business recommendations based on this dataset should be treated as analytical demonstrations rather than operational recommendations.

---

## 10. Conclusion

This project demonstrates the application of SQL and Power BI to analyze customer consumption, energy production, operational efficiency, carbon emissions, and sustainability performance.

The methodology emphasizes structured data analysis, advanced SQL techniques, KPI development, data modeling, and interactive reporting.

The project is intended to showcase practical analytical capabilities and the ability to translate structured data into meaningful business-oriented reporting.
