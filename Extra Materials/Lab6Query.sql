drop table Country

create table Country(
CountryCode Varchar(3) primary key,
CountryName VarChar(100)
);

create table Customer(
CustID Varchar(5) primary key,
CustName Varchar(100) not null,
PaymentCardNumber varbinary(max),
PhoneNumber Varchar(12),
Country Varchar(3) 
foreign key ([Country]) references Country(CountryCode)
);

create table [Order](
OrderID Integer primary key,
Customer Varchar(5) not null 
foreign key ([Customer]) references Customer(CustID),
OrderDate DateTime default Getdate(),
AmountBeforeDiscount decimal(8,2),
AmountAfterDiscount decimal(8,2)
);

drop table Product
create table Product(
ProductCode Varchar(10) primary key,
ProductName Varchar(100) not null,
Price Decimal (8,2),
CountryCode Varchar(3) default 'MAS' references Country(CountryCode),
QuantityInStock Int check (QuantityInStock>0),
Discount decimal(4,2) default 'null' check ((Discount >= 1.00) and (Discount <= 50.00))
);

create table OrderItem(
OrderItemID int identity primary key,
OrderID int references [Order](OrderID),
ProductID Varchar(10) references Product(ProductCode),
Quantity int check (Quantity>0)
);


--Encryption ---------------------------------------------
--Step 1 
go
create master key encryption by password = 'QwErTy12345!@#$%'
select * from sys.symmetric_keys

-- can use cert or assym key to directly encrypted data or encrypt 
-- the symm key that will be used to encrypt the data

---Step 2 - Create Certificate
Create Certificate Cert1 With Subject = 'Cert1'
go
select * from sys.certificates
--Or
Create Asymmetric Key AsymKey1 With Algorithm = RSA_2048
go
select * from sys.asymmetric_keys

--Step 3 - Optional if you want to use symmetirc key to encrypt your data
CREATE SYMMETRIC KEY SimKey1
WITH ALGORITHM = AES_256  
ENCRYPTION BY CERTIFICATE Cert1
GO
-- Or
CREATE SYMMETRIC KEY SimKey2
WITH ALGORITHM = AES_256  
ENCRYPTION BY Asymmetric Key AsymKey1
GO
select * from sys.symmetric_keys


--Value Inserting ---------------------------------
--DML Query  
INSERT Into Country values ('MAS','Malaysia')
INSERT Into Country values('INA','Indonesia')
INSERT Into Country values ('JPN','Japan')

Insert Into Customer( CustID , CustName , PaymentCardNumber , PhoneNumber , Country )
Values
('C0001','John',EncryptByAsymKey(AsymKey_ID('AsymKey1'),'12345611789'),'0116567678','MAS'),
('C0002','Sam',EncryptByAsymKey(AsymKey_ID('AsymKey1'),'9944226789'),'01176787573','INA')

select EncryptByAsymKey(AsymKey_ID('AsymKey1'),'12345611789')


Select * From Customer Where CustID in ('C0001','C0002')
Select  CustID , CustName , Convert(varchar, DecryptByAsymKey(AsymKey_ID('AsymKey1'),PaymentCardNumber)) As PaymentCardNumber, PhoneNumber , Country 
From Customer Where CustID in ('C0001','C0002')

Insert Into Customer( CustID , CustName , PaymentCardNumber , PhoneNumber , Country )
Values
('C0003','John2',EncryptByCert(Cert_ID('Cert1'),'12345611789'),'0116567678','MAS'),
('C0004','Sam2',EncryptByCert(Cert_ID('Cert1'),'9944226789'),'01176787573','INA')

Select  CustID , CustName , Convert(varchar, DecryptByCert(Cert_ID('Cert1'),PaymentCardNumber)) As PaymentCardNumber, PhoneNumber , Country 
From Customer Where CustID in ('C0003','C0004')


OPEN SYMMETRIC KEY SimKey1 DECRYPTION BY CERTIFICATE Cert1

Insert Into Customer( CustID , CustName , PaymentCardNumber , PhoneNumber , Country )
Values
('C0005','John3',EncryptByKey(Key_GUID('SimKey1'),'123456789'),'0116567678','MAS')

Select  CustID , CustName , Convert(varchar, DecryptByKey(PaymentCardNumber)) As PaymentCardNumber, PhoneNumber , Country 
From Customer Where CustID in ('C0005')

CLOSE SYMMETRIC KEY SimKey1

Insert Into Product Values ('P100','X',12.00,'MAS',100,5.00)

Insert Into Product 
(ProductCode, ProductName, Price , CountryCode , QuantityInStock, Discount )
Values ('P300','Z',99.00,'JPN',100,15.00)

Insert Into Product 
(ProductCode, ProductName, Price , CountryCode , QuantityInStock )
Values ('P200','Y',6.50,'MAS',100)

Select * From Product

Insert Into [Order] (CustID, OrderDate) Values ('C0001',getdate()-1)
Insert Into [Order] (CustID, OrderDate) Values ('C0001',getdate()-1)
Insert Into [Order] (CustID, OrderDate) Values ('C0001',getdate())

Insert Into [Order] (CustID, OrderDate) Values ('C0002',getdate()-1.1)
Insert Into [Order] (CustID, OrderDate) Values ('C0002',getdate()-1)
Insert Into [Order] (CustID, OrderDate) Values ('C0002',getdate()-0.8)
Insert Into [Order] (CustID, OrderDate) Values ('C0002',getdate())

Select * From [Order]

Insert Into OrderItem (OrderID, ProductCode,Quantity)
Values (1,'P100',2), (1,'P200',3)

Insert Into OrderItem (OrderID, ProductCode,Quantity)
Values (2,'P200',1), (2,'P300',2)

Insert Into OrderItem (OrderID, ProductCode,Quantity)
Values (3,'P100',3), (3,'P200',3)

Insert Into OrderItem (OrderID, ProductCode,Quantity)
Values (4,'P300',1), (4,'P200',2)

Insert Into OrderItem (OrderID, ProductCode,Quantity)
Values (5,'P100',2), (5,'P300',1)

Insert Into OrderItem (OrderID, ProductCode,Quantity)
Values (6,'P300',2), (6,'P100',1)

Insert Into OrderItem (OrderID, ProductCode,Quantity)
Values (7,'P300',3), (7,'P200',3)

Select * From [OrderItem]

--Update amounts - semi automated way

declare @orderid int = 1
while @orderid < 8
begin

--Calculate and update price before discount

	Update [Order] Set AmountBeforeDiscount = 
	(
	Select sum(price*quantity) as total from product inner join OrderItem b
	on product.productcode = b.productcode
	where product.ProductCode in 
	(select ProductCode from OrderItem Where OrderID = @orderid)
	and orderid=@orderid
	group by OrderID
	)
	Where OrderID =@orderid

--Calculate and update price after discount

	Update [Order] Set AmountAfterDiscount = 
	(
	Select sum((price - (price*isnull(Discount,0)/100) ) * quantity) as totalafter
	from product a inner join OrderItem b
	on a.productcode = b.productcode
	where a.ProductCode in 
	(select ProductCode from OrderItem Where OrderID = @orderid)
	and orderid=@orderid
	group by OrderID
	)
	Where OrderID =@orderid


	SET @orderid = @orderid + 1

end