# Full-Extract (ADB)

## Pre-Requisites

- Python 3.5 or later installed
- `pip3` installed
- `adb` installed **and referenced in system PATH**
  - i.e., in any terminal window, ensure `adb --version` gives expected output

## Running it

- Make sure you have an active ADB connection to a device with Egg, Inc. installed
- Run `fullextract.bat` from CMD, or with a double click

---

# Extract-From-APK

## Pre-Requisites

- Python 3.5 or later installed
- `pip3` installed
- **Single merged APK in directory**

## Running it

- Run `apkextract {apkname.apk}` from CMD

# Common Notes

The proto extraction will extract ***all*** protos from the provided/extracted APK, potentially including a lot of garbage that is not necessarily of interest.
The file you'll most likely want will be generated in `protos/ei.proto`

The following will be missing from `protos/ei.proto` post-extraction:

```
enum Platform {
    UNKNOWN_PLATFORM = 0;
    IOS = 1;
    DROID = 2;
}

enum DeviceFormFactor {
    UNKNOWN_DEVICE = 0;
    PHONE = 1;
    TABLET = 2;
}

enum AdNetwork {
    VUNGLE = 0;
    CHARTBOOST = 1;
    AD_COLONY = 2;
    HYPER_MX = 3;
    UNITY = 4;
    FACEBOOK = 5;
    APPLOVIN = 6;
}
```

This will compound into other issues, where references to `Platform`, `DeviceFormFactor`, `AdNetwork`, will have `aux.` appended to them, for example:

```diff
- optional Platform platform = 3;
+ optional aux.Platform platform = 3;
```