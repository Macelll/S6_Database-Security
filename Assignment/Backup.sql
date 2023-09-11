--BACKUP USING TDE--
CREATE CERTIFICATE TDE_Certificate WITH SUBJECT = 'TDE Certificate';
GO

BACKUP CERTIFICATE TDE_Certificate TO FILE = 'E:\BackupDatabase\TDE_Certificate_Backup.cer';
GO

USE DBS_Assignment;
GO

+
GO

ALTER DATABASE DBS_Assignment SET ENCRYPTION ON;
GO
--DONE BACKUP USING TDE--


-- Backup the source database with encryption
USE master;
GO

BACKUP DATABASE DBS_Assignment
TO DISK = 'E:\BackupDatabase\EncryptedBackup.bak'
WITH COMPRESSION, ENCRYPTION
(
    ALGORITHM = AES_256,
    SERVER CERTIFICATE = Cert1  -- Use the same certificate used for TDE, if applicable
);
GO

--DONE Backup the source database with encryption--





-- Restore the database on the target SQL Server instance
USE master;
GO

-- Restore the certificate from the backup file (copied from the source)
CREATE CERTIFICATE TDE_Certificate
FROM FILE = 'E:\BackupDatabase\TDE_Certificate_Backup.cer';
GO


RESTORE FILELISTONLY
FROM DISK = 'E:\BackupDatabase\EncryptedBackup.bak';
GO

-- Restore the database with encryption
RESTORE DATABASE DBS_Assignment
FROM DISK = 'E:\BackupDatabase\EncryptedBackup.bak'
WITH MOVE 'DBS_Assignment' TO 'E:\BackupDatabase\DBS_Assignment.mdf',
     MOVE 'DBS_Assignment_log' TO 'E:\BackupDatabase\DBS_Assignment_log.ldf',
     REPLACE, NORECOVERY, STATS = 5;
GO

SELECT name, state_desc
FROM sys.databases
WHERE name = 'DBS_Assignment';

-- Final restore with recovery to bring the database online
RESTORE DATABASE DBS_Assignment WITH RECOVERY;
GO