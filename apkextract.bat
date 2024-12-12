@echo off
setlocal

rem Check if APK file parameter is provided
if "%~1"=="" (
	echo [41mError: Please provide the APK filename as a parameter.[0m
    exit /b 1
)

rem Check if the specified APK file exists
if not exist "%~1" (
	echo [41mError: The specified APK file "%~1" does not exist.[0m
    exit /b 1
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

rem Extract .proto definitions from specified APK
echo [42mGenerating protos, this will take a WHILE...[0m
python -W ignore ./pbtk/extractors/jar_extract.py "%~1" %protos_folder%
echo.

rem Cleanup proto file with protocleanup.py
echo [42mCleaning up proto files...[0m
python -W ignore ./protocleanup.py %protos_folder%
echo.

rem Finished
echo [42mProto files generated...[0m

rem Pause to keep the terminal window open
pause

endlocal