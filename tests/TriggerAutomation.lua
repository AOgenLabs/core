-- TriggerAutomation.lua
-- Test script to trigger an existing automation

print(\"Triggering the automation...\")

-- Send a 'File Uploaded' event to the automation
Send({
  Target = \"auto-1744933766612-0\",  -- Use the automation ID from the SimpleTest output
  Action = \"File Uploaded\",
  Data = {
    fileId = \"file-123\",
    fileName = \"test.txt\",
    fileSize = 1024
  }
})

print(\"Trigger event sent to automation: auto-1744933766612-0\")
print(\"Check the console for the results.\")
