# Queryon Technical Exercise – Project Profitability Analysis

**Candidate:** Sai Gowtham Yanala     
**Role:** Data Analytics Consultant & Delivery Lead

---

## Overview

This exercise demonstrates a practical approach to preparing raw operational data for **project profitability analysis**.

The provided datasets represent a simplified services environment tracking:

* projects
* employee time entries
* client invoices

The goal was to create an analytics-ready dataset that answers core profitability questions while addressing common real-world data issues such as:

* duplicate records
* inconsistent identifier formats
* currency formatting inconsistencies
* missing or incomplete values
* fragmented operational datasets

Rather than over-engineering the exercise, the focus was on building a **clear, pragmatic, and scalable transformation approach** similar to what I would implement during the early stages of a client data engagement.

---

## Key Skills Demonstrated

* analytics-oriented data modeling
* SQL-based data transformation
* data cleaning and duplicate handling
* project profitability analysis
* clear documentation of assumptions
* consulting-style solution delivery

---

## Solution Architecture

The solution follows a simple analytics pipeline structure often used in consulting data projects.

```
Raw Data Sources
│
├── projects.csv
├── time_entries.csv
└── invoices.csv
│
▼
Data Cleaning Layer
• standardize project IDs
• clean currency fields
• remove duplicate records
• handle unusable records
│
▼
Transformation Layer
• aggregate labor hours and costs
• aggregate invoice revenue
• combine project metadata
│
▼
Analytics Dataset
Project-level profitability table
│
▼
Business Insights
• project profitability
• budget overruns
• top revenue clients
```

---

## Repository Structure

```
queryon-project-profitability-analysis
│
├── README.md
├── sql
│   └── project_profitability_analysis.sql
└── data
    ├── projects.csv
    ├── time_entries.csv
    ├── invoices.csv
    └── data_dictionary.csv
```

---

## Data Modeling Approach

The transformation produces a **project-level profitability dataset** that combines cost and revenue data.

### Analytical Output

**project_profitability**

**Grain:** one row per project

**Metrics**

* total_hours
* total_cost
* total_revenue
* gross_margin

---

### Supporting Entities

**Projects**

* project_id
* project_name
* client_id
* budget_amount
* status

**Time Entries**

* time_entry_id
* project_id
* employee_id
* work_date
* hours

**Invoices**

* invoice_id
* project_id
* client_id
* invoice_amount
* status

---

### Relationships

```
projects.project_id
│
├── time_entries.project_id
└── invoices.project_id
```

Profitability metrics are derived by aggregating time-based cost and invoice revenue for each project.

---

## Data Preparation Process

### 1. Project ID Standardization

Project identifiers appear in multiple formats in the source data, such as:

* `001`
* `PRJ-001`
* `PRJ001`
* `PRJ_001`

To ensure reliable joins between datasets, project IDs were standardized by:

* removing non-numeric characters
* padding numeric values to a consistent 3-digit format

This allows all representations of the same project to map to a consistent join key.

---

### 2. Duplicate Handling

Operational datasets often contain duplicate rows due to incremental loads or system updates.

Duplicates were resolved by keeping the **most recent version of each record** based on `last_updated_at`.

Example approach:

```
ROW_NUMBER() OVER (PARTITION BY business_key ORDER BY last_updated_at DESC)
```

This was applied to:

* projects
* time entries
* invoices

---

### 3. Currency Cleaning

Budget and invoice values contained currency formatting.

To convert them into numeric fields for calculations:

* `$` and `,` characters were removed
* numeric values were cast into decimal types

Some budget values used **k notation** (e.g., `25k`).
These were converted to full numeric values (`25000`).

---

### 4. Cost Calculation

The exercise specifies that project cost should be calculated as:

```
cost = hours × hourly_rate
```

Since the dataset does not include an employee rate table, I assumed a **flat rate of $100/hour** for demonstration purposes.

In a real engagement, this rate would be replaced with employee or project billing rates from the financial system.

---

### 5. Revenue Aggregation

Revenue was calculated by summing invoice amounts per project after:

* cleaning invoice values
* removing duplicate invoices
* excluding invoices marked as `Voided`

Invoices without a usable `project_id` were excluded from project profitability calculations.

---

### 6. Final Analytical Dataset

The final dataset contains:

* project information
* aggregated labor hours
* total labor cost
* total invoice revenue
* gross margin

This dataset directly supports the business questions required in the exercise.

---

## Business Questions Answered

### 1. Project Profitability

For each project, the solution calculates:

* total revenue
* total cost
* gross margin

This provides a quick view of which projects are financially performing well.

---

### 2. Projects Where Total Cost Exceeds Budget

The solution identifies projects where:

```
total_cost > budget_amount
```

These projects represent potential **budget overruns** that may require operational review.

---

## Stretch Analysis

### Top 3 Clients by Revenue

An additional query calculates the **top three clients by total revenue** by aggregating project revenue per client.

---

## Additional Data Quality Checks (Recommended for Production)

In a real engagement, additional checks would typically be implemented for:

### Referential Integrity

* time entries referencing non-existent projects
* invoices referencing non-existent projects

### Completeness

* missing budget values
* missing hours in time entries

### Business Logic

* negative invoice values
* extremely high hour entries
* projects with revenue but no labor cost

### Monitoring

* duplicate rate trends
* row count changes across refreshes
* unmatched joins across source tables

---

## Scaling the Solution

If implemented in production environments, the solution could be extended with:

### Incremental Data Pipelines

Process only new or changed records instead of full dataset reloads.

### Partitioned Storage

Partition large tables by fields such as:

* work_date
* invoice_date
* project_id

### Analytics Platforms

Deploy the transformations into scalable environments such as:

* Microsoft Fabric Lakehouse
* Snowflake
* Delta Lake
* Azure Synapse

### Semantic Layer

Expose the curated dataset through a semantic model for BI tools such as **Power BI**.

---

## Assumptions

The following assumptions were necessary due to limited context in the source data:

* labor rate assumed to be **$100/hour**
* most recent record retained when duplicates exist
* invoices marked `Voided` excluded from revenue
* invoices without valid project IDs excluded from profitability calculations

These assumptions would normally be validated with stakeholders during project discovery.

---

## Next Steps (If This Were a Real Engagement)

If this work were part of an actual consulting engagement, the next steps would include:

1. validating metrics with finance and operations stakeholders
2. confirming labor cost logic and billing rates
3. implementing automated data quality checks
4. publishing curated datasets for BI reporting
5. building a project profitability dashboard
6. implementing scheduled refresh pipelines

---

## Tools Used

Primary implementation used **SQL**.

Reference materials were used only for minor syntax checks and formatting verification, consistent with standard engineering workflows.

---

## Summary

This solution demonstrates a pragmatic approach to transforming raw operational datasets into an analytics-ready profitability dataset.

The main priorities were:

* reliable joins across messy operational data
* clear assumptions and documentation
* practical data cleaning techniques
* business-ready profitability insights
