#Код для того, чтобы узнать путь к скрытой папке. В эту папку скинуть все необходимые файлы
SHOW VARIABLES LIKE 'secure_file_priv';

#Создаем базу данных
CREATE DATABASE orders;
SHOW DATABASES;
USE orders;

DROP table orders;


#создаем таблицу orders
 create table orders
    (no bigint not null auto_increment,
    seccode varchar(30),
    buysell char(1),
    time bigint,
    orderno bigint,
    action enum('0', '1', '2'),
    price float,
    volume bigint,
    tradeno bigint,
    tradeprice float,
    primary key (no));

#Загрузим данные в созданную таблицу
 load data infile '/private/var/lib/mysql-files/IT/OrderLog20150901/OrderLog20150901.txt'
        into table orders
        fields terminated by ','
        enclosed by '"'
        lines terminated by '\r\n'
        ignore 1 lines
        (@no,
        @seccode,
        @buysell,
        @time,
        @orderno,
        @action,
        @price,
        @volume,
        @tradeno,
        @tradeprice)
        set
        no = if(@no='', default(no), @no),
        seccode = if(@seccode='', default(seccode), @seccode),
        buysell = if(@buysell='', default(buysell), @buysell),
        time = if(@time='', default(time), @time),
        orderno = if(@orderno='', default(orderno), @orderno),
        action = if(@action='', default(action), @action),
        price = if(@price='', default(price), @price),
        volume = if(@volume='', default(volume), @volume),
        tradeno = if(@tradeno='', default(tradeno), @tradeno),
        tradeprice = if(@tradeprice='', default(tradeprice), @tradeprice);

#Проверим заполненность таблицы        
select * from orders;


#проверка данные на нулевые значения
SELECT *,
If (
no is NULL or no =''
or
seccode is NULL or seccode =''
or
buysell is NULL or buysell =''
or
time is NULL or time =''
or
orderno is NULL or orderno =''
or
action is NULL or action =''
or
price is NULL or price =''
or
volume is NULL or volume   = '', 'DATA IS REQUIRED','COMPLETE DATA' 
) as `NULL AND GAPS CHECK` from orders;


#проверяем корректность тикеров.  
 SELECT *,
If (
length(seccode) = 5 or length(seccode) = 4 or length(seccode) = 12, 'data correct','data unidentified' 
) as `DATA CHECK` from orders;


#создадим таблицу для классификатора 
CREATE TABLE classificator (
INSTRUMENT_ID int,
INSTRUMENT_TYPE text,
TRADE_CODE text
); 

#загрузим данные
LOAD DATA INFILE '/private/var/lib/mysql-files/IT/classificator.csv' 
INTO TABLE classificator 
fields terminated by ','
lines terminated by '\r\n'
ignore 1 lines
(@INSTRUMENT_ID,@INSTRUMENT_TYPE,@TRADE_CODE)
set
INSTRUMENT_ID = if(@INSTRUMENT_ID='', default(INSTRUMENT_ID), @INSTRUMENT_ID),
INSTRUMENT_TYPE = if(@INSTRUMENT_TYPE='', default(INSTRUMENT_TYPE), @INSTRUMENT_TYPE),
TRADE_CODE = if(@TRADE_CODE='', default(TRADE_CODE), @TRADE_CODE);

#создадим таблицу с обыкновенным акциями 

CREATE TABLE Ordinary_Shares
SELECT SECCODE,BUYSELL,TIME,ORDERNO,ACTION,PRICE,VOLUME,TRADENO,TRADEPRICE 
FROM orders JOIN classificator
on SECCODE=TRADE_CODE
where INSTRUMENT_TYPE='Ordinary share';

#создадим таблицу с привилегированными акциями 

CREATE TABLE Preferred_Shares
SELECT SECCODE,BUYSELL,TIME, ORDERNO,ACTION,PRICE,VOLUME,TRADENO,TRADEPRICE 
FROM orders JOIN classificator
on SECCODE=TRADE_CODE
where INSTRUMENT_TYPE='preferred shares';

#создадим таблицу для облигаций

CREATE TABLE Bonds
SELECT SECCODE,BUYSELL,TIME,ORDERNO,ACTION,PRICE,VOLUME,TRADENO,TRADEPRICE 
FROM orders JOIN classificator
on SECCODE=TRADE_CODE
where INSTRUMENT_TYPE='Bond'
or INSTRUMENT_TYPE='Corporate bond' 
or INSTRUMENT_TYPE='Subfederal bond' 
or INSTRUMENT_TYPE='Bonds of a foreign issuer' 
or INSTRUMENT_TYPE='Eurobonds'
or INSTRUMENT_TYPE='Federal loan bond';

#проверим
select * from orders.Ordinary_shares;
select * from orders.Preferred_Shares;
select * from orders.Bonds;


#тикер с наибольшим количеством сделок
select SECCODE, count(SECCODE) 
from Ordinary_Shares 
group by SECCODE 
order by count(SECCODE) desc 
limit 1; 




