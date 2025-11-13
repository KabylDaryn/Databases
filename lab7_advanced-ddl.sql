---create tables
DROP TABLE IF EXISTS employees;
CREATE TABLE employees(
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT ,
    salary DECIMAL(10,2 )
);DROP TABLE IF EXISTS departments CASCADE ;
CREATE TABLE departments(
    dept_id INT PRIMARY KEY ,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);
DROP TABLE IF EXISTS projects CASCADE ;
CREATE TABLE projects (
    project_id INT PRIMARY KEY ,
    project_name VARCHAR(50),
    dept_id INT,
    budget DECIMAL(10,2)
);
---step 1.2 insert sample data
INSERT INTO employees (emp_id,emp_name,dept_id,salary) VALUES (1,'John Smith',101,50000),(2,'Jana Doe',102,60000),(3,'Mike Johnson', 101,55000),(4,'Sarah Williams',103,65000),(5,'Tom Brown',NULL,45000);
INSERT INTO departments (dept_id , dept_name , location ) VALUES(101,'IT','Building A'),(102,'HR','Building B'),(103, 'Finance','Building C'),(104 , 'Marketing','Building D');
INSERT INTO projects (project_id,project_name,dept_id,budget) VALUES (1,'Website Redesign',101,100000),(2 , 'Employee training',102,50000),(3,'Budget Analysis',103,75000),(4,'Cloud Migration',101,150000),(5,'AI Research',NULL,200000);
SELECT * FROM employees;
---PART 2
---2.1
CREATE VIEW employee_details AS
    SELECT e.emp_name , e.salary, d.dept_name, d.location
FROM employees e
LEFT JOIN departments d ON e.dept_id=d.dept_id
WHERE d.dept_id IS NOT NULL;
SELECT * FROM employee_details;

---2.2
DROP VIEW IF EXISTS dept_statistics;
CREATE VIEW dept_statistics AS
    SELECT d.dept_name , COUNT( e.emp_id) AS employee_count ,COALESCE(AVG(e.salary),0)  AS average_salary,COALESCE(max(e.salary),0) AS max_salary ,COALESCE( min(e.salary),0) AS min_salary
FROM employees  e
LEFT JOIN departments d ON e.dept_id=d.dept_id
GROUP BY d.dept_name ;
SELECT * FROM dept_statistics
ORDER BY employee_count DESC;

---2.3
DROP VIEW IF EXISTS project_overview;
CREATE VIEW project_overview AS
    SELECT p.project_name, p.budget, d.dept_name , d.location , COUNT(DISTINCT e.emp_id) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id=d.dept_id
LEFT JOIN employees e ON d.dept_id=e.dept_id
GROUP BY p.project_name, p.budget, d.dept_name, d.location ;
SELECT * FROM project_overview;

---2.4
DROP VIEW IF EXISTS high_earners;
CREATE VIEW high_earners AS
    SELECT e.emp_name , e.salary , d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id=d.dept_id
WHERE e.salary>55000;
SELECT * FROM high_earners;

---PART 3
---3.1
DROP VIEW IF EXISTS employee_details;
CREATE VIEW employee_details AS
    SELECT e.emp_name , e.salary, d.dept_name, d.location,
    CASE
        WHEN e.salary>60000 THEN 'high'
        WHEN e.salary>50000 THEN 'medium'
        ELSE 'standard'
    END AS salary_grade
FROM employees e
JOIN departments d ON e.dept_id=d.dept_id
WHERE d.dept_id IS NOT NULL;
SELECT * FROM employee_details;

---3.2
ALTER VIEW high_earners RENAME TO top_performance;
SELECT * FROM top_performance;

---3.3
CREATE TEMPORARY VIEW temp_view AS
    SELECT e.emp_name , e.salary
FROM employees e
WHERE e.salary<50000;
SELECT * FROM temp_view;
DROP VIEW IF EXISTS temp_view;

---PART 4
---4.1
DROP VIEW IF EXISTS employee_salaries;
CREATE VIEW employee_salaries AS
    SELECT emp_id , emp_name , dept_id ,salary
FROM employees ;
---4.2
UPDATE employee_salaries SET salary =52000 WHERE emp_name='John Smith';
SELECT * FROM employee_salaries WHERE emp_name='John Smith';
---4.3
INSERT INTO employee_salaries VALUES (6,'Alice Johnson',102,58000);
SELECT * FROM employee_salaries;

--4.4
DROP VIEW IF EXISTS it_employees;
CREATE  VIEW it_employees AS
    SELECT  emp_id , emp_name ,dept_id, salary
FROM employees
WHERE dept_id=101
WITH LOCAL CHECK OPTION ;
INSERT INTO it_employees (emp_id, emp_name, dept_id, salary)
VALUES (7, 'Bob Wilson', 103, 60000);
---Question Answer: You'll receive an error similar to:ERROR: new row violates check option for view "it_employees"
--DETAIL: Failing row contains (7, 'Bob Wilson', 103, 60000).


---PART 5
---5.1
DROP MATERIALIZED VIEW  IF EXISTS dept_summary_mv;
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id, d.dept_name , SUM(e.emp_id) AS total_employees,COALESCE(SUM(e.salary),0) AS total_salaries , SUM(p.project_id )AS total_projects,COALESCE(SUM(p.budget),0) AS total_budget
FROM departments d
LEFT JOIN employees e ON d.dept_id=e.dept_id
LEFT JOIN projects p on d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;
SELECT * FROM dept_summary_mv ORDER BY total_employees DESC;
---5.2
INSERT INTO employees VALUES (8,'Charlie Brown',101,54000);
SELECT * FROM dept_summary_mv WHERE dept_id=101;
REFRESH MATERIALIZED VIEW dept_summary_mv;
SELECT * FROM dept_summary_mv WHERE dept_id=101;

---5.3
CREATE UNIQUE INDEX ind_dept_summary_mv ON dept_summary_mv (dept_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
---Question Answer: The CONCURRENTLY option allows the materialized view to be queried while it's being refreshed, but it requires a unique index and takes longer to complete.

---5.4
CREATE MATERIALIZED VIEW project_stats_mv  AS
    SELECT p.project_name  ,p.budget, d.dept_name , COUNT(e.emp_id) AS assigned_employees
FROM projects p
JOIN departments d ON p.dept_id=d.dept_id
LEFT JOIN employees e ON d.dept_id=e.dept_id
GROUP BY p.project_name, p.budget, d.dept_name
WITH NO DATA;
SELECT * FROM project_stats_mv;
---Question Answer: You'll get an error like:
----ERROR: materialized view "project_stats_mv" has not been populated
----HINT: Use the REFRESH MATERIALIZED VIEW command.
---how to fix it :
REFRESH MATERIALIZED VIEW project_stats_mv;
SELECT * FROM project_stats_mv;

---PART 6
---6.1
CREATE ROLE analyst NOLOGIN ;
CREATE ROLE data_viewer WITH LOGIN PASSWORD 'viewer123';
CREATE USER  report_user WITH  PASSWORD 'report456';
SELECT rolname FROM pg_roles WHERE rolname NOT LIKE 'pg_%';

---6.2
CREATE ROLE db_creator WITH CREATEDB LOGIN PASSWORD 'creator789';
CREATE ROLE user_manager  WITH CREATEROLE LOGIN PASSWORD 'manager101';
CREATE ROLE admin_user WITH SUPERUSER LOGIN PASSWORD 'admin999';
---6.3
GRANT SELECT ON employees,departments , projects TO analyst;
GRANT ALL PRIVILEGES  ON employee_details TO data_viewer;
GRANT SELECT ,INSERT ON employees TO report_user;
---6.4
CREATE ROLE hr_team ;
CREATE ROLE finance_team ;
CREATE ROLE it_team;
CREATE USER hr_user1 WITH PASSWORD 'hr001';
CREATE USER hr_user2 WITH PASSWORD 'hr002';
CREATE USER finance_user1 WITH PASSWORD 'fim001';
GRANT hr_team TO hr_user1 , hr_user2;
GRANT finance_team TO finance_user1;
GRANT SELECT , UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

---6.5
REVOKE UPDATE on employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

---6.6
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER ;
ALTER ROLE analyst WITH PASSWORD NULL;
ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;

---PART 7
---7.1
CREATE ROLE read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO  read_only;
CREATE ROLE  junior_analyst WITH PASSWORD 'junior123';
CREATE ROLE senior_analyst WITH PASSWORD 'senior123';
GRANT read_only TO junior_analyst , senior_analyst;
GRANT INSERT , UPDATE ON employees TO senior_analyst;

---7.2
CREATE ROLE project_manager WITH LOGIN PASSWORD 'pm123';
ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

SELECT tablename, tableowner FROM pg_tables WHERE schemaname='public';

---7.3
CREATE ROLE temp_owner WITH LOGIN ;
CREATE TABLE temp_table(temp_id INT );
ALTER TABLE temp_table OWNER TO temp_owner;
REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

---7.4
CREATE VIEW hr_employee_view AS
    SELECT dept_id, emp_name, emp_id, salary
FROM employees
WHERE dept_id=102;
GRANT SELECT ON hr_employee_view TO hr_team;
CREATE VIEW finance_employee_view AS
    SELECT emp_id , emp_name, salary
FROM employees;
GRANT SELECT ON finance_employee_view TO finance_team;


---PART 8
---8.1
CREATE VIEW dept_dashboard AS
    SELECT d.dept_name , d.location , COUNT(e.emp_id ) AS employee_count, ROUND(COALESCE(AVG(e.salary),0),2) AS average_salary , COUNT(p.project_id )AS active_projects ,COALESCE(SUM(p.budget),0) AS total_budget ,
            CASE
        WHEN COUNT(e.emp_id) = 0 THEN 0
        ELSE ROUND(COALESCE(SUM(p.budget), 0)::DECIMAL / COUNT(e.emp_id), 2)
    END AS budget_per_employee
FROM departments d
LEFT JOIN employees e on d.dept_id = e.dept_id
LEFT JOIN projects p on d.dept_id = p.dept_id
GROUP BY d.dept_name, d.location ;

SELECT * FROM dept_dashboard ORDER BY total_budget DESC;

---8.2
ALTER TABLE projects ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
CREATE VIEW high_budget_projects AS
    SELECT p. project_id,p.project_name , p.budget , d.dept_name ,p.dept_id , p.created_date,
           CASE
               WHEN p.budget >150000 THEN 'Critical Review Required'
               WHEN p.budget >100000 THEN 'Management Approval Needed'
              ELSE 'Standard Process'
        END AS Approval_status
FROM projects p
JOIN departments d ON p.dept_id=d.dept_id
WHERE p.budget >75000;

---8.3
---level1
CREATE ROLE viewer_role ;
GRANT SELECT ON ALL TABLES  IN SCHEMA public TO viewer_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO viewer_role;

---level 2
CREATE ROLE entry_role;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees ,projects TO entry_role;

---level 3
CREATE ROLE analyst_role;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees , projects TO analyst_role;
 ---level4
 CREATE ROLE manager_role ;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

