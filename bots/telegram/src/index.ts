// index.ts
// Main entry point for the Telegram Bot

import dotenv from "dotenv";
import { initBot } from "./bot.js";
import app from "./server.js";
import { checkForNewMessages } from "./bridge.js";

// Load environment variables
dotenv.config();

// Configuration
const PORT = parseInt(process.env.PORT || "3003");
const CHECK_INTERVAL = parseInt(process.env.CHECK_INTERVAL || "10");

// Initialize the Telegram Bot
initBot();

// Start the server
app.listen(PORT, () => {
    console.log(`Telegram Bot API server running on port ${PORT}`);
});

// Set up a loop to check for new messages
setInterval(checkForNewMessages, CHECK_INTERVAL * 1000);

console.log(
    `AO-Telegram Bridge started. Checking every ${CHECK_INTERVAL} seconds...`
);

// Run once immediately
checkForNewMessages();
