--1.create database and tables
CREATE DATABASE "advanced_Lab";

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INTEGER,
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

--2. INSERT with column specification
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (101, 'Alex', 'Smith', 'IT');

--3. INSERT with DEFAULT values
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('John', 'Doe', 'HR', DEFAULT, '2023-01-15', DEFAULT);

--4. INSERT multiple rows in single statement
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
    ('IT', 150000, 1),
    ('HR', 80000, 2),
    ('Sales', 120000, 3);

--5. INSERT with expressions
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Anna', 'Taylor', 'Finance', 50000 * 1.1, CURRENT_DATE);

--6. INSERT from SELECT (subquery)
CREATE TEMP TABLE temp_employees AS SELECT * FROM employees WHERE 1=0;

INSERT INTO temp_employees
SELECT * FROM employees
WHERE department = 'IT';

--7. UPDATE with arithmetic expressions
UPDATE employees
SET salary = salary * 1.1
WHERE emp_id > 0;

--8. UPDATE with WHERE clause and multiple conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

--9. UPDATE using CASE expression
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END
WHERE emp_id > 0;

--10. UPDATE with DEFAULT
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

--11. UPDATE with subquery
UPDATE departments d
SET budget = (
    SELECT AVG(salary) * 1.2
    FROM employees e
    WHERE e.department = d.dept_name
)
WHERE EXISTS (
    SELECT 1 FROM employees e WHERE e.department = d.dept_name
);

--12. UPDATE multiple columns
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

--Part D: Advanced DELETE Operations

--13. DELETE with simple WHERE condition
DELETE FROM employees
WHERE status = 'Terminated';

--14. DELETE with complex WHERE clause
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

--15. DELETE with subquery
DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT dept_id
    FROM employees
    WHERE department IS NOT NULL
);

--16. DELETE with RETURNING clause
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

--Part E: Operations with NULL Values

--17. INSERT with NULL values
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Mike', 'Brown', NULL, NULL);

--18. UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

--19. DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

--Part F: RETURNING Clause Operations

--20. INSERT with RETURNING
INSERT INTO employees (first_name, last_name, department, salary)
VALUES ('Elena', 'Gilbert', 'IT', 65000)
RETURNING emp_id, (first_name || ' ' || last_name) AS full_name;

--21. UPDATE with RETURNING
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, (salary - 5000) AS old_salary, salary AS new_salary;

--22. DELETE with RETURNING all columns
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

--Part G: Advanced DML Patterns

--23. Conditional INSERT
INSERT INTO employees (first_name, last_name, department, salary)
SELECT 'David', 'Miller', 'Finance', 55000
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'David' AND last_name = 'Miller'
);

--24. UPDATE with JOIN logic using subqueries
UPDATE employees e
SET salary = CASE
    WHEN (SELECT budget FROM departments d WHERE d.dept_name = e.department) > 100000
    THEN salary * 1.10
    ELSE salary * 1.05
END
WHERE department IS NOT NULL;

--25. Bulk operations
INSERT INTO employees (first_name, last_name, department, salary)
VALUES
    ('John', 'Smith', 'IT', 40000),
    ('Alice', 'Smith', 'IT', 42000),
    ('Robert', 'Smith', 'HR', 45000),
    ('Emily', 'Smith', 'Sales', 48000),
    ('Michael', 'Smith', 'Sales', 50000);

UPDATE employees
SET salary = salary * 1.10
WHERE last_name = 'Smith';

--26. Data migration simulation
CREATE TABLE IF NOT EXISTS employee_archive (LIKE employees INCLUDING ALL);

INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

--27. Complex business logic
UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000 AND dept_id IN (
    SELECT d.dept_id
    FROM departments d
    JOIN employees e ON e.department = d.dept_name
    GROUP BY d.dept_id
    HAVING COUNT(e.emp_id) > 3
);