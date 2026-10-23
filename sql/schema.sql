-- =====================================================================
-- RoadReady Auto Parts  -  CSCE 4350 Project, Phase II
-- Physical database schema (PostgreSQL 16)
-- Run:  createdb roadready && psql -d roadready -f sql/schema.sql
-- =====================================================================

DROP SCHEMA IF EXISTS roadready CASCADE;
CREATE SCHEMA roadready;
SET search_path TO roadready;

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- bcrypt password hashing (crypt / gen_salt)

-- ---------------------------------------------------------------------
-- 1. STORES AND PERSONNEL
-- ---------------------------------------------------------------------
CREATE TABLE store (
    store_id      SERIAL       PRIMARY KEY,
    store_name    VARCHAR(60)  NOT NULL UNIQUE,
    street        VARCHAR(100) NOT NULL,
    city          VARCHAR(50)  NOT NULL,
    state         CHAR(2)      NOT NULL,
    zip           VARCHAR(10)  NOT NULL CHECK (zip ~ '^[0-9]{5}(-[0-9]{4})?$'),
    phone         VARCHAR(15)  NOT NULL,
    opened_date   DATE         NOT NULL DEFAULT CURRENT_DATE,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE department (
    dept_id       SERIAL       PRIMARY KEY,
    dept_name     VARCHAR(40)  NOT NULL UNIQUE
);

CREATE TABLE employee (
    employee_id   SERIAL       PRIMARY KEY,
    first_name    VARCHAR(40)  NOT NULL,
    last_name     VARCHAR(40)  NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    phone         VARCHAR(15),
    job_title     VARCHAR(40)  NOT NULL,
    dept_id       INT          NOT NULL REFERENCES department(dept_id) ON UPDATE CASCADE,
    store_id      INT          NOT NULL REFERENCES store(store_id)     ON UPDATE CASCADE,
    manager_id    INT          REFERENCES employee(employee_id) ON DELETE SET NULL,
    hire_date     DATE         NOT NULL DEFAULT CURRENT_DATE,
    hourly_rate   NUMERIC(6,2) NOT NULL CHECK (hourly_rate >= 7.25),
    username      VARCHAR(30)  NOT NULL UNIQUE,
    password_hash VARCHAR(100) NOT NULL,                   -- bcrypt hash, never plain text
    access_role   VARCHAR(10)  NOT NULL DEFAULT 'STAFF'
                  CHECK (access_role IN ('STAFF','MANAGER','ADMIN')),
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,      -- "delete" = deactivate, keeps history
    CHECK (manager_id IS NULL OR manager_id <> employee_id)
);

CREATE TABLE shift (
    shift_id      SERIAL       PRIMARY KEY,
    employee_id   INT          NOT NULL REFERENCES employee(employee_id) ON DELETE CASCADE,
    store_id      INT          NOT NULL REFERENCES store(store_id),
    shift_date    DATE         NOT NULL,
    start_time    TIME         NOT NULL,
    end_time      TIME         NOT NULL,
    CHECK (end_time > start_time),
    UNIQUE (employee_id, shift_date, start_time)
);

-- ---------------------------------------------------------------------
-- 2. CUSTOMERS AND VEHICLES
-- ---------------------------------------------------------------------
CREATE TABLE customer (
    customer_id        SERIAL       PRIMARY KEY,
    first_name         VARCHAR(40)  NOT NULL,
    last_name          VARCHAR(40)  NOT NULL,
    email              VARCHAR(100) NOT NULL UNIQUE,
    phone              VARCHAR(15),
    street             VARCHAR(100),
    city               VARCHAR(50),
    state              CHAR(2),
    zip                VARCHAR(10)  CHECK (zip ~ '^[0-9]{5}(-[0-9]{4})?$'),
    preferred_store_id INT          REFERENCES store(store_id) ON DELETE SET NULL,
    username           VARCHAR(30)  NOT NULL UNIQUE,
    password_hash      VARCHAR(100) NOT NULL,
    created_at         TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE vehicle_model (
    model_id      SERIAL       PRIMARY KEY,
    make          VARCHAR(30)  NOT NULL,
    model         VARCHAR(40)  NOT NULL,
    model_year    SMALLINT     NOT NULL CHECK (model_year BETWEEN 1950 AND 2030),
    engine        VARCHAR(30)  NOT NULL DEFAULT 'ALL',
    UNIQUE (make, model, model_year, engine)
);

CREATE TABLE customer_vehicle (
    vehicle_id    SERIAL       PRIMARY KEY,
    customer_id   INT          NOT NULL REFERENCES customer(customer_id) ON DELETE CASCADE,
    model_id      INT          NOT NULL REFERENCES vehicle_model(model_id),
    vin           CHAR(17)     UNIQUE CHECK (vin ~ '^[A-HJ-NPR-Z0-9]{17}$'),
    nickname      VARCHAR(30)
);

-- ---------------------------------------------------------------------
-- 3. CATALOG AND INVENTORY
-- ---------------------------------------------------------------------
CREATE TABLE category (
    category_id        SERIAL      PRIMARY KEY,
    category_name      VARCHAR(50) NOT NULL UNIQUE,
    parent_category_id INT         REFERENCES category(category_id)
);

CREATE TABLE part (
    part_id       SERIAL       PRIMARY KEY,
    part_number   VARCHAR(20)  NOT NULL UNIQUE,
    part_name     VARCHAR(80)  NOT NULL,
    description   TEXT,
    brand         VARCHAR(40)  NOT NULL,
    category_id   INT          NOT NULL REFERENCES category(category_id),
    warranty_months SMALLINT   NOT NULL DEFAULT 12 CHECK (warranty_months >= 0)
);

-- Which parts fit which vehicles (M:N)
CREATE TABLE part_fitment (
    part_id       INT REFERENCES part(part_id)           ON DELETE CASCADE,
    model_id      INT REFERENCES vehicle_model(model_id) ON DELETE CASCADE,
    PRIMARY KEY (part_id, model_id)
);

-- A sellable version of a part: NEW or REMANUFACTURED, each with its own price
CREATE TABLE part_sku (
    sku_id        SERIAL        PRIMARY KEY,
    part_id       INT           NOT NULL REFERENCES part(part_id) ON DELETE CASCADE,
    condition     VARCHAR(15)   NOT NULL CHECK (condition IN ('NEW','REMANUFACTURED')),
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price > 0),
    core_charge   NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (core_charge >= 0),
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    UNIQUE (part_id, condition)
);

-- Stock of each SKU at each store (M:N with attributes)
CREATE TABLE inventory (
    store_id      INT REFERENCES store(store_id)    ON DELETE CASCADE,
    sku_id        INT REFERENCES part_sku(sku_id)   ON DELETE CASCADE,
    qty_on_hand   INT NOT NULL DEFAULT 0 CHECK (qty_on_hand >= 0),
    reorder_level INT NOT NULL DEFAULT 5 CHECK (reorder_level >= 0),
    bin_location  VARCHAR(10),
    PRIMARY KEY (store_id, sku_id)
);

-- ---------------------------------------------------------------------
-- 4. PURCHASING (store reorders from suppliers)
-- ---------------------------------------------------------------------
CREATE TABLE supplier (
    supplier_id   SERIAL       PRIMARY KEY,
    supplier_name VARCHAR(80)  NOT NULL UNIQUE,
    contact_name  VARCHAR(60),
    phone         VARCHAR(15),
    email         VARCHAR(100)
);

CREATE TABLE purchase_order (
    po_id         SERIAL       PRIMARY KEY,
    supplier_id   INT          NOT NULL REFERENCES supplier(supplier_id),
    store_id      INT          NOT NULL REFERENCES store(store_id),
    ordered_by    INT          NOT NULL REFERENCES employee(employee_id),
    order_date    DATE         NOT NULL DEFAULT CURRENT_DATE,
    expected_date DATE,
    received_date DATE,
    status        VARCHAR(10)  NOT NULL DEFAULT 'PENDING'
                  CHECK (status IN ('PENDING','RECEIVED','STOPPED')),
    is_reorder    BOOLEAN      NOT NULL DEFAULT FALSE,
    CHECK (expected_date IS NULL OR expected_date >= order_date),
    CHECK (received_date IS NULL OR received_date >= order_date)
);

CREATE TABLE po_line (
    po_id         INT           REFERENCES purchase_order(po_id) ON DELETE CASCADE,
    sku_id        INT           REFERENCES part_sku(sku_id),
    quantity      INT           NOT NULL CHECK (quantity > 0),
    unit_cost     NUMERIC(10,2) NOT NULL CHECK (unit_cost >= 0),
    PRIMARY KEY (po_id, sku_id)
);

-- ---------------------------------------------------------------------
-- 5. CUSTOMER ORDERS, PAYMENT, DELIVERY, RETURNS
-- ---------------------------------------------------------------------
CREATE TABLE customer_order (
    order_id         SERIAL      PRIMARY KEY,
    customer_id      INT         NOT NULL REFERENCES customer(customer_id),
    store_id         INT         NOT NULL REFERENCES store(store_id),   -- fulfilling store
    handled_by       INT         REFERENCES employee(employee_id),      -- NULL for web orders
    order_date       TIMESTAMP   NOT NULL DEFAULT NOW(),
    channel          VARCHAR(8)  NOT NULL DEFAULT 'WEB'
                     CHECK (channel IN ('WEB','IN_STORE')),
    fulfillment_type VARCHAR(8)  NOT NULL DEFAULT 'PICKUP'
                     CHECK (fulfillment_type IN ('PICKUP','DELIVERY')),
    status           VARCHAR(10) NOT NULL DEFAULT 'PLACED'
                     CHECK (status IN ('PLACED','PAID','SHIPPED','COMPLETED','CANCELLED')),
    cancelled_at     TIMESTAMP,
    cancel_reason    VARCHAR(200),
    CHECK ((status = 'CANCELLED') = (cancelled_at IS NOT NULL))
);

CREATE TABLE order_line (
    order_id      INT           REFERENCES customer_order(order_id) ON DELETE CASCADE,
    line_no       SMALLINT      CHECK (line_no > 0),
    sku_id        INT           NOT NULL REFERENCES part_sku(sku_id),
    quantity      INT           NOT NULL CHECK (quantity > 0),
    unit_price    NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),  -- price at time of sale
    PRIMARY KEY (order_id, line_no),
    UNIQUE (order_id, sku_id)
);

-- Saved cards: only a processor token, card type and last four digits are stored
CREATE TABLE payment_method (
    method_id       SERIAL      PRIMARY KEY,
    customer_id     INT         NOT NULL REFERENCES customer(customer_id) ON DELETE CASCADE,
    card_type       VARCHAR(12) NOT NULL CHECK (card_type IN ('VISA','MASTERCARD','AMEX','DISCOVER')),
    last_four       CHAR(4)     NOT NULL CHECK (last_four ~ '^[0-9]{4}$'),
    exp_month       SMALLINT    NOT NULL CHECK (exp_month BETWEEN 1 AND 12),
    exp_year        SMALLINT    NOT NULL CHECK (exp_year >= 2024),
    billing_street  VARCHAR(100) NOT NULL,
    billing_city    VARCHAR(50)  NOT NULL,
    billing_state   CHAR(2)      NOT NULL,
    billing_zip     VARCHAR(10)  NOT NULL,
    processor_token VARCHAR(64)  NOT NULL UNIQUE,
    is_default      BOOLEAN      NOT NULL DEFAULT FALSE
);

CREATE TABLE payment (
    payment_id    SERIAL        PRIMARY KEY,
    order_id      INT           NOT NULL REFERENCES customer_order(order_id),
    method_id     INT           REFERENCES payment_method(method_id) ON DELETE SET NULL,
    payment_type  VARCHAR(8)    NOT NULL CHECK (payment_type IN ('CARD','CASH','GIFTCARD')),
    amount        NUMERIC(10,2) NOT NULL CHECK (amount <> 0),   -- negative = refund
    paid_at       TIMESTAMP     NOT NULL DEFAULT NOW(),
    status        VARCHAR(10)   NOT NULL DEFAULT 'APPROVED'
                  CHECK (status IN ('APPROVED','DECLINED','REFUNDED')),
    CHECK (payment_type <> 'CARD' OR method_id IS NOT NULL)
);

CREATE TABLE delivery (
    delivery_id       SERIAL      PRIMARY KEY,
    order_id          INT         NOT NULL UNIQUE REFERENCES customer_order(order_id) ON DELETE CASCADE,
    ship_street       VARCHAR(100) NOT NULL,
    ship_city         VARCHAR(50)  NOT NULL,
    ship_state        CHAR(2)      NOT NULL,
    ship_zip          VARCHAR(10)  NOT NULL,
    carrier           VARCHAR(30)  NOT NULL DEFAULT 'STORE DRIVER',
    tracking_number   VARCHAR(40),
    driver_id         INT          REFERENCES employee(employee_id),
    ship_date         DATE,
    est_delivery_date DATE,
    delivered_date    DATE,
    status            VARCHAR(10)  NOT NULL DEFAULT 'PENDING'
                      CHECK (status IN ('PENDING','IN_TRANSIT','DELIVERED','CANCELLED')),
    CHECK (delivered_date IS NULL OR delivered_date >= ship_date)
);

CREATE TABLE order_return (
    return_id     SERIAL        PRIMARY KEY,
    order_id      INT           NOT NULL,
    line_no       SMALLINT      NOT NULL,
    quantity      INT           NOT NULL CHECK (quantity > 0),
    reason        VARCHAR(200)  NOT NULL,
    return_date   DATE          NOT NULL DEFAULT CURRENT_DATE,
    refund_amount NUMERIC(10,2) NOT NULL CHECK (refund_amount >= 0),
    processed_by  INT           NOT NULL REFERENCES employee(employee_id),
    FOREIGN KEY (order_id, line_no) REFERENCES order_line(order_id, line_no)
);

-- ---------------------------------------------------------------------
-- 6. INDEXES for common searches and reports
-- ---------------------------------------------------------------------
CREATE INDEX idx_part_name       ON part (LOWER(part_name));
CREATE INDEX idx_part_category   ON part (category_id);
CREATE INDEX idx_fitment_model   ON part_fitment (model_id);
CREATE INDEX idx_order_customer  ON customer_order (customer_id, order_date DESC);
CREATE INDEX idx_order_date      ON customer_order (order_date);
CREATE INDEX idx_employee_store  ON employee (store_id);

-- ---------------------------------------------------------------------
-- 7. BUSINESS RULES (triggers)
-- ---------------------------------------------------------------------
-- A returned quantity can never exceed what was bought on that line
CREATE FUNCTION check_return_qty() RETURNS trigger AS $$
DECLARE bought INT; already INT;
BEGIN
    SELECT quantity INTO bought FROM order_line
     WHERE order_id = NEW.order_id AND line_no = NEW.line_no;
    SELECT COALESCE(SUM(quantity),0) INTO already FROM order_return
     WHERE order_id = NEW.order_id AND line_no = NEW.line_no
       AND return_id IS DISTINCT FROM NEW.return_id;
    IF already + NEW.quantity > bought THEN
        RAISE EXCEPTION 'Return of % exceeds % remaining on order % line %',
              NEW.quantity, bought - already, NEW.order_id, NEW.line_no;
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_return_qty BEFORE INSERT OR UPDATE ON order_return
FOR EACH ROW EXECUTE FUNCTION check_return_qty();

-- Receiving a purchase order adds its quantities to the store's inventory
CREATE FUNCTION receive_po() RETURNS trigger AS $$
BEGIN
    IF NEW.status = 'RECEIVED' AND OLD.status <> 'RECEIVED' THEN
        INSERT INTO inventory (store_id, sku_id, qty_on_hand)
        SELECT NEW.store_id, l.sku_id, l.quantity FROM po_line l WHERE l.po_id = NEW.po_id
        ON CONFLICT (store_id, sku_id)
        DO UPDATE SET qty_on_hand = inventory.qty_on_hand + EXCLUDED.qty_on_hand;
        NEW.received_date := COALESCE(NEW.received_date, CURRENT_DATE);
    END IF;
    RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_receive_po BEFORE UPDATE OF status ON purchase_order
FOR EACH ROW EXECUTE FUNCTION receive_po();

-- ---------------------------------------------------------------------
-- 8. REPORT VIEWS (Report Management)
-- ---------------------------------------------------------------------
CREATE VIEW v_order_totals AS
SELECT o.order_id, o.customer_id, o.store_id, o.order_date, o.status,
       SUM(l.quantity * l.unit_price) AS order_total
  FROM customer_order o JOIN order_line l USING (order_id)
 GROUP BY o.order_id;

CREATE VIEW v_daily_sales AS
SELECT s.store_name, o.order_date::date AS sale_date,
       COUNT(*) AS orders, SUM(o.order_total) AS revenue
  FROM v_order_totals o JOIN store s USING (store_id)
 WHERE o.status <> 'CANCELLED'
 GROUP BY s.store_name, o.order_date::date;

CREATE VIEW v_inventory_status AS
SELECT s.store_name, p.part_number, p.part_name, k.condition, k.unit_price,
       i.qty_on_hand, i.reorder_level,
       (i.qty_on_hand <= i.reorder_level) AS needs_reorder
  FROM inventory i
  JOIN store s    USING (store_id)
  JOIN part_sku k USING (sku_id)
  JOIN part p     USING (part_id);

CREATE VIEW v_low_stock AS
SELECT * FROM v_inventory_status WHERE needs_reorder;

CREATE VIEW v_employee_roster AS
SELECT e.employee_id, e.first_name || ' ' || e.last_name AS employee,
       e.job_title, d.dept_name, s.store_name,
       m.first_name || ' ' || m.last_name AS manager,
       e.access_role, e.is_active
  FROM employee e
  JOIN department d USING (dept_id)
  JOIN store s      ON s.store_id = e.store_id
  LEFT JOIN employee m ON m.employee_id = e.manager_id;
