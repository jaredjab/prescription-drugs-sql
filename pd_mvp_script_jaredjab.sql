-- Prescription Drugs Project -- MVP Script -- Jared Baker
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
a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
*/
SELECT npi,
    SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 1;
-- npi: 1881634483, 99707 claims
/*
b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
*/
SELECT nppes_provider_last_org_name AS npi_last_org,
    nppes_provider_first_name AS npi_first,
    specialty_description AS specialty,
    SUM(total_claim_count) AS total_claims
FROM prescription AS p1
    JOIN prescriber AS p2 USING (npi)
GROUP BY npi_last_org, npi_first, specialty
ORDER BY total_claims DESC
LIMIT 1;
-- PENDLEY, BRUCE. Family Practice. 99707



-- Task 2
/*
a. Which specialty had the most total number of claims (totaled over all drugs)?
*/
SELECT specialty_description AS specialty,
    SUM(total_claim_count) AS total_claims
FROM prescription AS p1
    JOIN prescriber AS p2 USING (npi)
GROUP BY specialty
ORDER BY total_claims DESC
LIMIT 1;
-- Family Practice: 9,752,347
/*
b. Which specialty had the most total number of claims for opioids?
*/
SELECT specialty_description AS specialty,
    SUM(total_claim_count) AS total_claims
FROM prescription AS p1
    JOIN prescriber AS p2 USING (npi)
    JOIN drug AS d USING (drug_name)
WHERE d.opioid_drug_flag = 'Y'
GROUP BY specialty
ORDER BY total_claims DESC
LIMIT 1;
-- Nurse Practitioner: 900,845
/*
c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
*/
SELECT specialty_description AS specialty,
    SUM(total_claim_count) AS total_claims
FROM prescriber AS p1
    LEFT JOIN prescription AS p2 USING (npi)
GROUP BY specialty
ORDER BY total_claims NULLS FIRST;
-- Yes, 15 specialties.
/*
d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
*/
WITH spec_total_claims AS (SELECT specialty_description AS specialty,
                               COALESCE(SUM(total_claim_count), 0) AS total_claims
                           FROM prescriber AS p1
                               LEFT JOIN prescription AS p2 USING (npi)
                             --LEFT JOIN drug AS d USING (drug_name)
                           GROUP BY specialty
                           ORDER BY specialty)

  , spec_opioid_claims AS (SELECT specialty_description AS specialty,
                               SUM(total_claim_count) AS total_opioid_claims
                           FROM prescriber AS p1
                               LEFT JOIN prescription AS p2 USING (npi)
                               LEFT JOIN drug AS d USING (drug_name)
                           WHERE opioid_drug_flag = 'Y'
                           GROUP BY specialty)
SELECT specialty, 
    ROUND(COALESCE((total_opioid_claims / total_claims), 0), 2) AS opioid_claim_percentage
FROM spec_total_claims AS t
    LEFT JOIN spec_opioid_claims AS o USING (specialty)
ORDER BY opioid_claim_percentage DESC;
-- Case Manager / Care Coordinator: 72%
-- Orthopaedic Surgery: 69%
-- Interventional Pain Management: 61%



-- Task 3
/*
a. Which drug (generic_name) had the highest total drug cost?
*/
SELECT generic_name, SUM(total_drug_cost) AS total_cost
FROM prescription AS p
    JOIN drug AS d USING (drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC
LIMIT 1;
-- INSULIN: $104,264,066.35
/*
b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
*/
SELECT generic_name,
    ROUND((SUM(total_drug_cost) / SUM(total_day_supply)), 2) AS cost_per_day
FROM prescription AS p
    JOIN drug AS d USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC
LIMIT 1;
-- C1 ESTERASE INHIBITOR: $3495.22



-- Task 4
/*
a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
*/
SELECT drug_name,
    CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
         WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
         ELSE 'neither'
    END AS drug_type
FROM drug;
--
/*
b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
*/
SELECT drug_type, SUM(total_drug_cost::money) AS total_cost
FROM prescription AS p
    JOIN (SELECT drug_name,
            CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
                 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
                 ELSE 'neither'
            END AS drug_type
          FROM drug) AS d USING (drug_name)
WHERE drug_type != 'neither'
GROUP BY drug_type
ORDER BY total_cost DESC;
-- Opioids had a greater spend ($105,080,626.37)



-- Task 5
/*
a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
*/
SELECT COUNT(cbsa) AS total_TN_cbsa
FROM cbsa
WHERE cbsaname LIKE '%, TN';
-- 33
/*
b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
*/
SELECT cbsaname, SUM(population) AS total_pop
FROM cbsa AS c
    FULL JOIN fips_county AS f USING (fipscounty)
    FULL JOIN population AS p USING (fipscounty)
WHERE population IS NOT NULL
GROUP BY cbsaname
ORDER BY total_pop DESC;
-- Nashville-Davidson-Murfreesboro-Franklin, TN: 1,830,410 | Morristown, TN: 116,352
/*
c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
*/
SELECT county as non_cbsa_county, SUM(population) AS total_pop
FROM cbsa AS c
    FULL JOIN fips_county AS f USING (fipscounty)
    FULL JOIN population AS p USING (fipscounty)
WHERE cbsa IS NULL
GROUP BY county
ORDER BY total_pop DESC NULLS LAST
LIMIT 1;
-- SEVIER 95,523



-- Task 6
/*
a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
*/
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;
-- 9 drugs
/*
b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
*/
SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription AS p
    JOIN drug AS d USING (drug_name)
WHERE total_claim_count >= 3000;
-- 2 Y's
/*
c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
*/
SELECT drug_name,
    total_claim_count,
    opioid_drug_flag,
    nppes_provider_first_name AS prescriber_first_name,
    nppes_provider_last_org_name AS prescriber_last_org
FROM prescription AS p1
    JOIN drug AS d USING (drug_name)
    JOIN prescriber AS p2 USING (npi)
WHERE total_claim_count >= 3000;
--



-- Task 7
/*
The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opioid_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
*/
SELECT npi, drug_name
FROM prescriber AS p
   CROSS JOIN drug AS d
WHERE specialty_description = 'Pain Management'
    AND nppes_provider_city = 'NASHVILLE'
    AND opioid_drug_flag = 'Y';
--
/*
b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
*/
-- combos = table of all Nashville Pain Management NPI & Opioid prescrition combos
WITH combos AS (SELECT npi, drug_name
                FROM prescriber AS p
                    CROSS JOIN drug AS d
                WHERE specialty_description = 'Pain Management'
                    AND nppes_provider_city = 'NASHVILLE'
                    AND opioid_drug_flag = 'Y')
SELECT npi, drug_name, total_claim_count
FROM combos AS c
    LEFT JOIN prescription AS p USING (npi, drug_name)
ORDER BY npi, drug_name;
--
/*
c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
*/
WITH combos AS (SELECT npi, drug_name
                FROM prescriber AS p
                    CROSS JOIN drug AS d
                WHERE specialty_description = 'Pain Management'
                    AND nppes_provider_city = 'NASHVILLE'
                    AND opioid_drug_flag = 'Y')
SELECT npi, drug_name, COALESCE(total_claim_count, 0) AS total_claim_count
FROM combos AS c
    LEFT JOIN prescription AS p USING (npi, drug_name)
ORDER BY npi, drug_name;
--