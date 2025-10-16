
-- Part 1: CHECK Constraints

-- Task 1.1: Basic CHECK Constraint
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS products_catalog CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS inventory CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS course_enrollments CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS student_courses CASCADE;
DROP TABLE IF EXISTS employees_dept CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS publishers CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS products_fk CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS ecommerce_customers CASCADE;
DROP TABLE IF EXISTS ecommerce_products CASCADE;
DROP TABLE IF EXISTS ecommerce_orders CASCADE;
DROP TABLE IF EXISTS ecommerce_order_details CASCADE;
CREATE TABLE employees (
    employee_id INTEGER,
    first_name TEXT,
    last_name TEXT,
    age INTEGER CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

-- Valid inserts
INSERT INTO employees VALUES (1, 'John', 'Doe', 25, 50000);
INSERT INTO employees VALUES (2, 'Jane', 'Smith', 30, 60000);

-- Invalid inserts
-- INSERT INTO employees VALUES (3, 'Bob', 'Young', 17, 45000); -- Violates age constraint (below 18)
-- INSERT INTO employees VALUES (4, 'Alice', 'Brown', 40, -1000); -- Violates salary constraint (negative salary)

-- Task 1.2: Named CHECK Constraint
CREATE TABLE products_catalog (
    product_id INTEGER,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0 AND
        discount_price > 0 AND
        discount_price < regular_price
    )
);

-- Valid inserts
INSERT INTO products_catalog VALUES (1, 'Laptop', 1000, 800);
INSERT INTO products_catalog VALUES (2, 'Mouse', 50, 40);

-- Invalid inserts
-- INSERT INTO products_catalog VALUES (3, 'Keyboard', -100, 80); -- Violates regular_price > 0
-- INSERT INTO products_catalog VALUES (4, 'Monitor', 500, -50); -- Violates discount_price > 0
-- INSERT INTO products_catalog VALUES (5, 'Speaker', 200, 250); -- Violates discount_price < regular_price

-- Task 1.3: Multiple Column CHECK
CREATE TABLE bookings (
    booking_id INTEGER,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INTEGER CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

-- Testing CHECK Constraints for bookings
-- Valid inserts
INSERT INTO bookings VALUES (1, '2024-01-15', '2024-01-20', 2);
INSERT INTO bookings VALUES (2, '2024-02-01', '2024-02-05', 4);

-- Invalid inserts
-- INSERT INTO bookings VALUES (3, '2024-03-10', '2024-03-05', 3); -- Violates check_out_date > check_in_date
-- INSERT INTO bookings VALUES (4, '2024-04-01', '2024-04-03', 0); -- Violates num_guests constraint (below 1)
-- INSERT INTO bookings VALUES (5, '2024-05-01', '2024-05-05', 12); -- Violates num_guests constraint (above 10)

-- Part 2: NOT NULL Constraints

-- Task 2.1: NOT NULL Implementation
CREATE TABLE customers (
    customer_id INTEGER NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

-- Task 2.2: Combining Constraints
CREATE TABLE inventory (
    item_id INTEGER NOT NULL,
    item_name TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

-- Task 2.3: Testing NOT NULL
-- Valid inserts
INSERT INTO customers VALUES (1, 'john@email.com', '123-456-7890', '2024-01-01');
INSERT INTO customers VALUES (2, 'jane@email.com', NULL, '2024-01-02');

INSERT INTO inventory VALUES (1, 'Widget A', 100, 19.99, '2024-01-01 10:00:00');
INSERT INTO inventory VALUES (2, 'Widget B', 50, 29.99, '2024-01-01 11:00:00');

-- Invalid inserts
-- INSERT INTO customers VALUES (NULL, 'bob@email.com', '111-222-3333', '2024-01-03'); -- Violates NOT NULL on customer_id
-- INSERT INTO customers VALUES (3, NULL, '444-555-6666', '2024-01-04'); -- Violates NOT NULL on email
-- INSERT INTO inventory VALUES (NULL, 'Widget C', 25, 39.99, '2024-01-01 12:00:00'); -- Violates NOT NULL on item_id

-- Part 3: UNIQUE Constraints

-- Task 3.1: Single Column UNIQUE
CREATE TABLE users (
    user_id INTEGER,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

-- Task 3.2: Multi-Column UNIQUE
CREATE TABLE course_enrollments (
    enrollment_id INTEGER,
    student_id INTEGER,
    course_code TEXT,
    semester TEXT,
    UNIQUE (student_id, course_code, semester)
);

-- Task 3.3: Named UNIQUE Constraints
drop table if exists inventory cascade ;
create table inventory(
    item_id integer not null,
    item_name text not null,
    quantity integer not null check(quantity >= 0),
    unit_price numeric not null check(unit_price > 0),
    last_updated timestamp not null
);DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INTEGER,
    username TEXT,
    email TEXT,
    created_at TIMESTAMP,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

INSERT INTO users VALUES (1, 'user1', 'user1@email.com', '2024-01-01 10:00:00');
INSERT INTO users VALUES (2, 'user2', 'user2@email.com', '2024-01-01 11:00:00');

-- Invalid inserts
-- INSERT INTO users VALUES (3, 'user1', 'user3@email.com', '2024-01-01 12:00:00'); -- Violates unique_username
-- INSERT INTO users VALUES (4, 'user4', 'user1@email.com', '2024-01-01 13:00:00'); -- Violates unique_email

-- Part 4: PRIMARY KEY Constraints

-- Task 4.1: Single Column Primary Key
CREATE TABLE departments (
    dept_id INTEGER PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

-- Insert departments
INSERT INTO departments VALUES (1, 'HR', 'New York');
INSERT INTO departments VALUES (2, 'IT', 'San Francisco');
INSERT INTO departments VALUES (3, 'Finance', 'Chicago');

-- Invalid inserts
-- INSERT INTO departments VALUES (1, 'Marketing', 'Boston'); -- Violates PRIMARY KEY (duplicate dept_id)
-- INSERT INTO departments VALUES (NULL, 'Sales', 'Miami'); -- Violates PRIMARY KEY (NULL dept_id)

-- Task 4.2: Composite Primary Key
CREATE TABLE student_courses (
    student_id INTEGER,
    course_id INTEGER,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

-- Task 4.3: Comparison Exercise
/*
DIFFERENCES BETWEEN UNIQUE AND PRIMARY KEY:

1. A table can have only one PRIMARY KEY but multiple UNIQUE constraints
2. PRIMARY KEY columns cannot contain NULL values, while UNIQUE columns can (unless also defined as NOT NULL)
3. PRIMARY KEY automatically creates a clustered index (in some databases), while UNIQUE creates a non-clustered index
4. PRIMARY KEY implies NOT NULL for all columns in the key

SINGLE-COLUMN VS COMPOSITE PRIMARY KEY:
- Use single-column PK when you have a natural identifier (like customer_id, product_id)
- Use composite PK when the unique identity requires multiple columns (like student_id + course_id for enrollments)

WHY ONLY ONE PRIMARY KEY:
- The primary key represents the fundamental identity of a table record
- Having multiple primary keys would create ambiguity in identifying records
- UNIQUE constraints can enforce additional uniqueness requirements without being the primary identifier
*/

-- Part 5: FOREIGN KEY Constraints

-- Task 5.1: Basic Foreign Key
CREATE TABLE employees_dept (
    emp_id INTEGER PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INTEGER REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES (101, 'Alice Johnson', 1, '2023-01-15');
INSERT INTO employees_dept VALUES (102, 'Bob Wilson', 2, '2023-02-20');

-- Invalid insert
-- INSERT INTO employees_dept VALUES (103, 'Charlie Brown', 99, '2023-03-10'); -- Violates FOREIGN KEY (dept_id 99 doesn't exist)

-- Task 5.2: Multiple Foreign Keys
-- Create library system schema

CREATE TABLE authors (
    author_id INTEGER PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INTEGER PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INTEGER REFERENCES authors(author_id),
    publisher_id INTEGER REFERENCES publishers(publisher_id),
    publication_year INTEGER,
    isbn TEXT UNIQUE
);

INSERT INTO authors VALUES (1, 'J.K. Rowling', 'UK');
INSERT INTO authors VALUES (2, 'George Orwell', 'UK');
INSERT INTO authors VALUES (3, 'Agatha Christie', 'UK');

INSERT INTO publishers VALUES (1, 'Penguin Books', 'London');
INSERT INTO publishers VALUES (2, 'HarperCollins', 'New York');
INSERT INTO publishers VALUES (3, 'Simon & Schuster', 'New York');

INSERT INTO books VALUES (1, 'Harry Potter', 1, 1, 1997, '978-0439708180');
INSERT INTO books VALUES (2, '1984', 2, 2, 1949, '978-0451524935');
INSERT INTO books VALUES (3, 'Murder on the Orient Express', 3, 3, 1934, '978-0062693662');

-- Task 5.3: ON DELETE Options
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INTEGER REFERENCES categories ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES orders ON DELETE CASCADE,
    product_id INTEGER REFERENCES products_fk,
    quantity INTEGER CHECK (quantity > 0)
);

INSERT INTO categories VALUES (1, 'Electronics');
INSERT INTO categories VALUES (2, 'Books');

INSERT INTO products_fk VALUES (1, 'Laptop', 1);
INSERT INTO products_fk VALUES (2, 'Novel', 2);

INSERT INTO orders VALUES (1, '2024-01-15');
INSERT INTO orders VALUES (2, '2024-01-16');

INSERT INTO order_items VALUES (1, 1, 1, 2);
INSERT INTO order_items VALUES (2, 1, 2, 1);
INSERT INTO order_items VALUES (3, 2, 1, 1);


-- Part 6: Practical Application - E-commerce Database Design

-- Task 6.1: E-commerce Database Schema
CREATE TABLE ecommerce_customers (
    customer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE ecommerce_products (
    product_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INTEGER CHECK (stock_quantity >= 0)
);

CREATE TABLE ecommerce_orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER REFERENCES ecommerce_customers,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE ecommerce_order_details (
    order_detail_id INTEGER PRIMARY KEY,
    order_id INTEGER REFERENCES ecommerce_orders ON DELETE CASCADE,
    product_id INTEGER REFERENCES ecommerce_products,
    quantity INTEGER CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);


INSERT INTO ecommerce_customers VALUES
(1, 'John Smith', 'john.smith@email.com', '123-456-7890', '2024-01-01'),
(2, 'Sarah Johnson', 'sarah.j@email.com', '123-456-7891', '2024-01-02'),
(3, 'Mike Davis', 'mike.davis@email.com', '123-456-7892', '2024-01-03'),
(4, 'Emily Wilson', 'emily.w@email.com', '123-456-7893', '2024-01-04'),
(5, 'David Brown', 'david.b@email.com', '123-456-7894', '2024-01-05');


INSERT INTO ecommerce_products VALUES
(1, 'Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 100),
(2, 'Mechanical Keyboard', 'RGB mechanical keyboard', 89.99, 50),
(3, 'Monitor 24"', '24 inch HD monitor', 199.99, 25),
(4, 'Laptop Stand', 'Adjustable laptop stand', 49.99, 75),
(5, 'USB-C Cable', 'High-speed USB-C cable', 19.99, 200);


INSERT INTO ecommerce_orders VALUES
(1, 1, '2024-01-10', 119.98, 'delivered'),
(2, 2, '2024-01-11', 289.98, 'processing'),
(3, 3, '2024-01-12', 69.98, 'shipped'),
(4, 4, '2024-01-13', 199.99, 'pending'),
(5, 5, '2024-01-14', 39.98, 'cancelled');


INSERT INTO ecommerce_order_details VALUES
(1, 1, 1, 2, 29.99),
(2, 1, 5, 2, 19.99),
(3, 2, 2, 2, 89.99),
(4, 2, 3, 1, 199.99),
(5, 3, 4, 1, 49.99),
(6, 3, 5, 1, 19.99),
(7, 4, 3, 1, 199.99),
(8, 5, 1, 2, 19.99);

SELECT 'Customers:' as table_name;
SELECT * FROM ecommerce_customers;

SELECT 'Products:' as table_name;
SELECT * FROM ecommerce_products;

SELECT 'Orders:' as table_name;
SELECT * FROM ecommerce_orders;

SELECT 'Order Details:' as table_name;
select * from ecommerce_order_details;
