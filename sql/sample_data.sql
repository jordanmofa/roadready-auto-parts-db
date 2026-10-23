-- =====================================================================
-- RoadReady Auto Parts - sample data for testing the Phase II schema
-- Run after roadready_schema.sql
-- =====================================================================
SET search_path TO roadready;

INSERT INTO store (store_name, street, city, state, zip, phone, opened_date) VALUES
 ('RoadReady Denton',     '1200 W University Dr', 'Denton',     'TX', '76201', '940-555-0110', '2018-03-01'),
 ('RoadReady Lewisville', '455 S Stemmons Fwy',   'Lewisville', 'TX', '75067', '972-555-0120', '2021-06-15');

INSERT INTO department (dept_name) VALUES
 ('Management'), ('Sales Counter'), ('Warehouse'), ('Delivery');

-- Passwords hashed with bcrypt; demo plain-text password for all accounts is 'Demo#2026'
INSERT INTO employee (first_name, last_name, email, phone, job_title, dept_id, store_id, manager_id,
                      hire_date, hourly_rate, username, password_hash, access_role) VALUES
 ('Maria',   'Lopez',    'mlopez@roadready.com',   '940-555-0201', 'Store Manager',      1, 1, NULL, '2018-03-01', 32.00, 'mlopez',   crypt('Demo#2026', gen_salt('bf')), 'ADMIN'),
 ('James',   'Carter',   'jcarter@roadready.com',  '972-555-0202', 'Store Manager',      1, 2, NULL, '2021-06-15', 31.00, 'jcarter',  crypt('Demo#2026', gen_salt('bf')), 'MANAGER'),
 ('Aisha',   'Bello',    'abello@roadready.com',   '940-555-0203', 'Parts Specialist',   2, 1, 1,    '2022-01-10', 18.50, 'abello',   crypt('Demo#2026', gen_salt('bf')), 'STAFF'),
 ('Kevin',   'Nguyen',   'knguyen@roadready.com',  '940-555-0204', 'Inventory Clerk',    3, 1, 1,    '2023-05-22', 17.00, 'knguyen',  crypt('Demo#2026', gen_salt('bf')), 'STAFF'),
 ('Tyrell',  'Brooks',   'tbrooks@roadready.com',  '940-555-0205', 'Delivery Driver',    4, 1, 1,    '2024-02-05', 16.50, 'tbrooks',  crypt('Demo#2026', gen_salt('bf')), 'STAFF'),
 ('Sofia',   'Ramirez',  'sramirez@roadready.com', '972-555-0206', 'Parts Specialist',   2, 2, 2,    '2023-09-12', 18.00, 'sramirez', crypt('Demo#2026', gen_salt('bf')), 'STAFF'),
 ('Daniel',  'Kim',      'dkim@roadready.com',     '972-555-0207', 'Warehouse Lead',     3, 2, 2,    '2022-11-01', 19.25, 'dkim',     crypt('Demo#2026', gen_salt('bf')), 'STAFF');

INSERT INTO shift (employee_id, store_id, shift_date, start_time, end_time) VALUES
 (3, 1, '2026-10-20', '08:00', '16:00'),
 (4, 1, '2026-10-20', '12:00', '20:00'),
 (5, 1, '2026-10-20', '09:00', '17:00'),
 (6, 2, '2026-10-20', '08:00', '16:00'),
 (7, 2, '2026-10-21', '10:00', '18:00');

INSERT INTO customer (first_name, last_name, email, phone, street, city, state, zip,
                      preferred_store_id, username, password_hash) VALUES
 ('Chris',   'Walker',  'cwalker@example.com',  '940-555-1001', '310 Oak St',       'Denton',     'TX', '76201', 1, 'cwalker', crypt('Demo#2026', gen_salt('bf'))),
 ('Priya',   'Shah',    'pshah@example.com',    '940-555-1002', '88 Elm Ave',       'Denton',     'TX', '76205', 1, 'pshah',   crypt('Demo#2026', gen_salt('bf'))),
 ('Marcus',  'Johnson', 'mjohnson@example.com', '972-555-1003', '1501 Main St',     'Lewisville', 'TX', '75057', 2, 'mjohn',   crypt('Demo#2026', gen_salt('bf'))),
 ('Emily',   'Chen',    'echen@example.com',    '972-555-1004', '22 Lakeview Dr',   'Flower Mound','TX','75028', 2, 'echen',   crypt('Demo#2026', gen_salt('bf'))),
 ('Luis',    'Garcia',  'lgarcia@example.com',  '940-555-1005', '9 Bonnie Brae St', 'Denton',     'TX', '76207', 1, 'lgarcia', crypt('Demo#2026', gen_salt('bf')));

INSERT INTO vehicle_model (make, model, model_year, engine) VALUES
 ('Toyota',    'Camry',   2018, '2.5L I4'),
 ('Honda',     'Civic',   2016, '2.0L I4'),
 ('Ford',      'F-150',   2019, '5.0L V8'),
 ('Chevrolet', 'Silverado 1500', 2020, '5.3L V8'),
 ('Nissan',    'Altima',  2017, '2.5L I4');

INSERT INTO customer_vehicle (customer_id, model_id, vin, nickname) VALUES
 (1, 1, '4T1B11HK5JU512345', 'Daily driver'),
 (2, 2, '19XFC2F59GE212345', NULL),
 (3, 3, '1FTEW1E50KFA12345', 'Work truck'),
 (4, 5, '1N4AL3AP7HC212345', NULL),
 (5, 4, '3GCUYDED5LG112345', NULL),
 (1, 3, '1FTEW1E58KFB54321', 'Weekend truck');

INSERT INTO category (category_name, parent_category_id) VALUES
 ('Brakes', NULL), ('Engine', NULL), ('Electrical', NULL), ('Filters', NULL);
INSERT INTO category (category_name, parent_category_id) VALUES
 ('Brake Pads', 1), ('Brake Rotors', 1), ('Batteries', 3), ('Alternators', 3),
 ('Oil Filters', 4), ('Air Filters', 4), ('Spark Plugs', 2);

INSERT INTO part (part_number, part_name, description, brand, category_id, warranty_months) VALUES
 ('BP-1042', 'Ceramic Front Brake Pads',   'Low-dust ceramic pads, front axle set',           'Duralast',  5, 24),
 ('BR-2210', 'Front Brake Rotor',          'Vented rotor, OE replacement',                    'Duralast',  6, 12),
 ('BT-24F',  'Group 24F Battery',          '710 CCA AGM battery',                              'DieHard',   7, 36),
 ('AL-7781', 'Alternator 130A',            'Direct-fit 130 amp alternator',                   'Bosch',     8, 24),
 ('OF-3600', 'Oil Filter',                 'Synthetic-media spin-on oil filter',              'Mobil 1',   9, 6),
 ('AF-5521', 'Engine Air Filter',          'Panel air filter',                                'FRAM',     10, 6),
 ('SP-9005', 'Iridium Spark Plug',         'Long-life iridium tip, sold individually',        'NGK',      11, 12),
 ('BP-3310', 'Severe Duty Brake Pads',     'Semi-metallic pads for trucks and towing',        'Wagner',    5, 24);

INSERT INTO part_fitment (part_id, model_id) VALUES
 (1,1),(1,5),(2,1),(2,5),(3,1),(3,2),(3,5),(4,3),(4,4),(5,1),(5,2),(5,5),
 (6,1),(6,2),(7,1),(7,2),(7,5),(8,3),(8,4);

INSERT INTO part_sku (part_id, condition, unit_price, core_charge) VALUES
 (1, 'NEW', 54.99, 0),          -- sku 1
 (2, 'NEW', 69.99, 0),          -- sku 2
 (3, 'NEW', 219.99, 22.00),     -- sku 3
 (4, 'NEW', 289.99, 0),         -- sku 4
 (4, 'REMANUFACTURED', 169.99, 45.00),  -- sku 5
 (5, 'NEW', 11.49, 0),          -- sku 6
 (6, 'NEW', 24.99, 0),          -- sku 7
 (7, 'NEW', 12.99, 0),          -- sku 8
 (8, 'NEW', 79.99, 0),          -- sku 9
 (2, 'REMANUFACTURED', 44.99, 10.00);   -- sku 10

INSERT INTO inventory (store_id, sku_id, qty_on_hand, reorder_level, bin_location) VALUES
 (1,1,14,5,'A-03'),(1,2,6,4,'A-07'),(1,3,3,4,'E-01'),(1,4,2,2,'E-05'),(1,5,5,2,'E-06'),
 (1,6,40,15,'F-01'),(1,7,18,8,'F-04'),(1,8,60,20,'G-02'),(1,9,4,5,'A-04'),
 (2,1,9,5,'B-02'),(2,2,2,4,'B-05'),(2,3,7,4,'E-02'),(2,5,1,2,'E-03'),(2,6,25,15,'F-02'),
 (2,8,12,20,'G-01'),(2,9,8,5,'B-03'),(2,10,3,2,'B-06');

INSERT INTO supplier (supplier_name, contact_name, phone, email) VALUES
 ('Lone Star Parts Distribution', 'Dana Reyes',  '214-555-3001', 'orders@lonestarparts.example'),
 ('Midwest Reman Co.',            'Paul Becker', '316-555-3002', 'sales@midwestreman.example');

INSERT INTO purchase_order (supplier_id, store_id, ordered_by, order_date, expected_date, status, is_reorder) VALUES
 (1, 1, 4, '2026-10-15', '2026-10-20', 'PENDING', TRUE),
 (2, 2, 7, '2026-10-12', '2026-10-19', 'PENDING', TRUE),
 (1, 2, 2, '2026-10-01', '2026-10-06', 'STOPPED', FALSE);

INSERT INTO po_line (po_id, sku_id, quantity, unit_cost) VALUES
 (1, 3, 6, 141.00), (1, 9, 10, 46.50),
 (2, 5, 4, 98.00),  (2, 10, 6, 22.00),
 (3, 8, 50, 6.10);

-- Receiving PO 2 fires trg_receive_po and adds stock to store 2
UPDATE purchase_order SET status = 'RECEIVED', received_date = '2026-10-18' WHERE po_id = 2;

INSERT INTO payment_method (customer_id, card_type, last_four, exp_month, exp_year,
                            billing_street, billing_city, billing_state, billing_zip, processor_token, is_default) VALUES
 (1, 'VISA',       '4417', 8,  2028, '310 Oak St',     'Denton',      'TX', '76201', 'tok_demo_a1b2c3', TRUE),
 (2, 'MASTERCARD', '9021', 2,  2027, '88 Elm Ave',     'Denton',      'TX', '76205', 'tok_demo_d4e5f6', TRUE),
 (3, 'AMEX',       '1005', 11, 2029, '1501 Main St',   'Lewisville',  'TX', '75057', 'tok_demo_g7h8i9', TRUE),
 (4, 'DISCOVER',   '6630', 5,  2027, '22 Lakeview Dr', 'Flower Mound','TX', '75028', 'tok_demo_j0k1l2', TRUE);

INSERT INTO customer_order (customer_id, store_id, handled_by, order_date, channel, fulfillment_type, status, cancelled_at, cancel_reason) VALUES
 (1, 1, NULL, '2026-10-19 10:42', 'WEB',      'DELIVERY', 'COMPLETED', NULL, NULL),
 (2, 1, 3,    '2026-10-19 14:05', 'IN_STORE', 'PICKUP',   'COMPLETED', NULL, NULL),
 (3, 2, NULL, '2026-10-20 09:15', 'WEB',      'DELIVERY', 'SHIPPED',   NULL, NULL),
 (4, 2, 6,    '2026-10-20 16:30', 'IN_STORE', 'PICKUP',   'COMPLETED', NULL, NULL),
 (5, 1, NULL, '2026-10-21 08:20', 'WEB',      'PICKUP',   'CANCELLED', '2026-10-21 09:00', 'Customer found part elsewhere'),
 (1, 1, NULL, '2026-10-22 18:55', 'WEB',      'PICKUP',   'PAID',      NULL, NULL);

INSERT INTO order_line (order_id, line_no, sku_id, quantity, unit_price) VALUES
 (1, 1, 1, 1, 54.99), (1, 2, 2, 2, 69.99),
 (2, 1, 3, 1, 219.99),
 (3, 1, 9, 1, 79.99), (3, 2, 5, 1, 169.99),
 (4, 1, 6, 2, 11.49), (4, 2, 7, 1, 24.99),
 (5, 1, 4, 1, 289.99),
 (6, 1, 8, 4, 12.99), (6, 2, 6, 1, 11.49);

INSERT INTO payment (order_id, method_id, payment_type, amount, paid_at, status) VALUES
 (1, 1,    'CARD', 194.97, '2026-10-19 10:43', 'APPROVED'),
 (2, NULL, 'CASH', 219.99, '2026-10-19 14:07', 'APPROVED'),
 (3, 3,    'CARD', 249.98, '2026-10-20 09:16', 'APPROVED'),
 (4, 4,    'CARD',  47.97, '2026-10-20 16:31', 'APPROVED'),
 (6, 1,    'CARD',  63.45, '2026-10-22 18:56', 'APPROVED');

INSERT INTO delivery (order_id, ship_street, ship_city, ship_state, ship_zip, carrier, tracking_number,
                      driver_id, ship_date, est_delivery_date, delivered_date, status) VALUES
 (1, '310 Oak St',   'Denton',     'TX', '76201', 'STORE DRIVER', NULL,               5,    '2026-10-19', '2026-10-19', '2026-10-19', 'DELIVERED'),
 (3, '1501 Main St', 'Lewisville', 'TX', '75057', 'UPS',          '1Z999AA10123456784', NULL, '2026-10-21', '2026-10-23', NULL,         'IN_TRANSIT');

INSERT INTO order_return (order_id, line_no, quantity, reason, return_date, refund_amount, processed_by) VALUES
 (1, 2, 1, 'Ordered one rotor too many', '2026-10-21', 69.99, 3);

INSERT INTO payment (order_id, method_id, payment_type, amount, paid_at, status) VALUES
 (1, 1, 'CARD', -69.99, '2026-10-21 11:10', 'REFUNDED');
