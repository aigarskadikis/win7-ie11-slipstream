@echo off
cls
setlocal EnableDelayedExpansion
set path=%path%;%~dp0

for /f "tokens=*" %%d in ('time /t') do echo Slipstream started at: %%d
echo.

set v=Win7x86ultimate
echo Label for DVD will be: %v%
echo.

set u=%~dp0u7x86
echo Looking for updates in directory:
echo %u%
echo.

set s=%~dp0X17-59463.iso
echo Name for source ISO file:
echo %s%
echo.

set w=%temp%
echo Working directory is:
echo %w%
echo.

set d=%userprofile%\Desktop
echo Destination output for new ISO is:
echo %d%
echo.

for /f "tokens=*" %%d in ('"%~dp0date.exe" +%%Y-%%m-%%d') do set yyyymmdd=%%d

set l=%d%\%v%-%yyyymmdd%.iso.log
if exist "%l%" del "%l%" /Q /F
echo Existing errors will be writed on:
echo %l%
echo.

for /f "tokens=*" %%d in ('dir /b "%u%" ^| sed -n "$="') do echo Total number of updates to slipstream: %%d
echo.

set i=5
echo Updates will be slipstreamed into install.wim index(es): %i%
echo.

echo Extracting iso..
if exist "%w%\iso" rd "%w%\iso" /Q /S
7z x "%s%" -o"%w%\iso" > nul 2>&1

cd "C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\amd64\DISM"
if not exist "%w%\mount" md "%w%\mount"
for %%a in (%i%) do (
echo mounting install.wim index %%a..
dism /mount-wim /wimfile:"%w%\iso\sources\install.wim" /index:%%a /mountdir:"%w%\mount" > nul 2>&1
for /f "tokens=*" %%i in ('dir /b "%u%" ^| sed "s/^.*(KB//g;s/).*$//g" ^| gnusort -n') do (
for /f "tokens=*" %%d in ('dir /b "%u%" ^| grep "%%i"') do (
echo slipstreaming KB%%i
for /f "tokens=*" %%z in ('dir /b "%u%\%%d\*.msu" "%u%\%%d\*.cab"') do (
dism /image:"%w%\mount" /add-package /packagepath:"%u%\%%d\%%z" | grep "The operation completed successfully" > nul 2>&1
if not !errorlevel!==0 (
echo %%z not OK
echo %%z not OK >> "%l%"
)
)
)
)
dism /unmount-wim /mountdir:"%w%\mount" /commit
)
if exist "%w%\mount" rd "%w%\mount" /Q /S
echo.
"C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" -b"%w%\iso\boot\etfsboot.com" -h -u2 -m -l%v% "%w%\iso" "%d%\%v%-%yyyymmdd%.iso"
if exist "%w%\iso" rd "%w%\iso" /Q /S
endlocal
echo.
echo This is it!
time /t
pause
