# 🌍 Industry Carbon Emission Analysis (SQL | MySQL)

## 📌 Project Overview
This project analyzes global carbon emissions across industries and countries to evaluate environmental efficiency and economic decoupling using SQL.

---

## 🎯 Business Objectives
- Identify major emission contributors
- Measure emission efficiency using GDP-adjusted metrics
- Detect persistent industry inefficiencies
- Highlight country–industry risk hotspots
- Support sustainability-focused decision-making

---

The analysis is based on the following tables:

- **countries**: country_id, country_name, region, income_group
- **emissions**: emission_id, country_id, industry_id, year, emissions_mtco2
- **energy_sources**: energy_id, country_id, year, energy_type, share_percentage  
- **industries**: industry_id, industry_name, sector_type  

> Note: `industry_gdp` was created as a derived metric using `emissions` to standardize GDP vs Carbon Emissions calculations across analyses.

---

## 🔄 Analysis Workflow
1. Data Understanding & Sanity Checks
2. Global Emission Overview
3. Industry-Level Emission Trends & Efficiency
4. Country-Level Efficiency Comparison
5. Industry–Country Risk Hotspots
6. Advanced Decoupling Analysis

----

## 🔍 Key Insights
- Emissions are concentrated in a small number of industries
- Heavy industries remain structurally inefficient
- Relative benchmarks outperform absolute thresholds
- Persistent inefficiencies indicate weak decoupling
- Certain regions face elevated climate risk

---

## 💡 Business Recommendations
- Implement intensity-based emission targets
- Prioritize clean technology in inefficient industries
- Monitor multi-year emission persistence
- Develop industry-specific decarbonization strategies

---

## 🧠 SQL Concepts Used
- JOINs
- Aggregations
- Subqueries
- Window Functions
- CASE statements
- Time-series analysis

---

## 🛠️ Tools Used
- MySQL
- SQL
- Python
- GitHub

---

⭐ *If you found this project insightful, feel free to star the repository!*
