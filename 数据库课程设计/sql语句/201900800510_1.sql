--��һ����
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

--�ڶ�����
--char��2����varchar��2�����ܴ�һ�����֣�����Ӣ���ַ���
--nchar(2)��nvarchar(2)���ܴ��������ֻ�����Ӣ���ַ�
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
lb char(2) check(lb in ('��' , '��')),
bmf int
)

create table tgb
(
zzh char(4) not null,
qkh char(4) not null,
tgrq date not null default getdate(),
wzmc char(50),
sgjg nchar(3) check(sgjg in ('ͨ��','δͨ��')) default 'δͨ��',
primary key(zzh, qkh, tgrq),
foreign key(zzh) references zzb(zzh),
foreign key(qkh) references qkb(qkh)
)

--1.

--2.
--(1)
select zzb.zzm as ������, qkb.qkm as �ڿ���, tgb.wzmc as ��������, tgb.tgrq as Ͷ������
from tgb,qkb,zzb
where tgb.zzh = zzb.zzh and tgb.qkh = qkb.qkh and YEAR(tgrq) >= 2006

--��2��

select substring(zzm, 1,1) as ����, count(*) ����
from zzb
group by SUBSTRING(zzm,1,1)
having count(*) = 
(
select top 1 count(*) from zzb --��ȡ�����������ϵ�����
group by SUBSTRING(zzm,1, 1)
order by count(*) desc
)


--��3��
select distinct(qkm) from tgb join qkb on tgb.qkh = qkb.qkh
except
select distinct(qkm)
from tgb, zzb, qkb
where tgb.zzh = zzb.zzh and tgb.qkh = qkb.qkh and zzb.zzm = '���黪'

--(4)
select tgb.qkh, count(*) ͨ������, sum(qkb.bmf) �����
from tgb, qkb
where tgb.sgjg = 'ͨ��' and 
tgb.qkh = qkb.qkh and 
qkb.qkh in (
select distinct(tgb.qkh) -- ���黪Ͷ�����ڿ�
from tgb, zzb
where tgb.zzh = zzb.zzh and zzb.zzm = '���黪'
)
and qkb.qkh in (
select qkh  --Ͷ���������5�ε��ڿ�
from tgb
group by qkh
having count(*) > 5
)
group by tgb.qkh
having sum(qkb.bmf) > 7000

--(5)
select count(tgb.qkh) as ��Ͷ�����, count(zzb.zzh)  as ������, cast(count(tgb.qkh)/count(zzb.zzh) as decimal(3,2)) �˾�Ͷ�����
from tgb,zzb

--��6��

insert into tgb(zzh,qkh,wzmc)
values('zz01','qk02', '�����޽�ϵͳ���о�')
select *from tgb

--��7��
delete from 
tgb
where qkh = (select qkh from qkb where qkm = '��ѧ�о�')
and sgjg = 'δͨ��'
and year(tgrq) <= 2000

--��8��
select tmptable.zzm ������, tmptable.Ͷ��ͨ����, case when tmptable.Ͷ��ͨ���� > 0.7 then '��'
													  when tmptable.Ͷ��ͨ���� between 0.4 and 0.7 then '��'
													  when tmptable.Ͷ��ͨ���� < 0.4 then '��'
													  else ' '
												end as ����
from 
(select zzb.zzm,cast(cast(sum(case
				when tgb.sgjg = 'ͨ��' then 1
				else 0
				end) as decimal(10,8))/cast(count(*) as decimal(10,8)) as decimal(10,2)) Ͷ��ͨ����
from zzb left join tgb on zzb.zzh = tgb.zzh
group by zzb.zzh,zzb.zzm) as tmptable

--(9)
-- �������������ڿ������黪Ͷ�ˣ��������ûͶ
select x.zzm ������
from zzb x
where not exists
(
select *
from tgb yt, zzb yz
where yz.zzh = yt.zzh and yz.zzm = '���黪'
and not exists(
select *
from tgb z
where z.qkh = yt.qkh
and z.zzh = x.zzh
)
)

--��10��
declare cur1 scroll cursor for
select * from tgb, qkb where tgb.qkh = qkb.qkh and qkm = '�����Ӧ���о�' and sgjg = 'δͨ��'

open cur1
fetch last from cur1
update tgb
set sgjg = 'ͨ��'
where current of cur1
close cur1
deallocate cur1

-- ��
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
if @zw = '����' and @gz < 8000
begin
update teacher set salary = 8000
where tid = @id
print @mz + '��ʦ�Ĺ��ʸ�Ϊ8000Ԫ'
end
end

insert into teacher
values(123,'С��','����', 3000)

--��
create table lend
(
ѧ�� int,
����� int,
�������� date,
Ӧ������ date,
�Ƿ����� char(2)
)
create table student
(
ѧ�� int,
���� date,
Ƿ���� int
)
create table _return
(
ѧ�� int,
����� int,
�������� date
)
insert into student
values(123, '2020-1-1', 0)
insert into lend
values(123, 1,'2020-1-1','2020-2-1','��')
--select * from student
--select * from lend
go

create proc ���� @sno int, @bno int
as
declare @date date = getdate(), @return_date date

select @return_date = lend.Ӧ������ from lend
where lend.ѧ�� = @sno and lend.����� = @bno

delete from lend
where lend.ѧ�� = @sno and lend.����� = @bno

insert into _return
values(@sno,@bno,@date)

if @date > @return_date
begin
declare @days int = datediff(dd,@return_date,@date)
update student
set Ƿ���� = Ƿ���� + 0.1*@days
where ѧ�� = @sno
end


exec dbo.���� 123,1
--�ɹ�ִ��

--��

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
where C.tno = (select T.tno from T where T.tname = '����')
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
select C.cno �������,sum(CM.mqu) ҩƷ������, sum(CM.mprice*CM.mqu) ҩƷ�ܼ۸�,
count(distinct(CC.pname)) �����Ŀ������, sum(CC.pname*P.pprice) �����Ŀ�ܼ۸�
from C,CM,CC,P
where C.cno = CM.cno and CM.cno = CC.cno and CC.pname = P.pname
group by C.cno

--6.
select T.kname ����, T.tname ҽ������, month(M.mdate) �·�, sum(CM.mqu*CM.mprice)+sum(pprice) �ܽ��
from T,C,CM,CC,P
where T.tno = C.tno and C.cno = CM.cno and C.cno = CC.cno and CC.pname = P.pname
and year(M.mdate) = 2017
group by month(M.mdate), T.kname, T.tno, T.tname

--7.
select C.tno, sum(case when B.bsex = '��' then 1 else 0) �в�������, 
sum(case when B.bsex = 'Ů' then 1 else 0) Ů��������
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