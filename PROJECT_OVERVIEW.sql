#	Download and run Materialize inside Docker

--Open Docker, connect to and run your psqlserver.

--Get a single-node Kafka or Redpanda instance running in Docker:
--constructed, and run docker-compose.yml file with both redpanda and
--docker as separate containers within the DL_Proj Container


--run docker-compose.yml file with below command this in a different 
--terminal:

docker-compose up -d

--open 1st powershell:
docker run -p 6875:6875 materialize/materialized:v0.13.0 --workers 1

Materialized is listening on port  6875

--Open a second 2nd powershell:

psql -U materialize -h localhost -p 6875 materialize

--open materliaze run following commands:

--Let’s create a PubNub source that connects to the market orders 
--channel with a subscribe key:

CREATE SOURCE market_orders_raw
FROM PUBNUB
SUBSCRIBE KEY 'sub-c-4377ab04-f100-11e3-bffd-02ee2ddab7fe'
CHANNEL 'pubnub-market-orders';

SHOW COLUMNS FROM market_orders_raw;

--The PubNub source produces data as a single text column containing JSON. 
--To extract the JSON fields for each market order, you can 
--use the built-in jsonb operators:

CREATE VIEW market_orders AS
SELECT
    ((text::jsonb)->>'bid_price')::float AS bid_price,
    (text::jsonb)->>'order_quantity' AS order_quantity,
    (text::jsonb)->>'symbol' AS symbol,
    (text::jsonb)->>'trade_type' AS trade_type,
    to_timestamp(((text::jsonb)->'timestamp')::bigint) AS ts
FROM market_orders_raw;

--Create a materialized view that tracks the average, max, 
--and min price for each security.

 CREATE MATERIALIZED VIEW security_data AS
     SELECT
         symbol,
         AVG(bid_price) AS average,
         MAX(bid_price) AS maximum,
         MIN(bid_price)As minimun
     FROM market_orders
     GROUP BY symbol;

-- CREATE A SINK FOR THE security_data

CREATE SINK security_sink
FROM security_data
INTO KAFKA BROKER 'redpanda:29092' TOPIC 'security-sink'
FORMAT JSON;
COPY (TAIL price_data) TO stdout;

--Create a Materialized Sink that publishes to a redpanda topic
 --each time the max price changes for any symbol

--Max price materialized view
CREATE MATERIALIZED VIEW price_data AS
    SELECT
        symbol,
        MAX(bid_price) AS maximum,
    FROM market_orders
    GROUP BY symbol;

COPY (TAIL price_data) TO stdout;

--Max Price Sink:
 CREATE SINK price_sink
 FROM max_price_data
 INTO KAFKA BROKER 'redpanda:29092' TOPIC 'price-sink'
 FORMAT JSON;
 CREATE SINK

#Materialize:
COPY (TAIL price_data) TO stdout;

--Create a Materialized Sink that publishes to a redpanda topic each
 time the max price changes for any symbol
--Redpanda Topics cosume data from Materialize:

--redpanda max price consumer- in terminal
docker exec -it dl_proj_redpanda_1 \
rpk topic consume price-sink-u19-1641046207-11006669201913062486
--redpanda symbol,max,min,average consumer:
docker exec -it dl_proj_redpanda_1 \
rpk topic consume security-sink-u14-1641046207-11006669201913062486 

--Create a Python script that can read Redpanda topic 
--and print out max price updates. Feel free to use a framework like Faust if it helps. 
--Get Group ID, topic, and bootstrap server for consumer.py

--in terminal:
docker exec -it dl_proj_redpanda_1 rpk cluster info- check sink id

--for group id/container id and other info:
docker ps

--inspect max price sink cotainer:
docker container inspect CONTAINER 4504947f06a3

--Run kafka-python consumer App in python prompt:

python C:\Users\thomp\DL_Proj\consumer5.py

--Here are the container image id's:

redpanda docker image id: 900fd6dcfab0
materialize docker image id: a98cf4a7b057 