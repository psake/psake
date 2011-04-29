@echo on

:: Assumes robocopy and nuget.exe both on the path

SET DIR=%~dp0%
SET DESTDIR=%DIR%bin

IF EXIST %DESTDIR% goto deletebin

goto prepare

:deletebin
rmdir /s /q %DESTDIR%
if %ERRORLEVEL% NEQ 0 goto errors

:prepare
robocopy %DIR% %DESTDIR%\tools /E /B /NP /R:0 /W:0 /NJH /NJS /NS /NFL /NDL /XF ".git*" "Nuget*" "*.nupkg"  /XD "%DIR%nuget" "%DIR%.git" "%DIR%bin"
robocopy %DIR%nuget %DESTDIR% /E /B /NP /R:0 /W:0 /NJH /NJS /NS /NFL /NDL

:build
nuget pack %DESTDIR%\psake.nuspec
if %ERRORLEVEL% NEQ 0 goto errors

goto :eof

:errors
EXIT /B %ERRORLEVEL%