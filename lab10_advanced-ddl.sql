
-- LAB WORK №10 — SQL TRANSACTIONS AND ISOLATION LEVELS



-- 3.1

DROP TABLE IF EXISTS accounts;
DROP TABLE IF EXISTS products;

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10,2) DEFAULT 0
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

INSERT INTO accounts (name, balance) VALUES
('Alice', 1000),
('Bob', 500),
('Wally', 750);

INSERT INTO products (shop, product, price) VALUES
('Joe''s Shop', 'Coke', 2.50),
('Joe''s Shop', 'Pepsi', 3.00);




-- 3.2
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob';
COMMIT;

-- a) Final balances:
-- Alice = 900
-- Bob   = 600

-- b) Why group in one transaction?
-- Because transferring money must be atomic:
-- Either both updates succeed or both fail.

-- c) What happens if crash occurs between updates without transaction?
-- Alice may lose money (−100) while Bob never receives it.
-- Database becomes inconsistent.



-- 3.3

BEGIN;
UPDATE accounts SET balance = balance - 500 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';  -- shows 500 (temporary)
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';  -- shows 1000 again

-- a) After UPDATE but before ROLLBACK: 500
-- b) After ROLLBACK: 1000 (original balance)
-- c) We use ROLLBACK when an error happens or wrong data was entered.
-- For example: wrong amount, failed validation, unexpected system error.




-- 3.4
BEGIN;

UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';  -- Alice = 900
SAVEPOINT my_savepoint;

UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob';     -- Bob = 600 (temporary)
ROLLBACK TO my_savepoint;                                           -- Bob = back to 500

UPDATE accounts SET balance = balance + 100 WHERE name = 'Wally';   -- Wally = 850

COMMIT;

-- a) Final balances:
-- Alice = 900
-- Bob   = 500
-- Wally = 850

-- b) Was Bob ever credited?
-- Yes, temporarily, but after ROLLBACK TO SAVEPOINT his update was undone.

-- c) Why SAVEPOINT?
-- Allows partial rollback inside one transaction without losing full progress.



-- 3.5

-- SCENARIO A — READ COMMITTED
-- Terminal 1:
-- BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- SELECT * FROM products WHERE shop='Joe''s Shop';
-- (Shows Coke, Pepsi)
--
-- Terminal 2:
-- BEGIN;
-- DELETE FROM products WHERE shop='Joe''s Shop';
-- INSERT INTO products VALUES (DEFAULT, 'Joe''s Shop', 'Fanta', 3.50);
-- COMMIT;
--
-- Terminal 1 (again):
-- SELECT * FROM products WHERE shop='Joe''s Shop';
-- (Shows Fanta)

-- a) Terminal 1 sees:
-- Before: Coke, Pepsi
-- After:  Fanta


-- SCENARIO B — SERIALIZABLE
-- Terminal 1 executes same code but SERIALIZABLE
-- It will either:
-- 1) See the old rows (Coke, Pepsi), or
-- 2) Get a SERIALIZATION FAILURE

-- b) Terminal 1 DOES NOT see the new Fanta row.


-- c) Difference:
-- READ COMMITTED → sees new committed data.
-- SERIALIZABLE   → acts like it runs alone; no changes become visible.



-- 3.6

-- Terminal 1:
-- BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- SELECT MAX(price), MIN(price) FROM products WHERE shop='Joe''s Shop';

-- Terminal 2:
-- INSERT INTO products VALUES (DEFAULT, 'Joe''s Shop', 'Sprite', 4.00);
-- COMMIT;

-- Terminal 1 again:
-- SELECT MAX(price), MIN(price) FROM products WHERE shop='Joe''s Shop';

-- a) Terminal 1 does NOT see Sprite.
-- b) Phantom read = new rows appear between two SELECTs.
-- c) SERIALIZABLE is the only level that prevents phantom reads.



--3.7
-- Terminal 1:
-- BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- SELECT * FROM products;
-- (wait for Terminal 2)

-- Terminal 2:
-- BEGIN;
-- UPDATE products SET price = 99.99 WHERE product='Fanta';
-- (do NOT commit)
-- (wait)

-- Terminal 1:
-- SELECT * FROM products;  -- sees uncommitted 99.99 (dirty read)

-- Terminal 2:
-- ROLLBACK;

-- Terminal 1 again:
-- SELECT * FROM products; -- sees old value again

-- a) Yes, Terminal 1 saw price = 99.99 → dangerous, invalid data.
-- b) Dirty read = reading uncommitted data from another transaction.
-- c) READ UNCOMMITTED is unsafe and almost never used.



-- ============================================================
-- INDEPENDENT EXERCISES


--Exercise 1

BEGIN;

-- Lock Bob's row
SELECT balance FROM accounts WHERE name='Bob' FOR UPDATE;

-- Check funds
DO $$
DECLARE bal DECIMAL;
BEGIN
    SELECT balance INTO bal FROM accounts WHERE name='Bob';
    IF bal < 200 THEN
        RAISE EXCEPTION 'Insufficient funds';
    END IF;
END $$;

-- Perform transfer
UPDATE accounts SET balance = balance - 200 WHERE name='Bob';
UPDATE accounts SET balance = balance + 200 WHERE name='Wally';

COMMIT;

-- Final explanation:
-- If Bob < 200 → exception → rollback.



--Exercise 2

BEGIN;

INSERT INTO products (shop, product, price)
VALUES ('Tech Store', 'Mouse', 10.00);
SAVEPOINT s1;

UPDATE products SET price = 12.00
WHERE product = 'Mouse';
SAVEPOINT s2;

DELETE FROM products WHERE product='Mouse';

ROLLBACK TO s1;
COMMIT;

-- Final state:
-- Product 'Mouse' EXISTS with price = 10.00.



--exercise 3

-- Explanation (no code needed):
-- READ COMMITTED:
--   Both users may read the same initial balance → double withdraw possible.
--
-- SERIALIZABLE:
--   Second transaction fails with a serialization error → prevents overdraft.



--exercise 4

-- WRONG (without transactions)
-- User A: SELECT MAX(price) ...
-- User B: DELETE some products
-- User A: SELECT MIN(price) ...
-- → MAX < MIN because queries see different snapshots

-- CORRECT (with transaction)
-- BEGIN;
-- SELECT MAX(price), MIN(price) FROM Sells;
-- (both values come from same consistent snapshot)
-- COMMIT;



-- ============================================================
-- SELF-ASSESSMENT ANSWERS


-- 1. ACID:
-- A: atomicity → money transfer all or nothing
-- C: consistency → constraints intact
-- I: isolation → transactions behave as if alone
-- D: durability → survives crashes

-- 2. COMMIT saves, ROLLBACK cancels.

-- 3. SAVEPOINT is used for partial rollback.

-- 4. Isolation:
-- RU → dirty reads
-- RC → non-repeatable reads
-- RR → phantom reads possible
-- S  → no anomalies

-- 5. Dirty read allowed only in READ UNCOMMITTED.

-- 6. Non-repeatable read: same SELECT shows different values.

-- 7. Phantom read: new rows appear; prevented only by SERIALIZABLE.

-- 8. READ COMMITTED used in high traffic for performance.

-- 9. Transactions keep DB consistent during concurrency.

-- 10. Uncommitted changes are discarded on crash.

