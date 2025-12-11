-- CLEANUP
DROP MATERIALIZED VIEW IF EXISTS mv_salary_batch_summary;
DROP VIEW IF EXISTS suspicious_activity_view CASCADE;
DROP VIEW IF EXISTS daily_transaction_report CASCADE;
DROP VIEW IF EXISTS customer_balance_summary CASCADE;
DROP FUNCTION IF EXISTS process_salary_batch(TEXT, JSONB);
DROP FUNCTION IF EXISTS process_transfer(TEXT, TEXT, NUMERIC, TEXT, TEXT);
DROP FUNCTION IF EXISTS audit_insert(TEXT,TEXT,TEXT,JSONB,JSONB);
DROP FUNCTION IF EXISTS get_latest_rate(CHAR(3),CHAR(3));
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- CUSTOMERS
CREATE TABLE customers(
    customer_id SERIAL PRIMARY KEY,
    iin VARCHAR(12) UNIQUE,
    full_name TEXT,
    phone TEXT,
    email TEXT,
    status TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    daily_limit_kzt NUMERIC
);

-- ACCOUNTS
CREATE TABLE accounts(
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    account_number TEXT UNIQUE,
    currency CHAR(3),
    balance NUMERIC,
    is_active BOOLEAN DEFAULT true,
    opened_at TIMESTAMPTZ DEFAULT now(),
    closed_at TIMESTAMPTZ
);

-- EXCHANGE RATES
CREATE TABLE exchange_rates(
    rate_id SERIAL PRIMARY KEY,
    from_currency CHAR(3),
    to_currency CHAR(3),
    rate NUMERIC,
    valid_from TIMESTAMPTZ,
    valid_to TIMESTAMPTZ
);

-- TRANSACTIONS
CREATE TABLE transactions(
    transaction_id BIGSERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount NUMERIC,
    currency CHAR(3),
    exchange_rate NUMERIC,
    amount_kzt NUMERIC,
    type TEXT,
    status TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    description TEXT
);

-- AUDIT LOG
CREATE TABLE audit_log(
    log_id BIGSERIAL PRIMARY KEY,
    table_name TEXT,
    record_id TEXT,
    action TEXT,
    old_values JSONB,
    new_values JSONB,
    changed_by TEXT,
    changed_at TIMESTAMPTZ DEFAULT now(),
    ip_address TEXT
);

-- INSERT CUSTOMERS
INSERT INTO customers(iin, full_name, phone, email, status, daily_limit_kzt)
VALUES
('111111111111','Ismuhanov Anuar','+77770000001','anuar@kbtu.kz','active',5000000),
('222222222222','Olhabay Kuanysh','+77770000002','kuanysh@kbtu.kz','active',5000000),
('333333333333','Mukushev Islam','+77770000003','islam@kbtu.kz','active',8000000),
('444444444444','Siyazbek Didar','+77770000004','didar@kbtu.kz','active',6000000),
('555555555555','Slambek Daniel','+77770000005','daniel@kbtu.kz','active',4000000),
('666666666666','Jude Bellingham','+77770000006','bellingham@kbtu.kz','active',9000000),
('777777777777','Sachkov Ilyia','+77770000007','ilyia@kbtu.kz','active',3000000),
('888888888888','Student One','+77770000008','one@kbtu.kz','active',2000000),
('999999999999','DArkhan','+77770000009','two@kbtu.kz','active',2000000),
('101010101010','Saitama','+77770000010','three@kbtu.kz','active',5000000);

-- ACCOUNTS
INSERT INTO accounts(customer_id, account_number, currency, balance)
VALUES
(1,'ACC001KZT','KZT',2000000),
(2,'ACC002KZT','KZT',1500000),
(3,'ACC003USD','USD',3000),
(4,'ACC004KZT','KZT',700000),
(5,'ACC005EUR','EUR',900),
(6,'ACC006KZT','KZT',10000000),
(7,'ACC007RUB','RUB',200000),
(8,'ACC008KZT','KZT',500000),
(9,'ACC009USD','USD',1500),
(10,'ACC010KZT','KZT',250000);

-- EXCHANGE RATES
INSERT INTO exchange_rates(from_currency,to_currency,rate,valid_from,valid_to)
VALUES
('USD','KZT',470,now(),null),
('EUR','KZT',505,now(),null),
('RUB','KZT',5.5,now(),null),
('KZT','USD',1/470,now(),null),
('KZT','EUR',1/505,now(),null);

-- INDEXES
CREATE INDEX idx_acc_num ON accounts(account_number);
CREATE INDEX idx_cust_iin_hash ON customers USING HASH(iin);
CREATE INDEX idx_email_ci ON customers(lower(email));
CREATE INDEX idx_acc_active ON accounts(customer_id) WHERE is_active = true;
CREATE INDEX idx_tx_from_time ON transactions(from_account_id,created_at DESC);
CREATE INDEX idx_audit_new_gin ON audit_log USING GIN(new_values jsonb_path_ops);
CREATE INDEX idx_audit_old_gin ON audit_log USING GIN(old_values jsonb_path_ops);

-- RATE FUNCTION
CREATE OR REPLACE FUNCTION get_latest_rate(f CHAR(3), t CHAR(3))
RETURNS NUMERIC AS $$
DECLARE r NUMERIC;
BEGIN
    IF f=t THEN RETURN 1; END IF;
    SELECT rate INTO r FROM exchange_rates
    WHERE from_currency=f AND to_currency=t
    ORDER BY valid_from DESC LIMIT 1;
    IF r IS NOT NULL THEN RETURN r; END IF;
    SELECT rate INTO r FROM exchange_rates
    WHERE from_currency=t AND to_currency=f
    ORDER BY valid_from DESC LIMIT 1;
    IF r IS NOT NULL THEN RETURN 1/r; END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- AUDIT FUNCTION
CREATE OR REPLACE FUNCTION audit_insert(t TEXT, id TEXT, act TEXT, o JSONB, n JSONB)
RETURNS VOID AS $$
BEGIN
    INSERT INTO audit_log(table_name,record_id,action,old_values,new_values)
    VALUES(t,id,act,o,n);
END;
$$ LANGUAGE plpgsql;

-- FIXED process_transfer
CREATE OR REPLACE FUNCTION process_transfer(
    p_from_account_number TEXT,
    p_to_account_number   TEXT,
    p_amount              NUMERIC,
    p_currency            CHAR(3),
    p_desc                TEXT
) RETURNS JSONB AS $$
DECLARE
    v_from accounts%ROWTYPE;
    v_to   accounts%ROWTYPE;
    v_sender customers%ROWTYPE;
    v_rate NUMERIC;
    v_amount_kzt NUMERIC;
    v_txid BIGINT := NULL;
    v_daily_sum NUMERIC;
    v_conv NUMERIC;
BEGIN
    IF p_amount <= 0 THEN
        RETURN jsonb_build_object('status','error','code','INVALID_AMOUNT');
    END IF;

    SELECT * INTO v_from FROM accounts WHERE account_number = p_from_account_number FOR UPDATE;
    IF NOT FOUND THEN RETURN jsonb_build_object('status','error','code','FROM_ACCOUNT_NOT_FOUND'); END IF;

    SELECT * INTO v_to FROM accounts WHERE account_number = p_to_account_number FOR UPDATE;
    IF NOT FOUND THEN RETURN jsonb_build_object('status','error','code','TO_ACCOUNT_NOT_FOUND'); END IF;

    IF NOT v_from.is_active THEN RETURN jsonb_build_object('status','error','code','FROM_ACCOUNT_INACTIVE'); END IF;
    IF NOT v_to.is_active THEN RETURN jsonb_build_object('status','error','code','TO_ACCOUNT_INACTIVE'); END IF;

    SELECT * INTO v_sender FROM customers WHERE customer_id = v_from.customer_id;
    IF v_sender.status <> 'active' THEN
        RETURN jsonb_build_object('status','error','code','SENDER_NOT_ACTIVE');
    END IF;

    v_rate := get_latest_rate(p_currency,'KZT');
    IF v_rate IS NULL THEN RETURN jsonb_build_object('status','error','code','RATE_NOT_FOUND'); END IF;

    v_amount_kzt := p_amount * v_rate;

    SELECT COALESCE(SUM(t.amount_kzt),0) INTO v_daily_sum
    FROM transactions t
    JOIN accounts a ON t.from_account_id=a.account_id
    WHERE a.customer_id=v_from.customer_id
      AND t.created_at::date = now()::date
      AND t.status IN ('pending','completed');

    IF v_daily_sum + v_amount_kzt > v_sender.daily_limit_kzt THEN
        RETURN jsonb_build_object('status','error','code','DAILY_LIMIT_EXCEEDED');
    END IF;

    IF v_from.currency = p_currency THEN
        IF v_from.balance < p_amount THEN
            RETURN jsonb_build_object('status','error','code','INSUFFICIENT_FUNDS');
        END IF;
    ELSE
        v_conv := get_latest_rate(p_currency, v_from.currency);
        IF v_conv IS NULL OR v_from.balance < p_amount * v_conv THEN
            RETURN jsonb_build_object('status','error','code','INSUFFICIENT_FUNDS');
        END IF;
    END IF;

    SAVEPOINT sp_transfer;

    BEGIN
        INSERT INTO transactions(
            from_account_id,to_account_id,amount,currency,
            exchange_rate,amount_kzt,type,status,created_at,description
        )
        VALUES(
            v_from.account_id,v_to.account_id,
            p_amount,p_currency,v_rate,v_amount_kzt,
            'transfer','pending',now(),p_desc
        )
        RETURNING transaction_id INTO v_txid;

        IF v_from.currency = p_currency THEN
            UPDATE accounts SET balance = balance - p_amount WHERE account_id = v_from.account_id;
        ELSE
            v_conv := get_latest_rate(p_currency,v_from.currency);
            UPDATE accounts SET balance = balance - (p_amount*v_conv) WHERE account_id = v_from.account_id;
        END IF;

        IF v_to.currency = p_currency THEN
            UPDATE accounts SET balance = balance + p_amount WHERE account_id = v_to.account_id;
        ELSE
            v_conv := get_latest_rate(p_currency,v_to.currency);
            UPDATE accounts SET balance = balance + (p_amount*v_conv) WHERE account_id = v_to.account_id;
        END IF;

        UPDATE transactions SET status='completed',completed_at=now()
        WHERE transaction_id=v_txid;

        PERFORM audit_insert(
            'transactions',v_txid::text,'INSERT',
            NULL,
            (SELECT to_jsonb(t) FROM transactions t WHERE t.transaction_id=v_txid)
        );

        RELEASE SAVEPOINT sp_transfer;

        RETURN jsonb_build_object('status','ok','transaction_id',v_txid);
EXCEPTION WHEN OTHERS THEN
    -- Обновляем статус транзакции, если она была создана
    IF v_txid IS NOT NULL THEN
        UPDATE transactions
        SET status = 'failed',
            completed_at = now()
        WHERE transaction_id = v_txid;
    END IF;

    PERFORM audit_insert(
        'transactions', NULL, 'FAILED',
        NULL, jsonb_build_object('error', SQLERRM,'desc',p_desc)
    );

    RETURN jsonb_build_object('status','error','message',SQLERRM);

    END;
END;
$$ LANGUAGE plpgsql;

-- FIXED process_salary_batch
CREATE OR REPLACE FUNCTION process_salary_batch(acc TEXT, js JSONB)
RETURNS JSONB AS $$
DECLARE
    company accounts%ROWTYPE;
    row JSONB;
    total NUMERIC:=0;
    succ INT:=0;
    fail INT:=0;
    failjson JSONB:='[]';
    cust customers%ROWTYPE;
    acc_t accounts%ROWTYPE;
    tx BIGINT := NULL;
BEGIN
    SELECT * INTO company FROM accounts WHERE account_number=acc FOR UPDATE;
    IF NOT FOUND THEN RETURN '{"error":"company not found"}'; END IF;

    FOR row IN SELECT * FROM jsonb_array_elements(js)
    LOOP
        total := total + (row->>'amount')::numeric;
    END LOOP;

    IF company.balance < total THEN
        RETURN '{"error":"not enough money"}';
    END IF;

    FOR row IN SELECT * FROM jsonb_array_elements(js)
    LOOP
        SELECT * INTO cust FROM customers WHERE iin = row->>'iin';
        IF NOT FOUND THEN
            fail:=fail+1;
            failjson:=failjson||jsonb_build_object('iin',row->>'iin');
            CONTINUE;
        END IF;

        SELECT * INTO acc_t FROM (
            SELECT * FROM accounts WHERE customer_id=cust.customer_id LIMIT 1
        ) sub;

        INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status)
        VALUES(company.account_id,acc_t.account_id,
               (row->>'amount')::numeric,acc_t.currency,
               get_latest_rate(acc_t.currency,'KZT'),
               (row->>'amount')::numeric*get_latest_rate(acc_t.currency,'KZT'),
               'transfer','completed')
        RETURNING transaction_id INTO tx;

        UPDATE accounts SET balance = balance - (row->>'amount')::numeric
        WHERE account_id=company.account_id;

        UPDATE accounts SET balance = balance + (row->>'amount')::numeric
        WHERE account_id=acc_t.account_id;

        succ:=succ+1;
    END LOOP;

    RETURN jsonb_build_object('success',succ,'failed',fail,'details',failjson);
END;
$$ LANGUAGE plpgsql;

-- VIEWS
CREATE VIEW customer_balance_summary AS
SELECT c.customer_id,c.full_name,a.account_number,a.currency,a.balance,
       (a.balance*get_latest_rate(a.currency,'KZT')) AS balance_kzt,
       SUM(a.balance*get_latest_rate(a.currency,'KZT'))
         OVER(PARTITION BY c.customer_id) AS total_kzt
FROM customers c JOIN accounts a USING(customer_id);

CREATE VIEW daily_transaction_report AS
SELECT created_at::date AS day,type,
       COUNT(*) AS cnt,
       SUM(amount_kzt) AS total_kzt
FROM transactions
GROUP BY day,type;

CREATE VIEW suspicious_activity_view
WITH(security_barrier=true) AS
SELECT * FROM transactions WHERE amount_kzt >= 5000000;

-- MATERIALIZED VIEW
CREATE MATERIALIZED VIEW mv_salary_batch_summary AS
SELECT created_at::date AS day, COUNT(*) AS cnt, SUM(amount_kzt) AS total_kzt
FROM transactions
GROUP BY day
ORDER BY day DESC;
