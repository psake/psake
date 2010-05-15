@echo off
powershell -NoProfile -ExecutionPolicy unrestricted -Command "& {Import-Module %~dp0\psake.psm1; invoke-psake %*; remove-module psake }"
