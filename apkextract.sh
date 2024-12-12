#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Error: Please provide the APK filename as a parameter"
  exit 1
fi

if [ ! -f $1 ]; then
  echo "Error: The specified APK file \"$1\" does not exist."
  exit 1
fi

# Generate timestamp for unique protos folder
timestamp=$(date +"%Y-%m-%d_%H%M%S")
protos_folder="protos_$timestamp"

echo "Creating unique $protos_folder directory..."
mkdir "$protos_folder"

echo "Installing dependencies from PIP..."
python3 -m venv .venv
./.venv/bin/pip install protobuf pyqt5 pyqtwebengine requests websocket-client

echo "Generating protos..."
python3 -W ignore ./pbtk/extractors/jar_extract.py "$1" "$protos_folder"
echo

echo "Proto files generated..."

echo "Cleaning up generated $protos_folder..."
python3 -W ignore ./protocleanup.py
echo