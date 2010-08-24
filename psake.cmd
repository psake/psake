@echo off
powershell -NoProfile -ExecutionPolicy unrestricted -Command "& '%~dp0\psake.ps1' %*"
