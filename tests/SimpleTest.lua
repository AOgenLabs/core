-- SimpleTest.lua
-- A simple test script for the AO Process Builder

print("Starting AO Process Builder test...")

-- Store process IDs
local processBuilderID = nil
local emailBotID = nil

-- Step 1: Load the EmailBot
print("\n----- Step 1: Loading EmailBot -----")
-- In a real deployment, you would load the EmailBot in a separate process
-- For this test, we'll simulate it in the same process
Handlers.add(
  "Notify User",
  Handlers.utils.hasMatchingTag("Action", "Notify User"),
  function(msg)
    print("\n=== EmailBot Notification ===")
    print("User would be notified")
    print("From automation process: " .. (msg.Tags and msg.Tags.AutomationProcess or "unknown"))
    print("Original sender: " .. (msg.Tags and msg.Tags.OriginalSender or "unknown"))
    print("Content: " .. (msg.Data or "No content"))
    print("===========================\n")
    
    -- Acknowledge receipt
    Send({
      Target = msg.From,
      Action = "UserNotified",
      Data = "User successfully notified"
    })
  end
)

print("EmailBot handler registered")
emailBotID = ao.id
print("EmailBot ID: " .. emailBotID)

-- Step 2: Load the ProcessBuilder
print("\n----- Step 2: Loading ProcessBuilder -----")
-- In a real deployment, you would load the ProcessBuilder in a separate process
-- For this test, we'll simulate it in the same process

-- Store automations
local Automations = {}

-- Function to create a new automation
function CreateAutomation(config)
  -- Validate configuration
  if not config.When or not config.Then or not config.Target then
    print("Invalid configuration: Missing required fields")
    return nil
  end
  
  -- Create a unique ID for this automation
  local automationId = "auto-" .. os.time() .. "-" .. #Automations
  
  -- Store the automation
  Automations[automationId] = config
  print("Created automation: " .. automationId)
  print("  Trigger: " .. config.When)
  print("  Action: " .. config.Then)
  print("  Target: " .. config.Target)
  
  -- Create a handler for this specific automation
  Handlers.add(
    "Automation-" .. automationId,
    function(msg)
      -- Check if this message is for this automation
      return msg.Target == automationId and msg.Action == config.When
    end,
    function(msg)
      print("\n=== Automation Triggered ===")
      print("Automation: " .. automationId)
      print("Received trigger: " .. config.When)
      print("Data: " .. (msg.Data or "none"))
      print("==========================\n")
      
      -- Forward to the target with the configured action
      Send({
        Target = config.Target,
        Action = config.Then,
        Data = msg.Data,
        Tags = {
          AutomationProcess = automationId,
          OriginalSender = msg.From,
          OriginalAction = config.When
        }
      })
      
      print("Action forwarded to: " .. config.Target)
    end
  )
  
  return automationId
end

-- Handler for CreateAutomation
Handlers.add(
  "CreateAutomation",
  Handlers.utils.hasMatchingTag("Action", "CreateAutomation"),
  function(msg)
    print("Received automation configuration request")
    
    -- Parse the configuration
    local success, config = pcall(function() return load("return " .. msg.Data)() end)
    if not success then
      print("Failed to parse configuration: " .. tostring(config))
      return
    end
    
    -- Create the automation
    local automationId = CreateAutomation(config)
    if not automationId then
      return
    end
    
    -- Send a confirmation message back to the user
    Send({
      Target = msg.From,
      Action = "AutomationCreated",
      Tags = {
        ProcessId = automationId,
        Trigger = config.When,
        TargetAction = config.Then
      },
      Data = "Automation process created successfully"
    })
  end
)

-- Handler for ListAutomations
Handlers.add(
  "ListAutomations",
  Handlers.utils.hasMatchingTag("Action", "ListAutomations"),
  function(msg)
    print("Listing all automations")
    
    local automationsList = {}
    for id, config in pairs(Automations) do
      table.insert(automationsList, {
        id = id,
        trigger = config.When,
        action = config.Then,
        target = config.Target
      })
    end
    
    Send({
      Target = msg.From,
      Action = "AutomationsList",
      Data = "Found " .. #automationsList .. " automations"
    })
  end
)

print("ProcessBuilder handlers registered")
processBuilderID = ao.id
print("ProcessBuilder ID: " .. processBuilderID)

-- Step 3: Create a test automation
print("\n----- Step 3: Creating a test automation -----")
local automationConfig = {
  When = "File Uploaded",
  Then = "Notify User",
  Target = emailBotID
}

print("Creating automation with configuration:")
print("  When: " .. automationConfig.When)
print("  Then: " .. automationConfig.Then)
print("  Target: " .. automationConfig.Target)

local automationId = CreateAutomation(automationConfig)
print("Test automation created with ID: " .. automationId)

-- Step 4: Trigger the automation
print("\n----- Step 4: Triggering the automation -----")
print("Sending 'File Uploaded' event to automation: " .. automationId)

Send({
  Target = automationId,
  Action = "File Uploaded",
  Data = "important_document.pdf"
})

print("\n----- Test completed -----")
print("The automation should have been triggered and sent a notification to the EmailBot.")
print("Check the console output for the results.")
