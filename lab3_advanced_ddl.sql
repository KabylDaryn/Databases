DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab
    WITH OWNER = postgres
    TEMPLATE = template0
    ENCODING = 'UTF8';



DROP TABLE IF EXISTS employee_archive CASCADE;
DROP TABLE IF EXISTS temp_employees CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS employees CASCADE;

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50) DEFAULT NULL,
    salary INTEGER DEFAULT 40000,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(50),
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

INSERT INTO employees (first_name, last_name, department) VALUES
('John', 'Doe', 'IT');

INSERT INTO employees (first_name, last_name) VALUES
('Anna', 'Smith');

INSERT INTO departments (dept_name, budget, manager_id) VALUES
('IT', 120000, 1),
('Sales', 90000, 2),
('HR', 60000, 3);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Mike', 'Johnson', 'Finance', (50000 * 1.1)::INTEGER, CURRENT_DATE);

CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

UPDATE employees SET salary = (salary * 1.1)::INTEGER;

UPDATE employees SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

UPDATE employees SET department = DEFAULT WHERE status = 'Inactive';

UPDATE departments d
SET budget = COALESCE(
    (SELECT (AVG(salary) * 1.2)::INTEGER FROM employees e WHERE e.department = d.dept_name),
    d.budget
);

UPDATE employees
SET salary = (salary * 1.15)::INTEGER,
    status = 'Promoted'
WHERE department = 'Sales';

DELETE FROM employees WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;

DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department FROM employees WHERE department IS NOT NULL
);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Null', 'Case', NULL, NULL);

UPDATE employees SET department = 'Unassigned' WHERE department IS NULL;

DELETE FROM employees WHERE salary IS NULL OR department IS NULL;

INSERT INTO employees (first_name, last_name, department)
VALUES ('Chris', 'Evans', 'Marketing')
RETURNING emp_id, first_name || ' ' || last_name;

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, (salary - 5000) AS old_salary, salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, department)
SELECT 'David', 'Brown', 'IT'
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'David' AND last_name = 'Brown'
);

UPDATE employees e
SET salary = (e.salary * CASE WHEN d.budget > 100000 THEN 1.1 ELSE 1.05 END)::INTEGER
FROM departments d
WHERE e.department = d.dept_name;

INSERT INTO employees (first_name, last_name, department, salary) VALUES
('E1', 'L1', 'IT', 50000),
('E2', 'L2', 'IT', 50000),
('E3', 'L3', 'IT', 50000),
('E4', 'L4', 'IT', 50000),
('E5', 'L5', 'IT', 50000);

UPDATE employees
SET salary = (salary * 1.1)::INTEGER
WHERE first_name IN ('E1','E2','E3','E4','E5');

CREATE TABLE employee_archive (LIKE employees INCLUDING ALL);

INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
FROM departments d
WHERE p.dept_id = d.dept_id
  AND p.budget > 50000
  AND (
       SELECT COUNT(*) FROM employees e WHERE e.department = d.dept_name
      ) > 3;
