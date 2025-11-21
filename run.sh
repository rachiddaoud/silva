#!/usr/bin/env bash

# Flutter Device Helper Script
# Usage: ./flutter_devices.sh <device_name>
# Example: ./flutter_devices.sh pixel

# Function to get device ID by name
get_device_id() {
  case "$1" in
    "pixel" | "rachid")
      echo "3A240DLJH000X6"
      ;;
    "sim")
      echo "B49CA4C3-9C83-49E2-BAF8-36DBC11E12E6"
      ;;
    "yasmine"|"iphone-yasmine")
      echo "00008140-000848C222D1801C"
      ;;
    "macos")
      echo "macos"
      ;;
    "chrome"|"web")
      echo "chrome"
      ;;
    *)
      echo ""
      ;;
  esac
}

# Function to list all devices
list_devices() {
  echo "Available device shortcuts:"
  echo "  pixel          → Pixel 8 (Android)"
  echo "  iphone         → iPhone 17 Pro (Simulator)"
  echo "  iphone-pro     → iPhone 17 Pro (Simulator)"
  echo "  yasmine        → iPhone de Yasmine (Physical)"
  echo "  iphone-yasmine → iPhone de Yasmine (Physical)"
  echo "  macos          → macOS Desktop"
  echo "  chrome         → Chrome Web"
  echo "  web            → Chrome Web"
  echo ""
  echo "Current connected devices:"
  flutter devices
}

# Function to run on a specific device
run_device() {
  local device_name=$1
  local device_id=$(get_device_id "$device_name")
  
  if [ -z "$device_id" ]; then
    echo "Error: Unknown device '$device_name'"
    echo ""
    list_devices
    exit 1
  fi
  
  echo "Running on device: $device_name ($device_id)"
  flutter run -d "$device_id" "${@:2}"
}

# Main script logic
if [ $# -eq 0 ]; then
  list_devices
elif [ "$1" == "list" ] || [ "$1" == "-l" ] || [ "$1" == "--list" ]; then
  list_devices
else
  run_device "$@"
fi
