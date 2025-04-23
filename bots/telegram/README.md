# Telegram Bot for AO Integration

This project integrates AO processes with Telegram using a message-based approach that focuses on detecting messages rather than accessing state directly.

## Components

1. **AO Handlers**: Lua scripts that run in the AO environment and send messages when Telegram notification requests are received.
2. **Telegram Bot**: A Node.js implementation of a Telegram bot that can send notifications to users.
3. **Message Bridge**: A Node.js script that uses aoconnect's results function to check for new messages.
4. **API Server**: An Express.js server that handles Telegram notification requests.

## Setup

### 1. Create a Telegram Bot

1. Open Telegram and search for the "BotFather" bot.
2. Start a chat with BotFather and use the `/newbot` command to create a new bot.
3. Follow the instructions to set a name and username for your bot.
4. BotFather will give you a token for your bot. Copy this token.
5. Edit the `.env` file in the `@core/bots/telegram` directory and set the `TELEGRAM_BOT_TOKEN` to your token.

### 2. Install Dependencies

```bash
# Install dependencies for the Telegram Bot
cd @core/bots/telegram
npm install
```

### 3. Configure the Telegram Bot

Edit the `.env` file in the `@core/bots/telegram` directory to set the AO process ID and other configuration:

```
# Telegram Bot Token (replace with your actual token)
TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"

# Server configuration
PORT=3003

# AO Process ID
AO_PROCESS_ID="your-ao-process-id"

# Arweave wallet path
ARWEAVE_WALLET_PATH="../../../arweave-keyfile-jAmz_Wcc_3ZeO_b5iruLNnI1e-ObZ9A8wHMKacigJ_g.json"
```

### 4. Build and Start the Telegram Bot

```bash
cd @core/bots/telegram
npm run build
npm start
```

This will start the Telegram Bot, which will check for new messages every 10 seconds (or whatever interval you set in the `.env` file).

### 5. Get Your Chat ID

1. Start a chat with your bot on Telegram.
2. Send the `/register` command to the bot.
3. The bot will respond with your chat ID. Copy this ID.
4. Edit the `test-script.lua` file and replace `YOUR_CHAT_ID` with your actual chat ID.

### 6. Load the AO Handlers

In the AO console, load the AO handlers:

```lua
.load @core/bots/telegram/ao-telegram-handler.lua
```

### 7. Test the Integration

In the AO console, load and run the test script:

```lua
.load @core/bots/telegram/test-script.lua
```

This will send a Telegram notification request, which will be processed by the Telegram Bot.

## Usage

### Sending a Telegram Notification

To send a Telegram notification from an AO process, send a message with the following format:

```lua
Send({
  Target = "your-ao-process-id",
  Action = "SendTelegram",
  Data = Utils.toJson({
    chatId = "recipient-chat-id",
    message = "Your notification message",
    parseMode = "Markdown", -- Optional: "Markdown" or "HTML"
    disableNotification = false -- Optional: true or false
  })
})
```

## Architecture

1. **AO Process**: Sends Telegram notification requests to itself using the AO handlers.
2. **AO Handlers**: Process the requests, store them in the process state, and send messages to be picked up by the Message Bridge.
3. **Message Bridge**: Checks for new messages and processes Telegram notification requests.
4. **Telegram Bot**: Sends notifications to users on Telegram.

The Message Bridge uses aoconnect's results function to check for new messages, which is a more reliable approach than trying to access the state directly.

## How It Works

1. The AO process receives a Telegram notification request (e.g., SendTelegram).
2. The AO handler processes the request, stores it in the process state, and sends a message with the Action "SendTelegram".
3. The Message Bridge checks for new messages and processes any "SendTelegram" messages that it finds.
4. The Message Bridge sends the notification to the Telegram Bot API.
5. When a request is processed, the Message Bridge sends a message back to the AO process to update the request status.
6. The AO process updates the status of the request and notifies the requester.

## Troubleshooting

If you encounter any issues, check the logs of the Telegram Bot and the AO console for error messages.

Common issues:

1. **Bot Token**: Make sure the Telegram Bot Token in the `.env` file is correct.
2. **Chat ID**: Make sure the chat ID in the test script is correct.
3. **AO Process ID**: Make sure the AO process ID in the `.env` file is correct.
4. **Arweave Wallet**: Make sure the Arweave wallet path in the `.env` file is correct.
5. **AO Handlers**: Make sure the AO handlers are loaded in the AO process.

## License

This project is licensed under the MIT License.
