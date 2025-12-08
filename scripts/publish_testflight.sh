#!/bin/bash
# Build and prepare iOS app for TestFlight/App Store

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting TestFlight Preparation Protocol...${NC}"

# Check for version in pubspec.yaml
echo -e "${BLUE}🔍 Checking version...${NC}"
grep "version:" pubspec.yaml
echo -e "${YELLOW}⚠️  Make sure you have incremented the version in pubspec.yaml before proceeding!${NC}"
echo -e "${YELLOW}   Current version shown above. Press Ctrl+C to stop if you need to edit it.${NC}"
echo -e "   Sleeping for 3 seconds..."
sleep 3

echo -e "${BLUE}🔨 Building iOS Archive...${NC}"
echo "This may take a few minutes."

# Build the IPA (this also creates the .xcarchive we need)
flutter build ipa --release

echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo ""

# The archive is located in build/ios/archive/Runner.xcarchive
ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"

if [ -d "$ARCHIVE_PATH" ]; then
    echo -e "${BLUE}📦 Archive found at: $ARCHIVE_PATH${NC}"
    echo -e "${BLUE}📲 Opening Xcode Organizer...${NC}"
    
    # Open the archive in Xcode - this usually opens the Organizer directly
    open "$ARCHIVE_PATH"
    
    echo ""
    echo -e "${GREEN}🎉 ready for upload!${NC}"
    echo "1. In the Xcode Organizer window that just opened, select your new archive."
    echo "2. Click 'Distribute App'."
    echo "3. Select 'TestFlight & App Store', then 'Distribute'."
    echo "4. Follow the prompts to validate and upload."
else
    echo -e "${RED}❌ Could not find the archive at $ARCHIVE_PATH${NC}"
    echo "Please check the build output for errors."
fi
