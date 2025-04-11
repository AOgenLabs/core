-- AdvancedTemplate.lua
-- Template module for advanced automation processes with conditions and multi-step workflows

local Utils = require("Utils")

-- Initialize state
local State = {
  config = nil,        -- Automation configuration
  creator = nil,       -- Creator of this automation
  processId = nil,     -- Process ID assigned by ProcessBuilder
  startTime = nil,     -- Time when this automation started
  triggerCount = 0,    -- Number of times the trigger has been activated
  lastTriggered = nil, -- Last time the trigger was activated
  workflowSteps = {},  -- Steps in the workflow
  currentStep = 1      -- Current step in the workflow
}

-- Log a message with timestamp
local function log(message)
  print(os.date("%Y-%m-%d %H:%M:%S") .. " [AdvancedAutomation-" .. (State.processId or "?") .. "] " .. message)
end

-- Initialize and read configuration from process environment
local function init()
  log("Initializing advanced automation process...")
  
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
  
  -- Set up workflow steps if provided
  if State.config.Workflow and type(State.config.Workflow) == "table" then
    State.workflowSteps = State.config.Workflow
    log("Workflow with " .. #State.workflowSteps .. " steps configured")
  else
    -- Create a single-step workflow
    State.workflowSteps = {
      {
        action = State.config.Then,
        target = State.config.Target
      }
    }
    log("Single-step workflow configured")
  end
  
  State.startTime = os.time()
  
  log("Advanced automation process initialized")
  log("Trigger: " .. State.config.When)
  log("Steps: " .. #State.workflowSteps)
  
  return true
end

-- Evaluate a condition
local function evaluateCondition(condition, data)
  if not condition then
    return true  -- No condition means always true
  end
  
  if condition.type == "equals" then
    local fieldValue = Utils.getFieldValue(data, condition.field)
    return fieldValue == condition.value
  elseif condition.type == "contains" then
    local fieldValue = Utils.getFieldValue(data, condition.field)
    return type(fieldValue) == "string" and fieldValue:find(condition.value) ~= nil
  elseif condition.type == "greater_than" then
    local fieldValue = tonumber(Utils.getFieldValue(data, condition.field))
    return fieldValue and fieldValue > tonumber(condition.value)
  elseif condition.type == "less_than" then
    local fieldValue = tonumber(Utils.getFieldValue(data, condition.field))
    return fieldValue and fieldValue < tonumber(condition.value)
  elseif condition.type == "exists" then
    local fieldValue = Utils.getFieldValue(data, condition.field)
    return fieldValue ~= nil
  end
  
  return false
end

-- Execute a workflow step
local function executeWorkflowStep(step, originalMsg)
  if not step then
    log("Error: Invalid workflow step")
    return false
  end
  
  -- Check if the step has a condition
  if step.condition then
    local data = originalMsg.Data
    if type(data) == "string" then
      -- Try to parse as JSON
      local parsedData = Utils.parseJson(data)
      if parsedData then
        data = parsedData
      end
    end
    
    local conditionMet = evaluateCondition(step.condition, data)
    if not conditionMet then
      log("Step condition not met, skipping")
      return true  -- Continue to next step
    end
  end
  
  -- Execute the action
  log("Executing workflow step: " .. (step.action or "unknown"))
  
  Send({
    Target = step.target,
    Action = step.action,
    Tags = {
      OriginalSender = originalMsg.From,
      OriginalAction = originalMsg.Tags and originalMsg.Tags["Action"] or "unknown",
      AutomationProcess = ao.id,
      WorkflowStep = tostring(State.currentStep),
      TriggerCount = tostring(State.triggerCount)
    },
    Data = step.transform and step.transform(originalMsg.Data) or originalMsg.Data
  })
  
  log("Action sent: " .. step.action .. " to " .. step.target)
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
      
      -- Execute the workflow
      for i, step in ipairs(State.workflowSteps) do
        State.currentStep = i
        log("Processing workflow step " .. i .. " of " .. #State.workflowSteps)
        
        local success = executeWorkflowStep(step, msg)
        if not success then
          log("Workflow execution failed at step " .. i)
          break
        end
        
        -- If there's a delay specified, we would handle it here
        -- In AO, we can't actually pause execution, but in a real system
        -- you might implement this with a timer or callback
      end
      
      log("Workflow execution completed")
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
        WorkflowSteps = tostring(#State.workflowSteps)
      },
      Data = Utils.toJson({
        id = ao.id,
        processId = State.processId,
        trigger = State.config and State.config.When,
        workflowSteps = #State.workflowSteps,
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
  log("Advanced automation process setup completed. Waiting for trigger events.")
else
  log("Failed to initialize advanced automation process.")
end
