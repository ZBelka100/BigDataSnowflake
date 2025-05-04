\echo 'Loading CSV into staging.mock_data …'

\set path '/docker-entrypoint-initdb.d'

\copy staging.mock_data
      FROM :'path'/mock_data1.csv WITH (FORMAT csv, HEADER true)
\copy staging.mock_data
      FROM :'path'/mock_data2.csv WITH (FORMAT csv, HEADER true)
\copy staging.mock_data
      FROM :'path'/mock_data3.csv WITH (FORMAT csv, HEADER true)
\copy staging.mock_data
      FROM :'path'/mock_data4.csv WITH (FORMAT csv, HEADER true)
\copy staging.mock_data
      FROM :'path'/mock_data5.csv WITH (FORMAT csv, HEADER true)
\copy staging.mock_data
      FROM :'path'/mock_data6.csv WITH (FORMAT csv, HEADER true)
\copy staging.mock_data
      FROM :'path'/mock_data7.csv WITH (FORMAT csv, HEADER true)
\copy staging.mock_data
      FROM :'path'/mock_data8.csv WITH (FORMAT csv, HEADER true)
\copy staging.mock_data
      FROM :'path'/mock_data9.csv WITH (FORMAT csv, HEADER true)
\copy staging.mock_data
      FROM :'path'/mock_data10.csv WITH (FORMAT csv, HEADER true)

SELECT COUNT(*) FROM staging.mock_data;
