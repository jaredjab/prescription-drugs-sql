-- Prescription Drugs Project -- Bonus Script -- Jared Baker
SELECT * FROM prescriber;
SELECT * FROM prescription;
SELECT * FROM drug;
SELECT * FROM zip_fips;
SELECT * FROM population;
SELECT * FROM cbsa;
SELECT * FROM fips_county;
SELECT * FROM overdose_deaths;



-- Task 1
/*
How many npi numbers appear in the prescriber table but not in the prescription table?
*/
WITH lazy_npis AS (SELECT npi
                   FROM prescriber
                   EXCEPT
                   SELECT npi
                   FROM prescription)
SELECT COUNT(*) AS num_lazy_npis
FROM lazy_npis;
-- 4458



-- Task 2
/*
a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
*/
SELECT generic_name, SUM(total_claim_count) AS total_claims
FROM prescriber AS p1
    JOIN prescription AS p2 USING (npi)
    JOIN drug AS d USING (drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;
--LEVOTHYROXINE SODIUM: 406547
--LISINOPRIL: 311506
--ATORVASTATIN CALCIUM: 308523
--AMLODIPINE BESYLATE: 304343
--OMEPRAZOLE: 273570
/*
b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
*/
SELECT generic_name, SUM(total_claim_count) AS total_claims
FROM prescriber AS p1
    JOIN prescription AS p2 USING (npi)
    JOIN drug AS d USING (drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;
--ATORVASTATIN CALCIUM: 120662
--CARVEDILOL: 106812
--METOPROLOL TARTRATE: 93940
--CLOPIDOGREL BISULFATE: 87025
--AMLODIPINE BESYLATE: 86928
/*
c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
*/
WITH top_fam_drugs AS (SELECT generic_name, SUM(total_claim_count) AS total_claims
                       FROM prescriber AS p1
                           JOIN prescription AS p2 USING (npi)
                           JOIN drug AS d USING (drug_name)
                       WHERE specialty_description = 'Family Practice'
                       GROUP BY generic_name
                       ORDER BY total_claims DESC
                       LIMIT 5)
   , top_car_drugs AS (SELECT generic_name, SUM(total_claim_count) AS total_claims
                       FROM prescriber AS p1
                           JOIN prescription AS p2 USING (npi)
                           JOIN drug AS d USING (drug_name)
                       WHERE specialty_description = 'Cardiology'
                       GROUP BY generic_name
                       ORDER BY total_claims DESC
                       LIMIT 5)
SELECT generic_name FROM top_fam_drugs
INTERSECT
SELECT generic_name FROM top_car_drugs;
-- ATORVASTATIN CALCIUM, AMLODIPINE BESYLATE



-- Task 3
/*
Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.

a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
*/
SELECT npi,
    SUM(total_claim_count) AS total_claims,
    nppes_provider_city AS city
FROM prescriber AS p1
    JOIN prescription AS p2 USING (npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, city
ORDER BY total_claims DESC
LIMIT 5;
--
/*
b. Now, report the same for Memphis.
*/
SELECT npi,
    SUM(total_claim_count) AS total_claims,
    nppes_provider_city AS city
FROM prescriber AS p1
    JOIN prescription AS p2 USING (npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, city
ORDER BY total_claims DESC
LIMIT 5;
--
/*
c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
*/
WITH top_nash_npis AS (SELECT npi,
                           SUM(total_claim_count) AS total_claims,
                           nppes_provider_city AS city
                       FROM prescriber AS p1
                           JOIN prescription AS p2 USING (npi)
                       WHERE nppes_provider_city = 'NASHVILLE'
                       GROUP BY npi, city
                       ORDER BY total_claims DESC
                       LIMIT 5)
   , top_memp_npis AS (SELECT npi,
                           SUM(total_claim_count) AS total_claims,
                           nppes_provider_city AS city
                       FROM prescriber AS p1
                           JOIN prescription AS p2 USING (npi)
                       WHERE nppes_provider_city = 'MEMPHIS'
                       GROUP BY npi, city
                       ORDER BY total_claims DESC
                       LIMIT 5)
   , top_knox_npis AS (SELECT npi,
                           SUM(total_claim_count) AS total_claims,
                           nppes_provider_city AS city
                       FROM prescriber AS p1
                           JOIN prescription AS p2 USING (npi)
                       WHERE nppes_provider_city = 'KNOXVILLE'
                       GROUP BY npi, city
                       ORDER BY total_claims DESC
                       LIMIT 5)
   , top_chat_npis AS (SELECT npi,
                           SUM(total_claim_count) AS total_claims,
                           nppes_provider_city AS city
                       FROM prescriber AS p1
                           JOIN prescription AS p2 USING (npi)
                       WHERE nppes_provider_city = 'CHATTANOOGA'
                       GROUP BY npi, city
                       ORDER BY total_claims DESC
                       LIMIT 5)
SELECT * FROM top_nash_npis -- Could UNION the queries without CTEs, but I thought this was more readable.
UNION
SELECT * FROM top_memp_npis
UNION
SELECT * FROM top_knox_npis
UNION
SELECT * FROM top_chat_npiS
ORDER BY total_claims DESC;
--



-- Task 4
/*
Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
*/
WITH avg_ods_per_county AS (SELECT fipscounty, AVG(overdose_deaths) AS avg_ods
                            FROM overdose_deaths
                            GROUP BY fipscounty)
SELECT county, ROUND(avg_ods, 2) AS avg_ods
FROM avg_ods_per_county AS a
    JOIN fips_county AS f ON a.fipscounty = f.fipscounty::integer
WHERE avg_ods > (SELECT AVG(overdose_deaths)
                 FROM overdose_deaths)
ORDER BY avg_ods DESC;
--



-- Task 5
/*
a. Write a query that finds the total population of Tennessee.
*/
SELECT SUM(population) AS total_TN_pop
FROM population AS p
    JOIN fips_county AS f USING (fipscounty)
WHERE state = 'TN';
-- 6,597,381
/*
b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
*/
SELECT county, population, 
    CONCAT(ROUND((population / (SELECT SUM(population) AS total_TN_pop
                         FROM population AS p
                            JOIN fips_county AS f USING (fipscounty)
                         WHERE state = 'TN')) * 100, 2), '%') AS pop_TN_percent
FROM population AS p
    JOIN fips_county AS f USING (fipscounty)
WHERE state = 'TN'
ORDER BY population DESC;
--