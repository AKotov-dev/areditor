# ArEditor - 51-android.rules editor for Android devices
1. In the list of connected USB-Devices (1), find your device that is not recognized when working with ADB and select it with the mouse
2. If the device is not in the list of rules, the necessary line (2) will be offered to insert into the file with the rules; copy it to the clipboard
3. Paste the contents of the buffer into the field (3) with the contents /usr/lib/udev/rules.d/51-android.rules between any rules by analogy
4. Click the button "Apply". Now the device is contained in the list of rules and should be recognized after the `adb` restart

**Reasons why Android devices may not be displayed:**
1. The USB debugging mode is not enabled on the smartphone
2. The device is not in the list of rules /usr/lib/udev/rules.d/51-android.rules
3. The User is not included in the group described in /usr/lib/udev/rules.d/51-android.rules 
4. The connection is hindered by the old key, which you need to delete and restart ADB:  
`adb kill-server; rm -rf ~/.android/*; adb start-server`

![](https://github.com/AKotov-dev/areditor/blob/main/ScreenShot.png)
