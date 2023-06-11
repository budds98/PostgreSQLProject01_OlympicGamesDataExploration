
--#1 total no of Olympic Games held as per the dataset.

select count(distinct games) as total_olympic_game
from olympics_history;

--#2 list of all the Olympic Games held so far.

select distinct year, season, city
from olympics_history
order by year;

--#3 total no of nations who participated in each olympics game.

select oh.games, count(distinct ohnr.region) as total_countries
from olympics_history oh
join olympics_history_noc_regions ohnr
	on oh.noc = ohnr.noc
group by 1
order by 1;

--#4 the Olympic Games with the highest and the lowest participating countries.

create temporary table temp_games (lowest_countries varchar)
insert into temp_games
	select concat(last_value(games) over (order by total_countries), ' - ', total_countries) as lowest_countries
	from(
		select oh.games, count(distinct ohnr.region) as total_countries
		from olympics_history oh
		join olympics_history_noc_regions ohnr
			on oh.noc = ohnr.noc
		group by 1
		order by 1) as total_countries_in_games
	limit 1

alter table temp_games
add column highest_countries varchar

update temp_games
set highest_countries = 
(select concat(first_value(games) over (order by total_countries desc), ' - ', total_countries) as highest_countries
from(
	select oh.games, count(distinct ohnr.region) as total_countries
	from olympics_history oh
	join olympics_history_noc_regions ohnr
		on oh.noc = ohnr.noc
	group by 1
	order by 1) as total_countries_in_games
limit 1);

select*
from temp_games;

--#5 the list of countries who have been part of every Olympics games.

select ohnr.region, count(distinct games) as total_participated_games
from olympics_history oh
join olympics_history_noc_regions ohnr
		on oh.noc = ohnr.noc
group by 1
having count(distinct games) = 51;

--#6 the sport which was played in all summer olympics

select  sport, count( distinct games) as no_of_games, count(distinct games) as total_games
from olympics_history
where season = 'Summer'
group by sport
having count(distinct games) = 29;

--#7 the sport which were just played once in all of olympics.

With 
oh1 as
	(select distinct games, sport
	from olympics_history),
oh2 as
	(select sport, count(distinct games) as no_of_games
	from oh1
	group by sport
	having count(distinct games) = 1)
select oh2.sport, no_of_games, games
from oh2
join oh1
	on oh1.sport = oh2.sport
order by 1;

--#8 the total no of sports played in each olympic games.

select distinct games, count(distinct sport) as no_of_sports
from olympics_history
group by 1;


--#9 the oldest athletes to win a gold medal

select name, sex, age, team, games
,city, sport, event, medal
from olympics_history
where medal = 'Gold' and age <> 'NA'
order by age desc, team
LIMIT 2;

--#10 the Ratio of male and female athletes participated in all olympic games.

with
t1 as
    (select sex, count(1) as cnt
    from olympics_history
    group by sex),
t2 as
	(select *, row_number() over(order by cnt) as rn
	from t1),
min_cnt as
	(select cnt from t2	where rn = 1),
max_cnt as
	(select cnt from t2	where rn = 2)
select concat(1, ' : ',round(max_cnt.cnt/min_cnt.cnt :: decimal,2))
from min_cnt, max_cnt;

--#11 the top 5 athletes who have won the most gold medals.

with 
top_medal as
			(select name, team, count(medal) as total_medal
			from olympics_history
			where medal = 'Gold'
			group by 1,2
			order by total_medal desc),
top_medal2 as
			(select *, dense_rank () over (order by total_medal desc) as rank
			from top_medal)	
select *
from top_medal2
where rank <= 5;


--#12 the top 5 athletes who have won the most medals (gold/silver/bronze).

with 
top_medal as
			(select name, team, count(medal) as total_medal
			from olympics_history
			where medal <> 'NA'
			group by 1,2)
select*
from top_medal
order by total_medal desc
limit 5;

--#13 the top 5 most successful countries in olympics. Success is defined by no of medals won.

with
successful_countries
as
	(select region, count(medal) as total_medals
	from olympics_history oh
	join olympics_history_noc_regions ohnr
		on ohnr.noc = oh.noc
	where medal <> 'NA'
	group by 1)
select *,
rank() over (Order by total_medals desc) as rnk
from successful_countries
limit 5;

--#14 total gold, silver and bronze medals won by each country during 1986 - 2016.

With
table1 as
		(select region, count(medal) as gold
		from olympics_history oh
			join olympics_history_noc_regions ohnr
				on ohnr.noc = oh.noc
			where medal = 'Gold'
			group by 1
			order by gold desc),
table2 as
		(select region, count(medal) as silver
		from olympics_history oh
			join olympics_history_noc_regions ohnr
				on ohnr.noc = oh.noc
			where medal = 'Silver'
			group by 1
			order by silver desc),
table3 as
		(select region, count(medal) as bronze
		from olympics_history oh
			join olympics_history_noc_regions ohnr
				on ohnr.noc = oh.noc
			where medal = 'Bronze'
			group by 1
			order by bronze desc)
select table1.region as country, table1.gold, table2.silver, table3.bronze
from table1
join table2
	on table2.region = table1.region
join table3
	on table3.region = table2.region
order by gold desc;

--#15 list of the  total gold, silver and bronze medals won by each country corresponding to each olympic games.

with 
temp_medal as
	(select games, region, medal,
	case when medal = 'Gold' then count(medal) else 0 end as gold,
	case when medal = 'Silver' then count(medal) else 0 end as silver,
	case when medal = 'Bronze' then count(medal) else 0 end as bronze
	from olympics_history oh
	join olympics_history_noc_regions ohnr
		on ohnr.noc = oh.noc
	where medal <> 'NA'
	group by 1,2,3
	order by 1)
select  games, region, sum(gold) tot_gold,sum(silver) tot_silver, sum(bronze) tot_bronze
from temp_medal
group by 1,2
order by 1;

--#16 country won the most gold, most silver and most bronze medals in each olympic games.

with
table1 as
		(select games, medal, region, count(1) as total_gold
		from olympics_history oh
		join olympics_history_noc_regions ohnr
			on ohnr.noc = oh.noc
			where medal = 'Gold'
			group by 1,2,3
			Order by 1),
table2 as
		(select games, medal, region, count(1) as total_silver
		from olympics_history oh
		join olympics_history_noc_regions ohnr
			on ohnr.noc = oh.noc
			where medal = 'Silver'
			group by 1,2,3
			Order by 1),
table3 as
		(select games, medal, region, count(1) as total_bronze
		from olympics_history oh
		join olympics_history_noc_regions ohnr
			on ohnr.noc = oh.noc
			where medal = 'Bronze'
			group by 1,2,3
			Order by 1)
select distinct table1.games,
concat(first_value (table1.region) over (partition by table1.games order by total_gold desc), ' - ',
	  first_value (total_gold) over (partition by table1.games order by total_gold desc)) as max_gold,
concat(first_value (table2.region) over (partition by table2.games order by total_silver desc), ' - ',
	  first_value (total_silver) over (partition by table2.games order by total_silver desc)) as max_silver,
concat(first_value (table3.region) over (partition by table3.games order by total_bronze desc), ' - ',
	  first_value (total_bronze) over (partition by table3.games order by total_bronze desc)) as max_bronze
from table1
full join table2
	on table2.games = table1.games
full join table3
	on table3.games = table2.games
order by games;

--#17 country that won the most gold, most silver, most bronze medals and the most medals in each olympic games.

Create temporary table temp_gold (games varchar, max_gold varchar)
insert into temp_gold
select distinct table1.games,
concat(first_value (table1.region) over (partition by table1.games order by total_gold desc), ' - ',
first_value (total_gold) over (partition by table1.games order by total_gold desc)) as max_gold
from
	(select games, medal, region, count(1) as total_gold
	from olympics_history oh
	join olympics_history_noc_regions ohnr
		on ohnr.noc = oh.noc
	where medal = 'Gold'
	group by 1,2,3) table1
	Order by 1

Create temporary table temp_silver (games varchar, max_silver varchar)
insert into temp_silver
select distinct table2.games,
concat(first_value (table2.region) over (partition by table2.games order by total_silver desc), ' - ',
first_value (total_silver) over (partition by table2.games order by total_silver desc)) as max_silver
from
	(select games, medal, region, count(1) as total_silver
	from olympics_history oh
	join olympics_history_noc_regions ohnr
		on ohnr.noc = oh.noc
	where medal = 'Silver'
	group by 1,2,3) table2
	Order by 1

Create temporary table temp_bronze (games varchar, max_bronze varchar)
insert into temp_bronze
select distinct table3.games,
concat(first_value (table3.region) over (partition by table3.games order by total_bronze desc), ' - ',
first_value (total_bronze) over (partition by table3.games order by total_bronze desc)) as max_bronze
from
	(select games, medal, region, count(1) as total_bronze
	from olympics_history oh
	join olympics_history_noc_regions ohnr
		on ohnr.noc = oh.noc
	where medal = 'Bronze'
	group by 1,2,3) table3
	Order by 1

Create temporary table temp_medals (games varchar, max_medals varchar)
insert into temp_medals
select distinct table4.games,
concat(first_value (table4.region) over (partition by table4.games order by total_medal desc), ' - ',
first_value (total_medal) over (partition by table4.games order by total_medal desc)) as max_medal
from
	(select games, region, count(1) as total_medal
	from olympics_history oh
	join olympics_history_noc_regions ohnr
		on ohnr.noc = oh.noc
	where medal <> 'NA'
	group by 1,2) table4
	Order by 1
	
select temp_gold.games, temp_gold.max_gold, temp_silver.max_silver
, temp_bronze.max_bronze, temp_medals.max_medals
from temp_gold
join temp_silver
	on temp_silver.games = temp_gold.games
join temp_bronze
	on temp_bronze.games = temp_silver.games
join temp_medals
	on temp_medals.games = temp_bronze.games;

--#18 countries which have never won gold medal but have won silver/bronze medals

with 
temp_medal as
	(select region, medal,
	case when medal = 'Gold' then count(medal) else 0 end as gold,
	case when medal = 'Silver' then count(medal) else 0 end as silver,
	case when medal = 'Bronze' then count(medal) else 0 end as bronze
	from olympics_history oh
	join olympics_history_noc_regions ohnr
		on ohnr.noc = oh.noc
	where medal <> 'NA'
	group by 1,2
	order by 1),
temp_medal2 as
	(select distinct region, sum(gold) cnt_gold,sum(silver) cnt_silver, sum(bronze) cnt_bronze
	from temp_medal
	group by region)
select distinct region, cnt_gold, cnt_silver, cnt_bronze
from temp_medal2
where cnt_gold = '0'
order by cnt_silver desc;

--#19 the sport which Indonesia has won the highest no of medals.

select sport, total_medals
from
	(select region, sport, count(medal) as total_medals
	from olympics_history oh
	join olympics_history_noc_regions ohnr
		on ohnr.noc = oh.noc
	where region = 'Indonesia' and medal <> 'NA'
	group by 1,2) Indonesia_medal
order by total_medals desc
limit 1;

--#20 Details of all Olympic Games where Indonesia won medal(s) in Badminton. 

select region, sport, games, count(medal) as total_medals
from olympics_history oh
join olympics_history_noc_regions ohnr
	on ohnr.noc = oh.noc
where region = 'Indonesia' and sport = 'Badminton' and medal <> 'NA'
group by 1,2,3
order by games;


