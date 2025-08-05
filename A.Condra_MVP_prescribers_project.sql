-- For this exericse, you'll be working with a database derived from the Medicare Part D Prescriber Public Use File. More information about the 
-- data is contained in the Methodology PDF file. See also the included entity-relationship diagram.


-- 1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
		-- npi: 1912011792

SELECT
	npi,
	total_claim_count
FROM
	prescriber
INNER JOIN
	prescription
USING
	(npi)
ORDER BY
	total_claim_count DESC
LIMIT
	1;

	-- b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total 
	-- number of claims.
			-- "DAVID"	"COFFEY"	"Family Practice"	4538

SELECT
	nppes_provider_first_name, 
	nppes_provider_last_org_name, 
	specialty_description,
	total_claim_count
FROM
	prescriber
INNER JOIN
	prescription
USING
	(npi)
ORDER BY
	total_claim_count DESC
LIMIT
	1;



-- 2. a. Which specialty had the most total number of claims (totaled over all drugs)?
	--"Family Practice"	9752347

SELECT
	specialty_description,
	SUM(total_claim_count) AS total_num_claims
FROM
	prescriber
INNER JOIN
	prescription
USING
	(npi)
GROUP BY
	specialty_description
ORDER BY
	total_num_claims DESC
LIMIT
	1;

	-- b. Which specialty had the most total number of claims for opioids?
		-- "Nurse Practitioner"	900845

SELECT
	specialty_description,
	SUM(total_claim_count) AS total_num_claims
FROM
	prescriber
INNER JOIN
	prescription
USING
	(npi)
INNER JOIN
	drug
USING
	(drug_name)
WHERE
	opioid_drug_flag ILIKE 'Y'
GROUP BY
	specialty_description
ORDER BY
	total_num_claims DESC
LIMIT
	1;

	-- c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the 
	-- prescription table?

--maybe Except??
SELECT
	npi
FROM
	prescriber
EXCEPT
SELECT
	npi
FROM
	prescription; --4458 rows

--maybe Semijoin??

SELECT
	DISTINCT(specialty_description),
	COUNT(npi)
FROM 
	prescriber
WHERE
	npi IN
	(SELECT
		npi
	FROM
		prescription)
GROUP BY
	specialty_description
ORDER BY
	COUNT(npi); --92 rows

--maybe Antijoin?? -----never finished querying....after 18 mins

SELECT
	DISTINCT(specialty_description),
	COUNT(npi)
FROM 
	prescriber
WHERE
	npi NOT IN
	(SELECT
		npi
	FROM
		prescription)
GROUP BY
	specialty_description;

	
	-- d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by 
	-- that specialty which are for opioids. Which specialties have a high percentage of opioids?

WITH total_claims AS
(SELECT
	specialty_description,
	SUM(CASE WHEN opioid_drug_flag ILIKE 'Y' THEN total_claim_count END) AS total_opioid_claims,
	SUM(total_claim_count) AS total_num_claims
FROM
	prescriber
INNER JOIN
	prescription
USING
	(npi)
INNER JOIN
	drug
USING
	(drug_name)
GROUP BY
	specialty_description)
SELECT
	specialty_description,
	ROUND(((total_opioid_claims/total_num_claims)*100),2)
FROM
	total_claims
ORDER BY
	specialty_description;

-- 3. a. Which drug (generic_name) had the highest total drug cost?
	--"PIRFENIDONE"	2829174.3

SELECT
	generic_name,
	total_drug_cost
FROM
	drug
INNER JOIN
	prescription
USING
	(drug_name)
ORDER BY
	total_drug_cost DESC
LIMIT
	1;
	
	-- b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND 
	-- to see how this works.
		--"INSULIN GLARGINE,HUM.REC.ANLOG"	3475468.88

SELECT
	generic_name,
	ROUND(SUM(total_drug_cost / 30), 2) AS cost_per_day
FROM
	drug
INNER JOIN
	prescription
USING
	(drug_name)
GROUP BY
	generic_name
ORDER BY
	cost_per_day DESC
LIMIT 1;

-- 4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have 
-- opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 
	-- Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT
	drug_name,
	CASE
		WHEN opioid_drug_flag ILIKE 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag ILIKE 'Y' THEN 'antibiotic'
		WHEN opioid_drug_flag ILIKE 'N' THEN 'neither'
		WHEN antibiotic_drug_flag ILIKE 'N' THEN 'neither'
	END drug_type
FROM
	drug
ORDER BY
	drug_type;

	-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
	-- Hint: Format the total costs as MONEY for easier comparision.
		--"opioid"	"$105,080,626.37"

SELECT
	CASE
		WHEN opioid_drug_flag ILIKE 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag ILIKE 'Y' THEN 'antibiotic'
		WHEN opioid_drug_flag ILIKE 'N' THEN 'neither'
		WHEN antibiotic_drug_flag ILIKE 'N' THEN 'neither'
	END drug_type,
	SUM(total_drug_cost::MONEY) AS cost_per_drug_type
FROM
	drug
INNER JOIN
	prescription
USING
	(drug_name)
GROUP BY
	drug_type
ORDER BY
	cost_per_drug_type;

-- 5. a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
	-- 56

SELECT
	cbsaname,
	COUNT(cbsa)
FROM
	cbsa
WHERE
	cbsaname LIKE '%TN%'
GROUP BY
	cbsaname;

SELECT
	COUNT(cbsa)
FROM
	cbsa
WHERE
	cbsaname LIKE '%TN%';
	

	-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
		--"Nashville-Davidson--Murfreesboro--Franklin, TN"	1830410
		--"Morristown, TN"	116352

SELECT
	cbsaname,
	SUM(population) AS total_population
FROM
	cbsa
INNER JOIN
	population
USING
	(fipscounty)
GROUP BY
	cbsaname
ORDER BY
total_population DESC;

SELECT
	cbsaname,
	SUM(population) AS total_population
FROM
	cbsa
INNER JOIN
	population
USING
	(fipscounty)
GROUP BY
	cbsaname
ORDER BY
total_population ASC;
	
	-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
		--"BEDFORD"	46854
SELECT
	county,
	population
FROM 
	population
INNER JOIN
	fips_county
USING
	(fipscounty)
WHERE
	fipscounty NOT IN
	(SELECT
		fipscounty
	FROM
		cbsa)
ORDER BY
	county
LIMIT 1;

		
-- 6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
	-- 9 rows

SELECT
	drug_name,
	total_claim_count
FROM
	prescription
WHERE
	total_claim_count >= 3000;

	-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
		-- 9 rows

SELECT
	drug_name,
	total_claim_count,
	opioid_drug_flag
FROM
	prescription
INNER JOIN
	drug
USING
	(drug_name)
WHERE
	total_claim_count >= 3000;

	-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
		-- 9 rows

SELECT
	drug_name,
	total_claim_count,
	opioid_drug_flag,
	nppes_provider_first_name,
	nppes_provider_last_org_name
FROM
	prescription
INNER JOIN
	drug
USING
	(drug_name)
INNER JOIN
	prescriber
USING
	(npi)
WHERE
	total_claim_count >= 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had 
-- for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the 
-- city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query 
-- before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
	-- **not possbile to run without prescription table since there are no common columns in prescriber and drug tables**

--from prescriber
SELECT
	npi,
	specialty_description,
	nppes_provider_city
FROM
	prescriber
WHERE
	specialty_description ILIKE  'Pain Management' --'%pain%'
	AND nppes_provider_city ILIKE '%nash%'; -- 9 rows with broad request, 7 rows = Pain Management

SELECT
	npi,
	CASE
		WHEN specialty_description ILIKE '%pain%' THEN 'Y' ELSE 'null'
		END AS specialty_pain,
	CASE
		WHEN nppes_provider_city ILIKE '%nash%' THEN 'Y' ELSE 'null'
		END AS city_nash
FROM
	prescriber; --25050 rows

-- from drug
SELECT
	*
FROM
	drug
WHERE
	opioid_drug_flag ILIKE '%Y%'; -- 91 rows

SELECT
	drug_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'Y' ELSE 'null'
		END AS opioid
FROM
	drug; --3425 rows

--INNER JOIN with prescription - not enough rows returned
SELECT
	npi,
	specialty_description,
	nppes_provider_city,
	drug_name,
	opioid_drug_flag
FROM
	prescriber
INNER JOIN
	prescription
USING
	(npi)
INNER JOIN
	drug
USING
	(drug_name)
WHERE
	specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'; --35 rows

--cross join without prescription??

SELECT
	npi,
	specialty_description,
	nppes_provider_city,
	drug_name,
	opioid_drug_flag
FROM
	drug
CROSS JOIN
	prescriber
WHERE
	specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';  --637 rows

	-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any 
	-- claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

WITH pain_nash_opioid AS
(SELECT
	npi,
	drug_name
FROM
	drug
CROSS JOIN
	prescriber
WHERE
	specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y')
SELECT
	npi,
	drug_name,
	SUM(total_claim_count) AS num_claims
FROM
	pain_nash_opioid
LEFT JOIN
	prescription
USING
	(npi,drug_name)
GROUP BY
	npi, drug_name
ORDER BY
	num_claims ASC; --637 rows

	
	-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

WITH pain_nash_opioid AS
(SELECT
	npi,
	drug_name
FROM
	drug
CROSS JOIN
	prescriber
WHERE
	specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y')
SELECT
	npi,
	drug_name,
	COALESCE(SUM(total_claim_count),0) AS num_claims
FROM
	pain_nash_opioid
LEFT JOIN
	prescription
USING
	(npi,drug_name)
GROUP BY
	npi, drug_name
ORDER BY
	num_claims DESC; --637 rows