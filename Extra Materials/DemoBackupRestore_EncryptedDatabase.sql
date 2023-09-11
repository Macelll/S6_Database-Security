
--Same Server Create Another Copy 
RESTORE DATABASE DB1_Encrypted 
FROM DISK = 'C:\Temp\DB1_NotEncrypted.bak'
WITH MOVE 'DB1_NotEncrypted' TO 'C:\Temp\DB1_Encrypted.mdf',
MOVE 'DB1_NotEncrypted_Log' TO 'C:\Temp\DB1_Encrypted_Log.ldf'

ALTER DATABASE DB1_Encrypted MODIFY FILE ( NAME = DB1_NotEncrypted, NEWNAME = DB1_Encrypted);
ALTER DATABASE DB1_Encrypted MODIFY FILE ( NAME = DB1_NotEncrypted_Log, NEWNAME = DB1_Encrypted_Log);


--Perform Encryption

---Step 1 - Create Master Key
--For TDE 
use master
go
create master key encryption by password = 'QwErTy12345!@#$%'
go
select * from sys.symmetric_keys
go

-- Step 2 - Create Certificate
Use master
go
Create Certificate CertMasterDB 
With Subject = 'CertmasterDB'
go
select * from sys.certificates

--Step 3
--Enabling TDE for Database

Use DB1_Encrypted
go

CREATE DATABASE ENCRYPTION KEY  
   WITH ALGORITHM = AES_128
   ENCRYPTION BY SERVER CERTIFICATE CertMasterDB;
go

ALTER DATABASE DB1_Encrypted
SET ENCRYPTION ON;

Use master
select b.name as [DB Name], a.encryption_state_desc, a.key_algorithm, a.encryptor_type
from sys.dm_database_encryption_keys a
inner join sys.databases b on a.database_id = b.database_id
where b.name = 'DB1_Encrypted'

--Back This DB

BACKUP DATABASE DB1_Encrypted 
TO DISK = 'C:\Temp3\DB1_Encrypted.bak'

Use master
Go
BACKUP CERTIFICATE CertMasterDB 
TO FILE = N'C:\Temp3\CertMasterDB.cert'
WITH PRIVATE KEY (
    FILE = N'C:\Temp3\CertMasterDB.key', 
ENCRYPTION BY PASSWORD = 'QwErTy12345!@#$%'
);
Go



--Another Server/Instance

USE MASTER
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'MyBackUpPassword$$12345'

USE MASTER
GO
Create CERTIFICATE CertMasterDB 
From FILE = N'C:\Temp2\CertMasterDB.cert'
WITH PRIVATE KEY (
    FILE = N'C:\Temp2\CertMasterDB.key', 
DECRYPTION BY PASSWORD = 'QwErTy12345!@#$%'
);


RESTORE DATABASE DB1_Encrypted 
FROM DISK = 'C:\Temp2\DB1_Encrypted.bak'
WITH MOVE 'DB1_Encrypted' TO 'C:\Temp2\DB1_Encrypted.mdf',
MOVE 'DB1_Encrypted_Log' TO 'C:\Temp2\DB1_Encrypted_Log.ldf'