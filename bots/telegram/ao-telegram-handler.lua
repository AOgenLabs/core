-- ao-telegram-handler.lua
-- A handler for Telegram notifications

-- Initialize state
if not ao.env then ao.env = {} end
if not ao.env.TelegramRequests then ao.env.TelegramRequests = {} end
if not ao.env.TelegramRequests.pending then ao.env.TelegramRequests.pending = {} end
if not ao.env.TelegramRequests.completed then ao.env.TelegramRequests.completed = {} end

-- Log a message with timestamp
local function log(message)
  print(os.date("%Y-%m-%d %H:%M:%S") .. " [TelegramHandler] " .. message)
end

-- Generate a unique ID
local function generateId()
  return "req-" .. os.time() .. "-" .. math.random(1000000)
end

-- Handler for sending Telegram notifications
Handlers.add(
  "SendTelegram",
  Handlers.utils.hasMatchingTag("Action", "SendTelegram"),
  function(msg)
    log("Received SendTelegram request from " .. msg.From)
    
    -- Parse the notification data
    local notificationData
    if type(msg.Data) == "string" then
      notificationData = Utils.parseJson(msg.Data)
      if not notificationData then
        log("Failed to parse notification data as JSON")
        log("Raw data: " .. msg.Data)
        return
      end
    else
      notificationData = msg.Data
    end
    
    -- Validate required fields
    if not notificationData.chatId or notificationData.chatId == "" then
      log("Error: Missing chat ID")
      return
    end
    
    if not notificationData.message or notificationData.message == "" then
      log("Error: Missing message")
      return
    end
    
    -- Create a request ID
    local requestId = generateId()
    
    -- Create the request object
    local request = {
      id = requestId,
      type = "telegram",
      chatId = notificationData.chatId,
      message = notificationData.message,
      parseMode = notificationData.parseMode,
      disableNotification = notificationData.disableNotification,
      timestamp = os.time(),
      status = "pending",
      requestedBy = msg.From
    }
    
    -- Store the request in pending requests
    ao.env.TelegramRequests.pending[requestId] = request
    
    log("Telegram notification request queued with ID: " .. requestId)
    
    -- Send a message to be picked up by the bridge
    -- Use "self" as the target to ensure it's recorded in the process history
    Send({
      Target = "self",
      Action = "SendTelegram",
      Tags = {
        {name = "RequestType", value = "telegram"},
        {name = "RequestId", value = requestId},
        {name = "Status", value = "pending"}
      },
      Data = Utils.toJson(request)
    })
    
    -- Send response to the requester
    Send({
      Target = msg.From,
      Action = "TelegramQueued",
      Data = Utils.toJson({
        success = true,
        requestId = requestId,
        message = "Telegram notification request queued for processing"
      })
    })
  end
)

-- Handler for updating request status (used by the bridge)
Handlers.add(
  "UpdateRequestStatus",
  Handlers.utils.hasMatchingTag("Action", "UpdateRequestStatus"),
  function(msg)
    log("Received UpdateRequestStatus request from " .. msg.From)
    
    -- Parse the update data
    local updateData
    if type(msg.Data) == "string" then
      updateData = Utils.parseJson(msg.Data)
      if not updateData then
        log("Failed to parse update data as JSON")
        log("Raw data: " .. msg.Data)
        return
      end
    else
      updateData = msg.Data
    end
    
    -- Validate required fields
    if not updateData.requestId or updateData.requestId == "" then
      log("Error: Missing requestId")
      return
    end
    
    if not updateData.result then
      log("Error: Missing result")
      return
    end
    
    -- Check if the request exists
    local request = ao.env.TelegramRequests.pending[updateData.requestId]
    
    if not request then
      log("Error: Request not found: " .. updateData.requestId)
      return
    end
    
    log("Updating status for request: " .. updateData.requestId)
    
    -- Update the request status
    request.status = updateData.result.success and "completed" or "failed"
    request.result = updateData.result
    request.completedAt = os.time()
    
    -- Move the request from pending to completed
    ao.env.TelegramRequests.completed[updateData.requestId] = request
    ao.env.TelegramRequests.pending[updateData.requestId] = nil
    
    -- Send a message to be picked up by the bridge
    -- Use "self" as the target to ensure it's recorded in the process history
    Send({
      Target = "self",
      Action = "TelegramRequest",
      Tags = {
        {name = "RequestType", value = "telegram"},
        {name = "RequestId", value = updateData.requestId},
        {name = "Status", value = "completed"}
      },
      Data = Utils.toJson(request)
    })
    
    -- Notify the requester
    if request.requestedBy then
      Send({
        Target = request.requestedBy,
        Action = "TelegramProcessed",
        Data = Utils.toJson(request)
      })
    end
    
    -- Send response to the bridge
    Send({
      Target = msg.From,
      Action = "RequestStatusUpdated",
      Data = Utils.toJson({
        success = true,
        requestId = updateData.requestId,
        message = "Request status updated"
      })
    })
  end
)

-- Initialize the handlers
log("Telegram Handlers initialized")

-- Return the handler state
return {
  pending = ao.env.TelegramRequests.pending,
  completed = ao.env.TelegramRequests.completed
}
