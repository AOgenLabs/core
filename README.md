# AO Process Builder Core

This directory contains the core AO Lua modules and templates for the AO Process Builder.

## Directory Structure

- **bots/** - Bot implementations (EmailBot, etc.)
- **core/** - Core modules (ProcessBuilder, Utils, etc.)
- **deploy/** - Deployment scripts
- **tests/** - Test scripts

## Deployment

To deploy the AO Process Builder, use the deployment scripts in the `deploy/` directory:

```bash
# Navigate to the deploy directory
cd deploy

# Make the deployment script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```

Or you can deploy the components manually:

```bash
# Start AOS
aos

# Load the Utils module
.load core/Utils.lua

# Load the ProcessBuilder
.load core/ProcessBuilder.lua

# Load the EmailBot
.load bots/EmailBot.lua

# Run a simple test
.load tests/SimpleTest.lua
```

## Testing

To run the tests, use the test scripts in the `tests/` directory:

```bash
# Start AOS
aos

# Load the test script
.load tests/SimpleTest.lua
```
