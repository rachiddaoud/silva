#!/bin/bash
# Build and distribute iOS app via Firebase App Distribution

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔨 Building iOS IPA...${NC}"

# Build the app
flutter build ipa --release

echo -e "${GREEN}✅ Build completed!${NC}"
echo ""
echo -e "${BLUE}📦 IPA location: build/ios/ipa/silva.ipa${NC}"
echo ""

# Your iOS Firebase App ID (from GoogleService-Info.plist - GOOGLE_APP_ID)
FIREBASE_APP_ID="1:174370766580:ios:6eead10cbb626bd532a8a1"

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
firebase appdistribution:distribute build/ios/ipa/silva.ipa \
  --app "$FIREBASE_APP_ID" \
  --release-notes "$RELEASE_NOTES" \
  --groups "internal"

# You can add more groups separated by commas
# --groups "internal,beta"

echo ""
echo -e "${GREEN}✅ iOS build distributed successfully!${NC}"
echo -e "${BLUE}📧 Testers will receive an email notification${NC}"
