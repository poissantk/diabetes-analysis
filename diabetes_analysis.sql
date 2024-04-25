-- Inspiration from https://www.linkedin.com/pulse/analysis-healthcare-data-using-sql-kristopher-bosch/

SELECT *
FROM diabetic_data;

-- How long do patients typically spend in the hospital?
SELECT AVG(time_in_hospital)
FROM diabetic_data;

SELECT 
	time_in_hospital,
	COUNT(*) AS num_patients,
    COUNT(*) * 100.0 / sum(count(*)) OVER() AS percent
FROM diabetic_data
GROUP BY time_in_hospital
ORDER BY time_in_hospital;
-- Is there any correlation between the number of lab procedures and time spent in the hospital?
SELECT 
    time_in_hospital,
    MIN(num_lab_procedures),
    MAX(num_lab_procedures),
    ROUND(AVG(num_lab_procedures), 2) AS avg_num,
    ROUND(AVG(num_lab_procedures) - 
		LAG(AVG(num_lab_procedures), 1) OVER(ORDER BY time_in_hospital), 2) AS diff
FROM diabetic_data
GROUP BY time_in_hospital
ORDER BY time_in_hospital
;
-- Is there a racial bias related to the number of lab procedures a patient receives?
SELECT 
	race,
    COUNT(*) AS num_patients,
    MIN(num_lab_procedures) AS min_procedures,
    MAX(num_lab_procedures) AS max_procedures,
    ROUND(AVG(num_lab_procedures), 2) AS avg_procedures
FROM diabetic_data
WHERE race != '?'
GROUP BY race
ORDER BY avg_procedures DESC;

WITH cte AS 
(
	SELECT 
		race,
		num_lab_procedures,
		CASE WHEN num_lab_procedures BETWEEN 0 AND 26 THEN 'low'
			WHEN num_lab_procedures BETWEEN 27 AND 53 THEN 'medium-low'
			WHEN num_lab_procedures BETWEEN 54 AND 80 THEN 'medium'
			WHEN num_lab_procedures BETWEEN 81 AND 107 THEN 'medium-high'
			ELSE 'high' END AS procedures_group
	FROM diabetic_data
    WHERE race != '?'
)
SELECT 
	race, 
    procedures_group,
    COUNT(*) AS num_patients,
    COUNT(*) * 100.0 / sum(count(*)) OVER(PARTITION BY race) AS percent
FROM cte
GROUP BY race, procedures_group
ORDER BY procedures_group, race
;

WITH cte AS 
(
	SELECT 
		race,
		num_lab_procedures,
		NTILE(5) OVER(ORDER BY num_lab_procedures) AS procedures_group
	FROM diabetic_data
    WHERE race != '?'
)
SELECT 
	race, 
    procedures_group,
    COUNT(*) AS num_patients,
	COUNT(*) * 100.0 / sum(count(*)) OVER(PARTITION BY race) AS percent
FROM cte
GROUP BY race, procedures_group
ORDER BY procedures_group, race
;
-- Which medical specialties perform the most lab procedures?
SELECT 
	medical_specialty,
    COUNT(*) AS num_occurrences,
    MAX(num_lab_procedures) as max_procedures,
    MIN(num_lab_procedures) as min_procedures,
    ROUND(AVG(num_lab_procedures), 2) as avg_procedures
FROM diabetic_data
WHERE medical_specialty <> '?' 
GROUP BY medical_specialty
HAVING num_occurrences > 25
ORDER BY avg_procedures DESC
LIMIT 5;
-- Are patients being readmitted to the hospital in under 30 days after discharge?
SELECT 
	readmitted,
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / sum(count(*)) OVER(), 2) AS percent
FROM diabetic_data
GROUP BY readmitted;
-- Which patients are receiving the most medication and lab procedures?
SELECT 
	race,
    gender,
    age,
    weight,
	num_medications,
    num_lab_procedures
FROM diabetic_data;

SELECT 
	race,
	AVG(num_medications),
    AVG(num_lab_procedures)
FROM diabetic_data
WHERE race <> '?'
GROUP BY race
ORDER BY race;

SELECT 
	gender,
	AVG(num_medications),
    AVG(num_lab_procedures)
FROM diabetic_data
GROUP BY gender
ORDER BY gender;

SELECT 
	age,
	AVG(num_medications),
    AVG(num_lab_procedures)
FROM diabetic_data
GROUP BY age
ORDER BY age;

SELECT 
	weight,
	AVG(num_medications),
    AVG(num_lab_procedures)
FROM diabetic_data
WHERE weight <> '?'
GROUP BY weight
ORDER BY CAST(SUBSTR(weight, 2, POSITION('-' IN weight)) AS DECIMAL);
