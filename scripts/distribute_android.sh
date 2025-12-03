#!/bin/bash
# Build and distribute Android app via Firebase App Distribution

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔨 Building Android APK...${NC}"

# Build the app
flutter build apk --release

echo -e "${GREEN}✅ Build completed!${NC}"
echo ""
echo -e "${BLUE}📦 APK location: build/app/outputs/flutter-apk/app-release.apk${NC}"
echo ""

# Your Firebase Android App ID (from google-services.json)
FIREBASE_APP_ID="1:174370766580:android:88ca971d45e3d0f932a8a1"

# Get release notes from user
echo -e "${BLUE}📝 Enter release notes (press Enter when done):${NC}"
read RELEASE_NOTES

# Default release notes if empty
if [ -z "$RELEASE_NOTES" ]; then
    RELEASE_NOTES="Test build - $(date '+%Y-%m-%d %H:%M')"
fi

echo ""
echo -e "${BLUE}🚀 Distributing to Firebase App Distribution...${NC}"

# Distribute to testers using the "internal" group
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app "$FIREBASE_APP_ID" \
  --release-notes "$RELEASE_NOTES" \
  --groups "internal"

# You can add more groups separated by commas
# --groups "internal,beta"

echo ""
echo -e "${GREEN}✅ Android build distributed successfully!${NC}"
echo -e "${BLUE}📧 Testers will receive an email notification${NC}"
