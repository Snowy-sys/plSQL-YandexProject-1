# plSQL-YandexProject-1
Самостоятельный проект по итогу окончания курса "Основы SQL и баз данных"

## Ревью
Результат ревью по проекту размещен в Comments.txt.

## Описание проекта. Автосалона "Врум-Бум".
«Врум-Бум» — прославившаяся сеть салонов легковых автомобилей — стремительно набирает обороты. Их карманный слоган «Если вы слышите Врум, значит уже Бум!» стал знаком качества, который привлекает тысячи покупателей ежедневно. Сеть предоставляет широкий выбор машин от экономкласса до люксовых спорткаров и обслуживает всю страну.

Однако их быстрый рост привел к непредвиденным трудностям: с каждым новым салоном становится все сложнее управлять огромным объёмом данных о продажах, поставках, запасах и клиентах. Вся эта информация сейчас хранится в сыром, неструктурированном виде, что сильно затрудняет работу.

Кроме того, «Врум-Бум» хотел бы применять более сложные аналитические методы, чтобы лучше понять своих клиентов, улучшить бизнес-процессы и увеличить продажи. Они понимают, что успешное будущее их компании во многом зависит от качественного анализа данных, и поэтому обратились к вам за помощью.

### Цель проекта
Нормализовать и структурировать существующие "сырые" данные, предварительно перенеся их в PostgreSQL, а потом написать несколько запросов для получения информации из БД. **Результатом станет набор SQL-команд, объединённых в единый скрипт**. 

#### Предусловия
Необходимо нормализовать и структурировать существующие "сырые" данные из файла cars.csv. Подробный процесс нормализации и структуризации размещен в СР_1.sql настоящего проекта.

#### Задание №1
Напишите запрос, который выведет процент моделей машин, у которых нет параметра gasoline_consumption.
```sql
select 100 - (count(gasoline_consumption) * 100 / count(*)) as nulls_percentage_gasoline_consumption
 from car_shop.cars;
```

#### Задание №2
Напишите запрос, который покажет название бренда и среднюю цену его автомобилей в разбивке по всем годам с учётом скидки. Итоговый результат отсортируйте по названию бренда и году в восходящем порядке. Среднюю цену округлите до второго знака после запятой.
```sql
select 
  br.brand_name as brand_name, 
  round(avg(pur.price),2) as avg_price, 
  extract (year from pur.purchase_date) as year
 from car_shop.brands as br
  left join car_shop.cars c ON c.id_brand = br.id
  left join car_shop.purchases pur on c.id_brand = pur.id_cars
 where br.brand_name is not null
  group by br.brand_name, extract (year from pur.purchase_date)
 order by brand_name, year asc;
```

#### Задание №3
Посчитайте среднюю цену всех автомобилей с разбивкой по месяцам в 2022 году с учётом скидки. Результат отсортируйте по месяцам в восходящем порядке. Среднюю цену округлите до второго знака после запятой.
```sql
select 
  extract(month from purchase_date) as month, 
  extract (year from purchase_date) as year,
  round(avg(price),2)
 from car_shop.purchases
  where extract (year from purchase_date) = 2022
 group by extract(month from purchase_date), extract (year from purchase_date)
  order by month asc;
```

#### Задание №4
Используя функцию STRING_AGG, напишите запрос, который выведет список купленных машин у каждого пользователя через запятую. Пользователь может купить две одинаковые машины — это нормально. Название машины покажите полное, с названием бренда — например: Tesla Model 3. Отсортируйте по имени пользователя в восходящем порядке. Сортировка внутри самой строки с машинами не нужна.
```sql
select 
  (c.first_name || ' ' || c.last_name) as person,
  string_agg((b.brand_name || '' || m.model_name), ', ') as cars
 from car_shop.clients c
  left join car_shop.purchases p on c.id = p.id_client
  left join car_shop.cars car on car.id = p.id_cars
  left join car_shop.brands b on b.id = car.id_brand
  left join car_shop.models m on m.id = car.id_model
 group by person
  order by person asc;
```

#### Задание №5
Напишите запрос, который вернёт самую большую и самую маленькую цену продажи автомобиля с разбивкой по стране без учёта скидки. Цена в колонке ```price``` дана с учётом скидки.
```sql
select 
  con.country_name as brand_origin, 
  round(max(pur.price / (100 - pur.discount) * 100),2) as price_max,
  round(min(pur.price / (100 - pur.discount) * 100),2) as price_min
 from car_shop.countries con
  left join car_shop.brands b on con.id = b.id_country
  left join car_shop.cars c on c.id_brand = b.id
  left join car_shop.purchases pur on c.id = pur.id_cars
 where con.country_name is not null
  group by brand_origin;
```

#### Задание №6
Напишите запрос, который покажет количество всех пользователей из США. Это пользователи, у которых номер телефона начинается на +1.
```sql
select count(first_name) as persons_from_usa_count
 from car_shop.clients
where phone like '+1%';
```
