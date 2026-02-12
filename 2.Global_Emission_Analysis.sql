-- ===============================================================================================================================================================================
--                                                  -: Step 1. Global Emission Overview :-
-- ===============================================================================================================================================================================
-- 1.1 How have global carbon emissions changed year over year?
SELECT 
    year,
    ROUND(SUM(emissions_mtco2), 2) AS total_emissions_mtco2
FROM
    emissions
GROUP BY year
ORDER BY year;

-- It's growing, but the growth is not stiff, more of a little by little.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.2 Which countries contribute the most to global emissions?
SELECT 
    c.country_name,
    ROUND(SUM(e.emissions_mtco2), 2) AS total_emissions_mtco2
FROM
    emissions e
        JOIN
    countries c ON e.country_id = c.country_id
GROUP BY c.country_name
ORDER BY total_emissions_mtco2 DESC
LIMIT 10;

-- 'Brazil', 'Germany', 'Canada', 'United Kingdom' are the leading countries contributing to global emissions.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.3 How concentrated are global emissions?
WITH global_total AS (
    SELECT SUM(emissions_mtco2) AS total_emissions
    FROM emissions
)
SELECT
    c.country_name,
    ROUND(SUM(e.emissions_mtco2) * 100 / gt.total_emissions, 2) AS emission_share_pct
FROM emissions e
JOIN countries c ON e.country_id = c.country_id
CROSS JOIN global_total gt
GROUP BY c.country_name, gt.total_emissions
ORDER BY emission_share_pct DESC
LIMIT 10;

-- Like the leading carbon emission countries, the American and European continent are the leading on concentrated carbon emission.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.4 Which industries are the biggest polluters globally?
SELECT 
    i.industry_name,
    ROUND(SUM(e.emissions_mtco2), 2) AS total_emissions_mtco2
FROM
    emissions e
        JOIN
    industries i ON e.industry_id = i.industry_id
GROUP BY i.industry_name
ORDER BY total_emissions_mtco2 DESC;

-- 'Manufacturing', 'Energy Production' and 'Mining' industries are the top 3 biggest polluters globally.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.5 Which industries dominate global emissions?
WITH industry_total AS (
    SELECT SUM(emissions_mtco2) AS total_emissions
    FROM emissions
)
SELECT
    i.industry_name,
    ROUND(SUM(e.emissions_mtco2) * 100 / it.total_emissions, 2) AS emission_share_pct
FROM emissions e
JOIN industries i ON e.industry_id = i.industry_id
CROSS JOIN industry_total it
GROUP BY i.industry_name, it.total_emissions
ORDER BY emission_share_pct DESC;

-- 'Manufacturing' industries are leading in global emissions, followed by 'Energy Production' and 'Mining' industries.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.6 Which country–industry combinations are the biggest emission hotspots?
SELECT 
    c.country_name,
    i.industry_name,
    ROUND(SUM(e.emissions_mtco2), 2) AS emissions_mtco2
FROM
    emissions e
        JOIN
    countries c ON e.country_id = c.country_id
        JOIN
    industries i ON e.industry_id = i.industry_id
GROUP BY c.country_name , i.industry_name
ORDER BY emissions_mtco2 DESC
LIMIT 15;

-- 'Brazil' with 'Manufacturing', 'Transportation' and 'Agriculture' industries are the leading carbon emission.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.7 Which countries show the fastest emission growth?
SELECT
    c.country_name,
    MIN(e.year) AS start_year,
    MAX(e.year) AS end_year,
    ROUND(
        MAX(CASE WHEN e.year = max_year THEN e.emissions_mtco2 END) -
        MIN(CASE WHEN e.year = min_year THEN e.emissions_mtco2 END),
        2
    ) AS emission_growth
FROM emissions e
JOIN countries c ON e.country_id = c.country_id
JOIN (
    SELECT 
        country_id,
        MIN(year) AS min_year,
        MAX(year) AS max_year
    FROM emissions
    GROUP BY country_id
) y ON e.country_id = y.country_id
GROUP BY c.country_name, c.country_id
ORDER BY emission_growth DESC
LIMIT 10;

-- Based on emission growth, the top 3 countries are Brazil, Germany and India.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- ===============================================================================================================================================================================
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ===============================================================================================================================================================================