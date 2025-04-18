-- CreateAutomation.lua
-- Test script to create a custom automation

print(\"Creating a custom automation...\")

-- Get the process ID
local processId = ao.id
print(\"Process ID: \" .. processId)

-- Create the automation
Send({
  Target = processId,
  Action = \"CreateAutomation\",
  Data = {
    When = \"Document Updated\",
    Then = \"Send Email\",
    Target = processId
  }
})

print(\"Automation creation request sent.\")
print(\"Waiting for response...\")

-- Wait a moment for the automation to be created
ao.sleep(2000)

-- List all automations
Send({
  Target = processId,
  Action = \"ListAutomations\"
})

print(\"ListAutomations request sent.\")
print(\"Check the console for the list of automations.\")
