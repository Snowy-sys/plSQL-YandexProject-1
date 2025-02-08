/*Создание схемы*/
create schema raw_data;

/*Создание таблицы продаж (sales)*/
create table raw_data.sales (
	id serial primary key, --автоинкремент
	auto varchar(50) not null, --данные в таблице cars.csv размещены в текстовом формате. В названии бренда могут быть буквы и цифры
	gasoline_consumption numeric(3,1), --ограничение: число не может быть трёхзначным
	price numeric(9,2) not null, --ограничение: цена на авто не может равняться нулю. Тип данных numeric, т.к. необходима повышенная точность, а также цена не может быть больше семизначной суммы
	date date not null, --ограничение: дата покупки авто не может равняться нулю
	person_name varchar not null, --ограничение: ФИО покупателя не может равняться нулю
	phone varchar not null, --данные в таблице cars.csv размещены в текстовом формате
	discount smallint, --тип данных smallint, т.к. скидка может варьироваться в диапазоне от 0 до 100 процентов
	brand_origin varchar --данное поле может быть пустым
);

--Копирование данных таблицы cars.csv в таблицу sales
copy raw_data.sales from 'C:\Program Files\PostgreSQL\cars.csv' with csv header null as 'null';

/*Создание схемы car_shop*/
create schema car_shop;

/*Создание таблицы цвета авто (colors)*/
create table car_shop.colors (
	id serial primary key, --автоинкремент
	color_name varchar(10) not null unique --наименование цвета в таблице должно быть уникальным. Значение не должно быть пустым
);

--Заполнение таблицы colors
insert into car_shop.colors (color_name)
select distinct split_part(auto,' ',-1) as name
from raw_data.sales;

/*Создание таблицы стран производств (countries)*/
create table car_shop.countries (
	id serial primary key, --автоинкремент 
	country_name varchar(20) not null --название страны не может быть больше 20 символов, не может быть пустым и должно быть уникальным
);

--Заполнение таблицы countries
insert into car_shop.countries (country_name)
select distinct brand_origin as name
from raw_data.sales
where brand_origin is not null;

/*Создание таблицы стран (brands)*/
create table car_shop.brands (
	id serial primary key, --автоинкремент
	brand_name varchar(50), --название бренда не может быть больше 50 символов 
	id_country int references car_shop.countries(id) --ID страны производства бренда. Не может быть пустым
);

--Заполнение таблицы brands
INSERT INTO car_shop.brands (brand_name, id_country)
SELECT DISTINCT SUBSTR(sl.auto,1,STRPOS(sl.auto,' ')-1),cn.id
FROM raw_data.sales as sl 
full JOIN car_shop.countries as cn ON sl.brand_origin = cn.country_name
where sl.auto is not null;

/*Создание таблицы модели авто (models)*/
create table car_shop.models (
	id serial primary key, --автоинкремент
	model_name varchar(20) not null --название модели авто не может быть больше 20 символов
);

--Заполнение таблицы models
insert into car_shop.models (model_name)
SELECT DISTINCT split_part(SUBSTR(sl.auto,STRPOS(sl.auto,' '),STRPOS(sl.auto,',')),',', 1)
FROM raw_data.sales as sl;

/*Создание таблицы клиентов (clients)*/
create table car_shop.clients (
	id serial primary key, -- автоинкремент
	first_name varchar(50),--Имя клиента не может превышать 50 символов
	last_name varchar(50),--Фамилия клиента не может превышать 50 символов
	phone varchar --телефон клиента в формате varchar, т.к. данные в таблице cars.csv размещены в текстовом формате
);

--Заполнение таблицы clients
insert into car_shop.clients (first_name, last_name, phone)
select distinct 
	split_part(SUBSTR(sl.person_name,STRPOS(sl.person_name,'.'),STRPOS(sl.person_name,' ')),'.', 1) as name,
	split_part(SUBSTR(sl.person_name,STRPOS(sl.person_name,' '),STRPOS(sl.person_name,' ')),' ', 2) as surname, 
	sl.phone 
from raw_data.sales as sl
group by sl.person_name, sl.phone;

/*Создание таблицы с наименованием брендов авто (cars)*/
create table car_shop.cars (
	id serial primary key, --автоинкремент
	id_brand int not null references car_shop.brands(id), --id бренда авто из таблицы brands
	id_model int not null references car_shop.models(id), --id модели авто из таблицы models
	gasoline_consumption numeric(3,1) --расход бензина: число не может быть трёхзначным
);

--Заполнение данных таблицы cars
INSERT INTO car_shop.cars (id_brand, id_model, gasoline_consumption)
SELECT DISTINCT 
	b.id, 
	m.id,
	sl.gasoline_consumption
FROM raw_data.sales as sl
JOIN car_shop.brands as b ON SUBSTR(sl.auto,1,STRPOS(sl.auto,' ')-1) = b.brand_name
join car_shop.models as m on split_part(SUBSTR(sl.auto,STRPOS(sl.auto,' '),STRPOS(sl.auto,',')),',', 1) = m.model_name;

/*Создание таблицы сделок (purchases)*/
create table car_shop.purchases(
	id serial primary key, -- автоинкремент
	id_cars int references car_shop.cars(id), --id авто из таблицы cars
	id_colors int references car_shop.colors(id), --id цвета авто из таблицы colors
	price numeric(9,2) not null, -- цена сделки. Цена на авто не может равняться нулю. Тип данных numeric, т.к. необходима повышенная точность, а также цена не может быть больше семизначной суммы
	discount smallint, -- скидка
	purchase_date date not null, -- дата сделки
	id_client int references car_shop.clients(id) --id клиентов из таблицы clients
);

--Заполнение таблицы purchases
insert into car_shop.purchases (id_cars, id_colors, price, discount, purchase_date, id_client)
select distinct
	c.id,
	col.id,
	sl.price,
	sl.discount,
	sl.date,
	cl.id
from raw_data.sales as sl
join car_shop.models m on split_part(SUBSTR(sl.auto,STRPOS(sl.auto,' '),STRPOS(sl.auto,',')),',', 1) = m.model_name
join car_shop.cars c on c.id_model = m.id
join car_shop.colors col on split_part(sl.auto,' ',-1) = col.color_name
join car_shop.clients cl on sl.phone = cl.phone;

/*Создание выборок*/

 /*задание 1*/
select 100 - (count(gasoline_consumption) * 100 / count(*)) as nulls_percentage_gasoline_consumption
from car_shop.cars;

/*задание 2*/
select br.brand_name as brand_name, 
	   round(avg(pur.price),2) as avg_price, 
       extract (year from pur.purchase_date) as year
from car_shop.brands as br
left join car_shop.cars c ON c.id_brand = br.id
left join car_shop.purchases pur on c.id_brand = pur.id_cars
where br.brand_name is not null
group by br.brand_name, extract (year from pur.purchase_date)
order by brand_name, year asc;

/*задание 3*/
select extract(month from purchase_date) as month, extract (year from purchase_date) as year,
       round(avg(price),2)
from car_shop.purchases
where extract (year from purchase_date) = 2022
group by extract(month from purchase_date), extract (year from purchase_date)
order by month asc;

/*задание 4*/
select (c.first_name || ' ' || c.last_name) as person,
       string_agg((b.brand_name || '' || m.model_name), ', ') as cars
from car_shop.clients c
left join car_shop.purchases p on c.id = p.id_client
left join car_shop.cars car on car.id = p.id_cars
left join car_shop.brands b on b.id = car.id_brand
left join car_shop.models m on m.id = car.id_model
group by person
order by person asc;


/*задание 5*/
select con.country_name as brand_origin, round(max(pur.price / (100 - pur.discount) * 100),2) as price_max,
       round(min(pur.price / (100 - pur.discount) * 100),2) as price_min
from car_shop.countries con
left join car_shop.brands b on con.id = b.id_country
left join car_shop.cars c on c.id_brand = b.id
left join car_shop.purchases pur on c.id = pur.id_cars
where con.country_name is not null
group by brand_origin;

/*задание 6*/
select count(first_name) as persons_from_usa_count
from car_shop.clients
where phone like '+1%';