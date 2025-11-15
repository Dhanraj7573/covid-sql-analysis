/* ============================================================
   COVID-19 EXPLORATORY ANALYSIS
   Tables:
     - CovidDeaths
     - CovidVaccinations

   Notes:
   - Some numeric columns may be stored as text, so TRY_CONVERT is used.
   - Division uses NULLIF(...) to avoid divide-by-zero errors.
   - Adapt WHERE filters (like '%States%') to any country/region you want.
   ============================================================ */

---------------------------------------------------------------
-- 1. Quick peek at CovidDeaths
---------------------------------------------------------------
SELECT TOP (5)
    Location,
    total_cases,
    new_cases,
    [date],
    total_deaths,
    new_deaths
FROM CovidDeaths
ORDER BY Location, [date];


---------------------------------------------------------------
-- 2. Max total cases & deaths by location
---------------------------------------------------------------
SELECT TOP (5)
    Location,
    MAX(TRY_CONVERT(float, total_cases))  AS max_total_cases,
    MAX(TRY_CONVERT(float, total_deaths)) AS max_total_deaths
FROM CovidDeaths
GROUP BY Location
ORDER BY max_total_cases DESC;


---------------------------------------------------------------
-- 3. Quick look at both tables (raw structure check)
---------------------------------------------------------------
SELECT TOP (5) *
FROM CovidDeaths
ORDER BY [date] DESC, Location;

SELECT TOP (5) *
FROM CovidVaccinations
ORDER BY [date] DESC, Location;


---------------------------------------------------------------
-- 4. Case fatality rate (deaths as % of cases) by location
--    Example filter: locations containing 'States'
---------------------------------------------------------------
SELECT 
    Location,
    MAX(TRY_CONVERT(float, total_cases))  AS total_cases,
    MAX(TRY_CONVERT(float, total_deaths)) AS total_deaths,
    100.0 * MAX(TRY_CONVERT(float, total_deaths))
          / NULLIF(MAX(TRY_CONVERT(float, total_cases)), 0) AS pct_deaths_per_case
FROM CovidDeaths
WHERE Location LIKE '%Kingdom%'   -- change this filter as needed
GROUP BY Location
ORDER BY pct_deaths_per_case DESC;


---------------------------------------------------------------
-- 5. Total cases as % of population for each date
--    (Cases vs population for a specific country/region)
---------------------------------------------------------------
SELECT 
    d.Location, 
    d.[date],
    TRY_CONVERT(float, d.total_cases) AS total_cases,
    TRY_CONVERT(float, v.population)  AS population,
    100.0 * TRY_CONVERT(float, d.total_cases)
          / NULLIF(TRY_CONVERT(float, v.population), 0) AS pct_population_infected
FROM CovidDeaths d
INNER JOIN CovidVaccinations v
    ON  d.Location = v.Location
    AND d.[date]   = v.[date]
WHERE d.Location LIKE '%States%'      -- change this filter as needed
ORDER BY 
    d.Location,
    d.[date];


---------------------------------------------------------------
-- 6. Countries with the highest infection rate
--    (Max total_cases as % of population per country)
---------------------------------------------------------------
SELECT 
    d.Location,
    MAX(TRY_CONVERT(float, v.population))   AS population,
    100.0 * MAX(TRY_CONVERT(float, d.total_cases))
          / NULLIF(MAX(TRY_CONVERT(float, v.population)), 0) AS pct_population_infected
FROM CovidDeaths d
INNER JOIN CovidVaccinations v
    ON d.Location = v.Location
   AND d.[date]   = v.[date]
GROUP BY 
    d.Location
ORDER BY 
    pct_population_infected DESC;


---------------------------------------------------------------
-- 7. Daily % of population tested (per date & location)
---------------------------------------------------------------
SELECT 
    Location, 
    [date], 
    TRY_CONVERT(float, total_tests) AS total_tests,
    TRY_CONVERT(float, population)  AS population,
    100.0 * TRY_CONVERT(float, total_tests)
          / NULLIF(TRY_CONVERT(float, population), 0) AS pct_population_tested
FROM CovidVaccinations
WHERE total_tests IS NOT NULL;


---------------------------------------------------------------
-- 8. Countries with the highest overall testing rate
--    (Max total_tests as % of population per country)
---------------------------------------------------------------
SELECT 
    Location,
    MAX(TRY_CONVERT(float, total_tests)) AS max_total_tests,
    MAX(TRY_CONVERT(float, population))  AS population,
    100.0 * MAX(TRY_CONVERT(float, total_tests))
          / NULLIF(MAX(TRY_CONVERT(float, population)), 0) AS pct_population_tested
FROM CovidVaccinations
WHERE total_tests IS NOT NULL
GROUP BY Location
ORDER BY pct_population_tested DESC;


---------------------------------------------------------------
-- 9. Relationship between total tests and total deaths
--    (% of deaths per test on each date/location)
---------------------------------------------------------------
SELECT 
    d.Location, 
    d.[date],
    TRY_CONVERT(float, d.total_deaths) AS total_deaths, 
    TRY_CONVERT(float, v.total_tests)  AS total_tests, 
    100.0 * TRY_CONVERT(float, d.total_deaths)
          / NULLIF(TRY_CONVERT(float, v.total_tests), 0) AS pct_deaths_per_test
FROM CovidDeaths d
INNER JOIN CovidVaccinations v
    ON d.Location = v.Location
   AND d.[date]   = v.[date]
WHERE v.total_tests  IS NOT NULL 
  AND d.total_deaths IS NOT NULL
ORDER BY 
    d.Location,
    d.[date];
---------------------------------------------------------------
-- 10.  7-day rolling average of new cases for a country
---------------------------------------------------------------
SELECT
    Location,
    [date],
    TRY_CONVERT(float, new_cases) AS new_cases,
    AVG(TRY_CONVERT(float, new_cases)) OVER (
        PARTITION BY Location
        ORDER BY [date]
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS new_cases_7d_avg
FROM CovidDeaths
WHERE Location = 'France'   -- change to any country you like
ORDER BY [date];

---------------------------------------------------------------
-- 11.  Country-level summary of infection, death & testing
---------------------------------------------------------------
WITH country_summary AS (
    SELECT
        d.Location,
        MAX(TRY_CONVERT(float, v.population))   AS population,
        MAX(TRY_CONVERT(float, d.total_cases))  AS max_total_cases,
        MAX(TRY_CONVERT(float, d.total_deaths)) AS max_total_deaths,
        MAX(TRY_CONVERT(float, v.total_tests))  AS max_total_tests
    FROM CovidDeaths d
    INNER JOIN CovidVaccinations v
        ON d.Location = v.Location
       AND d.[date]   = v.[date]
    GROUP BY d.Location
)
SELECT
    Location,
    population,
    max_total_cases,
    max_total_deaths,
    max_total_tests,
    100.0 * max_total_cases / NULLIF(population, 0)  AS pct_population_infected,
    100.0 * max_total_deaths / NULLIF(population, 0) AS pct_population_dead,
    100.0 * max_total_tests / NULLIF(population, 0)  AS pct_population_tested
FROM country_summary
ORDER BY pct_population_infected DESC;
