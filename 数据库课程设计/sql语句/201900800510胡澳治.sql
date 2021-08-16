--创建俩数据库
use master;

create database 图书馆管理数据库
ON PRIMARY
(
	name = 'library',
	filename = 'D:\201900800510\library_data.mdf',
	size = 5mb,
	maxsize = 500mb,
	filegrowth = 10%
)
LOG ON
(
	name = 'library_log',
	filename = 'D:\201900800510\library_log.ldf',
	size = 3mb,
	maxsize = unlimited,
	filegrowth = 1mb
)

--创建表
use 图书馆管理数据库;

create table 学生表
(
学号 varchar(20) primary key,
姓名 varchar(10),
性别 char(2) check(性别 in ('男','女')),
学院 varchar(20),
电话号码 char(14),
密码 varchar(15)
)



create table 图书馆管理员表
(
管理员号 varchar(5) primary key,
性别 char(2),
姓名 varchar(20),
电话号码 char(14),
密码 varchar(15)
)


create table 书籍表
(
书号 varchar(10) primary key,
书名 varchar(20) not null,
封面图片地址 varchar(50),
作者 varchar(20) not null,
类型 varchar(20) not null,
出版社 varchar(20) not null,
价格 float(3),
在册或借出 char(4) default '在册' not null,
)


create table 借书记录表
(
学号 varchar(20) not null,
书号 varchar(10) not null,
管理员号 varchar(5),
借书日期 date not null,
应还日期 date,
已续借 char(2),
已归还 char(2) check(已归还 in ('是','否')),
primary key(学号,书号,借书日期)
)


create table 还书记录表
(
学号 varchar(20) not null,
书号 varchar(10) not null,
管理员号 varchar(5),
还书日期 date not null,
primary key(学号,书号,还书日期)
)


create table 罚款表
(
学号 varchar(20) not null,
书号 varchar(10) not null,
还书日期 date not null,
逾期天数 int,
罚款金额 float,
primary key(学号,书号,还书日期)
)



--外码约束
alter table 借书记录表 
add constraint frgn_key_lend_1 
foreign key(学号) references 学生表(学号);
alter table 借书记录表 
add constraint frgn_key_lend_2 
foreign key(书号) references 书籍表(书号);
alter table 借书记录表 
add constraint frgn_key_lend_3 
foreign key(管理员号) references 图书馆管理员表(管理员号);
alter table 还书记录表 
add constraint frgn_key_return_1 
foreign key(学号) references 学生表(学号);
alter table 还书记录表 
add constraint frgn_key_return_2 
foreign key(书号) references 书籍表(书号);
alter table 还书记录表 
add constraint frgn_key_return_3 
foreign key(管理员号) references 图书馆管理员表(管理员号);
alter table 罚款表 
add constraint frgn_key_fine_1 
foreign key(学号) references 学生表(学号);
alter table 罚款表 
add constraint frgn_key_fine_2 
foreign key(书号) references 书籍表(书号);
--自定义的约束
alter table 图书馆管理员表 
add constraint zdy_1 check(性别 in ('男','女'))
alter table 借书记录表 
add constraint zdy_2 check(已续借 in('是','否'))
alter table 借书记录表 
add constraint zdy_3 default getdate() for 借书日期 --借书日期是date型
alter table 借书记录表 
add constraint zdy_4 default dateadd(day, 30, getdate()) for 应还日期
alter table 借书记录表 
add constraint zdy_5 default '否' for 已续借
alter table 还书记录表 
add constraint zdy_6 default getdate() for 还书日期
alter table 学生表 
add constraint zdy_7 check(len(学号) >= 12) --学号大于等于12位
alter table 借书记录表 
add constraint zdy_8 default '否' for 已归还
-- 因为可能同一个学生可能借同一本书多次，必须记录是否归还



--create assertion asse_1  --断言，每个人任何时刻不能同时借书超过60本
--check((select max(count(*)) from 借书记录表 group by 学号) <= 60);
--网上说sql没有assertion关键字，应该通过触发器设置断言功能


--向书籍表，学生表，图书管理员表这三个表手动导入数据


--设置触发器
go
create trigger limited_book --保证每个人任何时刻不能同时借书超过60本
on 借书记录表
for insert
as
begin
declare @book_num int;
select top 1 @book_num = count(*)
from 借书记录表
group by 学号
order by count(*) desc;
if(@book_num > 60)
begin
print('该同学借书已达上限60本，无法再借，请先还部分书籍');
rollback;
end
end
go

create trigger return_book --还书时如果逾期则将罚款自动记录到罚款表,
							--同时将书籍表中所还书标记为在册
on 还书记录表
for insert
as 
begin
declare @学号 varchar(20);
declare @书号 varchar(10);
declare @应还日期 date;
select @学号 = 学号,@书号 = 书号
from inserted;

update 书籍表 --更新书籍表
set 在册或借出 = '在册'
where 书号 = @书号;

select @应还日期 = 应还日期
from 借书记录表
where 学号 = @学号 and 书号 = @书号 and 已归还 = '否';
declare @逾期天数 int;
set @逾期天数 = DATEDIFF(day, @应还日期, getdate())
if(@逾期天数 > 0)
begin
insert into 罚款表--逾期每天罚款0.15元
values(@学号,@书号,getdate(),@逾期天数,cast(@逾期天数*0.15 as float))
end
update 借书记录表 --更新借书记录表
set 已归还 = '是'
where 学号 = @学号 and 书号 = @书号 and 已归还 = '否';
end
go


--建立视图
create view 东野圭吾的书
as
select *
from 书籍表
where 作者 = '东野圭吾'
go

create view 机械工业出版社的书
as
select distinct(书名)
from 书籍表
where 出版社 = '机械工业出版社'
go

create view 价格大于30元的书
as
select distinct(书名)
from 书籍表
where 价格 > 30
go

create view 库存小于10本的书
as
select *
from (select 书名,count(*) 
		from 书籍表
		group by 书名) as lsb(书名,本数)
where lsb.本数 < 10;
go

create view 管理员彭于晏处理的借书记录
as
select *
from 借书记录表
where 管理员号 = (select 管理员号 from 图书馆管理员表 where 姓名 = '彭于晏')
go

create view 小说类型的书 --小说类型的书的全部书号，书名，以及小说类型的总数和在册数
as
select count(*) 总数,count(case 在册或借出 
										when '在册' 
										then 1 else 0 
									end)在册数
from 书籍表
where 类型 = '小说'
go

--建立存储过程

--查询指定读者的当前借阅图书的情况
create proc 读者借阅情况 @学号 varchar(20)
as
select 学生表.学号,学生表.姓名,借书日期,应还日期,已续借
from 借书记录表 join 学生表 on 借书记录表.学号 = 学生表.学号
where 借书记录表.学号 = @学号
and 已归还 = '否'
go

--查询指定读者的全部借阅历史
create proc 读者全部借阅历史 @学号 varchar(20)
as
select 学生表.学号,学生表.姓名,借书日期,应还日期,已续借
from 借书记录表 join 学生表 on 借书记录表.学号 = 学生表.学号
where 借书记录表.学号 = @学号
go

--借书
create proc 借书 @学号 varchar(20), @书号 varchar(10), @管理员号 varchar(5)
as
insert into 借书记录表
values(@学号,@书号,@管理员号,getdate(),DATEADD(day,30,getdate()),'否','否')
if(@@ROWCOUNT = 1) --没有因超过60本而被触发器rollback，则继续后面的步骤
begin
update 书籍表
set 在册或借出 = '借出'
where 书号 = @书号;
end
go

--续借
create proc 续借 @学号 varchar(20),  @书号 varchar(10)
as
declare @已续借 char(2);
select @已续借 = 已续借
from 借书记录表
where 学号 = @学号 and 书号 = @书号 and 已归还 = '否'
if(@已续借 = '是')
print('只能续借一次，续借失败！')
else
begin
declare @应还日期 date;
select @应还日期 = 应还日期
from 借书记录表
where 学号 = @学号 and 书号 = @书号 and 已归还 = '否'
if(DATEDIFF(day,getdate(),@应还日期) < 1) -- 在最后借期一天才可续借，并只能续借一次，加30天
begin
update 借书记录表
set 应还日期 = dateadd(day,30,@应还日期)
where 学号 = @学号 and 书号 = @书号 and 已归还 = '否';
update 借书记录表
set 已续借 = '是'
where 学号 = @学号 and 书号 = @书号 and 已归还 = '否'
end
end
go

--还书
create proc 还书 @书号 varchar(10),@管理员号 varchar(5) --还书可以不需要学号
as
begin
declare @学号 varchar(20);
select @学号 = 学号
from 借书记录表
where 书号 = @书号 and 已归还 = '否'
insert into 还书记录表 --具体细节操作触发前面写的触发器
values(@学号,@书号,@管理员号,getdate())
end



exec dbo.借书 '201799743842','2021042201','21001'; --两行受影响
exec dbo.借书 '201799743842','2021042204','21001'; --两行受影响

exec 还书 '2021042201','21001'; --三行受影响
--经检验功能无误
select * from 借书记录表
select * from 书籍表 where 书名 like '%夜行%'

go;

create proc 删除旧书 @书号 varchar(10)
as
begin
delete from 借书记录表 
where 书号 = @书号;
delete from 还书记录表
where 书号 = @书号;
delete from 罚款表
where 书号 = @书号;
delete from 书籍表 where 书号 = @书号;
end 
select * from 书籍表


go
create proc 删除学生 @学号 varchar(20)
as
begin
delete from 借书记录表 
where 学号 = @学号;
delete from 还书记录表
where 学号 = @学号;
delete from 罚款表
where 学号 = @学号;
delete from 学生表 where 学号 = @学号;
end 

