-- -- SQL Script to clean assessment.db
-- -- Requirements: 
-- -- 1. Remove duplicate transactions
-- -- 2. TRIM spaces
-- -- 3. Standardize category text to one consistent case
-- -- 4. Handle blank units (set to 1) and NULL region (set to 'Unknown')
-- -- 5. Correct data types and normalize date formats

-- -- Create a temporary month map for date normalization
-- CREATE TEMP TABLE month_map (name TEXT, val TEXT);
-- INSERT INTO month_map VALUES 
-- ('Jan', '01'), ('Feb', '02'), ('Mar', '03'), ('Apr', '04'), 
-- ('May', '05'), ('Jun', '06'), ('Jul', '07'), ('Aug', '08'), 
-- ('Sep', '09'), ('Oct', '10'), ('Nov', '11'), ('Dec', '12');

-- -- 1. Clean Products Table
-- CREATE TABLE products_new (
--     product_id TEXT PRIMARY KEY,
--     product_name TEXT,
--     category TEXT,
--     unit_cost REAL
-- );

-- INSERT INTO products_new
-- SELECT DISTINCT
--     TRIM(product_id),
--     TRIM(product_name),
--     UPPER(TRIM(category)),
--     CAST(unit_cost AS REAL)
-- FROM products;

-- -- 2. Clean Stores Table
-- CREATE TABLE stores_new (
--     store_id TEXT PRIMARY KEY,
--     store_name TEXT,
--     region TEXT
-- );

-- INSERT INTO stores_new
-- SELECT DISTINCT
--     TRIM(store_id),
--     TRIM(store_name),
--     COALESCE(NULLIF(TRIM(region), ''), 'Unknown')
-- FROM stores;

-- -- 3. Clean Transactions Table
-- CREATE TABLE transactions_new (
--     transaction_id TEXT,
--     date TEXT,
--     store_id TEXT,
--     product_id TEXT,
--     units INTEGER,
--     unit_price REAL,
--     total_amount REAL
-- );

-- -- Use a CTE to deduplicate and fix data
-- INSERT INTO transactions_new
-- WITH cleaned_transactions AS (
--     SELECT 
--         TRIM(transaction_id) as tid,
--         TRIM(date) as raw_date,
--         TRIM(store_id) as sid,
--         TRIM(product_id) as pid,
--         CASE 
--             WHEN TRIM(units) = '' OR units IS NULL THEN 1 
--             ELSE CAST(units AS INTEGER) 
--         END as u,
--         CAST(unit_price AS REAL) as up,
--         ROW_NUMBER() OVER (PARTITION BY TRIM(transaction_id) ORDER BY date) as rn
--     FROM transactions
-- )
-- SELECT 
--     tid,
--     CASE 
--         WHEN raw_date LIKE '%/%/%' THEN 
--             printf('%04d-%02d-%02d', 
--                 substr(raw_date, length(raw_date)-3),
--                 substr(raw_date, 1, instr(raw_date, '/')-1),
--                 substr(raw_date, instr(raw_date, '/')+1, instr(substr(raw_date, instr(raw_date, '/')+1), '/')-1)
--             )
--         WHEN raw_date LIKE '____-__-__' THEN raw_date
--         ELSE 
--             printf('%04d-%s-%02d',
--                 substr(raw_date, -4),
--                 (SELECT val FROM month_map WHERE name = substr(raw_date, 1, 3)),
--                 trim(substr(raw_date, instr(raw_date, ' ')+1, instr(raw_date, ',') - instr(raw_date, ' ') - 1))
--             )
--     END as fixed_date,
--     sid,
--     pid,
--     u,
--     up,
--     u * up as total_amount
-- FROM cleaned_transactions
-- WHERE rn = 1;

-- -- Replace old tables with new ones
-- DROP TABLE products;
-- ALTER TABLE products_new RENAME TO products;

-- DROP TABLE stores;
-- ALTER TABLE stores_new RENAME TO stores;

-- DROP TABLE transactions;
-- ALTER TABLE transactions_new RENAME TO transactions;

-- -- Clean up temp table
-- DROP TABLE month_map;

-- -- Vacuum to optimize
-- VACUUM;
