
Use DBSLab;

Select * From Customer
Select * From [Order]
Select * From [OrderItem]

--Drop User C0001
Create Login C0001 
With Password = 'QwErTy12345!@#$%'
Create User C0001 For Login C0001

--Create User C0001 Without Login

--Drop User C0002
Create User C0002 Without Login

--Drop User C0003
Create User C0003 Without Login

--Drop User C0005
Create User C0005 Without Login


--RBAC - 
--Drop Role Customers
Create Role [Customers]
Alter Role [Customers] Add Member C0001
Alter Role [Customers] Add Member C0002
Alter Role [Customers] Add Member C0003
Alter Role [Customers] Add Member C0005

--DENY SELECT, UPDATE ON Customer to [Customers]
GRANT SELECT, UPDATE ON Customer to [Customers]

CREATE SCHEMA Security;  
GO  

CREATE FUNCTION Security.fn_securitypredicate
	(@UserName AS nvarchar(100))  
RETURNS TABLE  
WITH SCHEMABINDING  
AS  
   RETURN SELECT 1 AS fn_securitypredicate_result
   WHERE @UserName = USER_NAME()
	OR USER_NAME() = 'dbo';
GO

select  USER_NAME()

CREATE SECURITY POLICY [SecurityPolicy_Customers]   
ADD FILTER PREDICATE 
[Security].[fn_securitypredicate]([CustID]) ON [dbo].[Customer] 

--DENY CONTROL ON ASYMMETRIC KEY::AsymKey1 to Customers
GRANT CONTROL ON ASYMMETRIC KEY::AsymKey1 to Customers

Execute as User = 'C0001'
--Select * From Customer
Select  CustID , CustName , PhoneNumber , Country ,
Convert(varchar, DecryptByAsymKey(AsymKey_ID('AsymKey1'),PaymentCardNumber)) As PaymentCardNumber
From Customer 
Revert


Execute as User = 'C0002'
--Select * From Customer
Select  CustID , CustName , PhoneNumber , Country ,
Convert(varchar, DecryptByAsymKey(AsymKey_ID('AsymKey1'),PaymentCardNumber)) As PaymentCardNumber
From Customer 
Revert

--DENY CONTROL ON CERTIFICATE::Cert1 TO Customers
GRANT CONTROL ON CERTIFICATE::Cert1 TO Customers

Execute as User = 'C0003'
Select  CustID , CustName , PhoneNumber , Country ,
Convert(varchar, DecryptByCert(Cert_ID('Cert1'),PaymentCardNumber)) As PaymentCardNumber
From Customer 
Revert

GRANT CONTROL ON SYMMETRIC KEY::SimKey1 to Customers

Execute as User = 'C0005'
OPEN SYMMETRIC KEY SimKey1 DECRYPTION BY CERTIFICATE Cert1
Select  CustID , CustName , PhoneNumber , Country ,
Convert(varchar, DecryptByKey(PaymentCardNumber)) As PaymentCardNumber
From Customer Where CustID in ('C0005')
CLOSE SYMMETRIC KEY SimKey1
Revert


--View To Show Details of Purchases

Select * From [Order] o
Inner Join OrderItem oi On o.OrderID = oi.OrderID
Inner Join Product p On p.ProductCode = oi.ProductCode

Drop View dbo.PurchaseDetails
Go

Create View dbo.PurchaseDetails WITH SCHEMABINDING 
As
Select CustID, OrderDate, ProductName, Quantity,  Price, Discount, AmountAfterDiscount
--Convert(Decimal(8,2),(Price - Price*isnull(Discount,0)/100)) PricePaidAfterDiscount 
From [dbo].[Order] o
Inner Join [dbo].OrderItem oi On o.OrderID = oi.OrderID
Inner Join [dbo].Product p On p.ProductCode = oi.ProductCode

Select * From PurchaseDetails

GRANT SELECT ON PurchaseDetails to [Customers]


CREATE SECURITY POLICY [SecurityPolicy_PurchaseDetails]   
ADD FILTER PREDICATE 
[Security].[fn_securitypredicate]([CustID]) ON [dbo].[PurchaseDetails] 

Execute as User = 'C0001'
--Select * From PurchaseDetails
Select CONVERT(date, OrderDate) as PurchaseDate, Sum(AmountAfterDiscount)  as TotalAmountSpent
From PurchaseDetails
Group By CONVERT(date, OrderDate)
Revert

Execute as User = 'C0002'
--Select * From PurchaseDetails
Select CONVERT(date, OrderDate) as PurchaseDate, Sum(AmountAfterDiscount)  as TotalAmountSpent
From PurchaseDetails
Group By CONVERT(date, OrderDate)
Revert

--If you are running as the admin, use the query below
Select CustID, CONVERT(date, OrderDate) as PurchaseDate, Sum(AmountAfterDiscount)  as TotalAmountSpent
From PurchaseDetails
Group By CustID, CONVERT(date, OrderDate)
Order By CustID

