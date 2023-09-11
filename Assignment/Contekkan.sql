---------------------------------------------------
--CREATE DATABASE--
---------------------------------------------------

USE master;
DROP DATABASE APUSportEquipment;
CREATE DATABASE APUSportEquipment;

--CREATE TRIGGER TO AVOID ACCIENTIAL DELETION OF DATABASE IN master
GO
CREATE TRIGGER [Trig_Prevent_Drop_Database]
ON ALL SERVER
FOR DROP_DATABASE
AS
RAISERROR('Dropping of databases has been disabled on this server.', 16,1);
ROLLBACK;

GO

DISABLE TRIGGER [Trig_Prevent_Drop_Database] ON ALL SERVER
GO

--DROP DATABASE APUSportEquipment;

USE APUSportEquipment;

---------------------------------------------------
--TDE--
---------------------------------------------------

--CREATE DATABASE MASTER KEY (DMK)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'APUSportEquipment@1234*';

--CREATE MASTER CERTIFICATE - TDE (PROTECT DB)
CREATE CERTIFICATE CertmasterDB WITH SUBJECT = 'CertmasterDB';

--CREATE DATABASE ENCRYPTION KEY (DEK) - PROTECTED BY CertmasterDB
CREATE DATABASE ENCRYPTION KEY
	WITH ALGORITHM = AES_128
	ENCRYPTION BY SERVER CERTIFICATE CertmasterDB;

-- ENABLE TRANSPARENT DATA ENCRYPTION FOR THE DATABASE
ALTER DATABASE APUSportEquipment SET ENCRYPTION ON;

---------------------------------------------------
--BACKUP CREATION AND RESTORATION--
---------------------------------------------------

--CREATE BACKUP FOR ENCRYPTED DATABASE
BACKUP DATABASE APUSportEquipment
TO DISK = 'C:\APUSportEquipmentBackup\APUSportEquipment.bak';

--BACKUP THE CERTIFICATE THAT PROTECTED DEK
USE master;
BACKUP CERTIFICATE CertmasterDB
   TO FILE = 'C:\APUSportEquipmentBackup\CertmasterDB.cer'
   WITH PRIVATE KEY (
       FILE = 'C:\APUSportEquipmentBackup\CertmasterDB.pvk',
       ENCRYPTION BY PASSWORD = 'APUSportEquipment@1234*'
   );

--COPY THE C:\TDECERTIFICATE.cer AND C:\TDECERTIFICATE.pvk FILES 
--FROM THE SOURCE SERVER TO A SIMILAR LOCATION ON THE DESTINATION SERVER.

-----------RUN THIS CODE IN ANOTHER SERVER (START)------------
--CREATE DATABASE MASTER KEY (DMK)
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'APUSportEquipment@1234*';

--ON THE DESTINATION, RESTORE THE CERTIFICATE
USE master;
CREATE CERTIFICATE CertmasterDB
   FROM FILE = 'C:\APUSportEquipmentRestoration\CertmasterDB.cer'
   WITH PRIVATE KEY (
       FILE = 'C:\APUSportEquipmentRestoration\CertmasterDB.pvk',
       DECRYPTION BY PASSWORD = 'APUSportEquipment@1234*'
   );

--ON THE DESTINATION, RESTORE THE DATABASE
RESTORE FILELISTONLY
FROM DISK = 'C:\APUSportEquipmentBackup\APUSportEquipment.bak';

RESTORE DATABASE APUSportEquipment
FROM DISK = 'C:\APUSportEquipmentBackup\APUSportEquipment.bak'
WITH MOVE 'APUSportEquipment' TO 'C:\APUSportEquipmentBackup\APUSportEquipment.mdf',
MOVE 'APUSportEquipment_Log' TO 'C:\APUSportEquipmentBackup\APUSportEquipment_Log.ldf';
-----------RUN THIS CODE IN ANOTHER SERVER (END)------------

---------------------------------------------------
--AUDITING--
---------------------------------------------------

USE master;
GO
--SERVER AUDIT
CREATE SERVER AUDIT [Audit-Login-Logout]
TO FILE (FILEPATH = 'C:\APUSportEquipmentAuditing')

ALTER SERVER AUDIT [Audit-Login-Logout]  WITH (STATE = ON) ;

CREATE SERVER AUDIT [Audit-StructuralChanges]
TO FILE (FILEPATH = 'C:\APUSportEquipmentAuditing')

ALTER SERVER AUDIT [Audit-StructuralChanges]  WITH (STATE = ON) ;

CREATE SERVER AUDIT [Audit-DataChanges]
TO FILE (FILEPATH = 'C:\APUSportEquipmentAuditing')

ALTER SERVER AUDIT [Audit-DataChanges]  WITH (STATE = ON) ;

CREATE SERVER AUDIT [Audit-PermissionChanges]
TO FILE (FILEPATH = 'C:\APUSportEquipmentAuditing')

ALTER SERVER AUDIT [Audit-PermissionChanges]  WITH (STATE = ON) ;

--DROP SERVER AUDIT [Audit-Activities]
--ALTER SERVER AUDIT [Audit-Activities]  WITH (STATE = OFF) ;

--LOGIN AND LOGOUT
CREATE SERVER AUDIT SPECIFICATION [ServerAuditSpecification-Login-Logout]
FOR SERVER AUDIT [Audit-Login-Logout]
ADD (SUCCESSFUL_LOGIN_GROUP),
ADD (FAILED_LOGIN_GROUP),
ADD (LOGOUT_GROUP)
WITH (STATE = ON);

--VIEW SERVER AUDIT DETAILS
SELECT *
FROM sys.fn_get_audit_file('C:\APUSportEquipmentAuditing\*.sqlaudit', default, default);

USE APUSportEquipment;

--DATABASE STRUCTURAL CHANGES
CREATE DATABASE AUDIT SPECIFICATION [DatabaseAuditSpecification-StructuralChanges]
FOR SERVER AUDIT [Audit-StructuralChanges]
ADD (SCHEMA_OBJECT_CHANGE_GROUP)
WITH (STATE = ON);

--DATA CHANGES
CREATE DATABASE AUDIT SPECIFICATION [DatabaseAuditSpecification-DataChanges]
FOR SERVER AUDIT [Audit-DataChanges]
ADD (SELECT, UPDATE, INSERT, DELETE ON SCHEMA::[dbo] BY public)
WITH (STATE = ON);

SELECT * FROM sys.database_audit_specifications WHERE name = 'DatabaseAuditSpecification-DataChanges';


--USER PERMISSION CHANGES
CREATE DATABASE AUDIT SPECIFICATION [DatabaseAuditSpecification-PermissionChanges]
FOR SERVER AUDIT [Audit-PermissionChanges]
ADD (DATABASE_PRINCIPAL_CHANGE_GROUP)
WITH (STATE = ON);

--READING AUDIT DATA
DECLARE @AuditFilePath VARCHAR(8000);

SELECT @AuditFilePath = audit_file_path
FROM sys.dm_server_audit_status
WHERE name = 'Audit-StructuralChanges';

SELECT action_id, event_time, database_name, database_principal_name, object_name, statement
FROM sys.fn_get_audit_file(@AuditFilePath,default,default)
WHERE database_name = 'APUSportEquipment';

---------------------------------------------------
--CREATE TABLES--
---------------------------------------------------
USE APUSportEquipment;
GO

CREATE TABLE COUNTRY(
	country_ID VARCHAR(3) PRIMARY KEY,
	country_name VARCHAR(100) NOT NULL
);

CREATE TABLE [USER] (
    user_ID INT IDENTITY(100000, 1) PRIMARY KEY,
    IC_passport_number VARBINARY(MAX) NOT NULL,
    name VARCHAR(100) NOT NULL,
    address_no VARCHAR(10),
    address_street VARCHAR(100),
    address_city VARCHAR(50),
    address_state VARCHAR(50),
    address_country VARCHAR(3) DEFAULT 'MYS' FOREIGN KEY REFERENCES COUNTRY(country_ID),
    phone_number VARCHAR(11) UNIQUE NOT NULL CHECK (phone_number LIKE '01[0-9]%'),
    date_of_birth DATE,
    gender CHAR(1) CHECK (gender IN ('F', 'M')),
    registration_date DATE DEFAULT GETDATE(),
    status TINYINT DEFAULT 1 CHECK (status IN (0, 1, 2)),
	username VARCHAR(30) NOT NULL UNIQUE CHECK (username NOT LIKE '% %'),
	password_hash VARBINARY(MAX) NOT NULL
);


CREATE TABLE [TRANSACTION] (
    transaction_ID INT PRIMARY KEY IDENTITY(400000, 1),
    user_ID INT FOREIGN KEY REFERENCES [USER](user_ID),
    transaction_date DATE NOT NULL
);

CREATE TABLE DISCOUNT (
    discount_ID INT IDENTITY(600000,1) PRIMARY KEY,
    discount_name VARCHAR(100),
	discount_description VARCHAR(100),
    percentage_off DECIMAL(5, 2),
    activation_date DATE,
    expiry_date DATE
);

CREATE TABLE EQUIPMENT_CATEGORY(
	equipment_category_ID INT IDENTITY(200000, 1) PRIMARY KEY,
	discount_ID INT DEFAULT NULL REFERENCES DISCOUNT,
	equipment_category_name TEXT NOT NULL
);

CREATE TABLE EQUIPMENT(
	equipment_ID INT IDENTITY(300000,1) PRIMARY KEY,
	equipment_category_ID INT FOREIGN KEY REFERENCES EQUIPMENT_CATEGORY,
	country_ID VARCHAR(3) FOREIGN KEY REFERENCES COUNTRY,
	equipment_name TEXT NOT NULL,
	price_per_unit_before_tax DECIMAL(7,2) NOT NULL,
	price_per_unit_after_tax DECIMAL(7,2) NULL,
	quantity_in_stock INT NOT NULL CHECK (quantity_in_stock >= 0)
);

CREATE TABLE [ITEM_PURCHASED] (
    item_purchased_ID INT PRIMARY KEY IDENTITY(500000, 1),
    transaction_ID INT FOREIGN KEY REFERENCES [TRANSACTION](transaction_ID),
    equipment_ID INT FOREIGN KEY REFERENCES [EQUIPMENT](equipment_ID),
    quantity_purchased INT NOT NULL,
    total_before_discount DECIMAL(7,2) NULL,
    total_after_discount DECIMAL(7,2) NULL);


CREATE TABLE REFER (
    refer_ID INT IDENTITY(700000,1) PRIMARY KEY,
    item_purchased_ID INT FOREIGN KEY REFERENCES ITEM_PURCHASED(item_purchased_ID),
    return_date DATE DEFAULT GETDATE(),
    return_reason VARCHAR(100),
    return_approval_status TINYINT DEFAULT 0 CHECK (return_approval_status IN (0, 1))
);

---------------------------------------------------
--CREATE TRIGGERS--
---------------------------------------------------

--USER STATUS TRIGGER
GO
CREATE OR ALTER TRIGGER USER_STATUS_TRIGGER
ON [TRANSACTION]
AFTER INSERT
AS
BEGIN
    -- SET THE USER STATUS TO INACTIVE IF THE TRANSACTION DATE IS LONGER THAN A MONTH FROM THE CURRENT DATE
    UPDATE [USER]
    SET status = 2
    WHERE user_ID IN (SELECT user_ID FROM inserted)
    AND DATEDIFF(month, 
	(SELECT MAX(transaction_date) FROM [TRANSACTION] WHERE user_ID = [USER].user_ID)
	, GETDATE()) > 1;

    -- SET THE USER STATUS TO EXPIRED IF THE TRANSACTION DATE IS LONGER THAN 6 MONTHS FROM THE CURRENT DATE
    UPDATE [USER]
    SET status = 0
    WHERE user_ID IN (SELECT user_ID FROM inserted)
    AND DATEDIFF(month, 
	(SELECT MAX(transaction_date) FROM [TRANSACTION] WHERE user_ID = [USER].user_ID)
	, GETDATE()) > 6;

    -- SET THE USER STATUS BACK TO ACTIVE IF THEY HAVE A TRANSACTION DATE WITHIN 1 MONTH FROM THE CURRENT DATE
    UPDATE [USER]
    SET status = 1
    WHERE user_ID IN (SELECT user_ID FROM inserted)
    AND DATEDIFF(month, 
	(SELECT MAX(transaction_date) FROM [TRANSACTION] WHERE user_ID = [USER].user_ID)
	, GETDATE()) <= 1;
END;

-----------------------------------------------------------------------------------------------
--TAX CALCULATION TRIGGER
--START ANOTHER BATCH
GO

--CREATE OR ALTER A TRIGGER TO CALCULATE THE TAXED PRICE 
--AFTER A USER INSERTED DATA INTO THE EQUIPMENT TABLE
CREATE OR ALTER TRIGGER TAX_CALCULATION
ON EQUIPMENT
AFTER INSERT, UPDATE
AS
BEGIN
	--UPDATE THE NEWLY INSERTED ROWS WITH THE CALCULATED PRICE AFTER TAX
	--IF THE COUNTRY IS NOT 'MYS', THEN TAX WILL BE CALCULATED
	--ELSE INSERT THE SAME AMOUNT AS BEFORE TAX
    UPDATE EQUIPMENT
    SET price_per_unit_after_tax = 
        CASE 
            WHEN INSERTED.country_ID != 'MYS' THEN INSERTED.price_per_unit_before_tax * 1.1 --10% TAX
            ELSE INSERTED.price_per_unit_before_tax
        END
    FROM EQUIPMENT
    INNER JOIN INSERTED ON EQUIPMENT.equipment_id = INSERTED.equipment_id;
END

GO

-----------------------------------------------------------------------------------------------
--TOTAL DISCOUNT CALCULATION TRIGGER
--START ANOTHER BATCH
GO
--CREATE OR ALTER A TRIGGER TO CALCULATE THE TAXED PRICE 
--AFTER A USER INSERTED DATA INTO THE EQUIPMENT TABLE
CREATE OR ALTER TRIGGER TOTAL_DISCOUNT_CALCULATION
ON ITEM_PURCHASED
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE ITEM_PURCHASED
    SET 
        total_before_discount = INSERTED.quantity_purchased * e.price_per_unit_after_tax,
        total_after_discount = 
            CASE 
                WHEN ec.discount_ID IS NOT NULL AND (t.transaction_date BETWEEN d.activation_date AND d.expiry_date) 
				THEN e.price_per_unit_after_tax * (1.0 - d.percentage_off)
                ELSE INSERTED.quantity_purchased * e.price_per_unit_after_tax
            END
    FROM ITEM_PURCHASED
    INNER JOIN INSERTED ON ITEM_PURCHASED.item_purchased_ID = INSERTED.item_purchased_ID
    INNER JOIN EQUIPMENT e ON e.equipment_ID = INSERTED.equipment_ID
	INNER JOIN [TRANSACTION] t ON t.transaction_ID = INSERTED.transaction_ID
    LEFT JOIN EQUIPMENT_CATEGORY ec ON ec.equipment_category_ID = e.equipment_category_ID
    LEFT JOIN DISCOUNT d ON d.discount_ID = ec.discount_ID;
END
GO

-----------------------------------------------------------------------------------------------
--TRIGGER TO ADD DATA INTO REFER TABLE WHEN ITEM_PURCHASED TABLE IS INSERTED
GO
CREATE OR ALTER TRIGGER TRIGGER_ADD_TO_REFER
ON [ITEM_PURCHASED]
AFTER INSERT
AS
BEGIN
    INSERT INTO [REFER] (item_purchased_ID, return_date, return_reason, return_approval_status)
    SELECT item_purchased_ID, GETDATE(), NULL, 0
    FROM inserted;
END;

-----------------------------------------------------------------------------------------------
--TRIGGER TO UPDATE REFER TABLE WHEN ITEM_PURCHASED(QUANTITY) IS UPDATED
GO
CREATE OR ALTER TRIGGER TRIGGER_UPDATE_REFER
ON [ITEM_PURCHASED]
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the quantity has changed in the updated rows
    IF UPDATE(quantity_purchased)
    BEGIN
        -- Update the REFER table based on changes in ITEM_PURCHASED
        UPDATE R
        SET R.return_approval_status = 1
        FROM [REFER] AS R
        JOIN INSERTED AS I ON R.item_purchased_ID = I.item_purchased_ID
        WHERE I.quantity_purchased <> R.return_approval_status;
    END;
END;

-----------------------------------------------------------------------------------------------
--TRIGGER TO SET REFER TABLE STATUS TO 1 AS RETURN WHEN THE RECORD ITEM_PURCHASED IS DELETED
GO
CREATE OR ALTER TRIGGER TRIGGER_RETURN_ITEM
ON [ITEM_PURCHASED]
AFTER DELETE
AS
BEGIN
    -- SET NOCOUNT ON;

    -- Update the status in the REFER table for the deleted item
    UPDATE R
    SET return_approval_status = 1
    FROM [REFER] AS R
    JOIN DELETED AS D ON R.item_purchased_ID = D.item_purchased_ID;

    -- Update the quantity_in_stock in the EQUIPMENT table based on the returned items
    UPDATE E
    SET E.quantity_in_stock = E.quantity_in_stock + D.quantity_purchased
    FROM [EQUIPMENT] AS E
    JOIN DELETED AS D ON E.equipment_ID = D.equipment_ID
    JOIN [REFER] AS R ON D.item_purchased_ID = R.item_purchased_ID
    WHERE R.return_approval_status = 1;
END;

-----------------------------------------------------------------------------------------------
--CREATE TRIGGER TO CHECK STOCK FOR UPDATE, INSERT AND DELETE
GO
CREATE OR ALTER TRIGGER STOCK_CHECKING
ON [ITEM_PURCHASED]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN

    -- Handle INSERTs
    IF EXISTS (SELECT * FROM INSERTED) AND NOT EXISTS (SELECT * FROM DELETED)
    BEGIN
        UPDATE e
        SET e.quantity_in_stock = e.quantity_in_stock - i.quantity_purchased
        FROM EQUIPMENT e
        INNER JOIN INSERTED i ON e.equipment_ID = i.equipment_ID
        WHERE e.quantity_in_stock >= i.quantity_purchased;
        
        -- Check for insufficient stock
        IF @@ROWCOUNT <> (SELECT COUNT(*) FROM INSERTED)
        BEGIN
            PRINT 'Stock is not enough for some products.';
            ROLLBACK; -- Cancel the INSERT operation.
            RETURN; -- Exit the trigger to prevent further processing.
        END;
    END;

    -- Handle DELETEs
    IF EXISTS (SELECT * FROM DELETED) AND NOT EXISTS (SELECT * FROM INSERTED)
    BEGIN
        UPDATE e
        SET e.quantity_in_stock = e.quantity_in_stock + d.quantity_purchased
        FROM EQUIPMENT e
        INNER JOIN DELETED d ON e.equipment_ID = d.equipment_ID;
    END;

    -- Handle UPDATEs
    IF EXISTS (SELECT * FROM INSERTED) AND EXISTS (SELECT * FROM DELETED)
    BEGIN
        UPDATE e
        SET e.quantity_in_stock = e.quantity_in_stock + d.quantity_purchased - i.quantity_purchased
        FROM EQUIPMENT e
        INNER JOIN INSERTED i ON e.equipment_ID = i.equipment_ID
        INNER JOIN DELETED d ON e.equipment_ID = d.equipment_ID
        WHERE e.quantity_in_stock + d.quantity_purchased >= i.quantity_purchased;

        -- Check for insufficient stock
        IF @@ROWCOUNT <> (SELECT COUNT(*) FROM INSERTED)
        BEGIN
            PRINT 'Stock is not enough for some products.';
            ROLLBACK; -- Cancel the UPDATE operation.
            RETURN; -- Exit the trigger to prevent further processing.
        END;
    END;

END;


---------------------------------------------------
--INSERT VALUES--
---------------------------------------------------

--INSERT DATA INTO TABLE COUNTRY
INSERT INTO COUNTRY(country_ID, country_name) VALUES
('MYS','Malaysia'),
('IDN','Indonesia'),
('NZL','New Zealand'),
('PHL','Philippines'),
('DEU','Germany');

--CREATE CERTIFICATE WITHOUT PASSWORD
CREATE CERTIFICATE Cert1 WITH Subject = 'Cert1';

-- CREATE A SYMMETRIC KEY PROTECTED BY A CERTIFICATE
CREATE SYMMETRIC KEY SimKey1
   WITH ALGORITHM = AES_256
   ENCRYPTION BY CERTIFICATE Cert1;

-- OPEN THE SYMMETRIC KEY
OPEN SYMMETRIC KEY SimKey1
   DECRYPTION BY CERTIFICATE Cert1;

-- INSERT DATA INTO THE USER TABLE USING THE SYMMETRIC KEY TO ENCRYPT THE IC_passport_number COLUMN
INSERT INTO [USER] 
(IC_passport_number, name, 
address_no, address_street, 
address_city, address_state, 
phone_number, date_of_birth, gender, username, password_hash)
VALUES 
(ENCRYPTBYKEY(KEY_GUID('SimKey1'), '1234567890'), 
'John Doe', '123', 'Main Street', 'Bukit Jalil', 'Kuala Lumpur', '0123456789', '2000-01-01', 'M', 'johndoe', 
HASHBYTES('SHA2_512', 'password1')),
(ENCRYPTBYKEY(KEY_GUID('SimKey1'), '2345678901'), 
'Jane Doe', '456', 'Second Street', 'OUG', 'Kuala Lumpur', '0134567890', '2001-02-02', 'F', 'janedoe', 
HASHBYTES('SHA2_512', 'password2')),
(ENCRYPTBYKEY(KEY_GUID('SimKey1'), '3456789012'), 
'Bob Smith', '789', 'Third Street', 'Cheras', 'Kuala Lumpur', '0145678901', '2002-03-03', 'M', 'bobsmith', 
HASHBYTES('SHA2_512', 'password3')),
(ENCRYPTBYKEY(KEY_GUID('SimKey1'), '4567890123'), 
'Alice Johnson', '012', 'Fourth Street', 'Desa Petaling', 'Kuala Lumpur', '0156789012', '2003-04-04', 'F', 'alicejohnson', 
HASHBYTES('SHA2_512', 'password4')),
(ENCRYPTBYKEY(KEY_GUID('SimKey1'), '5678901234'), 
'Charlie Brown', '345', 'Fifth Street', 'Petaling Jaya','Kuala Lumpur','0167890123','2004-05-05','M','charliebrown',
HASHBYTES('SHA2_512','password5')),
(ENCRYPTBYKEY(KEY_GUID('SimKey1'),'6789012345'),
'Dave Lee','789','Sixth Street','Bangsar','Kuala Lumpur','0178901234','2005-06-06','M','davelee',
HASHBYTES('SHA2_512','password6')),
(ENCRYPTBYKEY(KEY_GUID('SimKey1'),'6789012345'),
'Pua En Ni','23','Seventh Street','Sri Petaling','Kuala Lumpur','0183777043','2001-11-28','F','enni',
HASHBYTES('SHA2_512','12345')),
(ENCRYPTBYKEY(KEY_GUID('SimKey1'), '4567890124'), 
'Siew Wei Jing', '28', 'Hujan Lapan', 'OUG', 'Kuala Lumpur', '01112345678', '2001-11-12', 'F', 'siewweijing', 
HASHBYTES('SHA2_512', 'password1234')),
(ENCRYPTBYKEY(KEY_GUID('SimKey1'), '1234567890'), 
'Yonathan Vincent Xavier', '453', 'Jaya One Street', 'Sri Kembangan', 'Kuala Lumpur', '0183355678', '2001-02-02', 'M', 'yonathan', 
HASHBYTES('SHA2_512', 'password2234')),
(ENCRYPTBYKEY(KEY_GUID('SimKey1'), '0987654321'), 
'Pipin Setiawan', '789', 'Seven Street', 'Cheras', 'Kuala Lumpur', '0188234765', '2002-03-03', 'M', 'pipin', 
HASHBYTES('SHA2_512', 'password3234'));

-- CLOSE THE SYMMETRIC KEY
CLOSE SYMMETRIC KEY SimKey1;

SELECT * FROM [USER]

--INSERT TRANSACTION TABLE
INSERT INTO [TRANSACTION] (user_ID, transaction_date)
VALUES (100000, '2022-03-21'),
       (100001, '2023-02-21'),
       (100002, '2023-04-03'),
       (100003, '2023-06-20'),
       (100004, '2023-07-21'),
       (100005, '2023-07-28'),
	   (100006, '2023-07-31');

--INSERT INTO DISCOUNT TABLE
INSERT INTO DISCOUNT 
(discount_name, discount_description, percentage_off, activation_date, expiry_date)
VALUES
('Summer Sale','For Summer Sale we are giving all of our customer 10% off on all racket products',0.10,'2023-07-01','2023-08-31'),
('Winter Sale','For Winter Sale we are giving all of our customer 15% off on all balls products',0.15,'2024-01-01','2024-01-31'),
('Spring Sale','For Spring Sale we are giving all of our customer 25% off on all bats products',0.25,'2024-03-01','2024-03-31'),
('Autumn Sale','For Autumn Sale we are giving all of our customer 20% off on all nets products',0.20,'2024-09-01','2024-11-30'),
('Flash Sale','We are giving all of our customer 5% off on all nets products in a short period',0.05,'2024-02-01','2024-02-15'),
('Christmas Sale','All of our products 10% off',0.30,'2024-12-01','2024-12-26');

--INSERT DATA INTO TABLE EQUIPMENT_CATEGORY
INSERT INTO EQUIPMENT_CATEGORY(equipment_category_name, discount_ID) VALUES
('Ball', NULL),
('Racket', NULL),
('Bat', NULL),
('Net', NULL),
('Sportswear', NULL),
('Goal Post', 600000),
('Helmat', 600001);

--INSERT DATA INTO TABLE EQUIPMENT
INSERT INTO EQUIPMENT(equipment_category_ID,country_ID,equipment_name,price_per_unit_before_tax,quantity_in_stock)VALUES
(200001, 'DEU', 'Badminton Racket', '25.35', 10),
(200003, 'MYS', 'Volley Ball Net', '95.85', 10),
(200000, 'NZL', 'Basketball', '56.35', 10),
(200004, 'MYS', 'Swimsuit', '45.25', 10),
(200000, 'NZL', 'Volley Ball', '67.95', 10),
(200005, 'IDN', 'Football Post', '124.95', 10),
(200006, 'PHL', 'Bicycle Helmat', '75.95', 10);

--INSERT INTO ITEM PURCHASED TABLE
INSERT INTO [ITEM_PURCHASED] (transaction_ID,equipment_ID,quantity_purchased)
VALUES (400001, 300000, 4),
       (400002, 300001, 3),
       (400003, 300002, 4),
       (400004, 300003, 2),
       (400005, 300004, 3),
	   (400001, 300005, 1),
       (400002, 300006, 1),
	   (400006, 300003, 2);

---------------------------------------------------
--CREATE VIEWS--
---------------------------------------------------

--START ANOTHER BATCH
GO
-- CREATE A VIEW TO SELECT ALL ACTIVE USERS
CREATE VIEW active_users AS
SELECT *
FROM [USER]
WHERE status = 1;
GO

SELECT *
FROM active_users;

-- RLS
GO
CREATE SCHEMA Security
GO  
CREATE FUNCTION Security.fn_securitypredicate
	(@user_ID AS INT) 
RETURNS TABLE  
WITH SCHEMABINDING  
AS  
   RETURN SELECT 1 AS fn_securitypredicate_result
   WHERE @user_ID = USER_ID();
GO
SELECT USER_ID()

--CREATE members_details_ecrypted
GO
CREATE OR ALTER VIEW member_details_encrypted
WITH SCHEMABINDING
AS
SELECT user_ID, 
       IC_passport_number, 
       name, 
       address_no, 
       address_street, 
       address_city, 
       address_state, 
       address_country, 
       phone_number, 
       date_of_birth, 
       gender, 
       status, 
       username, 
       password_hash
FROM dbo.[USER];
GO

-- CREATE A SECURITY POLICY TO APPLY THE PREDICATE FUNCTION TO THE member_details_encrypted VIEW
CREATE SECURITY POLICY MemberDetailsSecurityPolicy
ADD FILTER PREDICATE Security.fn_securitypredicate(user_ID) ON dbo.member_details_encrypted

SELECT * FROM member_details_encrypted

--CREATE member_details_decrypted
GO
CREATE OR ALTER VIEW member_details_decrypted
WITH SCHEMABINDING
AS
SELECT
    user_ID,
    CONVERT(VARCHAR(100), DECRYPTBYKEY(IC_passport_number)) AS IC_passport_number,
    name,
    address_no,
    address_street,
    address_city,
    address_state,
    address_country,
    phone_number,
    date_of_birth,
    gender,
    registration_date,
    status,
    username
FROM
    dbo.[USER]
GO



-- CREATE A SECURITY POLICY TO APPLY THE PREDICATE FUNCTION TO THE member_details_decrypted VIEW
CREATE SECURITY POLICY MemberDetailsDecryptedSecurityPolicy
ADD FILTER PREDICATE Security.fn_securitypredicate(user_ID) ON dbo.member_details_decrypted

SELECT * FROM member_details_decrypted;

--CREATE MEMBER_NON_CONFIDENTIAL_DETAILS VIEW
GO
CREATE OR ALTER VIEW member_non_confidential_details
WITH SCHEMABINDING
AS
SELECT user_ID, name, address_city, address_state, address_country, date_of_birth, gender, status
FROM dbo.[USER];
GO

SELECT * FROM member_non_confidential_details;

--CREATE OR ALTER A VIEW TO SELECT THE DATA THAT RELATED TO EQUIPMENT PRICE
GO
CREATE OR ALTER VIEW equipment_price_report AS
SELECT e.equipment_ID AS 'Equipment ID', 
e.equipment_category_ID AS 'Equipment Category ID', 
ec.equipment_category_name AS 'Equipment Category Name',
e.country_ID AS 'Manufacture Country ID', 
c.country_name AS 'Manufacture Country Name', 
e.equipment_name AS 'Equipment Name', 
e.price_per_unit_before_tax AS 'Price Before Tax', 
e.price_per_unit_after_tax AS 'Price After Tax', 
CASE
    WHEN d.activation_date IS NOT NULL AND GETDATE() BETWEEN d.activation_date AND d.expiry_date THEN
        CONVERT(DECIMAL(7, 2), (e.price_per_unit_after_tax * (1 - d.percentage_off)))
    ELSE
        NULL -- Show NULL for the discount_price if the discount is not active
END AS 'Price After Discount',
CASE
    WHEN d.activation_date IS NOT NULL AND GETDATE() BETWEEN d.activation_date AND d.expiry_date THEN
        CONVERT(INT, (d.percentage_off * 100))
    ELSE
        NULL -- Show NULL for the percentage_off if the discount is not active
END AS 'Discount Percentage (%)',
e.quantity_in_stock AS 'Quantity'
FROM EQUIPMENT e
INNER JOIN EQUIPMENT_CATEGORY ec ON e.equipment_category_ID = ec.equipment_category_ID
INNER JOIN COUNTRY c ON c.country_ID = e.country_ID
LEFT JOIN DISCOUNT d ON d.discount_ID = ec.discount_ID
GO
--SELECT THE VIEW
SELECT * FROM equipment_price_report;

--CREATE OR ALTER A VIEW TO SELECT THE TRANSACTION DETAILS
GO
CREATE OR ALTER VIEW transaction_details 
WITH SCHEMABINDING
AS
SELECT
    t.transaction_id,
    t.user_id,
    t.transaction_date,
    i.equipment_id,
    e.equipment_name,
    i.quantity_purchased,
    i.total_after_discount,
    SUM(i.total_after_discount) OVER (PARTITION BY t.user_id) AS total_price
FROM
    dbo.[TRANSACTION] t
JOIN
    dbo.[ITEM_PURCHASED] i ON t.transaction_id = i.transaction_id
JOIN
    dbo.EQUIPMENT e ON i.equipment_id = e.equipment_id;
GO
--SELECT THE VIEW
SELECT * FROM transaction_details;

--CREATE VIEW
GO
CREATE OR ALTER VIEW refer_details 
WITH SCHEMABINDING
AS
SELECT
    r.refer_ID,
    r.item_purchased_ID,
	i.equipment_ID,
	e.equipment_name,
    r.return_date,
    r.return_reason,
    r.return_approval_status
FROM
    dbo.REFER r
JOIN
    dbo.ITEM_PURCHASED i ON r.item_purchased_ID  = i.item_purchased_ID
JOIN
	dbo.EQUIPMENT e ON i.equipment_id = e.equipment_id;
GO
SELECT * FROM refer_details;

----------------------------------------------------------------------------
--USER PERMISSION (ROLE BASED CONTROL) (MEMBER)--
----------------------------------------------------------------------------

--CREATE SQL LOGIN AND USER
CREATE LOGIN enni WITH PASSWORD = '12345';
CREATE USER enni FOR LOGIN enni;

-- CREATE THE MEMBERS ROLE
CREATE ROLE Member;
-- ADD USER TO MEMBERS ROLE
ALTER ROLE Member ADD MEMBER enni;

--CHECK IF THE ROLE IS INSERTED OR NOT
EXEC sp_helprolemember 'Member'

--PROCEDURE
GO
CREATE OR ALTER PROCEDURE dbo.update_member_details
    @ICPassportNumber VARCHAR(MAX),
    @Name VARCHAR(100),
    @AddressNo VARCHAR(10),
    @AddressStreet VARCHAR(100),
    @AddressCity VARCHAR(50),
    @AddressState VARCHAR(50),
    @AddressCountry VARCHAR(3),
    @PhoneNumber VARCHAR(11),
    @DateOfBirth DATE,
    @Gender CHAR(1),
	@UserName VARCHAR(30),
	@PasswordHash VARCHAR(MAX)
AS
BEGIN
	OPEN SYMMETRIC KEY SimKey1
	   DECRYPTION BY CERTIFICATE Cert1;
	DECLARE @UserID INT = (SELECT user_ID FROM [USER] WHERE username = @UserName);
    IF @UserID IS NOT NULL
    BEGIN
        UPDATE [USER]
        SET IC_passport_number = ENCRYPTBYKEY(KEY_GUID('SimKey1'), CONVERT(VARBINARY(MAX), @ICPassportNumber)),
            name = @Name,
            address_no = @AddressNo,
            address_street = @AddressStreet,
            address_city = @AddressCity,
            address_state = @AddressState,
            address_country = @AddressCountry,
            phone_number = @PhoneNumber,
            date_of_birth = @DateOfBirth,
            gender = @Gender,
			password_hash = HASHBYTES('SHA2_512', CONVERT(VARBINARY(MAX), @PasswordHash))
        WHERE user_ID = @UserID;
    END
	CLOSE SYMMETRIC KEY SimKey1;
END;

GO
CREATE OR ALTER PROCEDURE dbo.insert_transaction_details
    @user_ID INT,
    @transaction_date DATE,
    @equipment_ID INT,
    @quantity_purchased INT
AS
BEGIN
    -- INSERT INTO TRANSACTION TABLE
    DECLARE @transaction_ID INT;
    INSERT INTO [TRANSACTION] (user_ID, transaction_date)
    VALUES (@user_ID, @transaction_date);
    SET @transaction_ID = SCOPE_IDENTITY();

    -- INSERT INTO ITEM_PURCHASED TABLE
    INSERT INTO [ITEM_PURCHASED] (transaction_ID, equipment_ID, quantity_purchased)
    VALUES (@transaction_ID, @equipment_ID, @quantity_purchased);
END;

GO
CREATE OR ALTER PROCEDURE dbo.update_transaction_details
    @transaction_ID INT,
    @user_ID INT,
    @transaction_date DATE,
    @equipment_ID INT,
    @quantity_purchased INT
AS
BEGIN
    -- UPDATE TRANSACTION TABLE
    UPDATE [TRANSACTION]
    SET user_ID = @user_ID, transaction_date = @transaction_date
    WHERE transaction_ID = @transaction_ID;

    -- UPDATE ITEM_PURCHASED TABLE
    UPDATE [ITEM_PURCHASED]
    SET equipment_ID = @equipment_ID, quantity_purchased = @quantity_purchased
    WHERE transaction_ID = @transaction_ID;
END;

GO
CREATE OR ALTER PROCEDURE dbo.delete_transaction_details
    @transaction_ID INT,
    @user_ID INT
AS
BEGIN
    -- CHECK IF THE TRANSACTION BELONGS TO THE USER
    IF NOT EXISTS (SELECT 1 FROM [TRANSACTION] WHERE transaction_ID = @transaction_ID AND user_ID = @user_ID)
    BEGIN
        RAISERROR('The specified transaction does not belong to the user', 16, 1);
        RETURN;
    END;

    DELETE FROM [ITEM_PURCHASED]
    WHERE transaction_ID = @transaction_ID;

END;

-- GRANT UPDATE PERMISSION ON member_details VIEW TO MEMBER ROLE
GRANT SELECT ON [USER] TO Member;
GRANT EXECUTE ON update_member_details TO Member;
GRANT CONTROL ON SYMMETRIC KEY::SimKey1 TO Member;
GRANT CONTROL ON CERTIFICATE::Cert1 TO Member;

-- GRANT SELECT, INSERT, UPDATE, AND DELETE PERMISSIONS ON transaction_details VIEW TO MEMBER ROLE
GRANT SELECT, INSERT, UPDATE, DELETE ON transaction_details TO Member;
GRANT SELECT, INSERT ON [TRANSACTION] TO Member;
GRANT INSERT ON [ITEM_PURCHASED] TO Member;
GRANT EXECUTE ON insert_transaction_details TO Member;
GRANT EXECUTE ON update_transaction_details TO Member;
GRANT EXECUTE ON delete_transaction_details TO Member;

-- GRANT SELECT PERMISSION ON equipment_price_report VIEW TO MEMBER ROLE
GRANT SELECT ON equipment_price_report TO Member;

-- GRANT SELECT PERMISSION ON refer_details VIEW TO MEMBER ROLE
GRANT SELECT ON refer_details TO Member;

--UPDATE member_details
EXECUTE AS USER = 'enni';
SELECT USER_NAME();

DECLARE @user_name1 VARCHAR(30);
SELECT @user_name1 = USER_NAME();
EXECUTE dbo.update_member_details 
    @ICPassportNumber = '0192843948398',
    @Name = 'T',
    @AddressNo = '25',
    @AddressStreet = 'Seventh Street',
    @AddressCity = 'Bukit Jalil',
    @AddressState = 'Kuala Lumpur',
    @AddressCountry = 'MYS',
    @PhoneNumber = '0183233404',
    @DateOfBirth = '2001-11-28',
    @Gender = 'F',
	@UserName = @user_name1,
	@PasswordHash = '12345';
REVERT
SELECT USER_NAME();

--CHECK THE UPDATE VALUES
OPEN SYMMETRIC KEY SimKey1
	DECRYPTION BY CERTIFICATE Cert1;
SELECT *
FROM [USER] WHERE username = 'enni';
CLOSE SYMMETRIC KEY SimKey1;

---------------------------------------------
--SELECT transaction_details
EXECUTE AS USER = 'enni';
SELECT USER_NAME();

SELECT * FROM transaction_details WHERE user_ID = 
(SELECT user_ID FROM [USER] WHERE username = USER_NAME());

---------------------------------------------
--INSERT transaction_details
DECLARE @user_id3 INT;
SELECT @user_id3 = (SELECT user_ID FROM [USER] WHERE username = USER_NAME());
EXECUTE insert_transaction_details 
	@user_ID = @user_id3, 
	@transaction_date = '2023-08-02', 
	@equipment_ID = 300004, 
	@quantity_purchased = 3;

--CHECK THE INSERTED VALUES
SELECT * FROM transaction_details WHERE user_ID = 
(SELECT user_ID FROM [USER] WHERE username = USER_NAME());

---------------------------------------------
--UPDATE transaction_details
DECLARE @user_id4 INT;
SELECT @user_id4 = (SELECT user_ID FROM [USER] WHERE username = USER_NAME());
EXECUTE update_transaction_details 
	@transaction_ID = 400006, 
	@user_ID = @user_id4, 
	@transaction_date = '2023-08-02', 
	@equipment_ID = 300005, 
	@quantity_purchased = 4;

--CHECK THE INSERTED VALUES
SELECT * FROM transaction_details WHERE transaction_ID = 400006;

---------------------------------------------
--DELETE transaction_details
DECLARE @user_id5 INT;
SELECT @user_id5 = (SELECT user_ID FROM [USER] WHERE username = USER_NAME());
EXECUTE delete_transaction_details 
	@transaction_ID = 400006,
	@user_ID = @user_id5;

--CHECK THE DELETED VALUES
SELECT * FROM transaction_details WHERE user_ID = 
(SELECT user_ID FROM [USER] WHERE username = USER_NAME());

---------------------------------------------
--SELECT equipment_price_report
SELECT * FROM equipment_price_report;

---------------------------------------------
--SELECT refer_details

DECLARE @user_name7 VARCHAR(30);
SELECT @user_name7 = USER_NAME();
SELECT * FROM refer_details WHERE item_purchased_ID = 
(SELECT transaction_ID FROM [TRANSACTION] WHERE user_ID = 
(SELECT user_ID FROM [USER] WHERE username = @user_name7));

REVERT
SELECT USER_NAME();

----------------------------------------------------------------------------
--USER PERMISSION (ROLE BASED CONTROL) (STORE CLERK)--
----------------------------------------------------------------------------

--CREATE SQL LOGIN AND USER
CREATE LOGIN siewweijing WITH PASSWORD = 'password1234';
CREATE USER siewweijing FOR LOGIN siewweijing;

-- CREATE THE STORE CLERK ROLE
CREATE ROLE [Store_Clerk];
-- ADD USER TO STORE CLERK ROLE
ALTER ROLE [Store_Clerk] ADD MEMBER siewweijing;

--CHECK IF THE ROLE IS INSERTED OR NOT
EXEC sp_helprolemember 'Store_Clerk'

--GRANT PERMISSION TO ALL TABLE EXCEPT USER (INSERT ONLY), ITEM_PURCHASED (VIEW ONLY) AND TRANSACTION (VIEW ONLY)
GRANT SELECT, INSERT, UPDATE, DELETE ON DATABASE::[APUSportEquipment] TO [Store_Clerk];
DENY SELECT, UPDATE, DELETE ON [USER] TO [Store_Clerk];
DENY INSERT, UPDATE, DELETE ON [TRANSACTION] TO [Store_Clerk];
DENY INSERT, UPDATE, DELETE ON [ITEM_PURCHASED] TO [Store_Clerk];

--GRANT PERMISSION TO STORE CLERK TO VIEW ONLY equipment_price_report
DENY INSERT, UPDATE, DELETE ON equipment_price_report TO [Store_Clerk];

--GRANT PERMISSION TO STORE CLERK TO VIEW ONLY transaction_details
DENY INSERT, UPDATE, DELETE ON transaction_details TO [Store_Clerk];

--GRANT PERMISSION TO STORE CLERK TO VIEW AND UPDATE ONLY member_non_confidential_details
DENY INSERT, DELETE ON member_non_confidential_details TO [Store_Clerk];

--DENY PERMISSION TO STORE CLERK TO NOT VIEW THE member_details
DENY SELECT, INSERT, UPDATE, DELETE ON member_details_encrypted TO [Store_Clerk];

--EXECUTE AS A STORE CLERK
EXECUTE AS USER = 'siewweijing'

--SELECT IF THE PERMISSION IS GRANTED OR DENIED
SELECT * FROM COUNTRY;
SELECT * FROM DISCOUNT;
SELECT * FROM EQUIPMENT;
SELECT * FROM EQUIPMENT_CATEGORY;
SELECT * FROM REFER;
SELECT * FROM [TRANSACTION];
SELECT * FROM ITEM_PURCHASED;
SELECT * FROM equipment_price_report;
SELECT * FROM member_non_confidential_details;
SELECT * FROM transaction_details;
SELECT * FROM [USER];

--INSERT INTO USER TABLE
INSERT INTO [USER] (IC_passport_number, name, address_no, address_street, address_city, address_state, 
phone_number, date_of_birth, gender, username, password_hash) VALUES 
(ENCRYPTBYKEY(KEY_GUID('SimKey1'), '1234567890'), 'John Doe', '123', 'Main Street', 'Bukit Jalil', 
'Kuala Lumpur', '0123456789', '2000-01-01', 'M', 'johndoe', HASHBYTES('SHA2_512', 'password1'));

--UPDATE USER NON-CONFIDENTIAL DETAILS
UPDATE member_non_confidential_details SET gender = 'M' WHERE user_ID = 100007

REVERT;
SELECT USER_NAME();

----------------------------------------------------------------------------
--USER PERMISSION (ROLE BASED CONTROL) (DATABASE ADMINISTRATOR)--
----------------------------------------------------------------------------

--CREATE SQL LOGIN AND USER
CREATE LOGIN yonathan WITH PASSWORD = 'password2234'
CREATE USER yonathan FOR LOGIN yonathan

-- CREATE THE DATABASE ADMINISTRATOR ROLE
CREATE ROLE Database_Administrator;

-- ADD USER TO DATABASE ADMINISTRATOR ROLE
ALTER ROLE Database_Administrator ADD MEMBER yonathan;

--CHECK IF THE ROLE IS INSERTED OR NOT
EXEC sp_helprolemember 'Database_Administrator'

SELECT r.name AS RoleName, u.name AS UserName
FROM sys.database_role_members rm
JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
JOIN sys.database_principals u ON rm.member_principal_id = u.principal_id
WHERE r.name = 'Database_Administrator' AND u.name = 'yonathan';

GRANT CREATE TABLE TO Database_Administrator;
GRANT ALTER, DELETE, EXECUTE, INSERT, SELECT, UPDATE ON SCHEMA::dbo TO yonathan;
EXECUTE AS USER  = 'yonathan'
SELECT USER_NAME()

-- FOR TESTING
-- ADD A NEW TABLE
CREATE TABLE COUNTRYNAME(
	country_ID VARCHAR(3) PRIMARY KEY,
	country_name VARCHAR(100) NOT NULL
);
-- UPDATE THE TABLE
ALTER TABLE COUNTRYNAME
ADD capital_city VARCHAR(100);
-- DELETE THE TABLE
DROP TABLE COUNTRYNAME;

REVERT;
SELECT USER_NAME();

----------------------------------------------------------------------------
--USER PERMISSION (ROLE BASED CONTROL) (MANAGEMENT)--
----------------------------------------------------------------------------

-- USER PERMISSION
-- CREATE SQL LOGIN AND USER
CREATE LOGIN pipin WITH PASSWORD = 'password3234'
CREATE USER pipin FOR LOGIN pipin

-- CREATE THE MEMBERS ROLE
CREATE ROLE Management;

-- ADD USER TO MEMBERS ROLE
ALTER ROLE Management ADD MEMBER pipin;

--CHECK IF THE ROLE IS INSERTED OR NOT
EXEC sp_helprolemember 'Management'

-- Grant SELECT permission to view non confidential member details
GRANT SELECT ON member_non_confidential_details TO Management;

-- Grant SELECT permission on all tables Management role
GRANT SELECT ON SCHEMA::[dbo] TO Management;

EXECUTE AS USER = 'pipin'
SELECT * FROM member_non_confidential_details;

SELECT * FROM COUNTRY;
SELECT * FROM DISCOUNT;
SELECT * FROM EQUIPMENT;
SELECT * FROM EQUIPMENT_CATEGORY;
SELECT * FROM REFER;
SELECT * FROM [TRANSACTION];
SELECT * FROM ITEM_PURCHASED;
SELECT * FROM [USER];

REVERT;
SELECT USER_NAME();

---------------------------------------------------
--SELECT STATEMENTS AND TESTING--
---------------------------------------------------

-- OPEN THE SYMMETRIC KEY
OPEN SYMMETRIC KEY SimKey1
   DECRYPTION BY CERTIFICATE Cert1;

-- SELECT AND DECRYPT DATA FROM THE USER TABLE
SELECT TOP 5
    user_ID,
    CONVERT(VARCHAR(MAX), DECRYPTBYKEY(IC_passport_number)) 
	AS IC_passport_number,
    name,
    address_no,
    address_street,
    address_city,
    address_state,
    address_country,
    phone_number,
    date_of_birth,
    gender,
    registration_date,
    status
FROM [USER];

-- CLOSE THE SYMMETRIC KEY
CLOSE SYMMETRIC KEY SimKey1;

SELECT TOP 5 * FROM [USER];

SELECT TOP(5) * FROM COUNTRY ORDER BY country_name ASC;

SELECT TOP(5) * FROM EQUIPMENT_CATEGORY;

SELECT TOP(5) * FROM EQUIPMENT;

--CHECK STOCK TRIGGER TESTING
INSERT INTO [ITEM_PURCHASED] (transaction_ID,equipment_ID,quantity_purchased)
VALUES (400001, 300000, 4);

SELECT * FROM [ITEM_PURCHASED]
SELECT * FROM equipment_price_report
SELECT * FROM transaction_details

DELETE FROM [ITEM_PURCHASED] WHERE item_purchased_ID = 500009

INSERT INTO [ITEM_PURCHASED] (transaction_ID,equipment_ID,quantity_purchased)
VALUES (400001, 300000, 7);

UPDATE [ITEM_PURCHASED] SET quantity_purchased = 6 WHERE item_purchased_ID = 500001

EXECUTE AS USER = 'enni';
SELECT USER_NAME();
SELECT * FROM member_details_encrypted;
SELECT * FROM member_details_decrypted;
REVERT;
SELECT USER_NAME();

---------------------------------------------------
--QUERY PREPARATION FOR PRESENTATION--
---------------------------------------------------

--AVOID ACCIDENTIAL DELETION IN ROW
GO

USE APUSportEquipment;
GO

CREATE TRIGGER [Trig_Prevent_Delete_Rows]
ON COUNTRY
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR('Deletion of rows has been disabled on this table.', 16,1);
    ROLLBACK;
END

--WHO HAVE ACCESSED THE MEMBER DATA AND PERFORMED WHAT ACTION TO IT
SELECT *
FROM fn_get_audit_file ('C:\APUSportEquipmentAuditing\*.sqlaudit', DEFAULT, DEFAULT)
WHERE statement LIKE '%USER%'