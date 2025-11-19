-- lab_8
-- Schema + sample data (Part 1)
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    salary DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget DECIMAL(12,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments(dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees(emp_id, emp_name, dept_id, salary) VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);

INSERT INTO projects(proj_id, proj_name, budget, dept_id) VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);

-- =========================
-- Part 2: Basic Indexes
-- =========================
-- Exercise 2.1: create salary index
CREATE INDEX emp_salary_idx ON employees(salary);

-- Verify: list indexes for employees
-- SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'employees';

-- Exercise 2.2: index on foreign key
CREATE INDEX emp_dept_idx ON employees(dept_id);

-- A test query that should use emp_dept_idx (planner dependent)
-- EXPLAIN ANALYZE SELECT * FROM employees WHERE dept_id = 101;

-- Exercise 2.3: view indexes in DB (see answers for interpretation)
-- SELECT tablename, indexname, indexdef FROM pg_indexes WHERE schemaname = 'public' ORDER BY tablename, indexname;

-- =========================
-- Part 3: Multicolumn Indexes
-- =========================
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

-- Test queries (planner chooses index or not)
-- EXPLAIN ANALYZE SELECT emp_name, salary FROM employees WHERE dept_id = 101 AND salary > 52000;
-- EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 50000;

-- =========================
-- Part 4: Unique Indexes
-- =========================
ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- Test uniqueness (this will fail if uncommented)
-- INSERT INTO employees (emp_id, emp_name, dept_id, salary, email) VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');

-- UNIQUE constraint via ALTER TABLE
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

-- Confirm index for phone exists:
-- SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'employees' AND indexname LIKE '%phone%';

-- =========================
-- Part 5: Indexes and Sorting
-- =========================
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

-- Test ORDER BY
-- EXPLAIN ANALYZE SELECT emp_name, salary FROM employees ORDER BY salary DESC;

CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

-- Test
-- EXPLAIN ANALYZE SELECT proj_name, budget FROM projects ORDER BY budget NULLS FIRST;

-- =========================
-- Part 6: Indexes on Expressions
-- =========================
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

-- Test
-- EXPLAIN ANALYZE SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';

ALTER TABLE employees ADD COLUMN hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

-- Index on expression EXTRACT(YEAR FROM hire_date). Note: EXTRACT returns double precision; casting to int for better clarity:
CREATE INDEX emp_hire_year_idx ON employees(( (EXTRACT(YEAR FROM hire_date)):: int) );

-- Test
-- EXPLAIN ANALYZE SELECT emp_name, hire_date FROM employees WHERE (EXTRACT(YEAR FROM hire_date))::int = 2020;

-- =========================
-- Part 7: Managing Indexes
-- =========================
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

-- Verify rename:
-- SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

-- Drop redundant index example
DROP INDEX IF EXISTS emp_salary_dept_idx;

-- Reindex
REINDEX INDEX employees_salary_index;

-- =========================
-- Part 8: Practical Scenarios
-- =========================
-- Optimize slow query:
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
-- emp_dept_idx already created, emp_salary_desc_idx already created

-- Partial index on projects for high budgets
CREATE INDEX proj_high_budget_idx ON projects(budget) WHERE budget > 80000;

-- Analyze index usage example:
-- EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 52000;

-- =========================
-- Part 9: Index Types Comparison
-- =========================
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);

-- Test queries:
-- EXPLAIN ANALYZE SELECT * FROM projects WHERE proj_name = 'Website Redesign';
-- EXPLAIN ANALYZE SELECT * FROM projects WHERE proj_name > 'Database';

-- =========================
-- Part 10: Cleanup & Documentation
-- =========================
-- List all indexes and sizes (run in psql)
-- SELECT schemaname, tablename, indexname,
--    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
-- FROM pg_indexes
-- WHERE schemaname = 'public'
-- ORDER BY tablename, indexname;

DROP INDEX IF EXISTS proj_name_hash_idx;  -- drop hash duplicate (example)

CREATE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' as purpose
FROM pg_indexes
WHERE schemaname = 'public'
  AND indexname LIKE '%salary%';


