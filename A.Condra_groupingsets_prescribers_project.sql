-- In this set of exercises you are going to explore additional ways to group and organize the output of a query when using postgres.
-- For the first few exercises, we are going to compare the total number of claims from Interventional Pain Management Specialists compared to 
-- those from Pain Managment specialists.

-- 1. Write a query which returns the total number of claims for these two groups. Your output should look like this:
		-- specialty_description			total_claims
		-- Interventional Pain Management	55906
		-- Pain Management					70853

SELECT
	ber.specialty_description,
	SUM(tion.total_claim_count) AS total_claims
FROM
	prescriber AS ber
INNER JOIN
	prescription AS tion
USING
	(npi)
WHERE
	ber.specialty_description ILIKE '%Pain%'
GROUP BY
	ber.specialty_description;
	
		
-- 2. Now, let's say that we want our output to also include the total number of claims between these two groups. 
-- Combine two queries with the UNION keyword to accomplish this. Your output should look like this:
		-- specialty_description	total_claims
		--                         |      126759|
		-- Interventional Pain Management| 55906| Pain Management | 70853|

SELECT
	ber.specialty_description,
	SUM(tion.total_claim_count) AS total_claims
FROM
	prescriber AS ber
INNER JOIN
	prescription AS tion
USING
	(npi)
WHERE
	ber.specialty_description ILIKE '%Pain%'
GROUP BY
	ber.specialty_description
UNION
SELECT
	'GRAND TOTAL'  AS specialty_description,
	SUM(tion.total_claim_count) AS total_claims
FROM
	prescriber AS ber
INNER JOIN
	prescription AS tion
USING
	(npi)
WHERE
	ber.specialty_description ILIKE '%Pain%';
	

-- 3. Now, instead of using UNION, make use of GROUPING SETS to achieve the same output.

SELECT
	ber.specialty_description,
	SUM(tion.total_claim_count) AS total_claims
FROM
	prescriber AS ber
INNER JOIN
	prescription AS tion
USING
	(npi)
WHERE
	ber.specialty_description ILIKE '%Pain%'
GROUP BY
	GROUPING SETS ((ber.specialty_description),());


-- 4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. 
-- non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so that your output also shows the total number 
-- of opioid claims vs. non-opioid claims by these two specialites:

		-- specialty_description	opioid_drug_flag	total_claims
		--                           |                |      129726|
		--                           |Y               |       76143|
		--                           |N               |       53583|
		-- Pain Management | | 72487| Interventional Pain Management| | 57239|
	
SELECT
	ber.specialty_description,
	drug.opioid_drug_flag,
	SUM(tion.total_claim_count) AS total_claims
FROM
	prescriber AS ber
INNER JOIN
	prescription AS tion
USING
	(npi)
INNER JOIN
	drug
USING
	(drug_name)
WHERE
	ber.specialty_description ILIKE '%Pain%'
GROUP BY
	GROUPING SETS((drug.opioid_drug_flag),(ber.specialty_description),());


-- 5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). How is the result different from the 
-- output from the previous query? It breaks down the opioid totals by specialty and removes specialty only totals, grand total still exists.

SELECT
	ber.specialty_description,
	drug.opioid_drug_flag,
	SUM(tion.total_claim_count) AS total_claims
FROM
	prescriber AS ber
INNER JOIN
	prescription AS tion
USING
	(npi)
INNER JOIN
	drug
USING
	(drug_name)
WHERE
	ber.specialty_description ILIKE '%Pain%'
GROUP BY
	ROLLUP(opioid_drug_flag, specialty_description);


-- 6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change 
-- the result? Now the opioid only totals are gone and the specialty only totals exist again, the grand total still exists. 

SELECT
	ber.specialty_description,
	drug.opioid_drug_flag,
	SUM(tion.total_claim_count) AS total_claims
FROM
	prescriber AS ber
INNER JOIN
	prescription AS tion
USING
	(npi)
INNER JOIN
	drug
USING
	(drug_name)
WHERE
	ber.specialty_description ILIKE '%Pain%'
GROUP BY
	ROLLUP(specialty_description,opioid_drug_flag);


-- 7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output? 
-- All breakdowns and totals exist along with the grand total.

SELECT
	ber.specialty_description,
	drug.opioid_drug_flag,
	SUM(tion.total_claim_count) AS total_claims
FROM
	prescriber AS ber
INNER JOIN
	prescription AS tion
USING
	(npi)
INNER JOIN
	drug
USING
	(drug_name)
WHERE
	ber.specialty_description ILIKE '%Pain%'
GROUP BY
	CUBE(specialty_description,opioid_drug_flag);


-- 8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and 
-- Chattanooga), the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. 
-- For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. 
-- For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.
-- The end result of this question should be a table formatted like this:
		-- city	codeine	fentanyl	hyrdocodone	morphine	oxycodone	oxymorphone
		-- CHATTANOOGA	1323	3689	68315	12126	49519	1317
		-- KNOXVILLE	2744	4811	78529	20946	84730	9186
		-- MEMPHIS	4697	3666	68036	4898	38295	189
		-- NASHVILLE	2043	6119	88669	13572	62859	1261
-- For this question, you should look into use the crosstab function, which is part of the tablefunc extension. In order to use this function, you must
-- (one time per database) run the command CREATE EXTENSION tablefunc;
-- Hint #1: First write a query which will label each drug in the drug table using the six categories listed above. 

-- categorizing drug_names
SELECT
	CASE 
		WHEN drug_name ILIKE '%Codeine%' THEN 'Codeine'
		WHEN drug_name ILIKE '%Fentanyl%' THEN 'Fentanyl'
		WHEN drug_name ILIKE '%Hydrocodone%' THEN 'Hydrocodone'
		WHEN drug_name ILIKE '%Morphine%' THEN 'Morphine'
		WHEN drug_name ILIKE '%Oxycodone%' THEN 'Oxycodone'
		WHEN drug_name ILIKE '%Oxymorphone%' THEN 'Oxymorphone'
	END AS drug_category
FROM
	prescription
WHERE
	drug_name ILIKE '%Codeine%'
	OR drug_name ILIKE '%Fentanyl%'
	OR drug_name ILIKE '%Hydrocodone%'
	OR drug_name ILIKE '%Morphine%'
	OR drug_name ILIKE '%Oxycodone%'
	OR drug_name ILIKE '%Oxymorphone%'
GROUP BY
	drug_category;

-- filtering 4 TN cities (from cbsa table)
SELECT
	CASE
		WHEN cbsaname ILIKE '%nashville%' THEN 'Nashville'
		WHEN cbsaname ILIKE '%memphis%' THEN 'Memphis'
		WHEN cbsaname ILIKE '%knoxville%' THEN 'Knoxville'
		WHEN cbsaname ILIKE '%chattanooga%' THEN 'Chattanooga'
	END AS cities
FROM
	cbsa
WHERE
	cbsaname ILIKE '%nashville%'
	OR cbsaname ILIKE '%memphis%'
	OR cbsaname ILIKE '%knoxville%'
	OR cbsaname ILIKE '%chattanooga%'
GROUP BY
	cbsaname;

-- (from prescriber table)

SELECT
	CASE
		WHEN nppes_provider_city ILIKE '%nashville%' THEN 'Nashville'
		WHEN nppes_provider_city ILIKE '%memphis%' THEN 'Memphis'
		WHEN nppes_provider_city ILIKE '%knoxville%' THEN 'Knoxville'
		WHEN nppes_provider_city ILIKE '%chattanooga%' THEN 'Chattanooga'
	END AS cities
FROM
	prescriber
WHERE
	nppes_provider_city ILIKE '%nashville%'
	OR nppes_provider_city ILIKE '%memphis%'
	OR nppes_provider_city ILIKE '%knoxville%'
	OR nppes_provider_city ILIKE '%chattanooga%'
GROUP BY
	cities;

-- INNER JOIN??
SELECT
	CASE
		WHEN nppes_provider_city ILIKE '%nashville%' THEN 'Nashville'
		WHEN nppes_provider_city ILIKE '%memphis%' THEN 'Memphis'
		WHEN nppes_provider_city ILIKE '%knoxville%' THEN 'Knoxville'
		WHEN nppes_provider_city ILIKE '%chattanooga%' THEN 'Chattanooga'
	END AS cities,
	CASE
		WHEN drug_name ILIKE '%Codeine%' THEN 'Codeine'
		WHEN drug_name ILIKE '%Fentanyl%' THEN 'Fentanyl'
		WHEN drug_name ILIKE '%Hydrocodone%' THEN 'Hydrocodone'
		WHEN drug_name ILIKE '%Morphine%' THEN 'Morphine'
		WHEN drug_name ILIKE '%Oxycodone%' THEN 'Oxycodone'
		WHEN drug_name ILIKE '%Oxymorphone%' THEN 'Oxymorphone'
	END AS drug_category,
	SUM(total_claim_count) AS total_claims
FROM
	prescription
INNER JOIN
	prescriber
USING
	(npi)
WHERE
	(drug_name ILIKE '%Codeine%'
	OR drug_name ILIKE '%Fentanyl%'
	OR drug_name ILIKE '%Hydrocodone%'
	OR drug_name ILIKE '%Morphine%'
	OR drug_name ILIKE '%Oxycodone%'
	OR drug_name ILIKE '%Oxymorphone%')
	AND (nppes_provider_city ILIKE '%nashville%'
	OR nppes_provider_city ILIKE '%memphis%'
	OR nppes_provider_city ILIKE '%knoxville%'
	OR nppes_provider_city ILIKE '%chattanooga%')
GROUP BY
	drug_category, cities
ORDER BY
	1,2;

-- Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with one row_name column, one category 
-- column, and one value column. So in this case, you need to have a city column, a drug label column, and a total claim count column. Hint #3: The sql 
-- statement that goes inside of crosstab must be surrounded by single quotes. If the query that you are using also uses single quotes, you'll need to 
-- escape them by turning them into double-single quotes.

CREATE EXTENSION tablefunc;

SELECT *
FROM CROSSTAB(
'(SELECT
	CASE
		WHEN nppes_provider_city ILIKE ''%nashville%'' THEN ''Nashville''
		WHEN nppes_provider_city ILIKE ''%memphis%'' THEN ''Memphis''
		WHEN nppes_provider_city ILIKE ''%knoxville%'' THEN ''Knoxville''
		WHEN nppes_provider_city ILIKE ''%chattanooga%'' THEN ''Chattanooga''
	END AS cities,
	CASE
		WHEN drug_name ILIKE ''%Codeine%'' THEN ''Codeine''
		WHEN drug_name ILIKE ''%Fentanyl%'' THEN ''Fentanyl''
		WHEN drug_name ILIKE ''%Hydrocodone%'' THEN ''Hydrocodone''
		WHEN drug_name ILIKE ''%Morphine%'' THEN ''Morphine''
		WHEN drug_name ILIKE ''%Oxycodone%'' THEN ''Oxycodone''
		WHEN drug_name ILIKE ''%Oxymorphone%'' THEN ''Oxymorphone''
	END AS drug_category,
	SUM(total_claim_count) AS total_claims
FROM
	prescription
INNER JOIN
	prescriber
USING
	(npi)
WHERE
	(drug_name ILIKE ''%Codeine%''
	OR drug_name ILIKE ''%Fentanyl%''
	OR drug_name ILIKE ''%Hydrocodone%''
	OR drug_name ILIKE ''%Morphine%''
	OR drug_name ILIKE ''%Oxycodone%''
	OR drug_name ILIKE ''%Oxymorphone%'')
	AND (nppes_provider_city ILIKE ''%nashville%''
	OR nppes_provider_city ILIKE ''%memphis%''
	OR nppes_provider_city ILIKE ''%knoxville%''
	OR nppes_provider_city ILIKE ''%chattanooga%'')
GROUP BY
	drug_category, cities
ORDER BY
	1,2 )','SELECT
	CASE 
		WHEN drug_name ILIKE ''%Codeine%'' THEN ''Codeine''
		WHEN drug_name ILIKE ''%Fentanyl%'' THEN ''Fentanyl''
		WHEN drug_name ILIKE ''%Hydrocodone%'' THEN ''Hydrocodone''
		WHEN drug_name ILIKE ''%Morphine%'' THEN ''Morphine''
		WHEN drug_name ILIKE ''%Oxycodone%'' THEN ''Oxycodone''
		WHEN drug_name ILIKE ''%Oxymorphone%'' THEN ''Oxymorphone''
	END AS drug_category
FROM
	prescription
WHERE
	drug_name ILIKE ''%Codeine%''
	OR drug_name ILIKE ''%Fentanyl%''
	OR drug_name ILIKE ''%Hydrocodone%''
	OR drug_name ILIKE ''%Morphine%''
	OR drug_name ILIKE ''%Oxycodone%''
	OR drug_name ILIKE ''%Oxymorphone%''
GROUP BY
	drug_category
ORDER BY
	drug_category')
AS (cities VARCHAR,Codeine NUMERIC,Fentanyl NUMERIC,Hydrocodone NUMERIC,Morphine NUMERIC,Oxycodone NUMERIC,Oxymorphone NUMERIC);