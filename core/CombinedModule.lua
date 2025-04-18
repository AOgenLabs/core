-- CombinedModule.lua
-- Combines Utils and AutomationTemplate into a single file

-- Simple JSON implementation for AO
local json = {}

-- Encode a Lua table to JSON string
function json.encode(val)
  local t = type(val)
  if t == \"nil\" then
    return \"null\"
  elseif t == \"boolean\" or t == \"number\" then
    return tostring(val)
  elseif t == \"string\" then
    return '\"' .. val:gsub('\"', '\\\\\"'):gsub('\\n', '\\\\n') .. '\"'
  elseif t == \"table\" then
    local isArray = true
    local maxIndex = 0
    for k, v in pairs(val) do
      if type(k) ~= \"number\" or k <= 0 or math.floor(k) ~= k then
        isArray = false
        break
      end
      maxIndex = math.max(maxIndex, k)
    end
    
    local result = {}
    if isArray then
      for i = 1, maxIndex do
        result[i] = json.encode(val[i] or json.null)
      end
      return '[' .. table.concat(result, ',') .. ']'
    else
      for k, v in pairs(val) do
        if type(k) == \"string\" then
          table.insert(result, '\"' .. k .. '\":' .. json.encode(v))
        end
      end
      return '{' .. table.concat(result, ',') .. '}'
    end
  end
  return '\"' .. tostring(val) .. '\"'
end

-- Decode a JSON string to Lua table
function json.decode(str)
  -- This is a simplified implementation
  -- In a real-world scenario, you'd want a more robust parser
  if str == \"null\" then
    return nil
  elseif str == \"true\" then
    return true
  elseif str == \"false\" then
    return false
  elseif str:match(\"^%d+$\") then
    return tonumber(str)
  elseif str:match('^\".*\"$') then
    return str:sub(2, -2):gsub('\\\\\"', '\"'):gsub('\\\\n', '\\n')
  elseif str:match(\"^%[.*%]$\") then
    local result = {}
    local i = 1
    for item in str:sub(2, -2):gmatch(\"[^,]+\") do
      result[i] = json.decode(item)
      i = i + 1
    end
    return result
  elseif str:match(\"^%{.*%}$\") then
    local result = {}
    for key, value in str:sub(2, -2):gmatch('\"([^\"]+)\":([^,}]+)') do
      result[key] = json.decode(value)
    end
    return result
  end
  return str
end

-- Utils module
local Utils = {}

-- Parse JSON string into a Lua table
function Utils.parseJson(jsonStr)
  if not jsonStr or jsonStr == \"\" then
    return nil, \"Empty JSON string\"
  end
  
  local success, result = pcall(function() 
    return json.decode(jsonStr)
  end)
  
  if not success then
    return nil, \"Failed to parse JSON: \" .. tostring(result)
  end
  
  return result
end

-- Convert Lua table to JSON string
function Utils.toJson(tbl)
  if not tbl then
    return \"{}\"
  end
  
  local success, result = pcall(function() 
    return json.encode(tbl)
  end)
  
  if not success then
    return \"{}\", \"Failed to convert to JSON: \" .. tostring(result)
  end
  
  return result
end

-- Format error message
function Utils.formatError(message, details)
  local error = {
    message = message or \"Unknown error\",
    details = details or {},
    timestamp = os.time()
  }
  
  return error
end

-- Send error response
function Utils.sendError(target, message, details)
  Send({
    Target = target,
    Action = \"Error\",
    Data = Utils.toJson({
      message = message or \"Unknown error\",
      details = details or {},
      timestamp = os.time()
    })
  })
end

-- Print table contents (for debugging)
function Utils.printTable(t, indent)
  indent = indent or 0
  local indentStr = string.rep(\"  \", indent)
  
  if type(t) ~= \"table\" then
    print(indentStr .. tostring(t))
    return
  end
  
  for k, v in pairs(t) do
    if type(v) == \"table\" then
      print(indentStr .. k .. \": {\")
      Utils.printTable(v, indent + 1)
      print(indentStr .. \"}\")
    else
      print(indentStr .. k .. \": \" .. tostring(v))
    end
  end
end

-- Check if a table is empty
function Utils.isEmptyTable(t)
  return next(t) == nil
end

-- Convert table to string representation
function Utils.tableToString(t)
  if type(t) ~= \"table\" then
    return tostring(t)
  end
  
  local result = \"{\"
  for k, v in pairs(t) do
    local key = type(k) == \"number\" and \"[\" .. k .. \"]\" or k
    local value = type(v) == \"table\" and Utils.tableToString(v) or tostring(v)
    result = result .. key .. \"=\" .. value .. \", \"
  end
  result = result:sub(1, -3) .. \"}\"
  
  return result
end

-- Merge two tables
function Utils.mergeTables(t1, t2)
  local result = {}
  
  -- Copy t1
  for k, v in pairs(t1 or {}) do
    result[k] = v
  end
  
  -- Merge t2
  for k, v in pairs(t2 or {}) do
    result[k] = v
  end
  
  return result
end

-- Get a value from a nested table using a dot-separated path
function Utils.getFieldValue(obj, path)
  if not obj or not path then return nil end
  
  local parts = {}
  for part in path:gmatch(\"[^%.]+\") do
    table.insert(parts, part)
  end
  
  local current = obj
  for _, part in ipairs(parts) do
    if type(current) ~= \"table\" then
      return nil
    end
    current = current[part]
    if current == nil then
      return nil
    end
  end
  
  return current
end

-- Set a value in a nested table using a dot-separated path
function Utils.setFieldValue(obj, path, value)
  if not obj or not path then return obj end
  
  local parts = {}
  for part in path:gmatch(\"[^%.]+\") do
    table.insert(parts, part)
  end
  
  local current = obj
  for i = 1, #parts - 1 do
    local part = parts[i]
    if current[part] == nil or type(current[part]) ~= \"table\" then
      current[part] = {}
    end
    current = current[part]
  end
  
  current[parts[#parts]] = value
  return obj
end

-- Make Utils available globally
_G.Utils = Utils

-- Initialize state for AutomationTemplate
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
  print(os.date(\"%Y-%m-%d %H:%M:%S\") .. \" [Automation-\" .. (State.processId or \"?\") .. \"] \" .. message)
end

-- Initialize and read configuration from process environment
local function init()
  log(\"Initializing automation process...\")
  
  -- Check if we're in a spawned process with configuration
  if ao.env and ao.env.Process and ao.env.Process.Data then
    State.config = ao.env.Process.Data.Config
    State.creator = ao.env.Process.Data.Creator
    State.processId = ao.env.Process.Data.ProcessId
  end
  
  -- Validate configuration
  if not State.config then
    log(\"Error: No configuration found\")
    return false
  end
  
  if not State.config.When or not State.config.Then or not State.config.Target then
    log(\"Error: Invalid configuration - missing required fields\")
    return false
  end
  
  State.startTime = os.time()
  
  log(\"Automation process initialized\")
  log(\"Trigger: \" .. State.config.When)
  log(\"Action: \" .. State.config.Then)
  log(\"Target: \" .. State.config.Target)
  
  return true
end

-- Set up the main handler for the trigger event
local function setupTriggerHandler()
  local triggerEvent = State.config.When
  
  -- Add a handler that matches the trigger event
  Handlers.add(
    \"TriggerAction\",
    function(msg)
      -- Check if the incoming message's Action tag matches our trigger
      return msg.Tags and msg.Tags[\"Action\"] == triggerEvent
    end,
    function(msg)
      log(\"Trigger event detected: \" .. triggerEvent)
      
      -- Update trigger statistics
      State.triggerCount = State.triggerCount + 1
      State.lastTriggered = os.time()
      
      -- Forward the message to the target with the configured action
      Send({
        Target = State.config.Target,
        Action = State.config.Then,
        Tags = {
          OriginalSender = msg.From,
          OriginalAction = msg.Tags and msg.Tags[\"Action\"] or \"unknown\",
          AutomationProcess = ao.id,
          TriggerCount = tostring(State.triggerCount)
        },
        Data = msg.Data  -- Propagate the original data
      })
      
      log(\"Action forwarded: \" .. State.config.Then .. \" to \" .. State.config.Target)
    end
  )
  
  log(\"Trigger handler registered for event: \" .. triggerEvent)
}

-- Set up a handler for checking the status of this automation
Handlers.add(
  \"Status\",
  Handlers.utils.hasMatchingTag(\"Action\", \"Status\"),
  function(msg)
    log(\"Status request received from \" .. msg.From)
    
    Send({
      Target = msg.From,
      Action = \"AutomationStatus\",
      Tags = {
        ProcessId = ao.id,
        Trigger = State.config and State.config.When or \"unknown\",
        TargetAction = State.config and State.config.Then or \"unknown\",
        Target = State.config and State.config.Target or \"unknown\"
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
        status = \"active\"
      })
    })
  end
)

-- Initialize the process
if init() then
  setupTriggerHandler()
  log(\"Automation process setup completed. Waiting for trigger events.\")
else
  log(\"Failed to initialize automation process.\")
end

-- Return the Utils module for use by other modules
return Utils
