
CREATE DATABASE DB1_NotEncrypted;
Go

Use DB1_NotEncrypted
Go

CREATE TABLE Table1(id int primary key identity, name varchar(200))
INSERT INTO Table1 Values ('Kulo'),('Nathan')

CREATE USER User1 WITHOUT LOGIN 

GRANT CONTROL ON Table1 TO User1

Execute As User = 'User1'
Select * From Table1
Revert

BACKUP DATABASE DB1_NotEncrypted 
TO DISK = 'C:\Temp\DB1_NotEncrypted.bak'

Go

DROP DATABASE DB1_NotEncrypted 
Go

--Same Server/Instance
RESTORE DATABASE DB1_NotEncrypted 
FROM DISK = 'C:\Temp\DB1_NotEncrypted.bak'

--Another Server/Instance
RESTORE DATABASE DB1_NotEncrypted 
FROM DISK = 'C:\Temp\DB1_NotEncrypted.bak'
WITH MOVE 'DB1_NotEncrypted' TO 'C:\Temp2\DB1_NotEncrypted.mdf',
MOVE 'DB1_NotEncrypted_Log' TO 'C:\Temp2\DB1_NotEncrypted_Log.ldf'