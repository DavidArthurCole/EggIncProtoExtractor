#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Error: Please provide the APK filename as a parameter"
  exit 1
fi

if [ ! -f $1 ]; then
  echo "Error: The specified APK file \"$1\" does not exist."
  exit 1
fi

echo "Creating and wiping /protos/ directory..."
rm -rf protos
mkdir protos
echo

echo "Installing dependencies from PIP..."
python3 -m venv .venv
./.venv/bin/pip install protobuf pyqt5 pyqtwebengine requests websocket-client

echo "Generating protos..."
python3 -W ignore ./pbtk/extractors/jar_extract.py "$1" protos
echo

echo "Proto files generated..."

echo "Cleaning up generated protos..."
python3 -W ignore ./proto_cleanup.py
echo