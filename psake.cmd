@echo off

SET DIR=%~dp0%

if '%1'=='/?' goto usage
if '%1'=='-?' goto usage
if '%1'=='?' goto usage
if '%1'=='/help' goto usage
if '%1'=='help' goto usage

powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%DIR%psake.ps1' %*; if ($psake.build_success -eq $false) { exit 1 } else { exit 0 }"

goto :eof
:usage
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%DIR%psake-help.ps1'"
