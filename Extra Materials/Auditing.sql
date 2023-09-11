USE master ;  
GO  

--ALTER SERVER AUDIT AllTables_DML  WITH (STATE = OFF) ;
--Go
--DROP SERVER AUDIT AllTables_DML 
--Go

CREATE SERVER AUDIT AllTables_DML  TO FILE ( FILEPATH = 'C:\Temp' );   
GO  
-- Enable the server audit.   
ALTER SERVER AUDIT AllTables_DML  WITH (STATE = ON) ;
Go

Use DBSLab
Go

CREATE DATABASE AUDIT SPECIFICATION AllTables_DML_Specifications
FOR SERVER AUDIT AllTables_DML
ADD ( INSERT , UPDATE, DELETE, SELECT
ON DATABASE::DBSLab BY public)   
WITH (STATE = ON) ;   
GO

--ALTER DATABASE AUDIT SPECIFICATION AllTables_DML_Specifications WITH (STATE = OFF)
--DROP DATABASE AUDIT SPECIFICATION AllTables_DML_Specifications

--to read back the audit data
DECLARE @AuditFilePath VARCHAR(8000);

Select @AuditFilePath = audit_file_path
From sys.dm_server_audit_status
where name = 'AllTables_DML'

select action_id, event_time, database_name, database_principal_name, object_name, statement
from sys.fn_get_audit_file(@AuditFilePath,default,default)
Where database_name = 'DBSLab'

--Test
Execute as User='C0001'
Select * From Customer
Update Customer Set PhoneNumber ='0123456976' 
Revert

Go

DECLARE @AuditFilePath VARCHAR(8000);

Select @AuditFilePath = audit_file_path
From sys.dm_server_audit_status
where name = 'AllTables_DML'

select top 10 action_id, event_time, database_name, database_principal_name, object_name, statement
from sys.fn_get_audit_file(@AuditFilePath,default,default)
Where database_name = 'DBSLab' --and database_principal_name != 'dbo'
order by event_time desc
