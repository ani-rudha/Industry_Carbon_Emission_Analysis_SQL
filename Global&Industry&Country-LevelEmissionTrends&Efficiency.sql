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
--                                          -: Step 2. Industry-Level Emission Trends & Efficiency :-
-- ===============================================================================================================================================================================

## To measure emission efficiency, we need to understand how much economic output each industry generates relative to emissions.

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Table Design :-  'industry_gdp'
CREATE TABLE industry_gdp (
    gdp_id INT AUTO_INCREMENT PRIMARY KEY,
    country_id INT NOT NULL,
    industry_id INT NOT NULL,
    year INT NOT NULL,
    gdp_usd_bn DECIMAL(12,2) NOT NULL,

    CONSTRAINT fk_gdp_country
        FOREIGN KEY (country_id) REFERENCES countries(country_id),

    CONSTRAINT fk_gdp_industry
        FOREIGN KEY (industry_id) REFERENCES industries(industry_id),

    CONSTRAINT uq_country_industry_year
        UNIQUE (country_id, industry_id, year)
);
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

## Populate 'industry_gdp' = GDP increases slowly year-over-year + 
-- 			                 Heavy industries generate higher GDP + 
--                           Service industries generate moderate GDP

-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO industry_gdp (country_id, industry_id, year, gdp_usd_bn)
SELECT
    e.country_id,
    e.industry_id,
    e.year,
    ROUND(
        SUM(e.emissions_mtco2) * 
        (CASE
            WHEN e.industry_id IN (1,2) THEN 3.5                      # Energy, Manufacturing
            WHEN e.industry_id IN (3,4) THEN 2.2                      # Transport, Construction
            ELSE 1.5                                                  # Services, Agriculture
        END),
        2
    ) AS gdp_usd_bn
FROM emissions e
GROUP BY e.country_id, e.industry_id, e.year;
-- -- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.1 Which industries emit the most carbon per unit of economic output?
SELECT 
    i.industry_name,
    ROUND(SUM(e.emissions_mtco2) / NULLIF(SUM(g.gdp_usd_bn), 0),
            4) AS emissions_per_gdp_unit
FROM
    emissions e
        JOIN
    industry_gdp g ON e.country_id = g.country_id
        AND e.industry_id = g.industry_id
        AND e.year = g.year
        JOIN
    industries i ON e.industry_id = i.industry_id
GROUP BY i.industry_name
ORDER BY emissions_per_gdp_unit DESC;


--  Industries like 'Construction' and 'Mining' followed by 'Agriculture' and 'Transportation' emit the most carbon per unit of economic output.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.2 Are industries becoming more carbon-efficient over time?
SELECT 
    e.year,
    i.industry_name,
    ROUND(SUM(e.emissions_mtco2) / NULLIF(SUM(g.gdp_usd_bn), 0),
            5) AS emissions_per_gdp_unit
FROM
    emissions e
        JOIN
    industry_gdp g ON e.country_id = g.country_id
        AND e.industry_id = g.industry_id
        AND e.year = g.year
        JOIN
    industries i ON e.industry_id = i.industry_id
GROUP BY e.year , i.industry_name
ORDER BY i.industry_name , e.year;

-- Unfortunately NO, the rate of carbon emission is almost the same over time with no improvement.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.3 Which industries improved efficiency the most?
SELECT 
    i.industry_name,
    ROUND(MAX(e.emissions_mtco2 / g.gdp_usd_bn) - MIN(e.emissions_mtco2 / g.gdp_usd_bn),
            4) AS efficiency_change
FROM
    emissions e
        JOIN
    industry_gdp g ON e.country_id = g.country_id
        AND e.industry_id = g.industry_id
        AND e.year = g.year
        JOIN
    industries i ON e.industry_id = i.industry_id
GROUP BY i.industry_name
ORDER BY efficiency_change DESC;

-- 'Construction' and 'Mining' are the two industries that improved efficiency the most.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.4 Which industries are high-risk from a carbon regulation standpoint?
SELECT 
    i.industry_name,
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
    industries i ON e.industry_id = i.industry_id
GROUP BY i.industry_name
ORDER BY avg_emission_intensity DESC;

-- No such industries, but 'Construction', 'Mining', 'Agriculture' and 'Transportation' are in 'Medium Risk' zone.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.5 Which industries are relatively cleaner or dirtier?
WITH efficiency AS (
    SELECT
        i.industry_name,
        SUM(e.emissions_mtco2) / NULLIF(SUM(g.gdp_usd_bn), 0) AS emission_intensity
    FROM emissions e
    JOIN industry_gdp g
        ON e.country_id = g.country_id
       AND e.industry_id = g.industry_id
       AND e.year = g.year
    JOIN industries i ON e.industry_id = i.industry_id
    GROUP BY i.industry_name
)
SELECT
    industry_name,
    ROUND(emission_intensity, 4) AS emission_intensity,
    CASE
        WHEN emission_intensity > 0.8 THEN 'High Emission Intensity'
        WHEN emission_intensity BETWEEN 0.4 AND 0.8 THEN 'Medium Emission Intensity'
        ELSE 'Low Emission Intensity'
    END AS emission_category
FROM efficiency
ORDER BY emission_intensity DESC;

-- 'Construction', 'Mining', 'Agriculture' and 'Transportation' are in 'Medium Emission Intensity'.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.6 Which industries show unstable emission patterns over time?
SELECT 
    i.industry_name,
    ROUND(STDDEV(e.emissions_mtco2), 2) AS emission_volatility
FROM
    emissions e
        JOIN
    industries i ON e.industry_id = i.industry_id
GROUP BY i.industry_name
ORDER BY emission_volatility DESC;

-- Industries like 'Construction' and 'Mining' are showing unstable emission patterns over time.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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