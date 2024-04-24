# Full-Extract (ADB)

## Pre-Requisites

- Python 3.5 or later installed
- `pip3` installed
- `adb` installed **and referenced in system PATH**
  - i.e., in any terminal window, ensure `adb --version` gives expected output

## Running it

- Make sure you have an active ADB connection to a device with Egg, Inc. installed
- Run `fullextract` from CMD, or with a double click

---

# Extract-From-APK

## Pre-Requisites

- Python 3.5 or later installed
- `pip3` installed
- **Single `arm*` APK in directory** (ex: `split_config.arm64_v8a.apk`)

## Running it

- Run `apkextract {apkname.apk}` from CMD