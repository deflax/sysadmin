@ECHO ON
SETLOCAL

del c:\sqlbackup\*.bak

REM Get date in format YYYY-MM-DD (assumes the locale is the United States)
FOR /F "tokens=1,2,3,4 delims=/ " %%A IN ('Date /T') DO SET NowDate=%%D-%%B-%%C

REM Build a list of databases to backup
SET DBList=%SystemDrive%SQLDBList.txt
SqlCmd -E -S DBHOSTNAME -h-1 -W -Q "SET NoCount ON; SELECT Name FROM master.dbo.sysDatabases WHERE [Name] NOT IN ('master','model','msdb','tempdb')" > "%DBList%"

REM Backup each database, prepending the date to the filename
FOR /F "tokens=*" %%I IN (%DBList%) DO (
ECHO Backing up database: %%I
SqlCmd -E -S DBHOSTNAME -Q "BACKUP DATABASE [%%I] TO Disk='C:\sqlbackup\%NowDate%_%%I.bak'"
ECHO.
)

#pause

REM Clean up the temp file
IF EXIST "%DBList%" DEL /F /Q "%DBList%"

ENDLOCAL
