-- EmailBot.lua
-- A simple bot for sending email notifications

local Utils = require("Utils")

-- Initialize state
local State = {
  emailsSent = 0,
  startTime = os.time(),
  config = {
    defaultSubject = "Notification from AO Process Builder",
    defaultSender = "noreply@aoprocessbuilder.example"
  }
}

-- Log a message with timestamp
local function log(message)
  print(os.date("%Y-%m-%d %H:%M:%S") .. " [EmailBot] " .. message)
end

-- Initialize the EmailBot
local function init()
  log("Initializing EmailBot...")
  
  -- Load existing state if available
  if ao.env and ao.env.Process and ao.env.Process.Data and ao.env.Process.Data.State then
    State = ao.env.Process.Data.State
    log("Loaded existing state with " .. State.emailsSent .. " emails sent")
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
  end
end

-- Format an email
local function formatEmail(recipient, subject, body, sender)
  return {
    to = recipient,
    subject = subject or State.config.defaultSubject,
    body = body,
    from = sender or State.config.defaultSender,
    timestamp = os.time()
  }
end

-- Send an email (simulated)
local function sendEmail(email)
  -- In a real implementation, this would connect to an email service
  log("Sending email to: " .. email.to)
  log("Subject: " .. email.subject)
  log("Body: " .. email.body)
  
  -- Update statistics
  State.emailsSent = State.emailsSent + 1
  saveState()
  
  return true
end

-- Handler for sending emails
Handlers.add(
  "Send Email",
  Handlers.utils.hasMatchingTag("Action", "Send Email"),
  function(msg)
    log("Received Send Email request from " .. msg.From)
    
    -- Parse the email data
    local emailData
    if type(msg.Data) == "string" then
      emailData = Utils.parseJson(msg.Data)
      if not emailData then
        log("Failed to parse email data as JSON, using as plain text body")
        emailData = {
          body = msg.Data
        }
      end
    else
      emailData = msg.Data
    end
    
    -- Extract email fields
    local recipient = emailData.to or (msg.Tags and msg.Tags["Recipient"])
    local subject = emailData.subject or (msg.Tags and msg.Tags["Subject"]) or State.config.defaultSubject
    local body = emailData.body or "No content"
    local sender = emailData.from or (msg.Tags and msg.Tags["Sender"]) or State.config.defaultSender
    
    -- Validate recipient
    if not recipient or recipient == "" then
      log("Error: Missing recipient")
      Utils.sendError(msg.From, "Missing recipient")
      return
    end
    
    -- Format and send the email
    local email = formatEmail(recipient, subject, body, sender)
    local success = sendEmail(email)
    
    -- Send response
    if success then
      Send({
        Target = msg.From,
        Action = "EmailSent",
        Tags = {
          Recipient = recipient,
          MessageId = tostring(State.emailsSent)
        },
        Data = Utils.toJson({
          success = true,
          messageId = State.emailsSent,
          recipient = recipient,
          timestamp = os.time()
        })
      })
    else
      Utils.sendError(msg.From, "Failed to send email")
    end
  end
)

-- Handler for user notifications
Handlers.add(
  "Notify User",
  Handlers.utils.hasMatchingTag("Action", "Notify User"),
  function(msg)
    log("Received Notify User request from " .. msg.From)
    
    -- Extract notification data
    local notificationData
    if type(msg.Data) == "string" then
      -- Try to parse as JSON
      notificationData = Utils.parseJson(msg.Data)
      if not notificationData then
        -- Use as plain text message
        notificationData = {
          message = msg.Data
        }
      end
    else
      notificationData = msg.Data
    end
    
    -- Extract user information
    local userId = notificationData.userId or (msg.Tags and msg.Tags["UserId"])
    local message = notificationData.message or "No message"
    local channel = notificationData.channel or (msg.Tags and msg.Tags["Channel"]) or "email"
    
    log("Notifying user: " .. (userId or "unknown"))
    log("Channel: " .. channel)
    log("Message: " .. message)
    
    -- In a real implementation, this would send the notification through the appropriate channel
    -- For this example, we'll just log it
    
    -- Update statistics
    State.emailsSent = State.emailsSent + 1
    saveState()
    
    -- Send response
    Send({
      Target = msg.From,
      Action = "UserNotified",
      Tags = {
        UserId = userId,
        Channel = channel,
        NotificationId = tostring(State.emailsSent),
        AutomationProcess = msg.Tags and msg.Tags["AutomationProcess"]
      },
      Data = Utils.toJson({
        success = true,
        notificationId = State.emailsSent,
        userId = userId,
        channel = channel,
        timestamp = os.time()
      })
    })
  end
)

-- Handler for checking the status of the EmailBot
Handlers.add(
  "Status",
  Handlers.utils.hasMatchingTag("Action", "Status"),
  function(msg)
    log("Received Status request from " .. msg.From)
    
    Send({
      Target = msg.From,
      Action = "EmailBotStatus",
      Data = Utils.toJson({
        id = ao.id,
        emailsSent = State.emailsSent,
        uptime = os.time() - State.startTime,
        status = "active"
      })
    })
  end
)

-- Initialize the EmailBot
if init() then
  log("EmailBot initialized. Ready to send emails and notifications.")
else
  log("Failed to initialize EmailBot.")
end
