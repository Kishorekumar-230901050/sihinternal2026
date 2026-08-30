#!/bin/bash
# install.sh - Quick installation script for Luckfox Tamper Logging Library

set -e  # Exit on error

echo "🚀 Installing Tamper Logging Library with Real-time Alerts"
echo "=========================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on Luckfox
if [[ ! -f /etc/os-release ]] || ! grep -q "luckfox" /etc/os-release 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Warning: This script is designed for Luckfox devices${NC}"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 1: Install dependencies
echo -e "\n${GREEN}Step 1: Installing dependencies...${NC}"
sudo apt-get update
sudo apt-get install -y libcurl4-openssl-dev libssl-dev libsqlite3-dev build-essential

# Step 2: Create database directory
echo -e "\n${GREEN}Step 2: Creating database directory...${NC}"
mkdir -p /home/pico/calibris/data
echo "✅ Created: /home/pico/calibris/data"

# Step 3: Compile library
echo -e "\n${GREEN}Step 3: Compiling library...${NC}"
make clean
make

# Step 4: Test compilation
echo -e "\n${GREEN}Step 4: Testing library...${NC}"
if [[ -f ./test_tamper ]]; then
    echo "✅ Test program compiled successfully"
else
    echo -e "${RED}❌ Failed to compile test program${NC}"
    exit 1
fi

# Step 5: Configuration check
echo -e "\n${GREEN}Step 5: Configuration check...${NC}"
echo "Current configuration in tamper_logs_realtime.h:"
grep "API_ENDPOINT" tamper_logs_realtime.h || echo "  (not found)"
grep "DEVICE_ID" tamper_logs_realtime.h || echo "  (not found)"

echo -e "\n${YELLOW}⚠️  IMPORTANT: Update API_ENDPOINT in tamper_logs_realtime.h with your ngrok URL${NC}"
echo "Example: #define API_ENDPOINT \"https://your-ngrok-url.ngrok-free.dev/api/devices/1/tamper\""

# Step 6: Summary
echo -e "\n${GREEN}✅ Installation complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Update API_ENDPOINT in tamper_logs_realtime.h with your ngrok URL"
echo "2. Recompile: make"
echo "3. Test: ./test_tamper"
echo "4. Check dashboard for real-time alerts"
echo ""
echo "Files created:"
echo "  - libtamper_realtime.a (static library)"
echo "  - tamper_logs_realtime.o (object file)"
echo "  - test_tamper (test program)"
echo ""
echo "Usage in your code:"
echo "  gcc your_app.c tamper_logs_realtime.o -o your_app -lcurl -lssl -lcrypto -lsqlite3 -lpthread"
echo ""
echo "📚 See README.md for full documentation"
