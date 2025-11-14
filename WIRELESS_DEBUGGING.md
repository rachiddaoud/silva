# Wireless Android Debugging Guide

## Prerequisites
- Android phone with Android 11+ (API level 30+) for wireless debugging
- OR Android 5.0+ (API level 21+) for TCP/IP method
- Phone and computer on the same Wi-Fi network
- USB cable (for initial setup with TCP/IP method)

## Method 1: Wireless Debugging (Android 11+ - Recommended)

### Step 1: Enable Developer Options on Your Phone
1. Go to **Settings** → **About phone**
2. Tap **Build number** 7 times until you see "You are now a developer!"

### Step 2: Enable Wireless Debugging
1. Go to **Settings** → **Developer options**
2. Enable **Wireless debugging**
3. Tap on **Wireless debugging** to open settings
4. Tap **Pair device with pairing code**
5. Note the **IP address and port** (e.g., `192.168.1.100:12345`) and the **pairing code**

### Step 3: Connect from Your Computer
Run these commands in your terminal:

```bash
# Pair the device (replace with your IP:port and pairing code)
adb pair <IP_ADDRESS>:<PORT>
# Example: adb pair 192.168.1.100:12345
# Enter the pairing code when prompted

# After pairing, connect to the device
adb connect <IP_ADDRESS>:<PORT>
# The port will be different after pairing (usually shown in the Wireless debugging settings)
```

### Step 4: Verify Connection
```bash
adb devices
# You should see your device listed
```

### Step 5: Run Flutter App
```bash
flutter run
# Or specify the device
flutter run -d <device-id>
```

## Method 2: TCP/IP Debugging (Android 5.0+)

### Step 1: Initial USB Connection
1. Connect your phone via USB
2. Enable **USB debugging** in Developer options
3. Verify connection:
   ```bash
   adb devices
   ```

### Step 2: Find Your Phone's IP Address
On your phone:
- **Settings** → **About phone** → **Status** → **IP address**
- OR **Settings** → **Wi-Fi** → Tap your network → View IP address

### Step 3: Connect via TCP/IP
```bash
# Connect via TCP/IP (replace with your phone's IP)
adb tcpip 5555
adb connect <PHONE_IP_ADDRESS>:5555
# Example: adb connect 192.168.1.100:5555
```

### Step 4: Disconnect USB and Verify
```bash
# Unplug USB cable
adb devices
# Device should still be listed
```

### Step 5: Run Flutter App
```bash
flutter run
```

## Troubleshooting

### Device Not Found
- Ensure phone and computer are on the same Wi-Fi network
- Check firewall settings on your computer
- Try disconnecting and reconnecting

### Connection Drops
- Keep the phone screen on during development
- Reconnect using: `adb connect <IP>:<PORT>`

### Port Already in Use
```bash
# Kill existing ADB server
adb kill-server
# Restart ADB
adb start-server
```

### Find Your Phone's IP Address (Command Line)
```bash
# On macOS/Linux, you can also find devices on your network:
arp -a | grep -i android
```

## Quick Commands Reference

```bash
# List connected devices
adb devices

# Connect wirelessly
adb connect <IP>:<PORT>

# Disconnect wireless device
adb disconnect <IP>:<PORT>

# Reset ADB
adb kill-server && adb start-server

# Run Flutter app
flutter run

# Run on specific device
flutter devices  # List available devices
flutter run -d <device-id>
```

## Notes
- Wireless debugging requires Android 11+ (API 30+)
- TCP/IP method works on Android 5.0+ but requires initial USB connection
- Connection may drop if phone goes to sleep - keep screen on or adjust sleep settings
- Some corporate/guest Wi-Fi networks may block ADB connections

