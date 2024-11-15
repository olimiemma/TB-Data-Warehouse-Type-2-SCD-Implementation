--Let's start with Country.  
--Let's create a country_dim. 
--Let's use Serial. 

create table tb_dw.country_dim (
country_id serial primary key,
country_name varchar(100));

insert into tb_dw.country_dim (country_name) values ('Test Country');
select * from tb_dw.country_dim;
insert into tb_dw.country_dim (country_name)
values ('Another Test Country');

delete from tb_dw.country_dim; 

insert into tb_dw.country_dim (country_name)
(select distinct country from tb order by country);

select * from tb_dw.country_dim order by country_id;

--Now let's create a Gender dimension using Identity. 
--Let's create a code and description column.

create table tb_dw.gender_dim (
    gender_id int GENERATED ALWAYS AS IDENTITY primary key,
    gender_code char(1),
    gender_desc varchar(10)
);

select * from tb_dw.gender_dim; 

--Note we could have used DEFAULT if we wanted to override the identity column.  
--Also note that Identity still creates an explicit sequence - in prior versions it did not.

select distinct sex from tb

--Note the values are 'male' and 'female'.  Let's make the code M and F, 
--but we should also add another 'O' even though its not in our data.  
--There are many ways to do this (e.g. CASE, but let's upper the first character.  
--Also, let's have proper case on the description.

insert into tb_dw.gender_dim (gender_code,gender_desc)
(select distinct upper(substr(sex,1,1)), initcap(sex)
from tb order by initcap(sex));

select * from tb_dw.gender_dim;

--Now let's add our 'Other' row.

insert into tb_dw.gender_dim (gender_code,gender_desc)
values ('O','Other');


create table tb_dw.year_dim (
    year_id serial primary key,
    year_value int);
	
select * from  tb_dw.year_dim

drop table tb_dw.year_dim;

--Now that we have our dimensions, let's create our TB_FACT table.  
--We need to have the surrogate keys replace the value, and let's clean up some naming:

create table tb_dw.tb_fact
(country_id int references tb_dw.country_dim (country_id),
year_id int references tb_dw.year_dim (year_id),
gender_id int references tb_dw.gender_dim (gender_id),
child_disease_amt int,
adult_disease_amt int,
elderly_disease_amt int,
primary key (country_id, year_id, gender_id ));

select * from tb_dw.tb_fact

drop table tb_dw.tb_fact; 
--Now let's load it, 
--we will need to adjust, join and bring in the correct keys.

insert into tb_dw.tb_fact
(select c.country_id, y.year_id, g.gender_id, t.child, t.adult, t.elderly
from tb t, tb_dw.country_dim c, tb_dw.year_dim y, tb_dw.gender_dim g
where t.country = c.country_name
and t.year = y.year_value
and t.sex = lower(g.gender_desc));



select count(*) from tb;
select count(*) from tb_dw.tb_fact;

select * from tb_dw.tb_fact order by country_id, year_id, gender_id;


DROP TABLE IF EXISTS tb_dw.tb_fact;
DROP TABLE IF EXISTS tb_dw.gender_dim;
DROP TABLE IF EXISTS tb_dw.year_dim;
DROP TABLE IF EXISTS tb_dw.country_dim;


--Awesome, now let's get the better describing information from the dimensions:

select c.country_name, y.year_value, g.gender_code,
f.child_disease_amt, f.adult_disease_amt, f.elderly_disease_amt
from tb_dw.tb_fact f, tb_dw.country_dim c,
tb_dw.year_dim y, tb_dw.gender_dim g
where f.country_id = c.country_id
and f.year_id = y.year_id
and f.gender_id = g.gender_id
order by c.country_name, y.year_value, g.gender_code;


DROP SEQUENCE IF EXISTS tb_dw.country_dim_country_id_seq;
DROP SEQUENCE IF EXISTS tb_dw.gender_dim_gender_id_seq;

DROP SCHEMA IF EXISTS tb_dw CASCADE;
