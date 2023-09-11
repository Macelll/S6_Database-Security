--Punya Guru*

--DDL Query
Create Table Country
(
CountryCode varchar(3) primary key,
CountryName varchar(100)
)
Go

 

Create Table Customer
(
CustID varchar(5) primary key,
CustName varchar(100) not null,
PaymentCardNumber varbinary(max),
PhoneNumber varchar(12),
Country  varchar(3) References Country(CountryCode)
)

 

Create Table Product
(
ProductCode varchar(10) primary key,
ProductName varchar(100) not null,
Price decimal(5,2) Check (Price > 0.00),
CountryCode varchar(3) Default 'MAS' references Country(CountryCode),
QuantityInStock integer Check (QuantityInStock> 0),
Discount decimal(4,2) default null check ( (discount >= 1.00) and (discount <= 50.00))
)

 

--Drop Table [Order]
Create Table [Order]
(
OrderID integer identity primary key,
CustID varchar(5) references Customer(CustID),
OrderDate datetime default getdate(),
AmountBeforeDiscount decimal(8,2),
AmountAfterDiscount decimal(8,2)
)

 

--Drop Table [OrderItem]
Create Table OrderItem
(
OrderItemID integer identity primary key,
OrderID integer references [Order](OrderID),
ProductCode varchar(10) references Product(ProductCode),
Quantity integer Check (Quantity> 0)
)