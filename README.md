# Cordova Plugin Update NRF (DFU)

This plugin allows you to use the Nordic DFU service on your BLE devices to update the firmware. See the [Nordic documentation](https://www.nordicsemi.com/DocLib/Content/SDK_Doc/nRF5_SDK/v12-2-0/lib_bootloader_dfu) for more details.

## Supported platforms

- iOS
- Android

Additionally, the device to update must follow the rules as defined in the DFU documentation.

- Supported SDKs: 
  - iOS: [v4.4.1](https://github.com/NordicSemiconductor/IOS-Pods-DFU-Library/tree/4.4.1) (Uses Swift)
  - Android: [v1.9.0](https://github.com/NordicSemiconductor/Android-DFU-Library/tree/v1.9.0)

## Requirements

- Cordova: at least version 9
- Android: Cordova-android of at least 8.0.0

## Installation

To install the plugin, run:
```
cordova plugin add https://github.com/quintenadema/cordova-plugin-update-nrf
```

## API

The API is available as a global `updateNrf` object

### Start update

```
updateNrf.dfu(deviceIdentifier, fileURL, resultCallback, errorCallback);
```

Params:

-   `deviceIdentifier`: A string that contains the identifier for the Bluetooth LE device to update. It will either be a MAC address (on Android) or a UUID (on iOS).
-   `fileURL`: A string that is the path to the file to use in the update. It can be either in either `cdvfile://` or `file://` format. It _must_ be a Zip file and end with `.zip` (iOS library requirement, Android doesn't have this issue)
-   `resultCallback`: A function that takes a single argument object. 
-   `errorCallback`: A function that takes a single argument.