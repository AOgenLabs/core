# AO Process Builder Core

This directory contains the core AO Lua modules and templates for the AO Process Builder.

## Directory Structure

-   **bots/** - Bot implementations (EmailBot, etc.)
-   **core/** - Core modules (ProcessBuilder, Utils, etc.)
-   **deploy/** - Deployment scripts
-   **tests/** - Test scripts

## Detailed Deployment Guide

### Prerequisites

1. Make sure you have the AO platform installed on your system
2. Ensure you have the `aos` command available in your terminal
3. Make sure you have a stable internet connection

### Method 1: Using the Deployment Script

The easiest way to deploy the AO Process Builder is using the provided deployment script:

```bash
# Navigate to the deploy directory
cd deploy

# Make the deployment script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```

The deployment script will:

1. Start the AOS platform if it's not already running
2. Load all necessary modules in the correct order
3. Output the Process IDs for each component
4. Save these Process IDs to a configuration file for later use

### Method 2: Manual Deployment (Step by Step)

If you prefer to deploy manually or need more control over the process, follow these steps:

#### Step 1: Start the AOS Platform

```bash
# Start AOS in a terminal window
aos
```

This will start the AOS platform and provide you with an interactive terminal.

#### Step 2: Deploy the Utils Module

```bash
# In the AOS terminal, load the Utils module
.load core/Utils.lua
```

After loading, you should see output similar to:

```
Loaded module: Utils
Process ID: <utils-process-id>
```

Make note of the Process ID as you'll need it later.

#### Step 3: Deploy the ProcessBuilder

```bash
# Load the ProcessBuilder module
.load core/ProcessBuilder.lua
```

After loading, you should see output similar to:

```
Loaded module: ProcessBuilder
Process ID: <process-builder-id>
```

Make note of the ProcessBuilder ID as you'll need it for the backend integration.

#### Step 4: Deploy the EmailBot

```bash
# Load the EmailBot module
.load bots/EmailBot.lua
```

After loading, you should see output similar to:

```
Loaded module: EmailBot
Process ID: <email-bot-id>
```

Make note of the EmailBot ID as you'll need it for the backend integration.

#### Step 5: Verify Deployment

To verify that all components are deployed correctly, you can check the process list:

```bash
# In the AOS terminal
.processes
```

You should see all the processes you've deployed listed with their IDs.

#### Step 6: Test the Deployment

To ensure everything is working correctly, run a simple test:

```bash
# Load the simple test script
.load tests/SimpleTest.lua
```

You should see output indicating that the test has run successfully and the components are communicating with each other.

### Advanced Deployment Options

#### Deploying with Custom Templates

If you want to use custom automation templates:

```bash
# Load the basic automation template
.load core/AutomationTemplate.lua

# Load the advanced template with conditions
.load core/AdvancedTemplate.lua
```

#### Monitoring Deployed Processes

To monitor the messages being sent to and from your processes:

```bash
# View the inbox of a specific process
.inbox <process-id>

# View a specific message
.view <message-number>

# Send a test message to a process
Send({
  Target = "<process-id>",
  Action = "<action-name>",
  Data = "<your-data>"
})
```

## Testing

### Basic Testing

To run the basic tests, use the test scripts in the `tests/` directory:

```bash
# Start AOS if not already running
aos

# Load the simple test script
.load tests/SimpleTest.lua
```

### Advanced Testing

For more comprehensive testing, you can use the ProcessBuilderTest script:

```bash
# Load the ProcessBuilder test script
.load ProcessBuilderTest.lua
```

This script will:

1. Register handlers for various actions
2. Send test messages to itself
3. Process those messages and send responses
4. Output detailed logs of the entire process

### Troubleshooting

If you encounter issues during deployment or testing:

1. Check that the AOS platform is running correctly
2. Verify that all process IDs are valid
3. Check the AOS logs for any error messages
4. Try restarting the AOS platform and redeploying
5. Ensure you're loading the modules in the correct order (Utils → ProcessBuilder → Bots)

### Production Deployment Notes

When deploying to production:

1. Always use the stable versions of the modules
2. Make sure to securely store the process IDs
3. Set up monitoring for the AOS platform
4. Consider using a process manager to keep AOS running
5. Regularly backup your process state
