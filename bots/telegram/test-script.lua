-- test-script.lua
-- A simple test script for AO that sends Telegram notifications

print("Starting Telegram Bot Test...")

-- Function to send a Telegram notification
function sendTelegramNotification()
  print("\n----- Sending Telegram Notification -----")

  local notificationData = {
    chatId = "-4770042285", -- Your actual chat ID
    message = "This is a test notification from AO using the Telegram Bot.",
    parseMode = "Markdown",
    disableNotification = false
  }

  print("Sending notification to chat ID: " .. notificationData.chatId)
  print("Message: " .. notificationData.message)

  local result = Send({
    Target = "self",
    Action = "SendTelegram",
    Data = Utils.toJson(notificationData)
  })

  print("Telegram notification request sent")
  return result
end

-- Run the test
print("\nRunning Telegram Bot Test...")

-- Send a Telegram notification
local notificationResult = sendTelegramNotification()
print("Telegram notification result: " .. Utils.toJson(notificationResult))

print("\nTest completed. Check the Telegram Bot logs for request processing.")
print("The Telegram Bot should detect this request and process it.")

return "Telegram Bot Test completed"
