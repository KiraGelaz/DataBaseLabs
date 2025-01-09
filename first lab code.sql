create table if not exists auto_personnel
(
	id serial primary key,
	first_name varchar,
	last_name varchar,
	father_name varchar
);

comment on table auto_personnel is 'Сотрудники автопарка';

create table if not exists auto
(
	id serial primary key,
	num varchar,
	color varchar,
	mark varchar,
	personal_id integer references auto_personnel (id) on delete cascade
);

comment on table auto is 'Автомобили автопарка';

create table if not exists routes
(
	id serial primary key,
	name varchar
);

comment on table routes is 'Маршруты';

create table if not exists journal
(
	id serial,
	time_out time,
	time_in time,
	route_id integer references routes (id) on delete cascade,
	auto_id integer references auto (id) on delete cascade
);

comment on table journal is 'Журнал оператора';