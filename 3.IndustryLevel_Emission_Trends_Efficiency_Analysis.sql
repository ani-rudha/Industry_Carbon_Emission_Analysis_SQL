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
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ===============================================================================================================================================================================