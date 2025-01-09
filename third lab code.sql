-- views --

-- 1 --
create temp view vodilas as
select first_name, last_name, father_name 
from auto_personnel;

select * from vodilas;
select * from auto_personnel;

drop view vodilas;

-- 2 --
create temp view routes_cars as
select routes.name, count(journal.auto_id) as number_of_cars
from routes
full join journal on routes.id = journal.route_id
group by routes.name;

select * from routes_cars;

select * from journal;
select * from routes;

drop view routes_cars;


-- procedure --

-- 1 --
create or replace function count_time()
returns table (routes_id varchar, time_avg numeric)
language plpgsql
as 
$$
BEGIN
	return query
		select routes.name, avg(extract(epoch from (journal.time_in - journal.time_out)) / 60)
		from routes
		left outer join journal on journal.route_id = routes.id
		--where not (time_in is null)
		group by routes.name;
END;
$$;

DROP FUNCTION count_time();

select * from count_time();

-- 2 --
drop function speed_driver(auto_id1 integer, auto_id2 integer);
create or replace function speed_driver(auto_id1 integer, auto_id2 integer)
returns table (route_name varchar)
language plpgsql
as 
$$
BEGIN
	return query
		select routes.name as route_name from routes
		left join journal as j1 
		on routes.id = j1.route_id
		left join journal as j2
		on j1.route_id = j2.route_id
		where 
		j1.time_in is not null 
		and j2.time_in is not null
		and j1.auto_id != j2.auto_id
		and (j1.auto_id = auto_id1 and j2.auto_id = auto_id2)
		and (j1.time_in - j1.time_out) < (j2.time_in - j2.time_out);
END;
$$;

DROP FUNCTION speed_driver();
select * from journal;

select * from speed_driver(7, 4);

-- 3 --
create or replace function record_driver(route integer)
returns table (time_rec interval, auto integer)
language plpgsql
as 
$$
BEGIN
	return query
		select min(time_in - time_out) as time_record, auto_id from journal
		where (route_id = route) and (time_in is not null)
		group by auto_id
		order by time_record limit 1;
END;
$$;

DROP FUNCTION record_driver(integer);
select * from journal;

select * from record_driver(1);

-- triggers --

-- 1 --
create or replace function save_insert()	
returns trigger
language plpgsql
as
$$
begin
	if (exists (select * from journal
	where (auto_id = new.auto_id) and (time_in is null)))
	then
	RAISE EXCEPTION '% no insert for this car', new;
	end if;
	return new;
end;
$$

create or replace trigger safety
	before insert
	on journal
	for each row
	execute function save_insert();

select * from journal;

insert into journal (time_out, time_in, route_id, auto_id) values 
('12:05:33', '16:07:20', 7, 2);
	
-- 2 --
create or replace function save_update()	
returns trigger
language plpgsql
as
$$
begin
	if exists (select * from journal
	where (route_id = old.id))
	then
		insert into routes(name) values (old.name);
		update journal
		set route_id = (select id from routes
		where name = old.name)
		where journal.route_id = new.id;
	end if;
	return new;
end;
$$

create or replace trigger safety_update
	after update
	on routes
	for each row
	execute function save_update();

select * from routes;
select * from journal;

update routes set name = 'Владивосток - Хабаровск' where name = 'rr';

-- 3 --
create or replace function save_delete()
returns trigger
language plpgsql
as
$$
begin
	if exists (select * from auto 
	where (personal_id = old.id))
	then
		RAISE EXCEPTION '% no delete for this human', new;
	end if;
	return old;
end;
$$

drop procedure save_delete();
drop trigger safety_delete on auto_personnel;

create or replace trigger safety_delete
	before delete
	on auto_personnel
	for each row
	execute function save_delete();

select * from auto_personnel;
select * from auto;

delete from auto_personnel
where id = 4;

-- cursor --
create or replace function prem_drivers(
	time1 time,
	time2 time,
	summa integer)
returns table (
	id_vod integer,
	prem double precision)
language plpgsql
as 
$$
declare
	vod_cursor cursor for
		select id
		from auto_personnel;
	vod1 integer;
	vod2 integer;
	vod3 integer;
	res1 double precision;
	res2 double precision;
	res3 double precision;
	res_temp double precision;
	time_temp double precision;
	count_temp integer;
	vod_id_temp integer;
BEGIN
	open vod_cursor;
	res1 = 0.0;
	res2 = 0.0;
	res3 = 0.0;
	loop
		fetch from vod_cursor into vod_id_temp;
		
		time_temp = (select sum(extract(epoch from (journal.time_in - journal.time_out)) / 60) from journal
		where (time_in <= time1) and (time_out >= time2) 
		and auto_id in 
		(select id from auto where auto.personal_id = vod_id_temp));
		raise notice 'Value: %', time_temp;
		
		count_temp = (select count(id) from journal
		where (time_in <= time1) and (time_out >= time2) 
		and auto_id in 
		(select id from auto where auto.personal_id = vod_id_temp));
		raise notice 'Value: %', count_temp;
		
		res_temp = count_temp / time_temp;

		if (res_temp >= res1) then
			res3 = res2;
			vod3 = vod2;
			res2 = res1;
			vod2 = vod1;
			res1 = res_temp;
			vod1 = vod_id_temp;
		else if (res_temp >= res2) then
			res3 = res2;
			vod3 = vod2;
			res2 = res_temp;
			vod2 = vod_id_temp;
		else if (res_temp >= res3) then
			res3 = res_temp;
			vod3 = vod_id_temp;
		end if;
		end if;
		end if;
		
		exit when not found;
	end loop;

	close vod_cursor;

	drop table premii;
	create temp table premii(id_vod integer,
	prem double precision);
	insert into premii (id_vod,	prem) values
		(vod1, summa * 0.5),
		(vod2, summa * 0.3),
		(vod3, summa * 0.2);
		
	return query 
		select * from premii;
END;
$$;

select * from prem_drivers(
	'23:59:59',
	'00:00:00',
	50000);

sum(extract(epoch from (journal.time_in - journal.time_out)) / 60)
select * from auto_personnel;
select * from auto;

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