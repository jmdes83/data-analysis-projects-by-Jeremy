/* CLEANING THE DATA */

/* First the columns are renamed ("Design" option for applicable table) for purposes of formatting and readability. */

/* Next, the following unnecessary columns are removed: 'PRECINCT', 'JURISDICTION_CODE', 'X_COORDINATE_CD', 
	'Y_COORDINATE_CD', and 'LON_LAT'. */

alter table PortfolioProjects..NYPD_shootings 
drop column if exists PRECINCT

alter table PortfolioProjects..NYPD_shootings
drop column if exists JURISDICTION_CODE

alter table PortfolioProjects..NYPD_shootings 
drop column if exists X_COORDINATE_CD

alter table PortfolioProjects..NYPD_shootings
drop column if exists Y_COORDINATE_CD

alter table PortfolioProjects..NYPD_shootings
drop column if exists LON_LAT

/* Now datatypes are verified. The 'OCCUR_DATE' column is converted to 'date' and the 'OCCUR_TIME' column
	to 'time' with a precision of zero. */

alter table PortfolioProjects..NYPD_shootings
alter column OCCUR_DATE date

alter table PortfolioProjects..NYPD_shootings
alter column OCCUR_TIME time(0)

/* It is immediately observable that there are missing values in the 'LOCATION_DESCRIPTION', 'PERPETRATOR_AGE_GROUP', 
	'PERPETRATOR_SEX', and 'PERPETRATOR_RACE' columns. A verification of unique values for the categorical columns 
	('STATISTICAL_MURDER_FLAG', 'PERPETRATOR_AGE_GROUP', 'PERPETRATOR_SEX', 'PERPETRATOR_RACE', 'VICTIM_AGE_GROUP', 
	'VICTIM_SEX', 'VICTIM_RACE') reveals that there is also a value of 'NONE' in 'LOCATION_DESCRIPTION' and 'U' in both 
	the 'PERPETRATOR_SEX' and 'VICTIM_SEX' columns. We replace all of the aforementioned with 'UNKNOWN'. 
	
	Further exploration reveals that the 'PERPETRATOR_AGE_GROUP' column contains values of '940','224', and '1020'; these 
	values are meaningless and amount to only 3 rows out of 23,568 total, so these rows can be safely removed. 
	
	Finally, the value '<18' is reformatted to '0-18' in the 'PERPETRATOR_AGE_GROUP' and 'VICTIM_AGE_GROUP' columns. */	

select distinct BOROUGH BOROUGH_DISTINCT from PortfolioProjects..NYPD_shootings 

select distinct STATISTICAL_MURDER_FLAG STAT_MURDER_FLAG_DISTINCT from PortfolioProjects..NYPD_shootings

select distinct LOCATION_DESCRIPTION LOCATION_DISTINCT from PortfolioProjects..NYPD_shootings 
update PortfolioProjects..NYPD_shootings
set LOCATION_DESCRIPTION = 'UNKNOWN' where LOCATION_DESCRIPTION is null or LOCATION_DESCRIPTION = 'NONE'
	
select distinct PERPETRATOR_AGE_GROUP PERPETRATOR_AGE_GROUP_DISTINCT from PortfolioProjects..NYPD_shootings 
update PortfolioProjects..NYPD_shootings
set PERPETRATOR_AGE_GROUP = 'UNKNOWN' where PERPETRATOR_AGE_GROUP is null
delete from PortfolioProjects..NYPD_shootings where PERPETRATOR_AGE_GROUP in ('940', '224', '1020')
update PortfolioProjects..NYPD_shootings
set PERPETRATOR_AGE_GROUP = REPLACE(PERPETRATOR_AGE_GROUP, '<18', '0-18')

select distinct PERPETRATOR_SEX PERPETRATOR_SEX_DISTINCT from PortfolioProjects..NYPD_shootings 
update PortfolioProjects..NYPD_shootings
set PERPETRATOR_SEX = 'UNKNOWN' where PERPETRATOR_SEX is null or PERPETRATOR_SEX = 'U'

select distinct PERPETRATOR_RACE PERPETRATOR_RACE_DISTINCT from PortfolioProjects..NYPD_shootings 
update PortfolioProjects..NYPD_shootings
set PERPETRATOR_RACE = 'UNKNOWN' where PERPETRATOR_RACE is null

select distinct VICTIM_AGE_GROUP VICTIM_AGE_GROUP_DISTINCT from PortfolioProjects..NYPD_shootings
update PortfolioProjects..NYPD_shootings
set VICTIM_AGE_GROUP = REPLACE(VICTIM_AGE_GROUP, '<18', '0-18')

select distinct VICTIM_SEX VICTIM_SEX_DISTINCT from PortfolioProjects..NYPD_shootings 
update PortfolioProjects..NYPD_shootings
set VICTIM_SEX = 'UNKNOWN' where VICTIM_SEX = 'U'

select distinct VICTIM_RACE VICTIM_RACE_DISTINCT from PortfolioProjects..NYPD_shootings 

/* Now the ranges of the continuous variables (OCCUR_DATE, OCCUR_TIME, LATITUDE, LONGITUDE) are verified to 
	detect any rogue values: */

Select concat(min(OCCUR_DATE), ' - ', max(OCCUR_DATE)) OCCUR_DATE_RANGE,
	   concat(min(OCCUR_TIME), ' - ', max(OCCUR_TIME)) OCCUR_TIME_RANGE,
	   concat(min(LATITUDE), ' - ', max(LATITUDE)) LATITUDE_RANGE,
	   concat(min(LONGITUDE), ' - ', max(LONGITUDE)) LONGITUDE_RANGE,
	   concat(min(day(OCCUR_DATE)), ' - ', max(day(OCCUR_DATE))) OCCUR_DAY_RANGE,
	   concat(min(month(OCCUR_DATE)), ' - ', max(month(OCCUR_DATE))) OCCUR_MONTH_RANGE 
		from PortfolioProjects..NYPD_shootings

/* There are none. A final check for additional null values: */

select 
	sum(case when INCIDENT_KEY is null then 1 else 0 end) as INCIDENT_KEY_NULLS,
	sum(case when OCCUR_DATE is null then 1 else 0 end) as OCCUR_DATE_NULLS,
	sum(case when OCCUR_TIME is null then 1 else 0 end) as OCCUR_TIME_NULLS,
	sum(case when BOROUGH is null then 1 else 0 end) as BOROUGH_NULLS,
	sum(case when STATISTICAL_MURDER_FLAG is null then 1 else 0 end) as STATISTICAL_MURDER_FLAG_NULLS,
	sum(case when VICTIM_AGE_GROUP is null then 1 else 0 end) as VICTIM_AGE_GROUP_NULLS,
	sum(case when VICTIM_SEX is null then 1 else 0 end) as VICTIM_SEX_NULLS,
	sum(case when VICTIM_RACE is null then 1 else 0 end) as VICTIM_RACE_NULLS,
	sum(case when LATITUDE is null then 1 else 0 end) as LATITUDE_NULLS,
	sum(case when LONGITUDE is null then 1 else 0 end) as LONGITUDE_NULLS from PortfolioProjects..NYPD_shootings

/* There are no nulls. */

/* Ideally, 1 and 0 would replace 'TRUE' and 'FALSE' respectively in the 'STATISTICAL_MURDER_FLAG' column. The 
	datatype for 'STATISTICAL_MURDER_FLAG', however, is 'bit'; therefore, the datatype cannot be altered or the 
	column's values directly replaced, so a 'MURDERED' column containing the values 'TRUE' and 'FALSE' is added: */  

alter table PortfolioProjects..NYPD_shootings
drop column if exists MURDERED

alter table PortfolioProjects..NYPD_shootings
add MURDERED nvarchar(10)

update PortfolioProjects..NYPD_shootings
set MURDERED = case when STATISTICAL_MURDER_FLAG = 1 then 'True'
	when STATISTICAL_MURDER_FLAG = 0 then 'False' end

/* The dataset is now viewed with the applied changes. It appears that everything worked as expected. */

select * from PortfolioProjects..NYPD_shootings 

/* Finally a check for duplicate entries is performed by partitioning by 'OCCUR_DATE', 'OCCUR_TIME', 'LATITUDE', and 
	'LONGITUDE' and ordering by 'INCIDENT_KEY'. Duplicate incident keys in fact appear to represent multiple shootings 
	at the same time and in the same location; one can observe that over identical incident keys, the location description 
	remains the same while the perpetrator age group, victim age group, perpetrator race, victim race, perpetrator sex, and
	victim sex are potentially different. */

;with row_num_CTE as 
	(select *, row_number() over (partition by OCCUR_DATE, OCCUR_TIME, LATITUDE, LONGITUDE order by INCIDENT_KEY) row_num 
	from PortfolioProjects..NYPD_shootings)
	select * from row_num_CTE order by INCIDENT_KEY

/* ANALYZING THE DATA */	

/* Of 23,565 documented shootings from 1/1/2006 - 12/31/2020, approximately 19.0% resulted in a murder. */

select format(cast(sum(case when MURDERED = 'True' then 1 else 0 end) as float)/cast(count(*) as float), 'P1') MURDERED_PCT
	from PortfolioProjects..NYPD_shootings

/* Most of the shootings occurred in 2006 (2,055 total) while the fewest occurred in 2018 (951 total).
   The highest number of murders also occurred in 2006 (445 total) while the fewest occurred in 2017 (174 total). */
 
select year(OCCUR_DATE) OCCUR_YEAR, count(*) YEAR_COUNT
	from PortfolioProjects..NYPD_shootings group by year(OCCUR_DATE) order by YEAR_COUNT desc

select year(OCCUR_DATE) OCCUR_YEAR, count(*) MURDERED_YEAR_COUNT
	from PortfolioProjects..NYPD_shootings where MURDERED = 'TRUE'
	group by year(OCCUR_DATE), MURDERED order by MURDERED_YEAR_COUNT desc

/* On a monthly basis, most of the shootings occurred in July (2,798 total) and the fewest in February (1,149 total). 
	The number of shootings increased during the warmer months (May - October). */

select month(OCCUR_DATE) OCCUR_MONTH, count(*) MONTH_COUNT
	from PortfolioProjects..NYPD_shootings group by month(OCCUR_DATE) order by MONTH_COUNT desc

/* Shootings were most frequent from 11 PM - 12 AM (1,994 total) and least frequent from 9 AM - 10AM (177 total). As 
	one might expect, shootings occurred most frequently during dark hours (9 PM - 3 AM). */

select datepart(hour, OCCUR_TIME) OCCUR_TIME, count(*) TIME_COUNT
	from PortfolioProjects..NYPD_shootings group by datepart(hour, OCCUR_TIME) order by TIME_COUNT desc

/* Most of the shootings occurred in Brooklyn (9,721 total); of these, the majority occurred in 2006 (850 total).
	The fewest occurred on Staten Island (698 total). */

select BOROUGH, count(*) BOROUGH_COUNT 
	from PortfolioProjects..NYPD_shootings group by BOROUGH order by BOROUGH_COUNT desc

select BOROUGH, year(OCCUR_DATE) OCCUR_YEAR, count(*) BOROUGH_COUNT 
	from PortfolioProjects..NYPD_shootings group by BOROUGH, year(OCCUR_DATE) order by BOROUGH_COUNT desc

/*  Of all documented shootings under review: 
		- At least 9,854 of the perpetrators were Black; these account for the largest percentage (74.2%) of 
			known-race perpetrators and 41.8% of all perpetrators of documented shooting instances in NYC 
			from 2006 - 2020. 
	
	    - The majority of victims -- at least 16,845, or 71.5% of all victims -- were Black. */
	
;with perp_race_CTE as (
	select PERPETRATOR_RACE, INVOLVEMENT = 'Perpetrator' from PortfolioProjects..NYPD_shootings),

	vic_race_CTE as (
	select VICTIM_RACE, INVOLVEMENT = 'Victim' from PortfolioProjects..NYPD_shootings)

	select PERPETRATOR_RACE, INVOLVEMENT, count(*) RACE_INVOLVEMENT_COUNT, format(cast(count(*) as float)/cast(23565 as float), 
		'P1') RI_PCT from perp_race_CTE group by PERPETRATOR_RACE, INVOLVEMENT 
	union
	select VICTIM_RACE, INVOLVEMENT, count(*) RACE_INVOLVEMENT_COUNT, format(cast(count(*) as float)/cast(23565 as float), 
		'P1') RI_PCT from vic_race_CTE group by VICTIM_RACE, INVOLVEMENT

/* Of all documented shootings under review: 
		- At least 13,302 (56.4%) shootings were perpetrated by males. At least 334 (1.4%) of the perpetrators were female. 
	
		- At least 21,350 (90.6%) of the victims were male. At least 2,195 (9.3%) of the victims were female. */

;with perp_sex_CTE as (
	select PERPETRATOR_SEX, INVOLVEMENT = 'Perpetrator' from PortfolioProjects..NYPD_shootings),

	vic_sex_CTE as (
	select VICTIM_SEX, INVOLVEMENT = 'Victim' from PortfolioProjects..NYPD_shootings)

	select PERPETRATOR_SEX, INVOLVEMENT, count(*) SEX_INVOLVEMENT_COUNT, format(cast(count(*) as float)/cast(23565 as float), 
		'P1') SI_PCT from perp_sex_CTE group by PERPETRATOR_SEX, INVOLVEMENT 
	union
	select VICTIM_SEX, INVOLVEMENT, count(*) SEX_INVOLVEMENT_COUNT, format(cast(count(*) as float)/cast(23565 as float), 
		'P1') SI_PCT from vic_sex_CTE group by VICTIM_SEX, INVOLVEMENT

/*Of the 7,954 instances wherein the race and sex of the perpetrator were the same as those of the victim, the majority 
	(6,818, or 85.7%) were perpetrated by Black males against other Black males. */

select count(*) PV_SAME_RACE_SEX from PortfolioProjects..NYPD_shootings where PERPETRATOR_RACE = VICTIM_RACE and PERPETRATOR_SEX = VICTIM_SEX 

select PERPETRATOR_RACE, PERPETRATOR_SEX, count(*) SAME_RACE_SEX_INCIDENT_COUNT, 
	format(cast(count(*) as float)/cast(7954 as float), 'P1') INCIDENT_PCT from PortfolioProjects..NYPD_shootings 
	where PERPETRATOR_RACE = VICTIM_RACE and PERPETRATOR_SEX = VICTIM_SEX 
	group by PERPETRATOR_RACE, PERPETRATOR_SEX order by SAME_RACE_SEX_INCIDENT_COUNT desc 

/* The majority of the shootings with a known location description (6,780, or 28.8% of total documented shootings) 
	occurred in multi-dwell settings - either public housing (4,229) or apartment buildings (2,551). */

select LOCATION_DESCRIPTION, count(*) LOCATION_COUNT, format(cast(count(*) as float)/cast(23565 as float), 'P1') LOC_PCT 
	from PortfolioProjects..NYPD_shootings group by LOCATION_DESCRIPTION order by LOCATION_COUNT desc

select count(*) MULTI_DWELL_COUNT, format(cast(count(*) as float)/cast(23565 as float), 'P1') MULTI_DWELL_PCT 
from PortfolioProjects..NYPD_shootings where LOCATION_DESCRIPTION like '%MULTI DWELL%'

/* The majority of documented shootings by perpetrators of a known race (7,093, or 51.9%) were done by Black 
	males between the ages of 18 and 44; this accounts for at least 30.1% of perpetrators of all documented shootings.
	Most of the resulting records of the query reflect a percentage below 1.0%; this would have resulted in a cluttered
	visualization. Therefore, only records reflecting a percentage of 1.0% or higher are shown.  */

select PERPETRATOR_AGE_GROUP, PERPETRATOR_RACE, PERPETRATOR_SEX, count(*) PERP_COUNT, 
	format(cast(count(*) as float)/cast(23565 as float), 'P1') PERP_PCT from PortfolioProjects..NYPD_shootings
	group by PERPETRATOR_AGE_GROUP, PERPETRATOR_RACE, PERPETRATOR_SEX
	having format(cast(count(*) as float)/cast(23565 as float), 'P1') >= '1.0%' order by PERP_COUNT desc

/* The majority of victims (12,889, or 54.7%) were also Black males between the ages of 18 and 44. 
	Most of the resulting records of the query reflect a percentage below 1.0; this would have resulted in a cluttered
	visualization. Therefore, only records reflecting a percentage of 1.0% or higher are shown.*/

select VICTIM_AGE_GROUP, VICTIM_RACE, VICTIM_SEX, count(*) VIC_COUNT,
	format(cast(count(*) as float)/cast(23565 as float), 'P1') VIC_PCT
	from PortfolioProjects..NYPD_shootings
	group by VICTIM_AGE_GROUP, VICTIM_RACE, VICTIM_SEX 
	having format(cast(count(*) as float)/cast(23565 as float), 'P1') >= '1.0%' order by VIC_COUNT desc

/* DATA FINDINGS ARE VISUALIZED IN TABLEAU */

/* END OF PROJECT */
