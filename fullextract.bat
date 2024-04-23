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

rem Merge extracted APKs into a single package
echo [42mCombining extracted APKs...[0m
java -jar APKEditor.jar m -i input_apks -o merged.apk

rem Create or clear /protos/ directory
echo [42mCreating and wiping /protos/ directory...[0m
rd /s /q protos 2>nul
mkdir protos
echo.

rem Install pip dependencies
echo [42mInstalling dependencies from PIP...[0m
pip3 install protobuf pyqt5 pyqtwebengine requests websocket-client

rem Extract .proto definitions from merged APK
echo [42mGenerating protos, this will take a WHILE...[0m
python ./pbtk/extractors/jar_extract.py ./merged.apk ./protos/ > nul 2>&1
echo.

rem Finished
echo [42mProto files generated, killing ADB...[0m

rem Shutdown ADB when done
adb kill-server

rem Pause to keep the terminal window open
pause

endlocal