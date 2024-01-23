CREATE or REPLACE TABLE DEMO_DB.ORDERS.ORDERS_ZAD2
(NR_ZAM varchar(255),
DATA_ZAM date,
DAWKA varchar(255),
WARTOSC  number(38,0));


INSERT INTO DEMO_DB.ORDERS.ORDERS_ZAD2
  (NR_ZAM, DATA_ZAM,DAWKA,WARTOSC)
VALUES
    ('NPR-001', '2015-01-22', 'bioaron c', '100'),
    ('NPR-002', '2015-05-22', 'bioaron k+d', '200'),
    ('NPR-003', '2015-07-23', 'bronchosol 100 ml', '10'),
    ('NPR-004', '2015-11-24', 'bronchosol 200 ml', '14'),
    ('NPR-005', '2015-12-25', 'zdrovital 100 tabl', '16'),
    ('NPR-006', '2015-08-26', 'fiorda 100 kaps', '4'),
    ('NPR-007', '2016-01-27', 'zdrovital tabl. Mus', '25'),
    ('NPR-008', '2015-02-28', 'fiorda 50 kaps', '2'),
    ('NPR-009', '2015-03-01', 'zdrovital tabl. Mus. + gratis', '30'),
    ('NPR-010', '2016-03-22', 'zdrovital 200 tabl', '5');
    
--1. Proszę wyświetlić najwyższą i najniższą wartość zamówienia oraz różnicę pomiędzy nimi.
--1. Display highest and lowest value of each order and difference between both.
SELECT 
    max(WARTOSC) as max , 
    min(WARTOSC) as min, 
    max(WARTOSC) - min(WARTOSC) as diff 
FROM DEMO_DB.ORDERS.ORDERS_ZAD2

--2. Proszę wyświetlić średnią wartość zamówień w 2015 roku.
--2. Avg price of orders in 2015
SELECT avg(WARTOSC) FROM DEMO_DB.ORDERS.ORDERS_ZAD2 WHERE year(DATA_ZAM) = '2015';

--3. Proszę sprawdzić czy numery zamówień są unikalne
--3. Check if each order has unique id
SELECT NR_ZAM, count(*) FROM DEMO_DB.ORDERS.ORDERS_ZAD2 GROUP BY 1 HAVING count(*) > 1