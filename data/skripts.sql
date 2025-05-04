CREATE SCHEMA IF NOT EXISTS analytics;

CREATE TABLE analytics.dim_country (
  country_key   SERIAL PRIMARY KEY,
  country_name  TEXT UNIQUE
);

INSERT INTO analytics.dim_country (country_name)
SELECT DISTINCT customer_country  FROM staging.mock_data UNION
SELECT DISTINCT seller_country    FROM staging.mock_data UNION
SELECT DISTINCT store_country     FROM staging.mock_data UNION
SELECT DISTINCT supplier_country  FROM staging.mock_data
ON CONFLICT (country_name) DO NOTHING;

SELECT COUNT(*) FROM analytics.dim_country;

CREATE TABLE analytics.dim_pet_category (
  pet_cat_key  SERIAL PRIMARY KEY,
  pet_category TEXT UNIQUE
);

INSERT INTO analytics.dim_pet_category (pet_category)
SELECT DISTINCT pet_category
FROM   staging.mock_data
ON CONFLICT (pet_category) DO NOTHING;

CREATE TABLE analytics.dim_customer (
  customer_key     SERIAL PRIMARY KEY,
  customer_id      TEXT UNIQUE,
  first_name       TEXT,
  last_name        TEXT,
  age              INT,
  email            TEXT,
  pet_type         TEXT,
  pet_name         TEXT,
  pet_breed        TEXT,
  postal_code      TEXT,
  country_key      INT REFERENCES analytics.dim_country,
  pet_cat_key      INT REFERENCES analytics.dim_pet_category
);

INSERT INTO analytics.dim_customer (
  customer_id, first_name, last_name, age, email,
  pet_type, pet_name, pet_breed, postal_code,
  country_key, pet_cat_key
)
SELECT DISTINCT
  sale_customer_id,
  customer_first_name,
  customer_last_name,
  customer_age::INT,
  customer_email,
  customer_pet_type,
  customer_pet_name,
  customer_pet_breed,
  customer_postal_code,
  dc.country_key,
  dpc.pet_cat_key
FROM staging.mock_data sm
LEFT JOIN analytics.dim_country       dc  ON sm.customer_country = dc.country_name
LEFT JOIN analytics.dim_pet_category  dpc ON sm.pet_category     = dpc.pet_category
ON CONFLICT (customer_id) DO NOTHING;

CREATE TABLE analytics.dim_seller (
  seller_key    SERIAL PRIMARY KEY,
  seller_id     TEXT UNIQUE,
  first_name    TEXT,
  last_name     TEXT,
  email         TEXT,
  postal_code   TEXT,
  country_key   INT REFERENCES analytics.dim_country
);

INSERT INTO analytics.dim_seller (
  seller_id, first_name, last_name, email, postal_code, country_key
)
SELECT DISTINCT
  sale_seller_id,
  seller_first_name,
  seller_last_name,
  seller_email,
  seller_postal_code,
  dc.country_key
FROM staging.mock_data sm
LEFT JOIN analytics.dim_country dc ON sm.seller_country = dc.country_name
ON CONFLICT (seller_id) DO NOTHING;

CREATE TABLE analytics.dim_store (
  store_key     SERIAL PRIMARY KEY,
  store_name    TEXT UNIQUE,
  location      TEXT,
  city          TEXT,
  state         TEXT,
  phone         TEXT,
  email         TEXT,
  country_key   INT REFERENCES analytics.dim_country
);

INSERT INTO analytics.dim_store (
  store_name, location, city, state, phone, email, country_key
)
SELECT DISTINCT
  store_name,
  store_location,
  store_city,
  store_state,
  store_phone,
  store_email,
  dc.country_key
FROM staging.mock_data sm
LEFT JOIN analytics.dim_country dc ON sm.store_country = dc.country_name
ON CONFLICT (store_name) DO NOTHING;

CREATE TABLE analytics.dim_supplier (
  supplier_key  SERIAL PRIMARY KEY,
  supplier_name TEXT UNIQUE,
  contact       TEXT,
  email         TEXT,
  phone         TEXT,
  address       TEXT,
  city          TEXT,
  country_key   INT REFERENCES analytics.dim_country
);

INSERT INTO analytics.dim_supplier (
  supplier_name, contact, email, phone, address, city, country_key
)
SELECT DISTINCT
  supplier_name,
  supplier_contact,
  supplier_email,
  supplier_phone,
  supplier_address,
  supplier_city,
  dc.country_key
FROM staging.mock_data sm
LEFT JOIN analytics.dim_country dc ON sm.supplier_country = dc.country_name
ON CONFLICT (supplier_name) DO NOTHING;

CREATE TABLE analytics.dim_product (
  product_key      SERIAL PRIMARY KEY,
  product_id       TEXT UNIQUE,
  name             TEXT,
  category         TEXT,
  weight           NUMERIC(10,2),
  color            TEXT,
  size             TEXT,
  brand            TEXT,
  material         TEXT,
  description      TEXT,
  rating           NUMERIC(3,2),
  reviews          INT,
  release_date     DATE,
  expiry_date      DATE
);

INSERT INTO analytics.dim_product (
  product_id, name, category, weight, color, size, brand,
  material, description, rating, reviews, release_date, expiry_date
)
SELECT DISTINCT
  sale_product_id,
  product_name,
  product_category,
  product_weight::NUMERIC,
  product_color,
  product_size,
  product_brand,
  product_material,
  product_description,
  product_rating::NUMERIC,
  product_reviews::INT,
  TO_DATE(product_release_date, 'MM-DD-YYYY'),
  TO_DATE(product_expiry_date,  'MM-DD-YYYY')
FROM staging.mock_data
ON CONFLICT (product_id) DO NOTHING;

CREATE TABLE analytics.fact_sale (
  sale_key      SERIAL PRIMARY KEY,
  sale_id       TEXT,               
  sale_date     DATE,
  customer_key  INT REFERENCES analytics.dim_customer,
  seller_key    INT REFERENCES analytics.dim_seller,
  product_key   INT REFERENCES analytics.dim_product,
  store_key     INT REFERENCES analytics.dim_store,
  supplier_key  INT REFERENCES analytics.dim_supplier,
  quantity      INT,
  total_price   NUMERIC(12,2)
);

INSERT INTO analytics.fact_sale (
  sale_id, sale_date,
  customer_key, seller_key, product_key, store_key, supplier_key,
  quantity, total_price
)
SELECT
  sm.id,
  TO_DATE(sm.sale_date, 'MM-DD-YYYY'),
  dc.customer_key,
  ds.seller_key,
  dp.product_key,
  dst.store_key,
  dsu.supplier_key,
  sm.sale_quantity::INT,
  sm.sale_total_price::NUMERIC
FROM staging.mock_data sm
JOIN analytics.dim_customer  dc  ON sm.sale_customer_id = dc.customer_id
JOIN analytics.dim_seller    ds  ON sm.sale_seller_id   = ds.seller_id
JOIN analytics.dim_product   dp  ON sm.sale_product_id  = dp.product_id
JOIN analytics.dim_store     dst ON sm.store_name       = dst.store_name
JOIN analytics.dim_supplier  dsu ON sm.supplier_name    = dsu.supplier_name;
