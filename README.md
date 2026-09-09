# 🏥 Healthcare Hospital Readmission Analysis

## 📌 Project Overview

Hospital readmissions are an important healthcare metric because frequent readmissions can indicate complex patient conditions, inadequate post-discharge care, or challenges in treatment management.

This project analyzes hospital encounter data for diabetic patients to identify demographic, clinical, treatment, hospitalization, and discharge-related factors associated with **30-day hospital readmission**.

The analysis was performed primarily using **MySQL**, with a focus on data cleaning, transformation, exploratory analysis, and answering healthcare-focused business questions.

---

# 🎯 Business Problem

The primary objective of this project is to answer:

> **Which patient characteristics, clinical factors, treatment patterns, and hospital-related factors are associated with a higher rate of readmission within 30 days?**

Hospitals can use this type of analysis to better understand patient groups that may require additional monitoring, follow-up care, or discharge planning.

---

# 📊 Dataset

The project uses a healthcare dataset containing hospital encounter information for diabetic patients.

The dataset includes information related to:

- Patient demographics
- Hospital admissions
- Discharge disposition
- Previous hospital utilization
- Diagnoses
- Laboratory procedures
- Medications
- Diabetes treatment
- Readmission outcomes

### Main Dataset

The main dataset contains patient encounter information with columns such as:

```text
encounter_id
patient_nbr
race
gender
age
weight
admission_type_id
discharge_disposition_id
admission_source_id
time_in_hospital
num_lab_procedures
num_procedures
num_medications
number_outpatient
number_emergency
number_inpatient
diag_1
diag_2
diag_3
number_diagnoses
max_glu_serum
A1Cresult
insulin
change
diabetesMed
readmitted
```

---

# 🗂️ Mapping Tables

The original mapping data was separated into three lookup tables to provide descriptive information for numeric IDs.

### 1. Admission Type Mapping

Maps:

```text
admission_type_id → admission type description
```

Examples include:

- Emergency
- Urgent
- Elective

---

### 2. Discharge Disposition Mapping

Maps:

```text
discharge_disposition_id → discharge description
```

Examples include:

- Discharged to home
- Skilled nursing facility
- Home health service
- Hospice
- Expired

---

### 3. Admission Source Mapping

Maps:

```text
admission_source_id → admission source description
```

Examples include:

- Physician referral
- Clinic referral
- Emergency room
- Transfer from another hospital

These mapping tables were joined with the main healthcare dataset when descriptive information was required.

---

# 🛠️ Tools Used

- **MySQL**
- **SQL**
- **MySQL Workbench**
- **CSV Datasets**

---

# 🔧 SQL Skills Demonstrated

This project demonstrates the following SQL concepts:

### Data Manipulation

- `SELECT`
- `UPDATE`
- `DELETE`
- `CREATE TABLE`
- `ALTER TABLE`

### Data Cleaning

- Handling missing values
- Converting placeholder values (`?`) to `NULL`
- Data validation
- Removing terminal discharge cases

### Data Analysis

- `GROUP BY`
- `HAVING`
- Aggregate functions
- `CASE` statements
- Feature engineering
- Percentage calculations

### Advanced SQL

- Common Table Expressions (`CTEs`)
- Subqueries
- `JOIN`s
- Conditional aggregation
- Dynamic filtering using lookup tables

---

# 🧹 Data Cleaning and Preparation

## 1. Missing Value Handling

The dataset uses `?` to represent missing values in several columns.

These values were converted to `NULL` to ensure proper data handling and analysis.

Columns cleaned include:

- Race
- Weight
- Payer code
- Medical specialty
- Diagnosis columns

---

## 2. Missing Data Analysis

The percentage of missing values was examined for important columns to understand data quality and identify fields with significant missing information.

---

## 3. Patient-Level Deduplication

The dataset contains multiple hospital encounters for some patients.

To avoid frequent hospital users disproportionately influencing the analysis, one encounter was retained per patient.

The lowest `encounter_id` was used as a proxy for the first recorded encounter.

> Note: This approach assumes that the lowest encounter ID represents the earliest recorded encounter available in the dataset.

---

## 4. Terminal and Hospice Discharge Filtering

Patients with discharge dispositions related to:

- Hospice
- Expired
- Deceased

were removed from the analytical dataset.

Instead of manually hardcoding discharge IDs, the project dynamically identified these categories using the `discharge_disposition_mapping` lookup table.

This improves maintainability and makes the filtering logic easier to understand.

---

# ⚙️ Feature Engineering

## Age Midpoint

The original dataset stores age as ranges such as:

```text
[40-50)
[50-60)
[60-70)
```

An approximate numerical midpoint was created for easier analysis and ordering.

Example:

```text
[40-50) → 45
[50-60) → 55
[60-70) → 65
```

---

## Readmission Indicator

The primary outcome analyzed in this project is:

```text
<30
```

which represents hospital readmission within 30 days.

This outcome is used throughout the project to calculate the **30-day readmission rate**.

---

# 📈 Exploratory Data Analysis

The project begins with exploratory analysis to understand the distribution of hospital readmissions.

The analysis includes:

- Overall readmission distribution
- Readmission rates across age groups
- Readmission rates by admission type

These analyses provide an initial understanding of patient groups and hospital admission characteristics associated with early readmission.

---

# 🔍 Key Business Questions and Analysis

## 1. Which Diagnosis Categories Have Higher Readmission Rates?

Diagnosis codes were grouped into broader clinical categories such as:

- Diabetes
- Circulatory
- Respiratory
- Digestive
- Genitourinary
- Injury
- Neoplasms
- Mental disorders
- Musculoskeletal
- Supplementary classification
- External causes
- Other

The analysis identifies diagnosis categories with readmission rates above the overall average.

### Business Value

This helps identify broad clinical groups that may experience relatively higher rates of early readmission.

---

## 2. Does Medication Change Relate to Readmission?

The project analyzes whether patients whose diabetes medication was changed experienced different 30-day readmission rates compared with patients whose medication remained unchanged.

### Business Question

> Does a change in diabetes medication correspond to different rates of early hospital readmission?

---

## 3. Does Discharge Disposition Affect Readmission?

The analysis examines readmission rates across different discharge destinations.

Examples include:

- Discharged to home
- Skilled nursing facility
- Home health services
- Other discharge destinations

### Business Question

> Which discharge pathways are associated with higher observed 30-day readmission rates?

### Business Value

This analysis can help explore whether certain patient groups may require additional post-discharge support.

---

## 4. Does A1C Testing and Result Relate to Readmission?

The project analyzes the relationship between:

- A1C testing
- A1C result categories
- 30-day readmission

### Business Question

> Are different A1C testing or result categories associated with different readmission rates?

---

## 5. Primary and Secondary Diagnosis Combination Analysis

The project examines selected combinations of primary and secondary diagnoses.

Examples include combinations such as:

```text
Diabetes + Circulatory
Diabetes + Respiratory
Diabetes + Digestive
Other Diagnosis Combinations
```

### Business Question

> How do selected primary and secondary diagnosis combinations relate to 30-day readmission?

This provides an exploratory view of how multiple clinical conditions may relate to hospital readmission.

---

## 6. Exploratory Patient Complexity Segmentation

Patients are grouped based on selected indicators including:

- Age
- Number of medications
- Previous inpatient visits

The purpose is to explore whether patients with combinations of higher healthcare complexity indicators show different observed readmission rates.

### Important Note

> This segmentation is exploratory and is **not a clinically validated risk prediction model**.

The thresholds used are analytical groupings designed for exploratory SQL analysis.

---

# 🧠 Key SQL Techniques Used

## CTEs

Common Table Expressions were used to simplify multi-step transformations and analysis.

Example use cases:

- Diagnosis categorization
- Readmission rate calculations
- Multi-step analytical queries

---

## CASE Statements

`CASE` statements were used for:

- Diagnosis categorization
- Age transformation
- Patient segmentation
- Conditional analysis

---

## JOINs

Mapping tables were joined with the main dataset to convert numeric IDs into meaningful descriptions.

Example:

```text
admission_type_id
        ↓
admission_type_mapping
        ↓
Admission Type Description
```

---

## Subqueries

Subqueries were used for:

- Comparing diagnosis category readmission rates with overall average rates
- Dynamic filtering of discharge disposition categories

---

# 🗃️ Project Structure

```text
Healthcare-Readmission-Analysis/
│
├── data/
│   ├── diabetic_data.csv
│   ├── admission_type_mapping.csv
│   ├── discharge_disposition_mapping.csv
│   └── admission_source_mapping.csv
│
├── sql/
│   └── project_final.sql
│
└── README.md
```

---

# ▶️ How to Run the Project

## Step 1: Create the Database

Create a MySQL database:

```sql
CREATE DATABASE hospital_readmissions;
USE hospital_readmissions;
```

---

## Step 2: Import the Main Healthcare Dataset

Import the main diabetic patient dataset into:

```text
diabetic_data_raw
```

---

## Step 3: Import Mapping Tables

Import the following CSV files into MySQL:

```text
admission_type_mapping.csv
discharge_disposition_mapping.csv
admission_source_mapping.csv
```

These tables are required for descriptive analysis and dynamic filtering.

---

## Step 4: Run the SQL Analysis

Execute:

```text
project_final.sql
```

The script performs:

1. Data cleaning
2. Missing value handling
3. Patient-level deduplication
4. Terminal discharge filtering
5. Feature engineering
6. Exploratory analysis
7. Readmission analysis
8. Clinical and treatment-related analysis

---

# 📌 Project Limitations

This project focuses on exploratory analysis and identifies **associations**, not causation.

### Important limitations include:

- The analysis does not prove that a specific factor causes hospital readmission.
- Patient complexity segmentation is exploratory and not a validated clinical risk model.
- The lowest `encounter_id` is used as a proxy for the first recorded encounter.
- Diagnosis categories are simplified for analytical purposes.
- The dataset represents diabetic patient encounters and may not generalize to all hospital populations.

---

# 🚀 Future Improvements

Potential future enhancements include:

- Analyzing previous inpatient, emergency, and outpatient utilization in greater detail
- Building a dedicated hospital utilization analysis
- Creating a Power BI dashboard for interactive visualization
- Performing statistical testing on key associations
- Building a machine learning model to predict 30-day readmission
- Creating a star schema for analytical reporting
- Adding automated data quality checks

---

# 💡 Conclusion

This project demonstrates how SQL can be used to transform raw healthcare encounter data into meaningful analytical insights.

The analysis explores demographic, clinical, treatment, hospitalization, and discharge-related factors associated with **30-day hospital readmission among diabetic patients**.

Rather than treating the project as only a collection of SQL queries, the analysis follows a structured workflow:

```text
Raw Healthcare Data
        ↓
Data Cleaning
        ↓
Data Preparation
        ↓
Feature Engineering
        ↓
Exploratory Analysis
        ↓
Business-Focused Questions
        ↓
Readmission Insights
```

The project demonstrates practical SQL skills while maintaining a clear healthcare analytics objective.

---

## 👤 Author

**Darshan Panchal**

Aspiring Data Analyst | SQL | Python | Data Analytics

GitHub: https://github.com/DarshaN131521
