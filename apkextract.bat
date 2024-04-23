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

rem Create or clear /protos/ directory
echo [42mCreating and wiping /protos/ directory...[0m
rd /s /q protos 2>nul
mkdir protos
echo.

rem Install pip dependencies
echo [42mInstalling dependencies from PIP...[0m
pip3 install protobuf pyqt5 pyqtwebengine requests websocket-client

rem Extract .proto definitions from specified APK
echo [42mGenerating protos, this will take a WHILE...[0m
python ./pbtk/extractors/jar_extract.py "%~1" ./protos/ > nul 2>&1
echo.

rem Finished
echo [42mProto files generated...[0m

rem Pause to keep the terminal window open
pause

endlocal