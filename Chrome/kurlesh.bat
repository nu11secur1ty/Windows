@echo off
:by @nu11secur1ty
reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome /v ChromeCleanupEnabled
reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome /v ChromeCleanupReportingEnabled