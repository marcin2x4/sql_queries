CREATE or REPLACE TABLE DEMO_DB.ORDERS.ORDERS
(id number(38,0),
date date,
CONSTRAINT "PK_ORDER" PRIMARY KEY (id));

CREATE or REPLACE TABLE DEMO_DB.ORDERS.PRODUCT
(id varchar(255),
name varchar(255),
price number(38,2),
CONSTRAINT "PK_PRODUCT" PRIMARY KEY (id));

CREATE or REPLACE TABLE DEMO_DB.ORDERS.ORDER_ITEM
(id varchar(255), --pozycja zamówienia/ROW_NUMBER()
order_id number(38,0),
product_id varchar(255),
quantity number(38,0),

CONSTRAINT "PK_ORDER_ITEM" PRIMARY KEY (id, order_id, product_id, quantity),
CONSTRAINT "FK_ORDER_ITEM_ORDER_ID" FOREIGN KEY (order_id) REFERENCES DEMO_DB.ORDERS.ORDERS (id),
CONSTRAINT "FK_ORDER_ITEM_PRODUCT_ID" FOREIGN KEY (product_id) REFERENCES DEMO_DB.ORDERS.PRODUCT (id)
);


--insert data
INSERT INTO DEMO_DB.ORDERS.ORDERS
  (id, date)
VALUES
  ('0', '2020-09-01'),
  ('1', '2020-10-01'),
  ('2', '2020-10-02'),
  ('3', '2020-11-01'),
  ('4', '2020-11-02'),
  ('5', '2020-12-01'),
  ('6', '2020-12-02');
  
INSERT INTO DEMO_DB.ORDERS.PRODUCT
    (id, name, price)
VALUES
    ('P0001', 'PRODUCT_1', '12.99'),
    ('P0002', 'PRODUCT_2', '6.99'),
    ('P0003', 'PRODUCT_3', '7.50');
    
INSERT INTO DEMO_DB.ORDERS.ORDER_ITEM
    (id, order_id, product_id, quantity)
VALUES
    ('1','0','P0001','1')
    
    ('1','1','P0001','2'),
    ('2','1','P0003','3'),
    
    ('1','2','P0001','1'),
    ('2','2','P0002','4'),
    ('3','2','P0003','2'),
    
    ('1','3','P0002','7'),
    ('2','3','P0003','2'),
    
    ('1','4','P0001','5'),
    ('2','4','P0002','1'),
    
    ('1','5','P0002','1'),
    ('2','5','P0003','7'),
    
    ('1','6','P0001','10'),
    ('2','6','P0002','5'),
    ('3','6','P0003','3');

--1) pokaż wszystkie zamówienia wraz z ich datami, liczbą zamówionych unikatowych produktów oraz kwotą każdego zamówienia, 
--1) display orders and thier date, distinct amount of products and order's value

SELECT distinct
    b.id as order_id,
    b.date,
    count(a.product_id) OVER (PARTITION BY b.id, b.date) as distinct_products_in_order,
    sum(c.price*a.quantity) OVER (PARTITION BY b.id, b.date) as order_price
    
FROM DEMO_DB.ORDERS.ORDER_ITEM a
INNER JOIN DEMO_DB.ORDERS.ORDERS b on a.order_id = b.id
INNER JOIN DEMO_DB.ORDERS.PRODUCT c on a.product_id = c.id

ORDER BY 2 desc;


--2) wyświetl średnią kwotę na każdą pozycję zamówienia dla zamówień z ostatnich 3 miesięcy. 
--2) avg price of each product for last 3 months

SELECT 
    a.order_id as order_id,
    avg(c.price) as avg_price
    
FROM DEMO_DB.ORDERS.ORDER_ITEM a
INNER JOIN DEMO_DB.ORDERS.ORDERS b on a.order_id = b.id
INNER JOIN DEMO_DB.ORDERS.PRODUCT c on a.product_id = c.id

WHERE b.date > (SELECT DATEADD('month', -3, DATE_TRUNC('month', CURRENT_DATE)))

GROUP BY 1
ORDER BY 2;



--3) pokaż ranking najczęściej zamawianych produktów: pod względem liczy uniaktowych zamówień w któych występuje i liczby sztuk. 
--3) rank of most often order products based on distinct orders in which it appears and quantity ordered

SELECT 
    c.name as product_name,
    count(a.product_id) as times_orderd,
    sum(a.quantity) as quantity_ordered
    
FROM DEMO_DB.ORDERS.ORDER_ITEM a
INNER JOIN DEMO_DB.ORDERS.ORDERS b on a.order_id = b.id
INNER JOIN DEMO_DB.ORDERS.PRODUCT c on a.product_id = c.id

GROUP BY 1
ORDER BY 2;


--4) pokaż zamówienia i ich wartość ale tylko zamówień na kwotę powyżej 50 pln, wyświetl pierwsze 5 o najwyższej kwocie
--4) dispaly top 5 orders whose price is above 50 pln

SELECT 
    a.order_id,
    sum(a.quantity*c.price) as total_price_of_order
    
FROM DEMO_DB.ORDERS.ORDER_ITEM a
INNER JOIN DEMO_DB.ORDERS.ORDERS b on a.order_id = b.id
INNER JOIN DEMO_DB.ORDERS.PRODUCT c on a.product_id = c.id

GROUP BY 1
HAVING total_price_of_order >= 50
ORDER BY 2 DESC
limit 5
;



--5) pokaż o ile procentowo wzrosły/spadły wartości zamówień produktów w styczniu w stosunku do grudnia 2016
--5) % rise/drop of products orders between jan and dec 16'

SELECT
    distinct
    product_name,
    trunc((total_price_of_order_month - total_price_of_order_previous_month) / total_price_of_order_month * 100) as diff_in_percentage
    
FROM (

        SELECT 

          distinct 
          product_name,

          iff(
            SPLIT_PART(LISTAGG(total_price_of_order, ' ') within group (ORDER BY product_name, month desc) OVER (PARTITION BY PRODUCT_NAME), ' ', 1) = '',
            0, 
            SPLIT_PART(LISTAGG(total_price_of_order, ' ') within group (ORDER BY product_name, month desc) OVER (PARTITION BY PRODUCT_NAME), ' ', 1)
          ) as total_price_of_order_month,

          iff(
            SPLIT_PART(LISTAGG(total_price_of_order, ' ') within group (ORDER BY product_name, month desc) OVER (PARTITION BY PRODUCT_NAME), ' ', 2) = '',
            0, 
            SPLIT_PART(LISTAGG(total_price_of_order, ' ') within group (ORDER BY product_name, month desc) OVER (PARTITION BY PRODUCT_NAME), ' ', 2)
          ) as total_price_of_order_previous_month


        FROM (SELECT 
                    c.name as product_name,
                    DATE_TRUNC('month', b.date) as month,
                    sum(a.quantity*c.price) as total_price_of_order

                FROM DEMO_DB.ORDERS.ORDER_ITEM a
                INNER JOIN DEMO_DB.ORDERS.ORDERS b on a.order_id = b.id
                INNER JOIN DEMO_DB.ORDERS.PRODUCT c on a.product_id = c.id

                WHERE b.date >= (SELECT DATEADD('month', -1, DATE_TRUNC('month', CURRENT_DATE)))
 

                GROUP BY 1,2));
                
--6) pokaż jaki udział % wszystkich zamówionych sztuk we wszystkich zamówieniach stanowią produkty o cenie większej niż 10 pln
--6) what is the % of ordered products' units whose price is > 10 pln 

SELECT 
  
   (SELECT sum(a.quantity) as total_quantity FROM DEMO_DB.ORDERS.ORDER_ITEM a 
    INNER JOIN DEMO_DB.ORDERS.PRODUCT c on a.product_id = c.id
    WHERE c.price > 10 ) / (SELECT sum(a.quantity) as total_quantity FROM DEMO_DB.ORDERS.ORDER_ITEM a) * 100 as val;
    
    
--7) posortuj wszystkie zamówienia, w których zamówiony był produkt Theozol Bio wg daty malejąco i pokaż jakie były odstępy pomiędzy zamówieniami w dniach
--7) order decending Theozol Bio's orders and display gap (in days) between each order's date

SELECT 
    a.order_id,
    --c.id as product_id,
    b.date as order_date,
    b.date - LAG(b.date, 1, null) OVER (PARTITION BY c.id ORDER BY c.id, b.date asc) as days_from_last_order

FROM DEMO_DB.ORDERS.ORDER_ITEM a
INNER JOIN DEMO_DB.ORDERS.ORDERS b on a.order_id = b.id
INNER JOIN DEMO_DB.ORDERS.PRODUCT c on a.product_id = c.id

WHERE c.id = 'P0002'
--ORDER BY 2 DESC