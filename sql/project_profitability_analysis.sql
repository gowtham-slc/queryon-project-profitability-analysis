/* =========================================================
   Queryon Technical Exercise
   Project Profitability Analysis
   Candidate: Sai Gowtham Yanala

   Notes:
   - Built as a pragmatic analytics-prep query for a consulting-style exercise
   - Handles duplicate records, inconsistent project_id formats, and currency cleanup
   - Assumes labor cost = hours * 100 because no employee rate table was provided
   ========================================================= */

WITH cleaned_projects AS (
    SELECT
        LPAD(REGEXP_REPLACE(COALESCE(project_id, ''), '[^0-9]', ''), 3, '0') AS project_id,
        TRIM(project_name) AS project_name,
        TRIM(client_id) AS client_id,
        CASE
            WHEN LOWER(TRIM(budget_amount)) LIKE '%k' THEN
                CAST(
                    REPLACE(REPLACE(REPLACE(LOWER(TRIM(budget_amount)), '$', ''), ',', ''), 'k', '')
                    AS DECIMAL(12,2)
                ) * 1000
            ELSE
                CAST(REPLACE(REPLACE(TRIM(budget_amount), '$', ''), ',', '') AS DECIMAL(12,2))
        END AS budget_amount,
        TRIM(status) AS status,
        last_updated_at
    FROM projects
    WHERE project_id IS NOT NULL
),

latest_projects AS (
    SELECT *
    FROM (
        SELECT
            cp.*,
            ROW_NUMBER() OVER (
                PARTITION BY project_id
                ORDER BY last_updated_at DESC
            ) AS rn
        FROM cleaned_projects cp
    ) x
    WHERE rn = 1
),

cleaned_time_entries AS (
    SELECT
        TRIM(time_entry_id) AS time_entry_id,
        LPAD(REGEXP_REPLACE(COALESCE(project_id, ''), '[^0-9]', ''), 3, '0') AS project_id,
        TRIM(employee_id) AS employee_id,
        CAST(hours AS DECIMAL(10,2)) AS hours,
        work_date,
        TRIM(billable_flag) AS billable_flag,
        TRIM(approved_flag) AS approved_flag,
        last_updated_at
    FROM time_entries
    WHERE hours IS NOT NULL
      AND project_id IS NOT NULL
),

dedup_time_entries AS (
    SELECT *
    FROM (
        SELECT
            cte.*,
            ROW_NUMBER() OVER (
                PARTITION BY time_entry_id
                ORDER BY last_updated_at DESC
            ) AS rn
        FROM cleaned_time_entries cte
    ) x
    WHERE rn = 1
),

time_costs AS (
    SELECT
        project_id,
        SUM(hours) AS total_hours,
        SUM(hours * 100) AS total_cost
    FROM dedup_time_entries
    GROUP BY project_id
),

cleaned_invoices AS (
    SELECT
        TRIM(invoice_id) AS invoice_id,
        LPAD(REGEXP_REPLACE(COALESCE(project_id, ''), '[^0-9]', ''), 3, '0') AS project_id,
        TRIM(client_id) AS client_id,
        CAST(REPLACE(REPLACE(TRIM(invoice_amount), '$', ''), ',', '') AS DECIMAL(12,2)) AS invoice_amount,
        TRIM(status) AS status,
        last_updated_at
    FROM invoices
    WHERE project_id IS NOT NULL
      AND COALESCE(TRIM(status), '') <> 'Voided'
),

dedup_invoices AS (
    SELECT *
    FROM (
        SELECT
            ci.*,
            ROW_NUMBER() OVER (
                PARTITION BY invoice_id
                ORDER BY last_updated_at DESC
            ) AS rn
        FROM cleaned_invoices ci
    ) x
    WHERE rn = 1
),

revenue AS (
    SELECT
        project_id,
        SUM(invoice_amount) AS total_revenue
    FROM dedup_invoices
    GROUP BY project_id
),

project_profitability AS (
    SELECT
        p.project_id,
        p.project_name,
        p.client_id,
        p.budget_amount,
        COALESCE(t.total_hours, 0) AS total_hours,
        COALESCE(t.total_cost, 0) AS total_cost,
        COALESCE(r.total_revenue, 0) AS total_revenue,
        COALESCE(r.total_revenue, 0) - COALESCE(t.total_cost, 0) AS gross_margin
    FROM latest_projects p
    LEFT JOIN time_costs t
        ON p.project_id = t.project_id
    LEFT JOIN revenue r
        ON p.project_id = r.project_id
)

/* Core Task 3 - Question 1: Project profitability */
SELECT
    project_id,
    project_name,
    client_id,
    budget_amount,
    total_hours,
    total_cost,
    total_revenue,
    gross_margin
FROM project_profitability
ORDER BY project_id;

/* Core Task 3 - Question 2: Projects where total cost exceeds budget */
SELECT
    project_id,
    project_name,
    budget_amount,
    total_cost,
    total_revenue,
    gross_margin
FROM project_profitability
WHERE total_cost > budget_amount
ORDER BY total_cost DESC;

/* Stretch Task 1: Top 3 clients by revenue */
SELECT
    client_id,
    SUM(total_revenue) AS client_revenue
FROM project_profitability
GROUP BY client_id
ORDER BY client_revenue DESC
LIMIT 3;
