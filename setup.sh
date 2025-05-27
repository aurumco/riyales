#!/bin/bash

# Riyales Flutter App Setup Script for Ubuntu

# ANSI Color Codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Riyales Flutter App setup...${NC}"

# 0. Update package list
echo -e "${BLUE}Updating package list...${NC}"
sudo apt-get update

# 1. Install prerequisites
echo -e "${BLUE}Installing prerequisites (git, curl, unzip, xz-utils, libglu1-mesa)...${NC}"
sudo apt-get install -y git curl unzip xz-utils libglu1-mesa
if [ $? -ne 0 ]; then
    echo -e "${RED}Error installing prerequisites. Please check your internet connection and permissions.${NC}"
    exit 1
fi
echo -e "${GREEN}Prerequisites installed successfully.${NC}"

# 2. Install Flutter SDK
FLUTTER_SDK_PATH="$HOME/flutter"
if [ -d "$FLUTTER_SDK_PATH" ]; then
    echo -e "${YELLOW}Flutter SDK already found at $FLUTTER_SDK_PATH. Skipping download. Will update instead.${NC}"
    cd "$FLUTTER_SDK_PATH"
    git pull
    flutter upgrade
else
    echo -e "${BLUE}Cloning Flutter SDK (stable channel) to $FLUTTER_SDK_PATH...${NC}"
    git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_SDK_PATH"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error cloning Flutter SDK. Please check your internet connection and git setup.${NC}"
        exit 1
    fi
fi

# 3. Add Flutter to PATH (for current session and bashrc)
echo -e "${BLUE}Adding Flutter to PATH...${NC}"
export PATH="$PATH:$FLUTTER_SDK_PATH/bin"

if ! grep -q "$FLUTTER_SDK_PATH/bin" ~/.bashrc; then
    echo '' >> ~/.bashrc
    echo '# Add Flutter SDK to PATH' >> ~/.bashrc
    echo "export PATH=\"\$PATH:$FLUTTER_SDK_PATH/bin\"" >> ~/.bashrc
    echo -e "${GREEN}Flutter SDK path added to ~/.bashrc. Please source it or open a new terminal.${NC}"
else
    echo -e "${YELLOW}Flutter SDK path already in ~/.bashrc.${NC}"
fi

# 4. Run Flutter Doctor to verify installation
echo -e "${BLUE}Running flutter doctor...${NC}"
flutter doctor
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Flutter doctor reported some issues. Please review the output above and resolve them.${NC}"
    # Exiting with 0 as flutter doctor itself might have issues but flutter is installed.
else
    echo -e "${GREEN}Flutter doctor check completed successfully.${NC}"
fi

# 5. Run flutter pub get in the project directory
# Assuming this script is in the root of the Flutter project or one level above 'riyales_app'
PROJECT_DIR=$(pwd)
if [ -f "$PROJECT_DIR/pubspec.yaml" ]; then
    echo -e "${BLUE}Running flutter pub get in $PROJECT_DIR...${NC}"
    flutter pub get
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error running flutter pub get. Please check your pubspec.yaml and internet connection.${NC}"
        exit 1
    fi
    echo -e "${GREEN}flutter pub get completed successfully.${NC}"
else
    echo -e "${YELLOW}pubspec.yaml not found in the current directory. Skipping 'flutter pub get'. Make sure to run it in your project directory.${NC}"
fi


# 6. Verify Flutter version
echo -e "${BLUE}Verifying Flutter version...${NC}"
flutter --version
if [ $? -ne 0 ]; then
    echo -e "${RED}Error verifying Flutter version.${NC}"
    exit 1
fi
echo -e "${GREEN}Flutter version verified.${NC}"

echo -e "${GREEN}Riyales Flutter App setup script finished.${NC}"
echo -e "${YELLOW}Please run 'source ~/.bashrc' or open a new terminal for PATH changes to take effect.${NC}"
echo -e "${BLUE}To create a new project (if not done): flutter create riyales_app${NC}"
echo -e "${BLUE}Then navigate to the project directory and run this script again, or manually run 'flutter pub get'.${NC}"

exit 0