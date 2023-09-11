
--Column based encryption
--Step 1--
--use DBSLab
use Test1

go
create master key encryption by password = 'QwErTy12345!@#$%'
go
select * from sys.symmetric_keys
go

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

--Step 3 - Optional if you want to use symmetric key to encrypt your data
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
