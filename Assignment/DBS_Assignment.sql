USE master
DROP DATABASE DBS_Assignment

USE master
CREATE DATABASE DBS_Assignment

USE DBS_Assignment
CREATE TABLE Category (
	CategoryID BIGINT PRIMARY KEY,
	CategoryName VARCHAR(100),
	Discount DECIMAL(7,2)
);

CREATE TABLE Equipment ( 
    ProductCode BIGINT PRIMARY KEY, 
    EquipmentName VARCHAR(100), 
    PricePerUnit FLOAT(50), 
    CategoryID BIGINT, 
	FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID),
    QuantityInStock INT DEFAULT 0, 
    ProducingCountry VARCHAR(100) 
); 

CREATE VIEW [EquipmentView] AS
SELECT 
    ProductCode,
    EquipmentName,
    PricePerUnit,
    CategoryID,
    QuantityInStock,
    ProducingCountry
FROM Equipment;

CREATE TABLE [Member] ( 
    MemberID BIGINT PRIMARY KEY, 
    NationalIDOrPassportNumber VARCHAR(max), 
    [Name] VARCHAR(100), 
    [Address] VARCHAR(max), 
    PhoneNumber VARCHAR(20), 
    MemberStatus VARCHAR(20), 
    LoginID VARCHAR(max),
	LoginPW VARBINARY(max)
); 

CREATE VIEW MemberDetails AS
SELECT 
    MemberID,
    NationalIDOrPassportNumber,
    [Name],
    [Address],
    PhoneNumber,
    MemberStatus,
    LoginID,
	LoginPW
FROM Member;
SELECT * FROM [Member]

CREATE VIEW dbo.memberDecryptedDetails AS
SELECT 
    MemberID,
    CONVERT(VARCHAR(MAX), DecryptByCert(Cert_ID('Cert1'), NationalIDOrPassportNumber)) AS NationalIDOrPassportNumber,
	[Name],
    CONVERT(VARCHAR(MAX), DecryptByCert(Cert_ID('Cert1'), [Address])) AS [Address],
	[PhoneNumber],
	[MemberStatus],
    CONVERT(VARCHAR(MAX), DecryptByCert(Cert_ID('Cert1'), LoginID)) AS LoginID,
    CONVERT(VARCHAR(MAX), DecryptByCert(Cert_ID('Cert1'), LoginPW)) AS LoginPW
FROM [Member];

EXECUTE AS USER = '1001'
SELECT * FROM memberDecryptedDetails

REVERT;

SELECT * FROM memberDecryptedDetails

CREATE VIEW memberHiddenDetails AS
SELECT
    MemberID,
    [Name],
	PhoneNumber,
    MemberStatus
FROM [Member];

CREATE TABLE [Transaction] ( 
	ProductCode BIGINT,
	FOREIGN KEY (ProductCode) REFERENCES Equipment(ProductCode),
    MemberID BIGINT, 
	FOREIGN KEY (MemberID) REFERENCES Member(MemberID),
    TransactionCode INT PRIMARY KEY, 
	TransactionDate DATE,
    QuantityPurchase INT,
	TotalBeforeDiscount DECIMAL(7,2) NULL,
    TotalAfterDiscount DECIMAL(7,2) NULL
);

CREATE VIEW TransactionDetails AS
SELECT 
    TransactionCode,
    ProductCode,
    MemberID,
	TransactionDate,
    QuantityPurchase,
	TotalBeforeDiscount,
	TotalAfterDiscount
FROM [Transaction];

CREATE TABLE OrderItem ( 
	ProductCode BIGINT,
	FOREIGN KEY (ProductCode) REFERENCES Equipment(ProductCode),
    OrderCode INT PRIMARY KEY, 
	OrderDate DATE,
    QuantityPurchase INT,
);

CREATE VIEW OrderDetails AS
SELECT 
    ProductCode,
    OrderCode,
	OrderDate,
    QuantityPurchase
FROM [OrderItem];
-------------------------------------------------------- ENCRYPTION -------------------------------------------------------------------------------------------------
--Encryption System
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'qwerty'
SELECT * FROM sys.symmetric_keys

CREATE CERTIFICATE Cert1 WITH SUBJECT = 'Cert1'
SELECT * FROM sys.certificates

CREATE SYMMETRIC KEY SimKey1
WITH ALGORITHM = AES_256  
ENCRYPTION BY CERTIFICATE Cert1
-------------------------------------------------------- INSERTION -------------------------------------------------------------------------------------------------
INSERT INTO [Category] (CategoryID, CategoryName, Discount)
VALUES	(2001, 'Ball', 0.1),
		(2002, 'Racket', 0.2),
		(2003, 'Sportswear', 0.3),
		(2004, 'Sneakers', 0.4),
		(2005, 'Bicycle', 0.5);

INSERT INTO [Equipment] (ProductCode, EquipmentName, PricePerUnit, CategoryID, QuantityInStock, ProducingCountry)
VALUES	(3001, 'Basketball Ball', 25.99, 2001, 50, 'USA'),
		(3002, 'Tennis Racket', 89.50, 2002, 30, 'China'),
		(3003, 'Cricket Bat', 75.75, 2002, 20, 'India'),
		(3004, 'Volleyball Ball', 19.99, 2001, 40, 'Brazil'),
		(3005, 'Badminton Racket', 45.25, 2002, 25, 'Malaysia');

DELETE Member
INSERT INTO Member (MemberID, NationalIDOrPassportNumber, [Name], [Address], PhoneNumber, MemberStatus, LoginID, LoginPW)
VALUES 
    (1001, EncryptByCert(Cert_ID('Cert1'),'A123456789'), 'Macel Agung',		EncryptByCert(Cert_ID('Cert1'),'123 Main St, City A'),	
	'069-1310', 'Active', EncryptByCert(Cert_ID('Cert1'),'macel'), EncryptByCert(Cert_ID('Cert1'),'qwerty')),
    
	(1002, EncryptByCert(Cert_ID('Cert1'),'B987654321'), 'Michael Henry',		EncryptByCert(Cert_ID('Cert1'),'456 Elm St, City B'),	
	'069-5678', 'Active', EncryptByCert(Cert_ID('Cert1'),'michenry'), EncryptByCert(Cert_ID('Cert1'),'qwerty')),
    
	(1003, EncryptByCert(Cert_ID('Cert1'),'C246813579'), 'Ferdian Marcel', EncryptByCert(Cert_ID('Cert1'),'789 Oak St, City C'),	
	'069-9876', 'Inactive', EncryptByCert(Cert_ID('Cert1'),'wenwen'), EncryptByCert(Cert_ID('Cert1'),'qwerty')),
    
	(1004, EncryptByCert(Cert_ID('Cert1'),'D135792468'), 'Ferdinand Wilson',	EncryptByCert(Cert_ID('Cert1'),'321 Maple St, City D'), 
	'069-4567', 'Active', EncryptByCert(Cert_ID('Cert1'),'mingming'), EncryptByCert(Cert_ID('Cert1'),'qwerty')),
    
	(1005, EncryptByCert(Cert_ID('Cert1'),'E864209753'), 'Celine Taydey',		EncryptByCert(Cert_ID('Cert1'),'654 Birch St, City E'), 
	'069-0317', 'Active', EncryptByCert(Cert_ID('Cert1'),'ctaydey'), EncryptByCert(Cert_ID('Cert1'),'qwerty'));

INSERT INTO [Transaction] (ProductCode, MemberID, TransactionCode, TransactionDate, QuantityPurchase) 
VALUES (3001, 1001, 1, '2023-07-08', 5); 

INSERT INTO [Transaction] (ProductCode, MemberID, TransactionCode, TransactionDate, QuantityPurchase) 
VALUES(3002, 1002, 2, '2023-07-09', 10); 

INSERT INTO [Transaction] (ProductCode, MemberID, TransactionCode, TransactionDate, QuantityPurchase) 
VALUES(3003, 1003, 3, '2023-07-23', 15); 

INSERT INTO [Transaction] (ProductCode, MemberID, TransactionCode, TransactionDate, QuantityPurchase) 
VALUES(3004, 1004, 4, '2023-07-26', 35);

INSERT INTO [Transaction] (ProductCode, MemberID, TransactionCode, TransactionDate, QuantityPurchase) 
VALUES(3005, 1005, 5, '2023-07-27', 40);

--DELETE FROM [Transaction]
SELECT * FROM [Transaction]

INSERT INTO [OrderItem] (ProductCode, OrderCode, OrderDate, QuantityPurchase) 
VALUES (3001, 1, '2023-07-18', 5), 
	   (3002, 2, '2023-07-19', 10), 
	   (3003, 3, '2023-07-20', 15), 
	   (3004, 4, '2023-07-21', 35),
	   (3005, 5, '2023-07-22', 40);

SELECT * FROM [Equipment]

--CLOSE CERTIFICATE Cert1;
-------------------------------------------------------- LAST N DAYS TRANSACTION ---------------------------------------------------------------------------------------------------------------
DECLARE @Days INT;
SET @Days = 100; --Modify last N days

SELECT * FROM [Transaction]
WHERE TransactionDate >= DATEADD(DAY, -@Days, GETDATE());

EXECUTE AS USER = '1001'
REVERT;

-------------------------------------------------------- TRIGGER -------------------------------------------------------------------------------------------------------------------------------
-- Trigger to update the equipment quantity when a new transaction is added
CREATE OR ALTER TRIGGER [Equipment_Sold]
ON [Transaction]
AFTER INSERT
AS
BEGIN
	DECLARE @quantitypurchase INT, @productcode BIGINT, @quantityinstock INT
	SELECT @quantitypurchase=QuantityPurchase, @productcode=ProductCode
	FROM inserted

	SELECT @quantityinstock=QuantityInStock
	FROM Equipment
	WHERE ProductCode=@productcode

	SET @quantityinstock = (@quantityinstock - @quantitypurchase)

	UPDATE Equipment
	SET QuantityInStock = @quantityinstock
	WHERE ProductCode=@productcode
END

-- Before order
SELECT * FROM Equipment

INSERT INTO [Transaction] (ProductCode, MemberID, TransactionCode, TransactionDate, QuantityPurchase) 
VALUES (3003, 1002, 8, '2023-08-05', 3)

-- After order
SELECT * FROM Equipment
SELECT * FROM [Transaction]

-- Trigger to update the equipment quantity when a new order item is added
CREATE OR ALTER TRIGGER [Equipment_Bought]
ON [OrderItem]
AFTER INSERT
AS
BEGIN
	DECLARE @quantitypurchase INT, @productcode BIGINT, @quantityinstock INT
	SELECT @quantitypurchase=QuantityPurchase, @productcode=ProductCode
	FROM inserted

	SELECT @quantityinstock=QuantityInStock
	FROM Equipment
	WHERE ProductCode=@productcode

	SET @quantityinstock = (@quantityinstock + @quantitypurchase)

	UPDATE Equipment
	SET QuantityInStock = @quantityinstock
	WHERE ProductCode=@productcode
END

-- Before order
SELECT * FROM Equipment

INSERT INTO [OrderItem] (ProductCode, OrderCode, OrderDate, QuantityPurchase)
VALUES (3003, 6,'2023-08-05', 10)

-- After order
SELECT * FROM Equipment
SELECT * FROM [OrderItem]

-- Avoid accidental deletion in row from member table [Ferdinand Wilson]
--DROP Trigger [Delete_Prevention_Member]
CREATE TRIGGER [Delete_Prevention_Member]
ON [Member]
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR('No one allowed to delete member row', 16,1);
    ROLLBACK;
END

DELETE FROM [Member] WHERE [MemberID] = '1001';
SELECT * FROM [Member]

-- DROP TRIGGER [Final_Price_Calculation]
-- Tax and discount trigger [Michael Henry]
CREATE OR ALTER TRIGGER [Final_Price_Calculation]
ON [Transaction]
AFTER INSERT, UPDATE
AS
BEGIN
	DECLARE @transactioncode BIGINT, @quantitypurchase INT, 
	@productcode BIGINT, @producingcountry VARCHAR(100), 
	@priceperunit FLOAT(50), @categoryid BIGINT, @discount DECIMAL(7,2), 
	@totalbeforediscount DECIMAL(7,2), @totalafterdiscount DECIMAL(7,2)
	SELECT @quantitypurchase=QuantityPurchase, @productcode=ProductCode, @transactioncode=TransactionCode
	FROM inserted

	SELECT @categoryid=CategoryID, @producingcountry=ProducingCountry, @priceperunit=PricePerUnit
	FROM Equipment
	WHERE ProductCode=@productcode

	SELECT @discount=Discount
	FROM Category
	WHERE @categoryid=CategoryID
	SET @totalbeforediscount = 
		CASE
			WHEN @producingcountry != 'Malaysia' THEN (@quantitypurchase * @priceperunit) * 1.1
			ELSE @quantitypurchase * @priceperunit
		END;
	SET @totalafterdiscount = @totalbeforediscount * (1 - @discount)

	UPDATE [Transaction]
	SET TotalBeforeDiscount = @totalbeforediscount, TotalAfterDiscount = @totalafterdiscount
	WHERE TransactionCode=@transactioncode
END

--test
SELECT * FROM [Transaction]
SELECT* FROM [Category]
SELECT * FROM [Equipment]

INSERT INTO [Transaction] (ProductCode, MemberID, TransactionCode, TransactionDate, QuantityPurchase) 
VALUES (3003, 1002, 7, '2023-08-05', 10)

DELETE [Transaction] WHERE ( TransactionCode = 7)

-- Return Item Trigger [Marcell Agung W]
--DROP TRIGGER  tr_TransferTransaction
CREATE TRIGGER TransferTransaction
ON [Transaction]
AFTER DELETE
AS
BEGIN
    DECLARE @ProductCode BIGINT, @TransactionCode INT, @QuantityPurchase INT, @TransactionDate Date;

    SELECT @ProductCode = ProductCode,
           @TransactionCode = TransactionCode,
           @QuantityPurchase = QuantityPurchase,
		   @TransactionDate = TransactionDate
    FROM DELETED;

    -- Check if the [Member] is executing the trigger and the TransactionDate is 3 days from now
    IF IS_ROLEMEMBER('MemberRole') = 1 AND GETDATE() - 3 <= @TransactionDate AND @TransactionDate <= GETDATE()
    BEGIN
        -- Update the quantity in the [Equipment] table
        UPDATE [Equipment]
        SET QuantityInStock = QuantityInStock + @QuantityPurchase
        WHERE ProductCode = @ProductCode;

        -- Delete the transaction from the [Transaction] table
        DELETE FROM [Transaction] WHERE TransactionCode = @TransactionCode;
    END
	ELSE
	BEGIN
		RAISERROR('Transaction %d cannot be deleted. It has exceeded the return time OR Executing as Non-Member Role.', 16, 1, @TransactionCode);
        ROLLBACK; -- Rollback the DELETE operation to prevent deletion
    END
END;

--Testing [Managenent]
Execute as User = 'Marcell Agung W'
SELECT * FROM [Transaction] WHERE TransactionCode = 1;
DELETE FROM [Transaction] WHERE TransactionCode = 11;
REVERT;

--[MemberRole]
EXECUTE AS USER = '1001'
SELECT * FROM [Transaction]
DELETE FROM [Transaction] WHERE TransactionCode = 1;
REVERT; 

SELECT * FROM Equipment
SELECT * FROM [Transaction]
INSERT INTO [Transaction] (ProductCode, MemberID, TransactionCode, TransactionDate, QuantityPurchase)
VALUES
    (3001, 1001, 12, '2023-08-10', 10);

-- User status trigger [Ferdian Marcel]
CREATE OR ALTER TRIGGER User_Status_Trigger
ON [TRANSACTION]
AFTER INSERT
AS
BEGIN
    UPDATE [Member]
    SET MemberStatus = 'Inactive'
    WHERE MemberID IN (SELECT MemberID FROM inserted)
    AND DATEDIFF(month, 
	(SELECT MAX(TransactionDate) FROM [TRANSACTION] WHERE MemberID = [Member].MemberID)
	, GETDATE()) > 1;

    UPDATE [Member]
    SET MemberStatus = 'Active'
    WHERE MemberID IN (SELECT MemberID FROM inserted)
    AND DATEDIFF(month, 
	(SELECT MAX(TransactionDate) FROM [TRANSACTION] WHERE MemberID = [Member].MemberID)
	, GETDATE()) <= 1;
END;

SELECT * FROM [Transaction]
SELECT * FROM [Member]
SELECT * FROM [Equipment]
INSERT INTO [Transaction] (ProductCode, MemberID, TransactionCode, TransactionDate, QuantityPurchase) 
VALUES (3001, 1001, 7, '2023-08-01', 3)

select * from member

select * from [Transaction]

-------------------------------------------------------- AUTHORIZATION -------------------------------------------------------------------------------------------------------------------------------
-- [Database Administrator]
--DROP USER [Michael Henry]
--DROP ROLE [Database Administrator]
CREATE LOGIN [Michael Henry] WITH PASSWORD = 'qwerty'
CREATE USER [Michael Henry] FOR LOGIN [Michael Henry]
CREATE ROLE [Database Administrator]
GRANT CONTROL ON [Equipment] TO [Database Administrator]
GRANT CONTROL ON [Transaction] TO [Database Administrator]
GRANT CONTROL ON [Member] TO [Database Administrator]
GRANT CONTROL ON [OrderItem] TO [Database Administrator]
GRANT CONTROL ON [Category] TO [Database Administrator]
DENY SELECT ON [Member] (NationalIDOrPassportNumber) TO [Database Administrator]
DENY SELECT ON [Member] (Address) TO [Database Administrator]
DENY SELECT ON [Member] (LoginID) TO [Database Administrator]
ALTER ROLE [Database Administrator] ADD MEMBER [Michael Henry]

--test
Execute as User = 'Michael Henry'
-- SELECT * FROM [Category]
-- ALTER TABLE [Member] ADD [test] INT
Revert

--[Management]
--DROP USER [Marcell Agung W]
--DROP ROLE [ManagementRole]

CREATE LOGIN [Marcell Agung W] WITH PASSWORD = 'qwerty'
CREATE USER [Marcell Agung W] FOR LOGIN [Marcell Agung W]
CREATE ROLE [ManagementRole]
GRANT CONTROL ON SCHEMA::dbo TO [ManagementRole] WITH GRANT OPTION;
DENY CONTROL ON [Member] TO [ManagementRole]
DENY SELECT ON [memberDecryptedDetails] TO [ManagementRole]
GRANT SELECT ON memberHiddenDetails TO [ManagementRole]
ALTER ROLE [ManagementRole] ADD MEMBER [Marcell Agung W]

--Testing
Execute as User = 'Marcell Agung W'
SELECT * FROM [memberDecryptedDetails] --Denied Access (Testing)
SELECT * FROM memberHiddenDetails ORDER BY MemberID
SELECT * FROM [TransactionDetails] Order By MemberID
Revert

SELECT * FROM [Member]

--Store Clerk--
--DROP USER [Ferdian Marcel]
--DROP ROLE [Store Clerk]
CREATE LOGIN [ferdianmarcel] WITH PASSWORD = 'akuganteng'
CREATE USER [ferdianmarcel] FOR LOGIN [ferdianmarcel]
CREATE ROLE [Store Clerk]
GRANT CONTROL ON Equipment TO [Store Clerk]
GRANT SELECT ON [Transaction] TO [Store Clerk]
GRANT INSERT ON [Member] TO [Store Clerk]
GRANT UPDATE ON [Member] (Name) TO [Store Clerk]
GRANT UPDATE ON [Member] (Address) TO [Store Clerk]
GRANT UPDATE ON [Member] (PhoneNumber) TO [Store Clerk]
GRANT UPDATE ON [Member] (MemberStatus) TO [Store Clerk]
GRANT SELECT ON [memberHiddenDetails] TO [Store Clerk]
GRANT SELECT, INSERT, DELETE ON [OrderItem] TO [Store Clerk]
GRANT SELECT, INSERT, DELETE ON [Category] TO [Store Clerk]

ALTER ROLE [Store Clerk] ADD MEMBER [ferdianmarcel]

EXECUTE AS USER = 'ferdianmarcel'
SELECT * FROM memberHiddenDetails
SELECT * FROM [Transaction]
REVERT

SELECT * FROM [Member]
--Member
DROP LOGIN [1001]
--DROP USER [1001]
--DROP ROLE [MemberRole]
CREATE LOGIN [1001] WITH PASSWORD = 'qwerty'
CREATE USER [1001] FOR LOGIN [1001]
CREATE ROLE [MemberRole]
GRANT SELECT ON [Equipment] TO [MemberRole]
GRANT SELECT, UPDATE ON [Member] TO [MemberRole]
DENY UPDATE ON [Member] (MemberID) TO [MemberRole]
GRANT DELETE, SELECT ON [Transaction] TO [MemberRole]
GRANT CONTROL ON CERTIFICATE::Cert1 to [MemberRole]
GRANT SELECT ON dbo.memberDecryptedDetails TO [MemberRole];

CREATE LOGIN [1002] WITH PASSWORD = 'qwerty'
CREATE USER [1002] FOR LOGIN [1002]

ALTER ROLE [MemberRole] ADD MEMBER [1001]
ALTER ROLE [MemberRole] ADD MEMBER [1002]


--test
EXECUTE AS USER = '1001'
SELECT * FROM memberDecryptedDetails
SELECT * FROM [Transaction]
REVERT

EXECUTE AS USER = '1002'
SELECT * FROM memberDecryptedDetails
SELECT * FROM [Transaction]
REVERT

--Member Update it's own details:
EXECUTE AS USER = '1001';
SELECT * FROM memberDecryptedDetails
SELECT * FROM [Member]
UPDATE [Member] SET PhoneNumber = 5555
-- Update Address
UPDATE [Member] SET [Address] = EncryptByCert(Cert_ID('Cert1'),'12345')
-- Update NationalIDOrPassportNumber
UPDATE [Member] SET NationalIDOrPassportNumber = EncryptByCert(Cert_ID('Cert1'),'new_national_id')
-- Update Name
UPDATE [Member] SET [Name] = 'new_name'
-- Update LoginID
UPDATE [Member] SET LoginID = EncryptByCert(Cert_ID('Cert1'),'new_login_id')
-- Update LoginPW
UPDATE [Member] SET LoginPW = EncryptByCert(Cert_ID('Cert1'),'qwerty')
REVERT;


SELECT dp.NAME AS principal_name,
dp.TYPE_DESC AS principal_type_desc,
o.NAME AS object_name,
o.type_desc AS object_type,
p.PERMISSION_NAME,
p.STATE_DESC AS permission_state_desc
FROM sys.database_permissions p
LEFT OUTER JOIN sys.all_objects o
ON p.MAJOR_ID = o.OBJECT_ID
INNER JOIN sys.database_principals dp
ON p.GRANTEE_PRINCIPAL_ID = dp.PRINCIPAL_ID
and dp.is_fixed_role = 0
and dp.Name NOT in ('public', 'dbo')


--Row Level Security
CREATE SCHEMA Security;

-- 1. Modify the fn_securitypredicate function
CREATE FUNCTION Security.fn_securitypredicate
    (@MemberID AS nvarchar(100))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 
        MemberID AS fn_securitypredicate_result
    FROM dbo.[Member]
    WHERE 
        (IS_ROLEMEMBER('MemberRole') = 1 AND @MemberID = USER_NAME())
        OR IS_ROLEMEMBER('MemberRole') = 0; -- Return all rows for other roles

-- 2. Modify the security policy
CREATE SECURITY POLICY [SecurityPolicy_Member]   
ADD FILTER PREDICATE 
[Security].[fn_securitypredicate]([MemberID]) ON [dbo].[Member]

CREATE SECURITY POLICY [SecurityPolicy_Transaction]   
ADD FILTER PREDICATE 
[Security].[fn_securitypredicate]([MemberID]) ON [dbo].[Transaction]
-------------------------------------------------------- AUDITING -------------------------------------------------------------------------------------------------------------------------------
------ Data Changes Audit
-- ALTER SERVER AUDIT Data_Changes_Audit  WITH (STATE = OFF)
-- DROP SERVER AUDIT Data_Changes_Audit
USE master
CREATE SERVER AUDIT Data_Changes_Audit  TO FILE ( FILEPATH = 'C:\Test' );   
ALTER SERVER AUDIT Data_Changes_Audit  WITH (STATE = ON) ;

-- ALTER DATABASE AUDIT SPECIFICATION Data_Changes_Audit_Spec WITH (STATE = OFF)
-- DROP DATABASE AUDIT SPECIFICATION Data_Changes_Audit_Spec
USE DBS_Assignment
CREATE DATABASE AUDIT SPECIFICATION Data_Changes_Audit_Spec
FOR SERVER AUDIT Data_Changes_Audit
ADD ( INSERT , UPDATE, DELETE, SELECT
ON DATABASE::DBS_Assignment BY PUBLIC)   
WITH (STATE = ON) ;   

-- Read
DECLARE @AuditFilePath VARCHAR(8000);
Select @AuditFilePath = audit_file_path
From sys.dm_server_audit_status
where name = 'Data_Changes_Audit'
select action_id, event_time, database_name, database_principal_name, object_name, statement
from sys.fn_get_audit_file(@AuditFilePath,default,default)
Where database_name = 'DBS_Assignment'

-- Test
Execute as User='Michael Henry'
Select * From [Transaction]
Revert

------ Database Structural Changes
-- ALTER SERVER AUDIT Structural_Changes_Audit  WITH (STATE = OFF)
-- DROP SERVER AUDIT Structural_Changes_Audit
USE master
CREATE SERVER AUDIT Structural_Changes_Audit  TO FILE ( FILEPATH = 'C:\Test' );   
ALTER SERVER AUDIT Structural_Changes_Audit  WITH (STATE = ON) ;

-- ALTER DATABASE AUDIT SPECIFICATION Structural_Changes_Audit_Spec WITH (STATE = OFF)
-- DROP DATABASE AUDIT SPECIFICATION Structural_Changes_Audit_Spec
USE DBS_Assignment
CREATE DATABASE AUDIT SPECIFICATION [Structural_Changes_Audit_Spec]
FOR SERVER AUDIT [Structural_Changes_Audit]
ADD (DATABASE_OBJECT_CHANGE_GROUP)
WITH (STATE = ON) ; 

-- Read
DECLARE @AuditFilePath VARCHAR(8000);
Select @AuditFilePath = audit_file_path
From sys.dm_server_audit_status
where name = 'Structural_Changes_Audit'
select action_id, event_time, database_name, database_principal_name, object_name, statement
from sys.fn_get_audit_file(@AuditFilePath,default,default)
Where database_name = 'DBS_Assignment'

-- Test
CREATE TABLE OrderItem1 ( 
	ProductCode BIGINT,
	FOREIGN KEY (ProductCode) REFERENCES Equipment(ProductCode),
    OrderCode INT PRIMARY KEY, 
	OrderDate DATE,
    QuantityPurchase INT,
);
DROP TABLE OrderItem1

------ User Permission Changes
-- ALTER SERVER AUDIT User_Permission_Audit  WITH (STATE = OFF)
-- DROP SERVER AUDIT User_Permission_Audit
USE master
CREATE SERVER AUDIT User_Permission_Audit  TO FILE ( FILEPATH = 'C:\Test' );   
ALTER SERVER AUDIT User_Permission_Audit  WITH (STATE = ON) ;

-- ALTER DATABASE AUDIT SPECIFICATION User_Permission_Audit_Spec WITH (STATE = OFF)
-- DROP DATABASE AUDIT SPECIFICATION User_Permission_Audit_Spec
USE DBS_Assignment
CREATE DATABASE AUDIT SPECIFICATION [User_Permission_Audit_Spec]
FOR SERVER AUDIT [User_Permission_Audit]
ADD (SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP)
WITH (STATE = ON) ; 

-- Read
DECLARE @AuditFilePath VARCHAR(8000);
Select @AuditFilePath = audit_file_path
From sys.dm_server_audit_status
where name = 'User_Permission_Audit'
select event_time, database_name, database_principal_name, object_name, statement
from sys.fn_get_audit_file(@AuditFilePath,default,default)
Where database_name = 'DBS_Assignment'

-- Test
GRANT SELECT ON [Equipment] TO [Database Administrator]
REVOKE SELECT ON [Equipment] TO [Database Administrator]

------ Login and Logout
-- ALTER SERVER AUDIT Login_Logout_Audit  WITH (STATE = OFF)
-- DROP SERVER AUDIT Login_Logout_Audit
USE master
CREATE SERVER AUDIT Login_Logout_Audit  TO FILE ( FILEPATH = 'C:\Test' );   
ALTER SERVER AUDIT Login_Logout_Audit  WITH (STATE = ON) ;

-- ALTER SERVER AUDIT SPECIFICATION Login_Logout_Audit_Spec WITH (STATE = OFF)
-- DROP SERVER AUDIT SPECIFICATION Login_Logout_Audit_Spec
USE DBS_Assignment
CREATE SERVER AUDIT SPECIFICATION [Login_Logout_Audit_Spec]
FOR SERVER AUDIT [Login_Logout_Audit]
ADD (LOGOUT_GROUP),
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (FAILED_LOGIN_GROUP)
WITH (STATE = ON);

-- Read
DECLARE @AuditFilePath VARCHAR(8000);
Select @AuditFilePath = audit_file_path
From sys.dm_server_audit_status
where name = 'Login_Logout_Audit'

SELECT event_time, action_id, succeeded, server_principal_name, statement
FROM sys.fn_get_audit_file(@AuditFilePath, DEFAULT, DEFAULT)

SELECT roles.[name] as role_name , members.[name] as user_name
FROM sys.database_role_members
INNER JOIN sys.database_principals roles
ON database_role_members.role_principal_id = roles.principal_id
INNER JOIN sys.database_principals members
ON database_role_members.member_principal_id = members.principal_id
WHERE roles.name = 'Database Administrator'

--drop all audit
--USE DBS_Assignment
--ALTER DATABASE AUDIT SPECIFICATION User_Permission_Audit_Spec WITH (STATE = OFF)
--DROP DATABASE AUDIT SPECIFICATION User_Permission_Audit_Spec
--ALTER DATABASE AUDIT SPECIFICATION Structural_Changes_Audit_Spec WITH (STATE = OFF)
--DROP DATABASE AUDIT SPECIFICATION Structural_Changes_Audit_Spec
--ALTER DATABASE AUDIT SPECIFICATION Data_Changes_Audit_Spec WITH (STATE = OFF)
--DROP DATABASE AUDIT SPECIFICATION Data_Changes_Audit_Spec

--USE master
--ALTER SERVER AUDIT SPECIFICATION Login_Logout_Audit_Spec WITH (STATE = OFF)
--DROP SERVER AUDIT SPECIFICATION Login_Logout_Audit_Spec
--ALTER SERVER AUDIT Login_Logout_Audit  WITH (STATE = OFF)
--DROP SERVER AUDIT Login_Logout_Audit
--ALTER SERVER AUDIT User_Permission_Audit  WITH (STATE = OFF)
--DROP SERVER AUDIT User_Permission_Audit
--ALTER SERVER AUDIT Structural_Changes_Audit  WITH (STATE = OFF)
--DROP SERVER AUDIT Structural_Changes_Audit
--ALTER SERVER AUDIT Data_Changes_Audit  WITH (STATE = OFF)
--DROP SERVER AUDIT Data_Changes_Audit
-------------------------------------------------------- BACKUP -------------------------------------------------------------------------------------------------------------------------------
USE master
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'qwert'
SELECT * FROM sys.symmetric_keys

USE master
CREATE CERTIFICATE CertMasterDB 
WITH SUBJECT = 'CertmasterDB'
SELECT * FROM sys.certificates

USE DBS_Assignment
CREATE DATABASE ENCRYPTION KEY  
   WITH ALGORITHM = AES_128
   ENCRYPTION BY SERVER CERTIFICATE CertMasterDB;
go

ALTER DATABASE DBS_Assignment SET ENCRYPTION ON;

USE master
SELECT b.name AS [DB Name], a.encryption_state_desc, a.key_algorithm, a.encryptor_type
FROM sys.dm_database_encryption_keys a
inner join sys.databases b on a.database_id = b.database_id
WHERE b.name = 'DBS_Assignment'

-- back up the DB --
BACKUP DATABASE DBS_Assignment
TO DISK = 'C:\Test\Backup\backup.bak'

BACKUP CERTIFICATE CertMasterDB 
TO FILE = 'C:\Test\Backup\CertMasterDB.cert'
WITH PRIVATE KEY (
    FILE = 'C:\Test\Backup\CertMasterDB.key', 
ENCRYPTION BY PASSWORD = 'qwert'
);
Go

USE master; -- Switch to the master database context (you cannot drop the current database)

DROP DATABASE DBS_Assignment;

USE master;
RESTORE DATABASE DBS_Assignment 
FROM DISK = 'C:\Test\Backup\backup.bak'
WITH MOVE 'DBS_Assignment' TO 'C:\Test\Backup\DBS_Assignment.mdf',
MOVE 'DBS_Assignment_Log' TO 'C:\Test\Backup\DBS_Assignment.ldf'