--第一大题
create database kcdb
ON PRIMARY
(
	name = 'stu',
	filename = 'D:\201900800510\kcdb_data.mdf',
	size = 5mb,
	maxsize = 500mb,
	filegrowth = 10%
)
LOG ON
(
	name = 'stu_log',
	filename = 'D:\201900800510\kcdb_log.ldf',
	size = 3mb,
	maxsize = unlimited,
	filegrowth = 1mb
)

--第二大题
--char（2）和varchar（2）都能存一个汉字，两个英文字符；
--nchar(2)和nvarchar(2)都能存两个汉字或两个英文字符
use kcdb;
create table zzb
(
zzh char(4) primary key,
zzm varchar(10) unique
)

create table qkb
(
qkh char(4) primary key,
qkm varchar(20) not null,
lb char(2) check(lb in ('是' , '否')),
bmf int
)

create table tgb
(
zzh char(4) not null,
qkh char(4) not null,
tgrq date not null default getdate(),
wzmc char(50),
sgjg nchar(3) check(sgjg in ('通过','未通过')) default '未通过',
primary key(zzh, qkh, tgrq),
foreign key(zzh) references zzb(zzh),
foreign key(qkh) references qkb(qkh)
)

--1.

--2.
--(1)
select zzb.zzm as 作者名, qkb.qkm as 期刊名, tgb.wzmc as 文章名称, tgb.tgrq as 投稿日期
from tgb,qkb,zzb
where tgb.zzh = zzb.zzh and tgb.qkh = qkb.qkh and YEAR(tgrq) >= 2006

--（2）

select substring(zzm, 1,1) as 姓氏, count(*) 人数
from zzb
group by SUBSTRING(zzm,1,1)
having count(*) = 
(
select top 1 count(*) from zzb --获取人数最多的姓氏的人数
group by SUBSTRING(zzm,1, 1)
order by count(*) desc
)


--（3）
select distinct(qkm) from tgb join qkb on tgb.qkh = qkb.qkh
except
select distinct(qkm)
from tgb, zzb, qkb
where tgb.zzh = zzb.zzh and tgb.qkh = qkb.qkh and zzb.zzm = '杨伍华'

--(4)
select tgb.qkh, count(*) 通过次数, sum(qkb.bmf) 版面费
from tgb, qkb
where tgb.sgjg = '通过' and 
tgb.qkh = qkb.qkh and 
qkb.qkh in (
select distinct(tgb.qkh) -- 杨伍华投过的期刊
from tgb, zzb
where tgb.zzh = zzb.zzh and zzb.zzm = '杨伍华'
)
and qkb.qkh in (
select qkh  --投稿次数超过5次的期刊
from tgb
group by qkh
having count(*) > 5
)
group by tgb.qkh
having sum(qkb.bmf) > 7000

--(5)
select count(tgb.qkh) as 总投稿次数, count(zzb.zzh)  as 总人数, cast(count(tgb.qkh)/count(zzb.zzh) as decimal(3,2)) 人均投稿次数
from tgb,zzb

--（6）

insert into tgb(zzh,qkh,wzmc)
values('zz01','qk02', '地铁限界系统的研究')
select *from tgb

--（7）
delete from 
tgb
where qkh = (select qkh from qkb where qkm = '哲学研究')
and sgjg = '未通过'
and year(tgrq) <= 2000

--（8）
select tmptable.zzm 作者名, tmptable.投稿通过率, case when tmptable.投稿通过率 > 0.7 then '高'
													  when tmptable.投稿通过率 between 0.4 and 0.7 then '中'
													  when tmptable.投稿通过率 < 0.4 then '低'
													  else ' '
												end as 评价
from 
(select zzb.zzm,cast(cast(sum(case
				when tgb.sgjg = '通过' then 1
				else 0
				end) as decimal(10,8))/cast(count(*) as decimal(10,8)) as decimal(10,2)) 投稿通过率
from zzb left join tgb on zzb.zzh = tgb.zzh
group by zzb.zzh,zzb.zzm) as tmptable

--(9)
-- 不存在这样的期刊，杨伍华投了，这个作者没投
select x.zzm 作者名
from zzb x
where not exists
(
select *
from tgb yt, zzb yz
where yz.zzh = yt.zzh and yz.zzm = '杨伍华'
and not exists(
select *
from tgb z
where z.qkh = yt.qkh
and z.zzh = x.zzh
)
)

--（10）
declare cur1 scroll cursor for
select * from tgb, qkb where tgb.qkh = qkb.qkh and qkm = '计算机应用研究' and sgjg = '未通过'

open cur1
fetch last from cur1
update tgb
set sgjg = '通过'
where current of cur1
close cur1
deallocate cur1

-- 三
create table teacher
(
tid smallint,
tname char(10),
job char(16),
salary int
)
go

create trigger t1
on teacher
for insert, update
as
begin
declare @gz int, @zw char(16), @mz char(10), @id smallint
select @id = tid, @gz = salary, @zw = job, @mz = tname from inserted
if @zw = '教授' and @gz < 8000
begin
update teacher set salary = 8000
where tid = @id
print @mz + '教师的工资改为8000元'
end
end

insert into teacher
values(123,'小米','教授', 3000)

--四
create table lend
(
学号 int,
索书号 int,
借书日期 date,
应还日期 date,
是否续借 char(2)
)
create table student
(
学号 int,
日期 date,
欠款金额 int
)
create table _return
(
学号 int,
索书号 int,
还书日期 date
)
insert into student
values(123, '2020-1-1', 0)
insert into lend
values(123, 1,'2020-1-1','2020-2-1','否')
--select * from student
--select * from lend
go

create proc 还书 @sno int, @bno int
as
declare @date date = getdate(), @return_date date

select @return_date = lend.应还日期 from lend
where lend.学号 = @sno and lend.索书号 = @bno

delete from lend
where lend.学号 = @sno and lend.索书号 = @bno

insert into _return
values(@sno,@bno,@date)

if @date > @return_date
begin
declare @days int = datediff(dd,@return_date,@date)
update student
set 欠款金额 = 欠款金额 + 0.1*@days
where 学号 = @sno
end


exec dbo.还书 123,1
--成功执行

--五

--1.
select b1.bno, b1.bname
from B b1
where not exists(
select *
from P p1
where not exists(
select *
from CC join C on CC.cno = C.cno
where CC.pname = p1.pname
and C.bno = b1.bno
and CC.pname = p1.pname
)
)

--2.
select M.mname
from M,CM where M.cno = CM.cno
and CM.cno in
(
select distinct(C.cno)
from C
except
select distinct(C.cno)
from C
where C.tno = (select T.tno from T where T.tname = '李明')
)

--3.

select top 1 month(cdate), M.mno, M.mname, sum(mqu)
from C join Cm on M.mno = CM.mno
where year(cdate) = 2019
group by month(cdate),M.mno, M.mname
order by sum(mqu)

--4.
alter table C
add constraint cc1 foreign key(tno) references T(tno)

alter table C
add constraint cc2 default getdate() for cdate

--5.
go
create view t5
as
select C.cno 处方编号,sum(CM.mqu) 药品总数量, sum(CM.mprice*CM.mqu) 药品总价格,
count(distinct(CC.pname)) 检查项目总数量, sum(CC.pname*P.pprice) 检查项目总价格
from C,CM,CC,P
where C.cno = CM.cno and CM.cno = CC.cno and CC.pname = P.pname
group by C.cno

--6.
select T.kname 科室, T.tname 医生名称, month(M.mdate) 月份, sum(CM.mqu*CM.mprice)+sum(pprice) 总金额
from T,C,CM,CC,P
where T.tno = C.tno and C.cno = CM.cno and C.cno = CC.cno and CC.pname = P.pname
and year(M.mdate) = 2017
group by month(M.mdate), T.kname, T.tno, T.tname

--7.
select C.tno, sum(case when B.bsex = '男' then 1 else 0) 男病人人数, 
sum(case when B.bsex = '女' then 1 else 0) 女病人人数
from B, C
where B.bno = C.bno
group by C.tno

--8.
create trigger t2
on CM
for insert
as
begin 
declare @mno int, @mqu int, @mprice int;
select @mno = mno, @mqu = mqu, @mprice = mprice from inserted
if @mno not in (select mno from M)
begin
rollback
end
else
begin
update C
set czi = czj + @mqu*@mprice
end
end

create trigger t3
on CC
for insert
as
begin 
declare @pname char(10), @pprice int;
select @pname = pname from inserted
if @pname not in(select pname from P)
begin
rollback
end
else
begin
select @pprice = pprice from p
where p.pname = @pname
update C
set czi = czj + @pprice
end
end

--9
go
create proc p2
@mno int
as
declare @mdate date, @odate date, @mex int;
select @mdate = mdate, @mex = mex
from M
where M.mno = @mno
set @odate = DATEADD(mm,@mex,@mdate)
if @odate < getdate()
begin
delete from
M
where mno = @mno
end
else if datediff(mm,getdate(),@odate) between 0 and 6
begin
insert into
OM
values
(@mno,@odate,datediff(dd,GETDATE(),@odate))
end


--10.
declare cur2 scroll cursor
for
select top 5 distinct(M.mno) 
from M join CM on M.mno = CM.mno
where year(M.mdate) = 2019
group by M.mno
order by sum(CM.mqu) desc
declare @mno int;
open cur2
fetch next  from cur2 into @mno
while @@FETCH_STATUS = 0
begin
update M
set mprice = mprice+1
where M.mno = @mno
fetch next from cur2  into @mno
end