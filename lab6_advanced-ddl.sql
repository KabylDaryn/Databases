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

---PART 2
---exercise 2.1
SELECT e.emp_name ,d.dept_name
FROM employees e CROSS JOIN departments d;
---employees have 5 rows ,and departments have 4 rows .calculate N*M=4*5=20 rows
---exercise 2.2
SELECT e.emp_name , d.dept_name
FROM employees e , departments d;
--- INNER JOIN with TRUE
SELECT e.emp_name,d.dept_name
FROM employees e INNER JOIN departments d ON TRUE;
---exercise 2.3
SELECT e.emp_name , p.project_name
FROM employees e CROSS JOIN  projects p;

---Part 3
---exercise 3.1
SELECT e.emp_name , d.dept_name , d.location
FROM employees e INNER JOIN departments d ON e.dept_id=d.dept_id;
---Answer: 4 rows returned. Tom Brown is not included because he has NULL dept_id.
---exercise 3.2
SELECT emp_name , dept_name , location
FROM employees
INNER JOIN departments USING (dept_id);
---Answer: The USING clause merges the two dept_id columns into one, while ON keeps both columns separate.
---exercise 3.3
SELECT emp_name , dept_name, location
FROM employees
NATURAL INNER JOIN departments;
---exercise 3.4
SELECT e.emp_name , d.dept_name , p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id=d.dept_id
INNER JOIN projects p ON d.dept_id=p.dept_id;
---PART 4.1
---exercise 4.1
SELECT e.emp_name , e.dept_id AS emp_dept ,d.dept_id AS dept_dept , d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id=d.dept_id;
---Answer: Tom Brown appears with NULL values in dept_dept and dept_name columns.
---exercise 4.2
SELECT emp_name , dept_name
FROM employees
LEFT JOIN departments USING(dept_id);
---exercise 4.3
SELECT e.emp_name , e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id =d.dept_id
WHERE d.dept_id IS NULL;
---exercise 4.4
SELECT d.dept_name , COUNT(e.emp_id ) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id=e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;
---PART 5
---exercise 5.1
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id =d.dept_id;
--- exercise 5.2
SELECT e.emp_name , d.dept_name
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id;
--- exercise 5.3
SELECT d.dept_name , d.location
FROM employees e
RIGHT JOIN departments d ON e.emp_id=d.dept_id
WHERE e.emp_id IS NULL;

---PART 6
---exercise 6.1
SELECT e.emp_name , e.dept_id AS emp_dept ,d.dept_id AS  dept_dept, d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id = d.dept_id;
---Answer: NULL on left side: departments without employees (Marketing). NULL on right side: employees without departments (Tom Brown).
---exercise 6.2
SELECT d.dept_name , p.project_name , p.budget
FROM departments d
FULL JOIN projects p ON d.dept_id = p.dept_id;

---exercise 6.3
SELECT
    CASE
        WHEN e.emp_id IS NULL THEN 'departments without employees'
        WHEN d.dept_id IS NULL THEN 'employees without departments '
    ELSE 'Matched'
    END AS record_status,
    e.emp_name ,
    d.dept_name
FROM employees e
FULL JOIN departments d ON e.dept_id =d.dept_id
WHERE e.emp_id IS NULL OR d.dept_id IS NULL;

---PART 7
---exercise 7.1
SELECT e.emp_name , d.dept_name , d.location
FROM employees e
FULL JOIN departments d ON e.dept_id=d.dept_id AND d.location='building A';
---exercise 7.2
SELECT e.emp_name , d.dept_name , d.location
FROM employees e
LEFT JOIN departments d ON e.dept_id=d.dept_id
WHERE d.location='building A';
---exercise 7.3
-- Filter in ON clause
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id AND d.location = 'Building A';

-- Filter in WHERE clause
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
---Answer: No difference in results with INNER JOIN because both queries filter to show only matching rows.

---PART 8
---exercise 8.1
SELECT d.dept_name , e.emp_name , e.salary , p.project_name , p.budget
FROM departments d
LEFT JOIN employees e ON e.dept_id=d.dept_id
RIGHT JOIN projects p ON p.dept_id=d.dept_id
ORDER BY d.dept_name , e.emp_name;
---exercise 8.2
---add column
ALTER TABLE employees ADD COLUMN manager_id INT;
---update
UPDATE employees SET manager_id=3 WHERE emp_id=1;
UPDATE employees SET manager_id=3 WHERE emp_id=2;
UPDATE employees SET manager_id=NULL  WHERE emp_id=3;
UPDATE employees SET manager_id=3 WHERE emp_id=4;
UPDATE employees SET manager_id=3 WHERE emp_id=5;
---self join
SELECT e.emp_name AS employee, m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id=e.emp_id;
---exercise 8.3
SELECT d.dept_name , AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id=e.dept_id
GROUP BY d.dept_id , d.dept_name
HAVING AVG(e.salary)>50000;
---Lab Questions - Answers
---1)INNER JOIN vs LEFT JOIN: INNER JOIN returns only matching rows from both tables. LEFT JOIN returns all rows from the left table and matching rows from the right table, with NULLs for non-matching right table rows.

---2)Practical CROSS JOIN usage: Generating all possible combinations for scheduling, availability matrices, or test data scenarios.

---3)ON vs WHERE in outer joins: In OUTER JOINs, conditions in ON affect the joining process but don't filter main table rows. Conditions in WHERE filter the final result and can remove NULL rows.

---4)CROSS JOIN result: 5 × 10 = 50 rows.

---5)NATURAL JOIN column matching: Joins on all columns with identical names in both tables.

---6)Risks of NATURAL JOIN: Schema changes can break queries or produce wrong results if new columns with same names are added.

---7)LEFT to RIGHT JOIN conversion:

-- Original: SELECT * FROM A LEFT JOIN B ON A.id = B.id
--SELECT * FROM B RIGHT JOIN A ON A.id = B.id
---8)FULL OUTER JOIN usage: When you need to see all records from both tables and identify which records have matches and which don't.

---ADDITIONAL CHALLENGES
--Challenge 1
SELECT e.emp_name , d.dept_name
FROM employees e
RIGHT JOIN  departments d ON e.dept_id=d.dept_id
UNION
SELECT e.emp_name , d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id=d.dept_id;
--Challenge 2
SELECT e.emp_name ,d.dept_name
FROM employees e
INNER JOIN departments d ON e.dept_id=d.dept_id
WHERE d.dept_id IN(
    SELECT dept_id FROM projects
    GROUP BY dept_id
    HAVING count(*)>1
    );
--Challenge 3
WITH RECURSIVE org_chart AS (
    SELECT emp_id, emp_name, manager_id, 1 as level
    FROM employees
    WHERE manager_id IS NULL
    UNION ALL
    SELECT e.emp_id, e.emp_name, e.manager_id, oc.level + 1
    FROM employees e
    INNER JOIN org_chart oc ON e.manager_id = oc.emp_id
)
SELECT emp_name, level FROM org_chart ORDER BY level, emp_name;
---Challenge 4
SELECT e1.emp_name AS employee1, e2.emp_name AS employee2, d.dept_name
FROM employees e1
INNER JOIN employees e2 ON e1.dept_id = e2.dept_id AND e1.emp_id < e2.emp_id
INNER JOIN departments d ON e1.dept_id = d.dept_id;