@echo off
setlocal enabledelayedexpansion

for /f %%a in ('echo prompt $E^| cmd /q') do set "ESC=%%a"

rem Smart APK pull with hash check
echo !ESC![42mChecking APKs via ADB...!ESC![0m
python -W ignore ./apkpull.py
if errorlevel 1 (
    echo !ESC![41mError: APK pull failed. Exiting...!ESC![0m
    goto :end
)
echo.

rem Read pull status file
set "pull_status="
set "arm_apk="
for /f "usebackq tokens=* delims=" %%l in ("input_apks\.pull_status") do (
    if not defined pull_status (
        set "pull_status=%%l"
    ) else if not defined arm_apk (
        set "arm_apk=%%l"
    )
)

if not defined arm_apk (
    echo !ESC![41mError: No arm APK found. Exiting...!ESC![0m
    goto :end
)

rem Find latest existing protos folder (before creating new one)
set "old_protos="
for /f "delims=" %%f in ('dir /b /ad /o-d "protos_*" 2^>nul') do (
    if not defined old_protos set "old_protos=%%f"
)

rem If APKs unchanged and protos already exist, skip extraction
if "!pull_status!"=="UNCHANGED" (
    if defined old_protos (
        if not "%FORCE%"=="1" (
            echo !ESC![42mAPKs unchanged. Existing protos: !old_protos!!ESC![0m
            echo Run with FORCE=1 to re-extract anyway.
            goto :end
        )
    )
)

if "!pull_status!"=="CHANGED" (
    if defined old_protos (
        echo !ESC![42mAPKs changed. Will diff against: !old_protos!!ESC![0m
    ) else (
        echo !ESC![42mAPKs changed. No previous protos found for diff.!ESC![0m
    )
)
echo.

rem Generate timestamp for unique protos folder
for /f "tokens=2 delims==." %%A in ('wmic os get localdatetime /value') do set timestamp=%%A
set protos_folder=protos_!timestamp:~0,4!-!timestamp:~4,2!-!timestamp:~6,2!_!timestamp:~8,2!-!timestamp:~10,2!-!timestamp:~12,2!

rem Create protos folder
echo !ESC![42mCreating unique /!protos_folder!/ directory...!ESC![0m
mkdir "!protos_folder!"
echo.

rem Install pip dependencies
echo !ESC![42mInstalling dependencies from PIP...!ESC![0m
pip3 install protobuf pyqt5 pyqtwebengine requests websocket-client
echo.

rem Extract .proto definitions from identified APK
echo !ESC![42mGenerating protos, this will take a WHILE...!ESC![0m
python -W ignore ./pbtk/extractors/jar_extract.py "!arm_apk!" "!protos_folder!"
echo.

rem Cleanup proto file with protocleanup.py
echo !ESC![42mCleaning up proto files...!ESC![0m
python -W ignore ./protocleanup.py "!protos_folder!"
echo.

rem Generate diff if old protos exist
if defined old_protos (
    if exist "!old_protos!\ei.proto" (
        if exist "!protos_folder!\ei.proto" (
            echo !ESC![42mGenerating proto diff...!ESC![0m
            set "diff_file=diff_!timestamp:~0,4!-!timestamp:~4,2!-!timestamp:~6,2!_!timestamp:~8,2!-!timestamp:~10,2!-!timestamp:~12,2!.diff"
            python -W ignore ./protodiff.py "!old_protos!\ei.proto" "!protos_folder!\ei.proto" "!diff_file!"
            echo.
        )
    )
)

rem Finished
echo !ESC![42mProto files generated in !protos_folder!...!ESC![0m
echo.

rem Shutdown ADB when done (opt-in: set KILL_ADB=1 to enable)
if "%KILL_ADB%"=="1" (
    echo !ESC![42mKilling ADB...!ESC![0m
    adb kill-server
)

:end
pause

endlocal
