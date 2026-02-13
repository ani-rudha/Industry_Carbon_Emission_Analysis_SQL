-- ===============================================================================================================================================================================
--                                         -: Step 3. Country-Level Emission & Efficiency Comparison :-
-- ===============================================================================================================================================================================
-- 3.1 Which countries contribute the most to total carbon emissions?
SELECT 
    c.country_name,
    ROUND(SUM(e.emissions_mtco2), 2) AS total_emissions_mtco2
FROM
    emissions e
        JOIN
    countries c ON e.country_id = c.country_id
GROUP BY c.country_name
ORDER BY total_emissions_mtco2 DESC;

-- 'Brazil', 'Germany', 'Canada', 'United Kingdom' are the leading countries contributing to global emissions.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.2 How much economic output does each country generate?
SELECT 
    c.country_name,
    ROUND(SUM(g.gdp_usd_bn), 2) AS total_gdp_usd_bn
FROM
    industry_gdp g
        JOIN
    countries c ON g.country_id = c.country_id
GROUP BY c.country_name
ORDER BY total_gdp_usd_bn DESC;

-- 'Brazil', 'Germany', 'Canada', 'United Kingdom' and 'China' are in the top 5.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.3 Which countries emit the most carbon per unit of economic output?
SELECT 
    c.country_name,
    ROUND(SUM(e.emissions_mtco2) / NULLIF(SUM(g.gdp_usd_bn), 0),
            4) AS emissions_per_gdp_unit
FROM
    emissions e
        JOIN
    industry_gdp g ON e.country_id = g.country_id
        AND e.industry_id = g.industry_id
        AND e.year = g.year
        JOIN
    countries c ON e.country_id = c.country_id
GROUP BY c.country_name
ORDER BY emissions_per_gdp_unit DESC;

-- Countries like 'South Africa', 'United Kingdom', 'Australia', 'India' are carbon-inefficient economies; on the other hand, 
-- countries like 'Japan' and 'United States' are cleaner growth models.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.4 Are countries becoming more or less carbon-efficient over time?
SELECT 
    e.year,
    c.country_name,
    ROUND(SUM(e.emissions_mtco2) / NULLIF(SUM(g.gdp_usd_bn), 0),
            4) AS emissions_per_gdp_unit
FROM
    emissions e
        JOIN
    industry_gdp g ON e.country_id = g.country_id
        AND e.industry_id = g.industry_id
        AND e.year = g.year
        JOIN
    countries c ON e.country_id = c.country_id
GROUP BY e.year , c.country_name
ORDER BY c.country_name , e.year;

-- This reveals 'Policy Impact' and shows 'Green Transition Progress or Regression'
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.5 Which countries combine high emissions with poor efficiency?
SELECT 
    c.country_name,
    ROUND(SUM(e.emissions_mtco2), 2) AS total_emissions,
    ROUND(SUM(e.emissions_mtco2) / NULLIF(SUM(g.gdp_usd_bn), 0),
            4) AS emissions_per_gdp_unit
FROM
    emissions e
        JOIN
    industry_gdp g ON e.country_id = g.country_id
        AND e.industry_id = g.industry_id
        AND e.year = g.year
        JOIN
    countries c ON e.country_id = c.country_id
GROUP BY c.country_name
HAVING total_emissions > (SELECT 
        AVG(country_emissions)
    FROM
        (SELECT 
            SUM(emissions_mtco2) AS country_emissions
        FROM
            emissions
        GROUP BY country_id) t)
ORDER BY emissions_per_gdp_unit DESC;

-- 'United Kingdom' and 'China' are two countries combine high emissions with poor efficiency.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 3.6 How can we classify countries by carbon risk level?
SELECT 
    c.country_name,
    ROUND(AVG(e.emissions_mtco2 / g.gdp_usd_bn), 4) AS avg_emission_intensity,
    CASE
        WHEN AVG(e.emissions_mtco2 / g.gdp_usd_bn) > 0.8 THEN 'High Risk'
        WHEN AVG(e.emissions_mtco2 / g.gdp_usd_bn) BETWEEN 0.4 AND 0.8 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS carbon_risk_category
FROM
    emissions e
        JOIN
    industry_gdp g ON e.country_id = g.country_id
        AND e.industry_id = g.industry_id
        AND e.year = g.year
        JOIN
    countries c ON e.country_id = c.country_id
GROUP BY c.country_name
ORDER BY avg_emission_intensity DESC;

-- Almost all listed countries are in the 'Medium Risk' zone.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- ===============================================================================================================================================================================
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ===============================================================================================================================================================================