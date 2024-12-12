@echo off
setlocal enabledelayedexpansion

rem Create or clear /input_apks/ directory
echo [42mCreating and wiping /input_apks/ directory...[0m
rd /s /q input_apks 2>nul
mkdir input_apks
echo.

rem Get the paths using adb shell pm path command
echo [42mExtracting APKs through ADB...[0m
for /f "tokens=1,*" %%a in ('adb shell pm path com.auxbrain.egginc') do (
    rem Check if the line starts with "package:" to filter out paths
    set "line=%%a"
    if "!line:~0,8!"=="package:" (
        rem Extract the path part by removing "package:" prefix
        set "package_path=!line:~8!"
        
        rem Trim leading and trailing spaces (if any)
        for /f "tokens=*" %%i in ("!package_path!") do set "trimmed_path=%%i"
        
        rem Run adb pull on the extracted path
        adb pull "!trimmed_path!" input_apks
    )
)

rem Identify the APK with 'arm64' in the filename
echo [42mIdentifying APK with 'arm' architecture...[0m
set "target_apk="
for %%f in (input_apks\*.apk) do (
    set "filename=%%~nxf"
    if "!filename:arm=!" neq "!filename!" (
        set "target_apk=%%f"
        echo Found APK with 'arm' architecture: %%f
    )
)

if not defined target_apk (
    echo [41mError: No APK with 'arm' architecture found. Exiting...[0m
    goto :end
)

rem Generate timestamp for unique protos folder
for /f "tokens=2 delims==." %%A in ('wmic os get localdatetime /value') do set timestamp=%%A
set protos_folder=protos_!timestamp:~0,4!-!timestamp:~4,2!-!timestamp:~6,2!_!timestamp:~8,2!-!timestamp:~10,2!-!timestamp:~12,2!

rem Create a new protos folder
echo [42mCreating unique /%protos_folder%/ directory...[0m
mkdir "%protos_folder%"
echo.

rem Install pip dependencies
echo [42mInstalling dependencies from PIP...[0m
pip3 install protobuf pyqt5 pyqtwebengine requests websocket-client

rem Extract .proto definitions from identified APK
echo [42mGenerating protos, this will take a WHILE...[0m
python -W ignore ./pbtk/extractors/jar_extract.py "!target_apk!" "%protos_folder%"
echo.

rem Cleanup proto file with protocleanup.py
echo [42mCleaning up proto files...[0m
python -W ignore ./protocleanup.py "%protos_folder%"
echo.

rem Finished
echo [42mProto files generated in %protos_folder%, killing ADB...[0m
echo.

rem Shutdown ADB when done
adb kill-server

rem Kill /inputs_apks/ directory
echo [42mKilling /input_apks/ directory...[0m
echo.
rd /s /q input_apks 2>nul

rem Killing APKs in base directory
echo [42mKilling APKs in base directory...[0m
echo.
del /q *.apk 2>nul

:end
rem Pause to keep the terminal window open
pause

endlocal
