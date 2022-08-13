-- Medicare Prescriptions Data In this exercise, you will be working with a database created from the 2017 Medicare Part D Prescriber Public Use File, available at https://data.cms.gov/provider-summary-by-type-of-service/medicare-part-d-prescribers/medicare-part-d-prescribers-by-provider-and-drug.

--1) a. Which prescriber had the highest total number of claims (totaled over all drugs)?Report the npi and the total number of claims.
--1881634483 @ 99707 total claims
SELECT npi, SUM(total_claim_count) AS Total_Claims
FROM prescription
GROUP BY npi
ORDER BY Total_Claims DESC;
-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
--DAVID COFFEY Family Practice 4538 claims
SELECT prescription.npi, SUM(total_claim_count) AS Total_Claims, prescriber.nppes_provider_first_name AS first_name, prescriber.nppes_provider_last_org_name AS last_name, prescriber.specialty_description
FROM prescription
INNER JOIN prescriber
ON prescription.npi = prescriber.npi
GROUP BY prescription.npi, total_claim_count, prescriber.nppes_provider_first_name, prescriber.nppes_provider_last_org_name, prescriber.specialty_description
ORDER BY Total_Claims DESC;


--2) a. Which specialty had the most total number of claims (totaled over all drugs)? Family Practice (9752347)
SELECT DISTINCT prescriber.specialty_description, SUM(total_claim_count) AS Total_Claims
FROM prescription
INNER JOIN prescriber
ON prescription.npi = prescriber.npi
GROUP BY prescriber.specialty_description
ORDER BY Total_Claims DESC;
 
-- b. Which specialty had the most total number of claims for opioids? Nurse Practioner
SELECT DISTINCT prescriber.specialty_description, SUM(total_claim_count) AS Total_Claims
FROM prescription
LEFT JOIN prescriber
ON prescription.npi = prescriber.npi
LEFT JOIN drug 
ON prescription.drug_name = drug.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description
ORDER BY Total_Claims DESC;
-- c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT DISTINCT prescriber.specialty_description
FROM prescription
LEFT JOIN prescriber
ON prescription.npi = prescriber.npi
WHERE prescription.npi IS NULL
GROUP BY prescriber.specialty_description;

-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

--3) a. Which drug (generic_name) had the highest total drug cost?
--Pirfednidone 
SELECT prescription.drug_name, total_drug_cost, drug.generic_name
FROM prescription
LEFT JOIN drug
ON prescription.drug_name = drug.drug_name
GROUP by prescription.drug_name, total_drug_cost, drug.generic_name
ORDER by total_drug_cost DESC;

-- b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
--IMMUN GLOB G(IGG)/GLY/IGA OV50
SELECT d.generic_name AS name, ROUND(p.total_drug_cost/p.total_day_supply, 2) AS cost_per_day
FROM drug as d
INNER JOIN prescription AS p
ON d.drug_name = p.drug_name
ORDER BY cost_per_day DESC;

--4) a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name AS name, 
    CASE WHEN opioid_drug_flag = 'Y' THEN 'Opioid'
        WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither' END drug_type
FROM drug;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision. Opioids
SELECT SUM(p.total_drug_cost) AS money, 
    CASE WHEN opioid_drug_flag = 'Y' THEN 'Opioid'
        WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither' END drug_type
FROM drug AS d
INNER JOIN prescription as p
ON d.drug_name = p.drug_name
GROUP BY drug_type
ORDER BY money;


--5) a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee. 33
SELECT COUNT(cbsaname)
FROM cbsa
WHERE cbsaname LIKE '%TN';

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population. Largest = Nashville-Davidson-Murfreesboro-Franklin, TN Smallest = Morristown, TN
SELECT c.cbsaname AS county, SUM(p.population) AS total_pop
FROM cbsa AS c
LEFT JOIN population AS p
ON c.fipscounty = p.fipscounty
WHERE p.population IS NOT NULL
GROUP BY county
ORDER BY total_pop DESC;

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population. SEVIER county, 95523
SELECT f.county, p.population
FROM population AS p
LEFT JOIN fips_county AS f
ON p.fipscounty = f.fipscounty
LEFT JOIN cbsa AS c
ON p.fipscounty = c.fipscounty
WHERE c.fipscounty IS NULL
ORDER BY p.population DESC;


--6) a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name AS name, total_claim_count
FROM prescription
WHERE total_claim_count >=3000;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT p.drug_name AS name, p.total_claim_count,
CASE WHEN d.opioid_drug_flag = 'Y' THEN 'True'
    ELSE 'False' END opioid
FROM prescription AS p
INNER JOIN drug as d
ON p.drug_name = d.drug_name
WHERE total_claim_count >=3000;

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT p2.nppes_provider_first_name AS provider_first_name, p2.nppes_provider_last_org_name AS last_name, p1.drug_name, p1.total_claim_count,
CASE WHEN d.opioid_drug_flag = 'Y' THEN 'True'
    ELSE 'False' END opioid
FROM prescription AS p1
INNER JOIN drug as d
ON p1.drug_name = d.drug_name
INNER JOIN prescriber AS p2
ON p1.npi = p2.npi
WHERE total_claim_count >=3000;


--7) The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT p.npi, d.drug_name
FROM prescriber AS p
CROSS JOIN drug as d
WHERE p.specialty_description = 'Pain Management'
    AND p.nppes_provider_city = 'Nashville'
    AND d.opioid_drug_flag = 'Y';

-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
























