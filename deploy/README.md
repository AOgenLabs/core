# AO Process Builder Deployment Guide

This guide explains how to deploy the AO Process Builder to the AO platform.

## Prerequisites

- AOS installed on your system
- Basic understanding of AO and Lua

## Deployment Options

### Option 1: Using the Deployment Script

The easiest way to deploy the AO Process Builder is to use the provided deployment script:

```bash
# Make the script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```

This script will:
1. Start AOS
2. Deploy the Utils module
3. Deploy the AutomationTemplate module
4. Deploy the AdvancedTemplate module
5. Deploy the ProcessBuilder
6. Deploy the EmailBot
7. Run a simple test

### Option 2: Manual Deployment

If you prefer to deploy manually, follow these steps:

1. Start AOS:
   ```bash
   aos
   ```

2. In the AOS console, load the modules and processes in the following order:

   ```
   # Load the Utils module
   .load backend/core/Utils.lua

   # Load the AutomationTemplate module
   .load backend/core/AutomationTemplate.lua

   # Load the AdvancedTemplate module
   .load backend/core/AdvancedTemplate.lua

   # Load the ProcessBuilder
   .load backend/core/ProcessBuilder.lua

   # Load the EmailBot
   .load backend/bots/EmailBot.lua
   ```

3. Save the process IDs displayed in the console. You'll need these to interact with the system.

## Testing the Deployment

To test if the deployment was successful, you can run the simple test script:

```
.load backend/tests/SimpleTest.lua
```

This will create a test automation and trigger it to verify that everything is working correctly.

## Interacting with the System

Once deployed, you can interact with the system using the following commands:

### Creating an Automation

```lua
Send({
  Target = "PROCESS_BUILDER_ID",
  Action = "CreateAutomation",
  Data = [[
    {
      "When": "File Uploaded",
      "Then": "Notify User",
      "Target": "EMAIL_BOT_ID"
    }
  ]]
})
```

Replace `PROCESS_BUILDER_ID` and `EMAIL_BOT_ID` with the actual process IDs from the deployment.

### Listing Automations

```lua
Send({
  Target = "PROCESS_BUILDER_ID",
  Action = "ListAutomations"
})
```

### Triggering an Automation

```lua
Send({
  Target = "AUTOMATION_ID",
  Action = "File Uploaded",
  Data = "important_document.pdf"
})
```

Replace `AUTOMATION_ID` with the ID of the automation you want to trigger.

## Troubleshooting

If you encounter any issues during deployment:

1. Check that AOS is running correctly
2. Verify that all modules and processes were loaded in the correct order
3. Check the console output for any error messages
4. Try running the simple test script to diagnose issues

For more detailed troubleshooting, refer to the developer documentation.
