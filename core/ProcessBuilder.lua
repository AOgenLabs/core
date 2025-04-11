-- ProcessBuilder.lua
-- Main process for creating and managing automations

local Utils = require("Utils")

-- Initialize state
local State = {
  automationProcesses = {},  -- Store spawned process IDs
  automationConfigs = {},    -- Store configurations for each process
  processCount = 0           -- Counter for created processes
}

-- Log a message with timestamp
local function log(message)
  print(os.date("%Y-%m-%d %H:%M:%S") .. " [ProcessBuilder] " .. message)
end

-- Initialize the ProcessBuilder
local function init()
  log("Initializing ProcessBuilder...")
  
  -- Load existing state if available
  if ao.env and ao.env.Process and ao.env.Process.Data and ao.env.Process.Data.State then
    State = ao.env.Process.Data.State
    log("Loaded existing state with " .. #State.automationProcesses .. " automations")
  else
    log("Starting with fresh state")
    -- Store state in process environment
    if not ao.env then ao.env = {} end
    if not ao.env.Process then ao.env.Process = {} end
    if not ao.env.Process.Data then ao.env.Process.Data = {} end
    ao.env.Process.Data.State = State
  end
  
  return true
end

-- Save the current state
local function saveState()
  if ao.env and ao.env.Process and ao.env.Process.Data then
    ao.env.Process.Data.State = State
    log("State saved")
  end
end

-- Validate automation configuration
local function validateConfig(config)
  if not config then
    return false, "Configuration is nil"
  end
  
  if type(config) ~= "table" then
    return false, "Configuration must be a table"
  end
  
  if not config.When or type(config.When) ~= "string" or config.When == "" then
    return false, "Missing or invalid 'When' field"
  end
  
  if not config.Then or type(config.Then) ~= "string" or config.Then == "" then
    return false, "Missing or invalid 'Then' field"
  end
  
  if not config.Target or type(config.Target) ~= "string" or config.Target == "" then
    return false, "Missing or invalid 'Target' field"
  end
  
  return true
end

-- Create a new automation process
local function createAutomation(config, isAdvanced, sender)
  -- Validate the configuration
  local isValid, errorMsg = validateConfig(config)
  if not isValid then
    log("Invalid configuration: " .. errorMsg)
    Utils.sendError(sender, "Invalid configuration", errorMsg)
    return nil
  end
  
  -- Increment process counter
  State.processCount = State.processCount + 1
  
  -- Choose the template module based on whether this is an advanced automation
  local templateModule = isAdvanced and "AdvancedAutomationTemplate" or "AutomationTemplate"
  
  log("Creating " .. (isAdvanced and "advanced" or "basic") .. " automation process")
  log("Trigger: " .. config.When)
  log("Action: " .. config.Then)
  log("Target: " .. config.Target)
  
  -- Spawn the automation process
  local processId = ao.spawn(templateModule, {
    Config = config,
    Creator = sender,
    ProcessId = State.processCount
  })
  
  -- Handle the process ID (which might be a table or string)
  local automationId
  if type(processId) == "table" then
    automationId = processId.id or "unknown-id-" .. State.processCount
  else
    automationId = processId
  end
  
  -- Store the process information
  table.insert(State.automationProcesses, automationId)
  State.automationConfigs[automationId] = {
    config = config,
    created = os.time(),
    creator = sender,
    isAdvanced = isAdvanced,
    processId = State.processCount
  }
  
  -- Save the updated state
  saveState()
  
  log("Automation process created: " .. automationId)
  return automationId
end

-- Get information about an automation
local function getAutomationInfo(automationId)
  local info = State.automationConfigs[automationId]
  if not info then
    return nil, "Automation not found"
  end
  
  return {
    id = automationId,
    trigger = info.config.When,
    action = info.config.Then,
    target = info.config.Target,
    created = info.created,
    creator = info.creator,
    isAdvanced = info.isAdvanced,
    processId = info.processId
  }
end

-- List all automations
local function listAutomations()
  local automations = {}
  
  for _, automationId in ipairs(State.automationProcesses) do
    local info, _ = getAutomationInfo(automationId)
    if info then
      table.insert(automations, info)
    end
  end
  
  return automations
end

-- Handler for creating a new automation
Handlers.add(
  "CreateAutomation",
  Handlers.utils.hasMatchingTag("Action", "CreateAutomation"),
  function(msg)
    log("Received CreateAutomation request from " .. msg.From)
    
    -- Parse the configuration
    local config, parseError
    
    -- Try to parse as JSON first
    config, parseError = Utils.parseJson(msg.Data)
    
    -- If JSON parsing fails, try as Lua table
    if not config then
      log("JSON parsing failed, trying as Lua table")
      local success, result = pcall(function() 
        return load("return " .. msg.Data)()
      end)
      
      if success then
        config = result
      else
        parseError = "Failed to parse configuration: " .. tostring(result)
      end
    end
    
    if not config then
      log("Configuration parsing failed: " .. parseError)
      Utils.sendError(msg.From, "Failed to parse configuration", parseError)
      return
    end
    
    -- Check if this is an advanced automation
    local isAdvanced = msg.Tags and msg.Tags["Advanced"] == "true"
    
    -- Create the automation
    local automationId = createAutomation(config, isAdvanced, msg.From)
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
      Data = Utils.toJson({
        id = automationId,
        message = "Automation process created successfully",
        trigger = config.When,
        action = config.Then,
        target = config.Target
      })
    })
  end
)

-- Handler for listing all automations
Handlers.add(
  "ListAutomations",
  Handlers.utils.hasMatchingTag("Action", "ListAutomations"),
  function(msg)
    log("Received ListAutomations request from " .. msg.From)
    
    local automations = listAutomations()
    
    Send({
      Target = msg.From,
      Action = "AutomationsList",
      Data = Utils.toJson(automations)
    })
  end
)

-- Handler for getting information about a specific automation
Handlers.add(
  "GetAutomation",
  Handlers.utils.hasMatchingTag("Action", "GetAutomation"),
  function(msg)
    log("Received GetAutomation request from " .. msg.From)
    
    local automationId = msg.Data
    if not automationId or automationId == "" then
      Utils.sendError(msg.From, "Missing automation ID")
      return
    end
    
    local info, errorMsg = getAutomationInfo(automationId)
    if not info then
      Utils.sendError(msg.From, errorMsg or "Failed to get automation info")
      return
    end
    
    Send({
      Target = msg.From,
      Action = "AutomationInfo",
      Data = Utils.toJson(info)
    })
  end
)

-- Handler for deleting an automation
Handlers.add(
  "DeleteAutomation",
  Handlers.utils.hasMatchingTag("Action", "DeleteAutomation"),
  function(msg)
    log("Received DeleteAutomation request from " .. msg.From)
    
    local automationId = msg.Data
    if not automationId or automationId == "" then
      Utils.sendError(msg.From, "Missing automation ID")
      return
    end
    
    -- Find the automation in the list
    local index = nil
    for i, id in ipairs(State.automationProcesses) do
      if id == automationId then
        index = i
        break
      end
    end
    
    if not index then
      Utils.sendError(msg.From, "Automation not found")
      return
    end
    
    -- Remove the automation
    table.remove(State.automationProcesses, index)
    State.automationConfigs[automationId] = nil
    
    -- Save the updated state
    saveState()
    
    log("Automation deleted: " .. automationId)
    
    Send({
      Target = msg.From,
      Action = "AutomationDeleted",
      Data = Utils.toJson({
        id = automationId,
        message = "Automation process deleted successfully"
      })
    })
  end
)

-- Handler for checking the status of the ProcessBuilder
Handlers.add(
  "Status",
  Handlers.utils.hasMatchingTag("Action", "Status"),
  function(msg)
    log("Received Status request from " .. msg.From)
    
    Send({
      Target = msg.From,
      Action = "ProcessBuilderStatus",
      Data = Utils.toJson({
        id = ao.id,
        automationCount = #State.automationProcesses,
        uptime = os.time() - (State.startTime or os.time()),
        status = "active"
      })
    })
  end
)

-- Initialize the ProcessBuilder
if init() then
  State.startTime = os.time()
  log("ProcessBuilder initialized. Ready to create automation processes.")
else
  log("Failed to initialize ProcessBuilder.")
end
