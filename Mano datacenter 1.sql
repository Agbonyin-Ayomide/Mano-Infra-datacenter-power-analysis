USE manodatacenter;
#Monthly PUE Summary
select
month,
count(*) as hours_recorded,
round(avg(pue), 3) as avg_pue,
ROUND(MIN(pue), 3) AS best_pue,
    ROUND(MAX(pue), 3) AS worst_pue,
    ROUND(AVG(it_load_kw), 1) AS avg_it_load_kw,
    ROUND(AVG(cooling_power_kw), 1) AS avg_cooling_kw,
    ROUND(SUM(total_facility_power_kw)/1000, 1) AS total_facility_mwh,
    ROUND(AVG(dcie_pct), 2) AS avg_efficiency_pct
FROM datacenter_power_data
GROUP BY month
ORDER BY month;

#ANOMALY DETECTION — Hours where PUE > 1.8 (inefficiency threshold)
SELECT
    timestamp,
    it_load_kw,
    total_facility_power_kw,
    pue,
    outside_temp_c,
    cooling_power_kw,
    is_anomaly
FROM datacenter_power_data
WHERE pue > 1.8
ORDER BY pue DESC
LIMIT 20;

#
#COOLING EFFICIENCY BY OUTSIDE TEMPERATURE
-- Shows relationship between weather and cooling cost
SELECT
    CASE
        WHEN outside_temp_c < 5  THEN '< 5°C (Cold)'
        WHEN outside_temp_c < 15 THEN '5-15°C (Mild)'
        WHEN outside_temp_c < 25 THEN '15-25°C (Warm)'
        ELSE '> 25°C (Hot)'
    END AS temp_band,
    COUNT(*) AS hours,
    ROUND(AVG(pue), 3) AS avg_pue,
    ROUND(AVG(cooling_power_kw), 1) AS avg_cooling_kw,
    ROUND(AVG(cooling_power_kw / it_load_kw), 3) AS cooling_ratio
FROM datacenter_power_data
GROUP BY temp_band
ORDER BY avg_pue;

#PEAK LOAD HOURS — Identify when IT load is highest (capacity planning)
SELECT
    hour,
    ROUND(AVG(it_load_kw), 1) AS avg_it_load_kw,
    ROUND(MAX(it_load_kw), 1) AS peak_it_load_kw,
    ROUND(AVG(pue), 3) AS avg_pue
FROM datacenter_power_data
GROUP BY hour
ORDER BY avg_it_load_kw DESC;

#WEEKDAY vs WEEKEND COMPARISON
SELECT
    CASE WHEN is_weekday = 1 THEN 'Weekday' ELSE 'Weekend' END AS day_type,
    ROUND(AVG(it_load_kw), 1) AS avg_it_load_kw,
    ROUND(AVG(pue), 3) AS avg_pue,
    ROUND(AVG(water_usage_litres), 1) AS avg_water_usage_L,
    ROUND(AVG(wue), 4) AS avg_wue
FROM datacenter_power_data
GROUP BY is_weekday;

#MONTHLY WATER USAGE (WUE tracking)
SELECT
    month,
    ROUND(AVG(wue), 4) AS avg_wue,
    ROUND(SUM(water_usage_litres)/1000, 1) AS total_water_kl,
    ROUND(AVG(outside_temp_c), 1) AS avg_outside_temp_c
FROM datacenter_power_data
GROUP BY month
ORDER BY month;

#COST ESTIMATION (assuming $0.07/kWh)
SELECT
    month,
    ROUND(SUM(total_facility_power_kw) * 0.07, 2) AS estimated_cost_usd,
    ROUND(SUM(it_load_kw) * 0.07, 2) AS it_only_cost_usd,
    ROUND((SUM(total_facility_power_kw) - SUM(it_load_kw)) * 0.07, 2) AS overhead_cost_usd
FROM datacenter_power_data
GROUP BY month
ORDER BY month;
