# covid-sql-analysis
SQL exploratory analysis on Covid cases, deaths and testing data

# COVID-19 SQL Exploration

This repo contains a small SQL project where I explore COVID-19 data for cases, deaths, testing and population impact using Microsoft SQL Server.

## Data

The project uses two tables:

- **CovidDeaths**
- **CovidVaccinations**

In this repo they are stored as:

- `data/CovidDeaths.xlsx`
- `data/CovidVaccinations.xlsx`

I imported these files into SQL Server and created tables with the same names.

## SQL Script

All analysis is in:

- `sql/covid_exploration.sql`

The script includes:

- Basic data preview (TOP 5 rows)
- Maximum total cases and deaths per country
- Case fatality rate (deaths as % of cases)
- Infection rate (cases as % of population)
- Testing rate (tests as % of population)
- Relationship between tests and deaths
- Country-level summary (infection, death and testing %)
- A 7-day rolling average of new cases using window functions

## How to Run

1. Import the Excel files into SQL Server as tables:
   - `CovidDeaths`
   - `CovidVaccinations`
2. Open `sql/covid_exploration.sql` in SSMS (or Azure Data Studio).
3. Run the queries section by section to explore the data.

This project is mainly for practice and learning SQL (joins, aggregates, window functions and CTEs).
