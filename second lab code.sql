-- funcs to see changes

select * from auto_personnel;
select * from auto;
select * from routes;
select * from journal;

--------------------1--------------------
select * from auto_personnel
order by last_name ASC, first_name DESC;

--------------------2--------------------
select count (num) 
from auto
where left(num, 1) = 'Р';

select count (num) 
from auto
where num like 'Р%';

--------------------3--------------------
select num from auto
where personal_id = (select id from auto_personnel
where last_name = 'Лебедев');

--------------------4--------------------
select name from routes
where exists (select route_id from journal
where time_in is NULL and route_id = routes.id);

select name from routes
where id in (select route_id from journal
where time_in is NULL);

--------------------5--------------------
select routes.name, journal.time_out from routes
left join journal
ON journal.route_id = routes.id;

--------------------6--------------------
select journal.time_out, journal.time_in, routes.name, auto.num
from journal
right join routes ON journal.route_id = routes.id
full join auto ON journal.auto_id = auto.id;

--funcs for cleaning

delete from auto_personnel;
delete from auto;
delete from routes;
delete from journal;

-- adding info in tables

-- auto_personnel table (first name, last name and father name)
insert into auto_personnel (first_name, last_name, father_name) values 
('Сергей','Иванов','Викторович'),
('Мария','Петрова','Михайловна'),
('Дмитрий','Смирнов','Иванович'),
('Елена','Васильева','Андреевна'),
('Алексей','Кузнецов','Сергеевич'),
('Наталья','Морозова','Васильевна'),
('Михаил','Лебедев','Юрьевич');

-- auto table (num, color and mark), personal id was added by interface
insert into auto (num, color, mark) values 
('К333МР','Красный','Toyota'),
('О777ОО','Черный','Ford'),
('Е555ЕР','Красный','Toyota'),
('Н888НК','Черный','BMW'),
('М666ММ','Серый','Ford'),
('А222АВ','Белый','Nissan'),
('С444СС','Белый','Toyota');

-- routes table (only name)
insert into routes (name) values 
('Москва - Санкт-Петербург'),
('Новосибирск - Красноярск'),
('Екатеринбург - Пермь'),
('Нижний Новгород - Казань'),
('Ростов-на-Дону - Краснодар'),
('Самара - Уфа'),
('Владивосток - Хабаровск');

-- journal table (time out, time in, route id, auto id)
insert into journal (time_out, time_in, route_id, auto_id) values 
('12:05:33', '16:07:20', 7, 1),
('16:55:31', NULL, 6, 2),
('06:00:57', '21:22:22', 6, 3),
('15:44:09', '16:37:28', 1, 4),
('18:08:08', '22:50:12', 3, 5),
('23:00:00', NULL, 1, 6),
('09:14:08', '10:07:20', 1, 7);
