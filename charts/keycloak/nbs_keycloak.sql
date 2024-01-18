
use master
  IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'keycloak')
  BEGIN
    CREATE DATABASE keycloak
 END
GO
  USE keycloak
GO

BEGIN
CREATE LOGIN NBS_keycloak WITH PASSWORD = 'EXAMPLE_KCDB_PASS8675309';
CREATE USER NBS_keycloak FOR LOGIN NBS_keycloak;
EXEC sp_addrolemember N'db_owner', N'NBS_keycloak'
END
