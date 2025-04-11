-- Utils.lua
-- Utility functions for the AO Process Builder

local json = require("json")

local Utils = {}

-- Parse JSON string into a Lua table
function Utils.parseJson(jsonStr)
  if not jsonStr or jsonStr == "" then
    return nil, "Empty JSON string"
  end
  
  local success, result = pcall(function() 
    return json.decode(jsonStr)
  end)
  
  if not success then
    return nil, "Failed to parse JSON: " .. tostring(result)
  end
  
  return result
end

-- Convert Lua table to JSON string
function Utils.toJson(tbl)
  if not tbl then
    return "{}"
  end
  
  local success, result = pcall(function() 
    return json.encode(tbl)
  end)
  
  if not success then
    return "{}", "Failed to convert to JSON: " .. tostring(result)
  end
  
  return result
end

-- Format error message
function Utils.formatError(message, details)
  local error = {
    message = message or "Unknown error",
    details = details or {},
    timestamp = os.time()
  }
  
  return error
end

-- Send error response
function Utils.sendError(target, message, details)
  Send({
    Target = target,
    Action = "Error",
    Data = Utils.toJson({
      message = message or "Unknown error",
      details = details or {},
      timestamp = os.time()
    })
  })
end

-- Print table contents (for debugging)
function Utils.printTable(t, indent)
  indent = indent or 0
  local indentStr = string.rep("  ", indent)
  
  if type(t) ~= "table" then
    print(indentStr .. tostring(t))
    return
  end
  
  for k, v in pairs(t) do
    if type(v) == "table" then
      print(indentStr .. k .. ": {")
      Utils.printTable(v, indent + 1)
      print(indentStr .. "}")
    else
      print(indentStr .. k .. ": " .. tostring(v))
    end
  end
end

-- Check if a table is empty
function Utils.isEmptyTable(t)
  return next(t) == nil
end

-- Convert table to string representation
function Utils.tableToString(t)
  if type(t) ~= "table" then
    return tostring(t)
  end
  
  local result = "{"
  for k, v in pairs(t) do
    local key = type(k) == "number" and "[" .. k .. "]" or k
    local value = type(v) == "table" and Utils.tableToString(v) or tostring(v)
    result = result .. key .. "=" .. value .. ", "
  end
  result = result:sub(1, -3) .. "}"
  
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
  for part in path:gmatch("[^%.]+") do
    table.insert(parts, part)
  end
  
  local current = obj
  for _, part in ipairs(parts) do
    if type(current) ~= "table" then
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
  for part in path:gmatch("[^%.]+") do
    table.insert(parts, part)
  end
  
  local current = obj
  for i = 1, #parts - 1 do
    local part = parts[i]
    if current[part] == nil or type(current[part]) ~= "table" then
      current[part] = {}
    end
    current = current[part]
  end
  
  current[parts[#parts]] = value
  return obj
end

return Utils
