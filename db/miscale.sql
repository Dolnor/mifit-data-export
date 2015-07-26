.header on
.mode csv
.output miscale_weight.csv

select distinct Name,
strftime('%Y-%m-%d',Date) as Date,
strftime('%H:%M:%S',Date) as Time,
round(Weight,2) as Weight,
case 
	when UserID = -1 
		and b.Height is not null 
    	and b.Height > 0 
    then round(Weight*100.0*100.0/(b.Height*b.Height),2) 
	when UserID > -1 
		and a.Height is not null 
		and a.Height > 0 
	then round(Weight*100.0*100.0/(a.Height*a.Height),2) 
	else 0 
end as BMI
 from
(
select strftime('%Y-%m-%d %H:%M:%S',datetime(substr(timestamp,1,10),'unixepoch','localtime')) as Date,
w.Weight,
case when w.UserID = -1 then 'Owner' else u.Name end as Name,
w.UserID,
u.Height
 from WeightInfos w
 left outer join UserInfos u on w.UserID = u.UserID
 where w.UserID <> 0
 -- there's no reason to constantly load all the data to Fitbit, last 7 days is enough
 and Date > date('now','-6 day')
) a,
(select CurrentVal,Height from WeightGoals where FUID = -1 order by DateTime desc limit 1) b
order by Name,Date,Time;
