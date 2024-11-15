drop table port_dim;

-- Type 2 needs dates, current ind and unique code
create table port_dim (
port_dim_id integer primary key,
port_nbr integer,
port_name varchar(50),
port_state varchar(20),
total_trade_amt decimal(15),
effective_date date,
expiry_date date,
current_nbr integer);

insert into port_dim 
values (100, 1, 'Port of South Louisiana','Lousiana',
	   238585604,to_date('11-02-2022','MM-DD-YYYY'),
	   null,1);

insert into port_dim 
values (101, 2, 'Port of Houston','Texas',
	   229246833,to_date('11-02-2022','MM-DD-YYYY'),
	   null,1);
	   
insert into port_dim 
values (102, 3, 'Port of Newark','New Jersey',
	   123322644,to_date('11-02-2022','MM-DD-YYYY'),
	   null,1);
	   
select * from port_dim order by port_dim_id;

-- Looks good, now name changed to for 3 to 
-- Port of Newark and New York on 11/9

insert into port_dim 
values (103, 3, 'Port of Newark and New York','New Jersey',
	   123322644,to_date('11-09-2022','MM-DD-YYYY'),
	   null,1);
update port_dim set expiry_date = 
		to_date('11-08-2022','MM-DD-YYYY'), 
		current_nbr = 0 where port_dim_id = 102;
--delete from port_dim where port_dim_id = 104;
select * from port_dim order by port_dim_id;
-- current rows only
select * from port_dim 
where current_nbr = 1
order by port_dim_id;

-- State changes a week later
insert into port_dim 
values (104, 3, 'Port of Newark and New York','New York',
	   123322644,to_date('11-16-2022','MM-DD-YYYY'),
	   null,1);
update port_dim set expiry_date = 
		to_date('11-15-2022','MM-DD-YYYY'), 
		current_nbr = 0 where port_dim_id = 103;
		
select * from port_dim order by port_dim_id;
-- current rows only
select * from port_dim 
where current_nbr = 1
order by port_dim_id;

-- Fact tables will point to the appropriate row, so 
-- it gets data 'as was' at time of reporting.
select port_name, port_state from port_dim where port_dim_id in (102, 103, 104)
order by port_dim_id;
-- What if always want current - Say fact points to original
-- Newark port but you want current.  Fact will have 102
select c.port_name, c.port_state,c.current_nbr 
from port_dim c, port_dim o
where o.port_dim_id = 102 -- this comes from fact
and o.port_nbr = c.port_nbr -- what is in common
and c.current_nbr = 1;

-- What if we wanted at as of specific date, say 11/11
select sd.port_name, sd.port_state,
sd.effective_date, sd.expiry_date, sd.current_nbr
from port_dim sd, port_dim o
where o.port_dim_id = 102 -- this comes from fact
and o.port_nbr = sd.port_nbr -- what is in common
and sd.effective_date <= 
to_date('11-11-2022', 'MM-DD-YYYY')
and 
coalesce(sd.expiry_date,
to_date('12-31-9999','MM-DD-YYYY'))
>= to_date('11-11-2022', 'MM-DD-YYYY');
-- original - one way
select fp.port_name, fp.port_state,
fp.effective_date, fp.expiry_date, fp.current_nbr
from port_dim fp, port_dim f
where f.port_dim_id = 102 -- this comes from fact
and f.port_nbr = fp.port_nbr -- what is in common
order by fp.effective_date limit 1;