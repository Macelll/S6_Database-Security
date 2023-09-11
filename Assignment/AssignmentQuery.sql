USE DBS_Assignment

--i) Create tables and views
CREATE TABLE [Equipment] (
    ProductCode BIGINT PRIMARY KEY,
    EquipmentName VARCHAR(100),
    PricePerUnit FLOAT(50),
    Category VARCHAR(50),
    QuantityInStock INT DEFAULT 0,
    ProducingCountry VARCHAR(100)
);
CREATE VIEW [EquipmentView] AS
SELECT
    ProductCode,
    EquipmentName,
    PricePerUnit,
    Category,
    QuantityInStock,
    ProducingCountry
FROM Equipment;

CREATE TABLE [Transaction] (
    ProductCode BIGINT,
    MemberID BIGINT,
    TransactionCode INT PRIMARY KEY,
	TransactionDate Date, 
    ItemsPurchase VARCHAR(50),
    QuantityPurchase INT
);
CREATE VIEW [TransactionView] AS
SELECT
    ProductCode,
    MemberID,
    TransactionCode,
    TransactionDate,
    ItemsPurchase,
    QuantityPurchase
FROM [Transaction];

CREATE TABLE [Member] (
    MemberID BIGINT PRIMARY KEY,
    NationalIDOrPassportNumber VARBINARY(max),
    [Name] VARCHAR(100),
    [Address] VARBINARY(max),
    PhoneNumber VARCHAR(20),
    MemberStatus VARCHAR(20),
    LoginID VARBINARY(max),
	LoginPW VARBINARY(max)
);
CREATE VIEW [MemberView] AS
SELECT
    MemberID,
    NationalIDOrPassportNumber,
    [Name],
    [Address],
    PhoneNumber,
    MemberStatus,
    LoginID,
    LoginPW
FROM [Member];

DROP TABLE [Equipment]
DROP TABLE [Member]
DROP TABLE [Transaction]

DROP VIEW [EquipmentView]
DROP VIEW [TransactionView]
DROP VIEW [MemberView]

SELECT * FROM [EquipmentView]
SELECT * FROM [TransactionView]
SELECT * FROM [MemberView]

--Encryption System
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Macel'
SELECT * FROM sys.symmetric_keys

CREATE CERTIFICATE Cert1 WITH SUBJECT = 'Cert1'
SELECT * FROM sys.certificates

CREATE SYMMETRIC KEY SimKey1
WITH ALGORITHM = AES_256  
ENCRYPTION BY CERTIFICATE Cert1

CLOSE SYMMETRIC KEY SimKey1


--ii) Populate
INSERT INTO [Equipment] (ProductCode, EquipmentName, PricePerUnit, Category, QuantityInStock, ProducingCountry)
VALUES	(3001, 'Basketball Ball', 25.99, 'Balls', 50, 'USA'),
		(3002, 'Tennis Racket', 89.50, 'Rackets', 30, 'China'),
		(3003, 'Cricket Bat', 75.75, 'Bats', 20, 'India'),
		(3004, 'Volleyball Ball', 19.99, 'Balls', 40, 'Brazil'),
		(3005, 'Badminton Racket', 45.25, 'Rackets', 25, 'Malaysia');

DELETE FROM [MEMBER]

INSERT INTO [Member] (MemberID, NationalIDOrPassportNumber, [Name], [Address], PhoneNumber, MemberStatus, LoginID, LoginPW)
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

DELETE FROM [Transaction]

INSERT INTO [Transaction] (ProductCode, MemberID, TransactionCode, TransactionDate, ItemsPurchase, QuantityPurchase)
VALUES
    (3001, 1001, 1, '2023-07-15', 'Basketball Ball', 2),
    (3002, 1001, 2, '2023-07-15', 'Tennis Racket', 1),
    (3003, 1002, 3, '2023-07-16', 'Cricket Bat', 3),
    (3004, 1002, 4, '2023-07-16', 'Volleyball Ball', 2),
    (3005, 1003, 5, '2023-07-17', 'Badminton Racket', 1),
    (3001, 1003, 6, '2023-07-17', 'Basketball Ball', 1),
    (3002, 1004, 7, '2023-07-18', 'Tennis Racket', 2),
    (3003, 1004, 8, '2023-07-18', 'Cricket Bat', 1),
    (3004, 1005, 9, '2023-07-19', 'Volleyball Ball', 1),
    (3005, 1005, 10, '2023-07-19', 'Badminton Racket', 2);

--iii) SQL query/queries that can produce details of transactions that happen in the last n days where n = {1,2,…., 7}
DECLARE @Days INT;
SET @Days = 30 --last n days, change to needs.

SELECT *
FROM [Transaction]
WHERE TransactionDate >= DATEADD(DAY, -@Days, GETDATE());

--Row Level Security
DROP SCHEMA Security
DROP FUNCTION Security.fn_securitypredicate

CREATE SCHEMA Security
GO  
CREATE FUNCTION Security.fn_securitypredicate
	(@MemberID AS INT) 
RETURNS TABLE  
WITH SCHEMABINDING  
AS  
   RETURN SELECT 1 AS fn_securitypredicate_result
   WHERE @MemberID = USER_NAME();

SELECT MemberID(;

--Return Item Trigger [Marcell Agung W]
DROP TRIGGER  tr_TransferTransaction
CREATE TRIGGER tr_TransferTransaction
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
SELECT * FROM [Transaction] WHERE TransactionCode = 11;
DELETE FROM [Transaction] WHERE TransactionCode = 11;
REVERT;

--[MemberRole]
EXECUTE AS USER = '1001'
SELECT * FROM [Transaction]
DELETE FROM [Transaction] WHERE TransactionCode = 11;
REVERT; 

SELECT * FROM Equipment

INSERT INTO [Transaction] (ProductCode, MemberID, TransactionCode, TransactionDate, ItemsPurchase, QuantityPurchase)
VALUES
    (3001, 1001, 11, '2023-08-5', 'Basketball Ball', 11);

--Data Encryption------------------------------------------------------------------------------------------------------------
--i) 
--Step 1: Create the view to show member details with decrypted values
DROP VIEW memberDecryptedDetails
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
SELECT * FROM memberDecryptedDetails      

--ii)
DROP VIEW memberHiddenDetails

CREATE VIEW memberHiddenDetails AS
SELECT
    MemberID,
    [Name],
	PhoneNumber,
    MemberStatus
FROM [Member];

SELECT * FROM memberHiddenDetails

--iii) 



--User Permission Management 
--[Management]
DROP USER [Manager1]
DROP ROLE [Management]

CREATE LOGIN [Marcell Agung W] WITH PASSWORD = 'qwerty'
CREATE USER [Marcell Agung W] FOR LOGIN [Marcell Agung W]
CREATE ROLE [ManagementRole]

-- Grant Control and Grant privilege to [Management]
GRANT CONTROL ON SCHEMA::dbo TO [ManagementRole] WITH GRANT OPTION;
DENY CONTROL ON [Member] TO [ManagementRole]
DENY SELECT ON [memberDecryptedDetails] TO [ManagementRole]
GRANT SELECT ON memberHiddenDetails TO [ManagementRole]

ALTER ROLE [ManagementRole] ADD MEMBER [Marcell Agung W]

Execute as User = 'Marcell Agung W'
SELECT * FROM [memberDecryptedDetails] --Denied Access (Testing)
SELECT * FROM memberHiddenDetails ORDER BY MemberID
SELECT * FROM [Transaction] Order By MemberID
Revert

--User Permission Management
--[Member]
--DROP USER [1002]
--DROP ROLE [MemberRole]
CREATE LOGIN [1001] WITH PASSWORD = 'qwerty'
CREATE USER [1001] FOR LOGIN [1001]

CREATE LOGIN [1002] WITH PASSWORD = 'qwerty'
CREATE USER [1002] FOR LOGIN [1002]
CREATE ROLE [MemberRole]

ALTER ROLE [MemberRole] ADD MEMBER [1001]

GRANT SELECT ON [Equipment] TO [MemberRole]

GRANT SELECT, UPDATE ON [Member] TO [MemberRole]
DENY UPDATE ON [Member] (MemberID) TO [MemberRole]

GRANT CONTROL ON CERTIFICATE::Cert1 to [MemberRole]
GRANT SELECT ON dbo.memberDecryptedDetails TO [MemberRole];

GRANT DELETE, SELECT ON [Transaction] TO [MemberRole]


--Row Level Security

DROP SCHEMA Security
DROP FUNCTION Security.fn_securitypredicate
DROP SECURITY POLICY [SecurityPolicy_Member] 
DROP SECURITY POLICY [SecurityPolicy_Transaction]

CREATE SCHEMA Security;

-- 1. fn_securitypredicate function
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

--Testing
EXECUTE AS USER = '1002'
SELECT * FROM memberDecryptedDetails
SELECT * FROM [Transaction]
REVERT

EXECUTE AS USER = '1001'
SELECT * FROM memberDecryptedDetails
SELECT * FROM [Transaction]
REVERT

--[Database Admin]
CREATE LOGIN [DBAAdmin1] WITH PASSWORD = 'qwerty'
CREATE USER [DBAAdmin1] FOR LOGIN [DBAAdmin1]

CREATE ROLE [Database Administrator]

GRANT SELECT ON [Transaction] TO [Database Administrator]
GRANT SELECT ON [Member] (MemberID) TO [Database Administrator]
GRANT SELECT ON [Member] (Name) TO [Database Administrator]
GRANT SELECT ON [Member] (MemberStatus) TO [Database Administrator]
ALTER ROLE [Database Administrator] ADD MEMBER [DBAAdmin1]

Execute as User = 'DBAAdmin1'
SELECT * FROM [Transaction]
Revert

EXEC sp_helprolemember 'MemberRole'

--Store Clerk--
DROP USER [ferdianmarcel]
DROP ROLE [Store Clerk]

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

ALTER ROLE [Store Clerk] ADD MEMBER [ferdianmarcel]

EXECUTE AS USER = 'ferdianmarcel'
SELECT * FROM memberHiddenDetails
REVERT

SELECT * FROM [Transaction]

