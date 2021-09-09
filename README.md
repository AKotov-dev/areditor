# ArEditor - automatic rule editor for Android devices
51-android.rules: https://github.com/M0Rf30/android-udev-rules

1. In the list of connected USB-Devices (1), find your device that is not recognized when working with ADB and select it with the mouse
2. If the device is not in the list of rules, the necessary line (2) will be offered to insert into the file with the rules
3. Specify the environment variable (`ENV{adb_user}="yes"` by default)
4. Click the button "Plus" (Add & Apply) and reconnect the device
5. Now the device is contained in the list of rules and should be recognized after the `adb` restart  

**Reasons why Android devices may not be displayed:**
1. The USB debugging mode is not enabled on the smartphone
2. The device is not in the list of rules `/etc/udev/rules.d/51-android.rules`
3. The User is not included in the group described in `/etc/udev/rules.d/51-android.rules`
4. The connection is hindered by the old key, which you need to delete and restart `adb`:  
`adb kill-server; rm -rf ~/.android/*; adb start-server`  

`ArEditor` works with the new versions `android-tools`: https://github.com/AKotov-dev/android-tools-rpm

![](https://github.com/AKotov-dev/areditor/blob/main/ScreenShot.png)
