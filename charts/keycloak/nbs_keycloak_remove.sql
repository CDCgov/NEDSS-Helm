# backup before delete

# check for open connections
SELECT 
    DB_NAME(dbid) as DBName,
    spid,
    loginame as LoginName,
    program_name,
    status
FROM
    sys.sysprocesses
WHERE 
    DB_NAME(dbid) = 'keycloak' AND spid != @@SPID

# delete - may fail in use
USE [master];
drop database keycloak;

# force disconnect and delete
USE [master];
GO
ALTER DATABASE [keycloak] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO  
DROP DATABASE [keycloak]
