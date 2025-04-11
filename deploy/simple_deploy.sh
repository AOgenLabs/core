#!/bin/bash
# Simple deployment script for AO Process Builder

echo "Starting AO Process Builder deployment..."

# Start AOS in the background
aos &
AOS_PID=$!

# Wait for AOS to start
echo "Waiting for AOS to initialize..."
sleep 5

# Deploy Utils module
echo "Deploying Utils module..."
echo ".load backend/core/Utils.lua" | aos

# Deploy AutomationTemplate module
echo "Deploying AutomationTemplate module..."
echo ".load backend/core/AutomationTemplate.lua" | aos

# Deploy ProcessBuilder
echo "Deploying ProcessBuilder..."
echo ".load backend/core/ProcessBuilder.lua" | aos

# Deploy EmailBot
echo "Deploying EmailBot..."
echo ".load backend/bots/EmailBot.lua" | aos

# Run a simple test
echo "Running simple test..."
echo ".load backend/tests/SimpleTest.lua" | aos

echo "Deployment completed!"
echo "Use the process IDs displayed above to interact with the system."

# Kill AOS
kill $AOS_PID
