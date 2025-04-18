#!/bin/bash
# Deployment script for AO Process Builder

# Set up colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting AO Process Builder deployment...${NC}"

# Source NVM to ensure Node.js is available
source ~/.nvm/nvm.sh
nvm use 22.14.0

# Check if aos is installed
if ! command -v aos &> /dev/null; then
    echo -e "${RED}Error: aos command not found. Please install AOS first.${NC}"
    exit 1
fi

# Start AOS
echo -e "${YELLOW}Starting AOS...${NC}"
aos &
AOS_PID=$!

# Wait for AOS to start
echo -e "${YELLOW}Waiting for AOS to initialize...${NC}"
sleep 5

# Deploy Utils module
echo -e "${YELLOW}Deploying Utils module...${NC}"
echo ".load core/core/Utils.lua" | aos

# Deploy AutomationTemplate module
echo -e "${YELLOW}Deploying AutomationTemplate module...${NC}"
echo ".load core/core/AutomationTemplate.lua" | aos

# Deploy AdvancedTemplate module
echo -e "${YELLOW}Deploying AdvancedTemplate module...${NC}"
echo ".load core/core/AdvancedTemplate.lua" | aos

# Deploy ProcessBuilder
echo -e "${YELLOW}Deploying ProcessBuilder...${NC}"
echo ".load core/core/ProcessBuilder.lua" | aos

# Deploy EmailBot
echo -e "${YELLOW}Deploying EmailBot...${NC}"
echo ".load core/bots/EmailBot.lua" | aos

# Run a simple test
echo -e "${YELLOW}Running simple test...${NC}"
echo ".load core/tests/SimpleTest.lua" | aos

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo "Use the process IDs displayed above to interact with the system."

# Keep AOS running
wait $AOS_PID
