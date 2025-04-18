-- AutomationTemplate.lua
-- Template module for automation processes spawned by ProcessBuilder

-- Get the Utils module from the global environment
local Utils = {}

-- Import Utils functions if available
if _G.Utils then
  for k, v in pairs(_G.Utils) do
    Utils[k] = v
  end
end

-- Initialize state
local State = {
  config = nil,      -- Automation configuration
  creator = nil,     -- Creator of this automation
  processId = nil,   -- Process ID assigned by ProcessBuilder
  startTime = nil,   -- Time when this automation started
  triggerCount = 0,  -- Number of times the trigger has been activated
  lastTriggered = nil -- Last time the trigger was activated
}

-- Log a message with timestamp
local function log(message)
  print(os.date("%Y-%m-%d %H:%M:%S") .. " [Automation-" .. (State.processId or "?") .. "] " .. message)
end

-- Initialize and read configuration from process environment
local function init()
  log("Initializing automation process...")

  -- Check if we're in a spawned process with configuration
  if ao.env and ao.env.Process and ao.env.Process.Data then
    State.config = ao.env.Process.Data.Config
    State.creator = ao.env.Process.Data.Creator
    State.processId = ao.env.Process.Data.ProcessId
  end

  -- Validate configuration
  if not State.config then
    log("Error: No configuration found")
    return false
  end

  if not State.config.When or not State.config.Then or not State.config.Target then
    log("Error: Invalid configuration - missing required fields")
    return false
  end

  State.startTime = os.time()

  log("Automation process initialized")
  log("Trigger: " .. State.config.When)
  log("Action: " .. State.config.Then)
  log("Target: " .. State.config.Target)

  return true
end

-- Set up the main handler for the trigger event
local function setupTriggerHandler()
  local triggerEvent = State.config.When

  -- Add a handler that matches the trigger event
  Handlers.add(
    "TriggerAction",
    function(msg)
      -- Check if the incoming message's Action tag matches our trigger
      return msg.Tags and msg.Tags["Action"] == triggerEvent
    end,
    function(msg)
      log("Trigger event detected: " .. triggerEvent)

      -- Update trigger statistics
      State.triggerCount = State.triggerCount + 1
      State.lastTriggered = os.time()

      -- Forward the message to the target with the configured action
      Send({
        Target = State.config.Target,
        Action = State.config.Then,
        Tags = {
          OriginalSender = msg.From,
          OriginalAction = msg.Tags and msg.Tags["Action"] or "unknown",
          AutomationProcess = ao.id,
          TriggerCount = tostring(State.triggerCount)
        },
        Data = msg.Data  -- Propagate the original data
      })

      log("Action forwarded: " .. State.config.Then .. " to " .. State.config.Target)
    end
  )

  log("Trigger handler registered for event: " .. triggerEvent)
}

-- Set up a handler for checking the status of this automation
Handlers.add(
  "Status",
  Handlers.utils.hasMatchingTag("Action", "Status"),
  function(msg)
    log("Status request received from " .. msg.From)

    Send({
      Target = msg.From,
      Action = "AutomationStatus",
      Tags = {
        ProcessId = ao.id,
        Trigger = State.config and State.config.When or "unknown",
        TargetAction = State.config and State.config.Then or "unknown",
        Target = State.config and State.config.Target or "unknown"
      },
      Data = Utils.toJson({
        id = ao.id,
        processId = State.processId,
        trigger = State.config and State.config.When,
        action = State.config and State.config.Then,
        target = State.config and State.config.Target,
        creator = State.creator,
        startTime = State.startTime,
        uptime = os.time() - (State.startTime or os.time()),
        triggerCount = State.triggerCount,
        lastTriggered = State.lastTriggered,
        status = "active"
      })
    })
  end
)

-- Initialize the process
if init() then
  setupTriggerHandler()
  log("Automation process setup completed. Waiting for trigger events.")
else
  log("Failed to initialize automation process.")
end
