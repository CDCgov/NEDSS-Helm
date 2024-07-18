-- This function needs to be created in master since the Sql Server agent is not exposed
-- We need to override this function in the helm chart distributed properties
USE MASTER

CREATE OR ALTER FUNCTION dbo.IsSqlAgentRunning() RETURNS BIT AS
BEGIN
    DECLARE @IsRunning BIT = 0;

    IF (EXISTS(SELECT dss.*
               FROM sys.dm_server_services dss
               WHERE dss.[servicename] LIKE N'SQL Server Agent (%'
                 AND dss.[status] = 4 -- Running
    ))
        BEGIN
            SET @IsRunning = 1;
        END;

    RETURN @IsRunning;
END;

GRANT VIEW SERVER STATE TO nbs_ods;