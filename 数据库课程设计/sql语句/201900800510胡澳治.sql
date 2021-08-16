--���������ݿ�
use master;

create database ͼ��ݹ������ݿ�
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

--������
use ͼ��ݹ������ݿ�;

create table ѧ����
(
ѧ�� varchar(20) primary key,
���� varchar(10),
�Ա� char(2) check(�Ա� in ('��','Ů')),
ѧԺ varchar(20),
�绰���� char(14),
���� varchar(15)
)



create table ͼ��ݹ���Ա��
(
����Ա�� varchar(5) primary key,
�Ա� char(2),
���� varchar(20),
�绰���� char(14),
���� varchar(15)
)


create table �鼮��
(
��� varchar(10) primary key,
���� varchar(20) not null,
����ͼƬ��ַ varchar(50),
���� varchar(20) not null,
���� varchar(20) not null,
������ varchar(20) not null,
�۸� float(3),
�ڲ���� char(4) default '�ڲ�' not null,
)


create table �����¼��
(
ѧ�� varchar(20) not null,
��� varchar(10) not null,
����Ա�� varchar(5),
�������� date not null,
Ӧ������ date,
������ char(2),
�ѹ黹 char(2) check(�ѹ黹 in ('��','��')),
primary key(ѧ��,���,��������)
)


create table �����¼��
(
ѧ�� varchar(20) not null,
��� varchar(10) not null,
����Ա�� varchar(5),
�������� date not null,
primary key(ѧ��,���,��������)
)


create table �����
(
ѧ�� varchar(20) not null,
��� varchar(10) not null,
�������� date not null,
�������� int,
������ float,
primary key(ѧ��,���,��������)
)



--����Լ��
alter table �����¼�� 
add constraint frgn_key_lend_1 
foreign key(ѧ��) references ѧ����(ѧ��);
alter table �����¼�� 
add constraint frgn_key_lend_2 
foreign key(���) references �鼮��(���);
alter table �����¼�� 
add constraint frgn_key_lend_3 
foreign key(����Ա��) references ͼ��ݹ���Ա��(����Ա��);
alter table �����¼�� 
add constraint frgn_key_return_1 
foreign key(ѧ��) references ѧ����(ѧ��);
alter table �����¼�� 
add constraint frgn_key_return_2 
foreign key(���) references �鼮��(���);
alter table �����¼�� 
add constraint frgn_key_return_3 
foreign key(����Ա��) references ͼ��ݹ���Ա��(����Ա��);
alter table ����� 
add constraint frgn_key_fine_1 
foreign key(ѧ��) references ѧ����(ѧ��);
alter table ����� 
add constraint frgn_key_fine_2 
foreign key(���) references �鼮��(���);
--�Զ����Լ��
alter table ͼ��ݹ���Ա�� 
add constraint zdy_1 check(�Ա� in ('��','Ů'))
alter table �����¼�� 
add constraint zdy_2 check(������ in('��','��'))
alter table �����¼�� 
add constraint zdy_3 default getdate() for �������� --����������date��
alter table �����¼�� 
add constraint zdy_4 default dateadd(day, 30, getdate()) for Ӧ������
alter table �����¼�� 
add constraint zdy_5 default '��' for ������
alter table �����¼�� 
add constraint zdy_6 default getdate() for ��������
alter table ѧ���� 
add constraint zdy_7 check(len(ѧ��) >= 12) --ѧ�Ŵ��ڵ���12λ
alter table �����¼�� 
add constraint zdy_8 default '��' for �ѹ黹
-- ��Ϊ����ͬһ��ѧ�����ܽ�ͬһ�����Σ������¼�Ƿ�黹



--create assertion asse_1  --���ԣ�ÿ�����κ�ʱ�̲���ͬʱ���鳬��60��
--check((select max(count(*)) from �����¼�� group by ѧ��) <= 60);
--����˵sqlû��assertion�ؼ��֣�Ӧ��ͨ�����������ö��Թ���


--���鼮��ѧ����ͼ�����Ա�����������ֶ���������


--���ô�����
go
create trigger limited_book --��֤ÿ�����κ�ʱ�̲���ͬʱ���鳬��60��
on �����¼��
for insert
as
begin
declare @book_num int;
select top 1 @book_num = count(*)
from �����¼��
group by ѧ��
order by count(*) desc;
if(@book_num > 60)
begin
print('��ͬѧ�����Ѵ�����60�����޷��ٽ裬���Ȼ������鼮');
rollback;
end
end
go

create trigger return_book --����ʱ��������򽫷����Զ���¼�������,
							--ͬʱ���鼮������������Ϊ�ڲ�
on �����¼��
for insert
as 
begin
declare @ѧ�� varchar(20);
declare @��� varchar(10);
declare @Ӧ������ date;
select @ѧ�� = ѧ��,@��� = ���
from inserted;

update �鼮�� --�����鼮��
set �ڲ���� = '�ڲ�'
where ��� = @���;

select @Ӧ������ = Ӧ������
from �����¼��
where ѧ�� = @ѧ�� and ��� = @��� and �ѹ黹 = '��';
declare @�������� int;
set @�������� = DATEDIFF(day, @Ӧ������, getdate())
if(@�������� > 0)
begin
insert into �����--����ÿ�췣��0.15Ԫ
values(@ѧ��,@���,getdate(),@��������,cast(@��������*0.15 as float))
end
update �����¼�� --���½����¼��
set �ѹ黹 = '��'
where ѧ�� = @ѧ�� and ��� = @��� and �ѹ黹 = '��';
end
go


--������ͼ
create view ��Ұ�������
as
select *
from �鼮��
where ���� = '��Ұ����'
go

create view ��е��ҵ���������
as
select distinct(����)
from �鼮��
where ������ = '��е��ҵ������'
go

create view �۸����30Ԫ����
as
select distinct(����)
from �鼮��
where �۸� > 30
go

create view ���С��10������
as
select *
from (select ����,count(*) 
		from �鼮��
		group by ����) as lsb(����,����)
where lsb.���� < 10;
go

create view ����Ա�����̴���Ľ����¼
as
select *
from �����¼��
where ����Ա�� = (select ����Ա�� from ͼ��ݹ���Ա�� where ���� = '������')
go

create view С˵���͵��� --С˵���͵����ȫ����ţ��������Լ�С˵���͵��������ڲ���
as
select count(*) ����,count(case �ڲ���� 
										when '�ڲ�' 
										then 1 else 0 
									end)�ڲ���
from �鼮��
where ���� = 'С˵'
go

--�����洢����

--��ѯָ�����ߵĵ�ǰ����ͼ������
create proc ���߽������ @ѧ�� varchar(20)
as
select ѧ����.ѧ��,ѧ����.����,��������,Ӧ������,������
from �����¼�� join ѧ���� on �����¼��.ѧ�� = ѧ����.ѧ��
where �����¼��.ѧ�� = @ѧ��
and �ѹ黹 = '��'
go

--��ѯָ�����ߵ�ȫ��������ʷ
create proc ����ȫ��������ʷ @ѧ�� varchar(20)
as
select ѧ����.ѧ��,ѧ����.����,��������,Ӧ������,������
from �����¼�� join ѧ���� on �����¼��.ѧ�� = ѧ����.ѧ��
where �����¼��.ѧ�� = @ѧ��
go

--����
create proc ���� @ѧ�� varchar(20), @��� varchar(10), @����Ա�� varchar(5)
as
insert into �����¼��
values(@ѧ��,@���,@����Ա��,getdate(),DATEADD(day,30,getdate()),'��','��')
if(@@ROWCOUNT = 1) --û���򳬹�60������������rollback�����������Ĳ���
begin
update �鼮��
set �ڲ���� = '���'
where ��� = @���;
end
go

--����
create proc ���� @ѧ�� varchar(20),  @��� varchar(10)
as
declare @������ char(2);
select @������ = ������
from �����¼��
where ѧ�� = @ѧ�� and ��� = @��� and �ѹ黹 = '��'
if(@������ = '��')
print('ֻ������һ�Σ�����ʧ�ܣ�')
else
begin
declare @Ӧ������ date;
select @Ӧ������ = Ӧ������
from �����¼��
where ѧ�� = @ѧ�� and ��� = @��� and �ѹ黹 = '��'
if(DATEDIFF(day,getdate(),@Ӧ������) < 1) -- ��������һ��ſ����裬��ֻ������һ�Σ���30��
begin
update �����¼��
set Ӧ������ = dateadd(day,30,@Ӧ������)
where ѧ�� = @ѧ�� and ��� = @��� and �ѹ黹 = '��';
update �����¼��
set ������ = '��'
where ѧ�� = @ѧ�� and ��� = @��� and �ѹ黹 = '��'
end
end
go

--����
create proc ���� @��� varchar(10),@����Ա�� varchar(5) --������Բ���Ҫѧ��
as
begin
declare @ѧ�� varchar(20);
select @ѧ�� = ѧ��
from �����¼��
where ��� = @��� and �ѹ黹 = '��'
insert into �����¼�� --����ϸ�ڲ�������ǰ��д�Ĵ�����
values(@ѧ��,@���,@����Ա��,getdate())
end



exec dbo.���� '201799743842','2021042201','21001'; --������Ӱ��
exec dbo.���� '201799743842','2021042204','21001'; --������Ӱ��

exec ���� '2021042201','21001'; --������Ӱ��
--�����鹦������
select * from �����¼��
select * from �鼮�� where ���� like '%ҹ��%'

go;

create proc ɾ������ @��� varchar(10)
as
begin
delete from �����¼�� 
where ��� = @���;
delete from �����¼��
where ��� = @���;
delete from �����
where ��� = @���;
delete from �鼮�� where ��� = @���;
end 
select * from �鼮��


go
create proc ɾ��ѧ�� @ѧ�� varchar(20)
as
begin
delete from �����¼�� 
where ѧ�� = @ѧ��;
delete from �����¼��
where ѧ�� = @ѧ��;
delete from �����
where ѧ�� = @ѧ��;
delete from ѧ���� where ѧ�� = @ѧ��;
end 

