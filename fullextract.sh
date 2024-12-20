#!/bin/bash

echo "Creating and wiping input_apks directory"
rm -rf input_apks
mkdir input_apks
echo

echo "Extracting APKs through ADB"
# Get paths, print part after package: and trim whitespace
APK=$(adb shell pm path com.auxbrain.egginc | grep "^package.*arm" | head -1 | cut -d: -f2-  | sed -e 's/^[[:space:]]//' -e 's/[[:space:]]$//')
adb pull $APK input_apks
echo

# Generate timestamp for unique protos folder
timestamp=$(date +"%Y-%m-%d_%H%M%S")
protos_folder="protos_$timestamp"

echo "Creating unique $protos_folder directory..."
mkdir "$protos_folder"
echo

echo "Installing dependencies from PIP..."
# some systems (like mine) will complain about trying to pip install outside of a venv so just make one
python3 -m venv .venv
./.venv/bin/pip install protobuf pyqt5 pyqtwebengine requests websocket-client
echo 

echo "Generating protos..."
python3 -W ignore ./pbtk/extractors/jar_extract.py ./input_apks/*.apk "$protos_folder"
echo

echo "Proto files generated in $protos_folder..."

echo "Cleaning up generated protos..."
python3 -W ignore ./proto_cleanup.py
echo
