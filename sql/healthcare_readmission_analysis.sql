CREATE DATABASE hospital_readmissions;
USE hospital_readmissions;

-- PREREQUISITES
-- Before running this analysis, import the following lookup CSV files into MySQL:
-- 1. admission_type_mapping.csv
-- 2. discharge_disposition_mapping.csv
-- 3. admission_source_mapping.csv
-- These lookup tables provide descriptive labels for the corresponding ID columns.

SELECT COUNT(*) FROM diabetic_data_raw;
SELECT * FROM admission_source_mapping;

TRUNCATE TABLE diabetic_data_raw;

DESCRIBE diabetic_data_raw;

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/diabetic_data.csv'
INTO TABLE diabetic_data_raw
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


SET SQL_SAFE_UPDATES = 0;

UPDATE diabetic_data_raw
SET race = NULLIF(race, '?'),
	weight = NULLIF(weight, '?'),
    payer_code = NULLIF(payer_code, '?'),
    medical_specialty = NULLIF(medical_specialty, '?'),
    diag_1 = NULLIF(diag_1, '?'),
    diag_2 = NULLIF(diag_2, '?'),
    diag_3 = NULLIF(diag_3, '?');
    
SELECT * FROM diabetic_data_raw LIMIT 10;

SELECT
	ROUND(SUM(weight IS NULL)/COUNT(*) * 100, 1) AS pct_missing_weight, 
	ROUND(SUM(payer_code IS NULL)/COUNT(*) * 100, 1) AS pct_missing_payer,
	ROUND(SUM(medical_specialty IS NULL)/COUNT(*) * 100, 1) AS pct_missing_specialty
FROM diabetic_data_raw;

-- STEP 2

SELECT
	patient_nbr, 
    COUNT(*) as encounter_count
FROM diabetic_data_raw
GROUP BY patient_nbr
HAVING COUNT(*) > 1
ORDER BY encounter_count DESC
LIMIT 10;
    
-- Keep one encounter per patient to avoid frequent hospital users
-- disproportionately influencing the analysis.
-- The lowest encounter_id is used as a proxy for the first recorded encounter.

CREATE TABLE diabetic_data_dedup AS
SELECT t.*
FROM diabetic_data_raw as t
INNER JOIN (SELECT 
	patient_nbr, 
    MIN(encounter_id) as first_encounter
FROM diabetic_data_raw
GROUP BY patient_nbr) first_enc
ON t.patient_nbr = first_enc.patient_nbr
AND t.encounter_id = first_enc.first_encounter;

 SELECT COUNT(*) FROM diabetic_data_dedup;
 
 
 SELECT 
	discharge_disposition_id, 
    COUNT(*) as encounter_count
FROM diabetic_data_raw
GROUP BY discharge_disposition_id
ORDER BY encounter_count DESC;



SELECT * FROM discharge_disposition_mapping
WHERE description LIKE '%hospice%' OR description LIKE '%expired%' OR description LIKE '%deceased%';


DELETE FROM diabetic_data_dedup 
WHERE discharge_disposition_id IN (
	SELECT discharge_disposition_id 
    FROM  discharge_disposition_mapping
    WHERE description LIKE '%hospice%' OR description LIKE '%expired%' OR description LIKE '%deceased%'
);




-- STEP 5: Feature Engineering
SELECT * FROM diabetic_data_dedup
LIMIT 50;

ALTER TABLE diabetic_data_dedup ADD COLUMN age_midpoint INT;

UPDATE diabetic_data_dedup
SET age_midpoint = CASE
    WHEN age = '[0-10)'   THEN 5
    WHEN age = '[10-20)'  THEN 15
    WHEN age = '[20-30)'  THEN 25
    WHEN age = '[30-40)'  THEN 35
    WHEN age = '[40-50)'  THEN 45
    WHEN age = '[50-60)'  THEN 55
    WHEN age = '[60-70)'  THEN 65
    WHEN age = '[70-80)'  THEN 75
    WHEN age = '[80-90)'  THEN 85
    WHEN age = '[90-100)' THEN 95
END;

-- EXPLORATORY ANALYSIS

SELECT
	readmitted, 
    COUNT(*) as encounter_count, 
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM diabetic_data_dedup) * 100, 1) as pct_of_total 
FROM diabetic_data_dedup
GROUP BY readmitted
ORDER BY encounter_count DESC;
	
SELECT
	age, 
    age_midpoint, 
    COUNT(*) as total_patients, 
    SUM(readmitted = '<30') as readmitted_under_30,
    ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) as readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY age, age_midpoint
ORDER BY age_midpoint;

SELECT
	m.description as admission_type, 
    COUNT(*) as total_patients, 
    ROUND(SUM(d.readmitted = '<30') / COUNT(*) * 100, 1) as readmission_rate_pct
FROM diabetic_data_dedup AS d
JOIN admission_type_mapping AS m
ON d.admission_type_id = m.admission_type_id
GROUP BY m.description
ORDER BY readmission_rate_pct DESC;



-- ADVANCED SQL ANALYSIS

-- diag_1 notes
-- 140-239: Neoplasms (Cancer)
-- 290-319: Mental Disorders
-- 390–459: Diseases of the circulatory system
-- 460–519: Diseases of the respiratory system
-- 520–579: Diseases of the digestive system
-- 580–629: Diseases of the genitourinary system
-- 710-739: Musculoskeletal System
-- 800–999: Injury and poisoning

-- REFINED: Expanded the CASE statement to capture more specific ICD-9 categories
WITH diag_categorized AS (
	SELECT
		encounter_id, 
        readmitted, 
        CASE
            WHEN diag_1 LIKE 'V%' THEN 'Supplementary Classification'
            WHEN diag_1 LIKE 'E%' THEN 'External Causes'
			WHEN diag_1 LIKE '250%' THEN 'Diabetes'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 390 AND 459 THEN 'Circulatory'
			WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 460 AND 519 THEN 'Respiratory'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 520 AND 579 THEN 'Digestive'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 580 AND 629 THEN 'Genitourinary'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 800 AND 999 THEN 'Injury'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 140 AND 239 THEN 'Neoplasms'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 290 AND 319 THEN 'Mental Disorders'
            WHEN CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 710 AND 739 THEN 'Musculoskeletal'
		ELSE 'Other'
	END AS diagnosis_category, 
    CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END AS is_readmitted_30
	FROM diabetic_data_dedup
    WHERE diag_1 IS NOT NULL
)
SELECT
	diagnosis_category, 
    COUNT(*) AS total_patients, 
    ROUND(AVG(is_readmitted_30) * 100, 1) AS readmission_rate_pct
FROM diag_categorized
GROUP BY diagnosis_category
HAVING AVG(is_readmitted_30) > (
	SELECT AVG(is_readmitted_30) FROM diag_categorized
)
ORDER BY readmission_rate_pct DESC;


-- KEY FINDINGS

-- Finding 1. Top diagnosis categories driving readmission (See query above)

-- Finding 2. Does a medication change at discharge affect readmission?


SELECT
	`change`, 
    COUNT(*) as total_patients,
	ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY `change`;


-- Finding 3. Discharge disposition impact


SELECT
	m.description as discharge_disposition, 
    COUNT(*) AS total_patients, 
	ROUND(SUM(d.readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_dedup as d
JOIN discharge_disposition_mapping as m
ON d.discharge_disposition_id = m.discharge_disposition_id
GROUP BY m.description
HAVING COUNT(*) > 100
ORDER BY readmission_rate_pct DESC
LIMIT 10;


-- Finding 4. A1C testing and readmission


SELECT
	A1Cresult, 
    COUNT(*) as total_patients, 
	ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY A1Cresult;


-- Finding 5. Primary and Secondary Diagnosis Combination Analysis
-- How do selected primary and secondary diagnosis combinations relate to readmissions?


SELECT
	CASE 
		WHEN diag_1 LIKE '250%' AND (CAST(LEFT(diag_2, 3) AS UNSIGNED) BETWEEN 390 AND 459) THEN 'Diabetes + Circulatory'
		WHEN diag_1 LIKE '250%' AND (CAST(LEFT(diag_2, 3) AS UNSIGNED) BETWEEN 460 AND 519) THEN 'Diabetes + Respiratory'
        WHEN (CAST(LEFT(diag_1, 3) AS UNSIGNED) BETWEEN 390 AND 459) AND (CAST(LEFT(diag_2, 3) AS UNSIGNED) BETWEEN 460 AND 519) THEN 'Circulatory + Respiratory'
		ELSE 'Other Combination / Single Focus'
	END AS diagnosis_combination,
	COUNT(*) AS total_patients,
	ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY diagnosis_combination
HAVING total_encounters > 50
ORDER BY readmission_rate_pct DESC;


-- Finding 6. Exploratory Patient Complexity Segmentation
-- This segmentation is based on selected age, medication burden, and prior inpatient utilization indicators.
-- The thresholds are analytical groupings and not a clinically validated risk prediction model.


SELECT
	CASE
		WHEN age_midpoint >= 70 AND num_medications > 15 AND number_inpatient >= 2
            THEN '1. High-Complexity Profile'
		WHEN (age_midpoint >= 70 AND num_medications > 15) OR number_inpatient >= 2
            THEN '2. Moderate-Complexity Profile'
		ELSE '3. Lower-Complexity Profile'
	END AS complexity_profile,
	COUNT(*) as patient_count,
	ROUND(SUM(readmitted = '<30') / COUNT(*) * 100, 1) AS readmission_rate_pct
FROM diabetic_data_dedup
GROUP BY complexity_profile
ORDER BY complexity_profile ASC;