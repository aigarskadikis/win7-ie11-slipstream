@echo off
cls
setlocal EnableDelayedExpansion
set path=%path%;%~dp0

for /f "tokens=*" %%d in ('time /t') do echo Slipstream started at: %%d
echo.

set v=Win7x64
echo Label for DVD will be: %v%
echo.

set u=%~dp0u7x64pro
echo Looking for updates in directory:
echo %u%
echo.

set i=%~dp0X17-59186.iso
echo Name for ISO file:
echo %i%
echo.

set r=%~dp0w7pro
echo Additional files (like autounattend.xml) will be overwrited from:
echo %r%
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

set m=3
echo Updates will be slipstreamed into install.wim index(es): %m%
echo.

echo Extracting iso..
if exist "%w%\iso" rd "%w%\iso" /Q /S
7z x "%i%" -o"%w%\iso" > nul 2>&1

cd "C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\amd64\DISM"
if not exist "%w%\mount" md "%w%\mount"
for %%a in (%m%) do (
echo mounting install.wim index %%a..
dism /mount-wim /wimfile:"%w%\iso\sources\install.wim" /index:%%a /mountdir:"%w%\mount" > nul 2>&1
echo integrating .NET 2.0, 3.0 and 3.5..
dism /image:"%w%\mount" /enable-feature /featurename:NetFx3 /all /limitaccess /source:"%w%\iso\sources\sxs" > nul 2>&1
rem echo integrating drivers..
rem dism /image:"%w%\mount" /add-driver /driver:"%~dp0d81x64" /recurse
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
echo Adding autounattend.xml or something..
xcopy "%r%" "%w%\iso" /Y /S /F /Q
"C:\Program Files (x86)\Windows Kits\8.1\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe" -b"%w%\iso\boot\etfsboot.com" -h -u2 -m -l%v% "%w%\iso" "%d%\%v%-%yyyymmdd%.iso"
if exist "%w%\iso" rd "%w%\iso" /Q /S
endlocal
echo.
echo This is it!
time /t
