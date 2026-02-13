-- ===============================================================================================================================================================================
--                                            -: Step 4. Industry–Country Risk Hotspots :-
-- ===============================================================================================================================================================================
-- 4.1 Which industry–country pairs contribute the most to global emissions?
SELECT
    c.country_name,
    i.industry_name,
    ROUND(SUM(e.emissions_mtco2), 2) AS total_emissions_mtco2
FROM emissions e
JOIN countries c ON e.country_id = c.country_id
JOIN industries i ON e.industry_id = i.industry_id
GROUP BY c.country_name, i.industry_name
ORDER BY total_emissions_mtco2 DESC
LIMIT 10;

-- 'Brazil' with 'Manufacturing', 'Transportation' and 'Agriculture' industries are the leading carbon emission.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4.2 Which industry–country combinations are the least carbon-efficient?
SELECT 
    c.country_name,
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
    countries c ON e.country_id = c.country_id
        JOIN
    industries i ON e.industry_id = i.industry_id
GROUP BY c.country_name , i.industry_name
ORDER BY emissions_per_gdp_unit DESC
LIMIT 10;

-- 'United Kingdom', 'South Africa' and 'Canada' with 'Construction'; and 'China' and 'United States' with 'Mining' combinations
-- are the least carbon-efficient.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4.3 Which industries dominate a country’s total emissions?
SELECT
    c.country_name,
    i.industry_name,
    ROUND(
        SUM(e.emissions_mtco2) /
        SUM(SUM(e.emissions_mtco2)) OVER (PARTITION BY c.country_name) * 100,
        2
    ) AS emission_share_percent
FROM emissions e
JOIN countries c ON e.country_id = c.country_id
JOIN industries i ON e.industry_id = i.industry_id
GROUP BY c.country_name, i.industry_name
ORDER BY c.country_name, emission_share_percent DESC;

-- The combinations are 'India'&'Australia' - 'Mining', 'Brazil' - 'Manufacturing', 'Canada' - 'Agriculture', 
-- 'South Africa'&'China'&'United Kingdom' - 'Construction', 'Japan'&'Germany'&'United Kingdom' - 'Energy Production'.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4.4 Can we classify industry–country pairs into risk levels?
SELECT
    c.country_name,
    i.industry_name,
    ROUND(
        SUM(e.emissions_mtco2) / NULLIF(SUM(g.gdp_usd_bn), 0),
        4
    ) AS emission_intensity,
    CASE
        WHEN SUM(e.emissions_mtco2) / NULLIF(SUM(g.gdp_usd_bn), 0) > 1 THEN 'High Risk'
        WHEN SUM(e.emissions_mtco2) / NULLIF(SUM(g.gdp_usd_bn), 0) BETWEEN 0.5 AND 1 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM emissions e
JOIN industry_gdp g
    ON e.country_id = g.country_id
   AND e.industry_id = g.industry_id
   AND e.year = g.year
JOIN countries c ON e.country_id = c.country_id
JOIN industries i ON e.industry_id = i.industry_id
GROUP BY c.country_name, i.industry_name
ORDER BY emission_intensity DESC;

-- Top 2 combinations are 'United Kingdom':'Construction' = 'Medium Risk' and 'South Africa':'Mining' = 'Medium Risk'.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4.5 Which industry–country combinations remain high risk year after year?
SELECT
    c.country_name,
    i.industry_name,
    COUNT(DISTINCT e.year) AS high_risk_years
FROM emissions e
JOIN industry_gdp g
    ON e.country_id = g.country_id
   AND e.industry_id = g.industry_id
   AND e.year = g.year
JOIN countries c ON e.country_id = c.country_id
JOIN industries i ON e.industry_id = i.industry_id
WHERE (e.emissions_mtco2 / g.gdp_usd_bn) > 1
GROUP BY c.country_name, i.industry_name
HAVING high_risk_years >= 3
ORDER BY high_risk_years DESC;

-- No such combinations found.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 4.6 Give me a quick summary of hotspot risk exposure.
SELECT 
    risk_category, COUNT(*) AS industry_country_pairs
FROM
    (SELECT 
        c.country_name,
            i.industry_name,
            CASE
                WHEN SUM(e.emissions_mtco2) / NULLIF(SUM(g.gdp_usd_bn), 0) > 1 THEN 'High Risk'
                WHEN SUM(e.emissions_mtco2) / NULLIF(SUM(g.gdp_usd_bn), 0) BETWEEN 0.5 AND 1 THEN 'Medium Risk'
                ELSE 'Low Risk'
            END AS risk_category
    FROM
        emissions e
    JOIN industry_gdp g ON e.country_id = g.country_id
        AND e.industry_id = g.industry_id
        AND e.year = g.year
    JOIN countries c ON e.country_id = c.country_id
    JOIN industries i ON e.industry_id = i.industry_id
    GROUP BY c.country_name , i.industry_name) t
GROUP BY risk_category;

-- For 'Low Risk' category there are total 40 Industry-Country pairs and for 'Low Risk' category there are total 20 Industry-Country pairs.
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- ================================================================================================================================================================================
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ================================================================================================================================================================================