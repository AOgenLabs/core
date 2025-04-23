// telegram-bot.js
// A simple Telegram bot implementation

import TelegramBot from 'node-telegram-bot-api';
import express from 'express';
import cors from 'cors';
import { readFileSync } from 'node:fs';
import { message, results, createDataItemSigner } from '@permaweb/aoconnect';
import axios from 'axios';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Configuration
const AO_PROCESS_ID = process.env.AO_PROCESS_ID || '';
const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const PORT = parseInt(process.env.PORT || '3003');
const CHECK_INTERVAL = parseInt(process.env.CHECK_INTERVAL || '10');
const ARWEAVE_WALLET_PATH = process.env.ARWEAVE_WALLET_PATH || '';

if (!TELEGRAM_BOT_TOKEN) {
  console.error('TELEGRAM_BOT_TOKEN is not defined in .env file');
  process.exit(1);
}

if (!AO_PROCESS_ID) {
  console.error('AO_PROCESS_ID is not defined in .env file');
  process.exit(1);
}

if (!ARWEAVE_WALLET_PATH) {
  console.error('ARWEAVE_WALLET_PATH is not defined in .env file');
  process.exit(1);
}

// Create a new Telegram Bot instance
const bot = new TelegramBot(TELEGRAM_BOT_TOKEN, { polling: true });

// Map to store chat IDs for users
const userChatIds = new Map();

// Initialize the bot
function initBot() {
  console.log('Initializing Telegram Bot...');

  // Handle /start command
  bot.onText(/\/start/, (msg) => {
    const chatId = msg.chat.id.toString();
    const username = msg.from?.username || 'User';
    
    // Store the chat ID for the user
    if (msg.from?.id) {
      userChatIds.set(msg.from.id.toString(), chatId);
    }
    
    bot.sendMessage(
      chatId,
      `Hello, ${username}! I'm the AO Integration Bot. I'll send you notifications from your AO processes.`
    );
    
    console.log(`User ${username} (${chatId}) started the bot`);
  });

  // Handle /register command
  bot.onText(/\/register/, (msg) => {
    const chatId = msg.chat.id.toString();
    const username = msg.from?.username || 'User';
    
    // Store the chat ID for the user
    if (msg.from?.id) {
      userChatIds.set(msg.from.id.toString(), chatId);
      
      bot.sendMessage(
        chatId,
        `You've been registered for notifications, ${username}! Your chat ID is: ${chatId}`
      );
      
      console.log(`User ${username} registered with chat ID: ${chatId}`);
    } else {
      bot.sendMessage(
        chatId,
        'Sorry, I could not register you. Please try again.'
      );
    }
  });

  // Handle /help command
  bot.onText(/\/help/, (msg) => {
    const chatId = msg.chat.id.toString();
    
    bot.sendMessage(
      chatId,
      'Available commands:\n' +
      '/start - Start the bot\n' +
      '/register - Register for notifications\n' +
      '/help - Show this help message'
    );
  });

  console.log('Telegram Bot initialized');
}

// Send a notification to a user
async function sendNotification(chatId, message, options = {}) {
  try {
    console.log(`Sending notification to chat ID: ${chatId}`);
    console.log(`Message: ${message}`);
    
    await bot.sendMessage(chatId, message, {
      parse_mode: options.parseMode,
      disable_notification: options.disableNotification
    });
    
    console.log('Notification sent successfully');
    return true;
  } catch (error) {
    console.error('Error sending notification:', error);
    return false;
  }
}

// Create Express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Routes
app.post('/api/telegram/send', async (req, res) => {
  try {
    const { chatId, message, parseMode, disableNotification } = req.body;
    
    // Validate required fields
    if (!chatId) {
      return res.status(400).json({ error: 'Chat ID is required' });
    }
    
    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }
    
    console.log(`Sending Telegram notification to: ${chatId}`);
    console.log(`Message: ${message}`);
    
    // Send the notification
    const success = await sendNotification(chatId, message, {
      parseMode,
      disableNotification
    });
    
    if (success) {
      return res.status(200).json({
        success: true,
        message: 'Telegram notification sent successfully'
      });
    } else {
      return res.status(500).json({
        success: false,
        error: 'Failed to send Telegram notification'
      });
    }
  } catch (error) {
    console.error('Error sending Telegram notification:', error);
    return res.status(500).json({ error: 'Failed to send Telegram notification' });
  }
});

// Health check endpoint
app.get('/api/telegram/health', (_req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString()
  });
});

// Load Arweave wallet
let wallet;
try {
  wallet = JSON.parse(readFileSync(ARWEAVE_WALLET_PATH).toString());
  console.log('Arweave wallet loaded successfully');
} catch (error) {
  console.error('Error loading Arweave wallet:', error);
  process.exit(1);
}

// Create a signer using the wallet
const signer = createDataItemSigner(wallet);

// Track processed requests to avoid duplicates
const processedRequests = new Set();

// Track the last cursor for pagination
let lastCursor = null;

/**
 * Process Telegram notification requests
 */
async function processTelegramRequest(request) {
  try {
    console.log(`Processing Telegram notification request: ${request.id}`);
    console.log(`Sending to chat ID: ${request.chatId}`);
    console.log(`Message: ${request.message}`);

    // Send the notification
    const success = await sendNotification(
      request.chatId,
      request.message,
      {
        parseMode: request.parseMode,
        disableNotification: request.disableNotification
      }
    );

    return {
      success,
      message: success ? 'Telegram notification sent successfully' : 'Failed to send Telegram notification'
    };
  } catch (error) {
    console.error(`Error processing Telegram request ${request.id}:`, error);

    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * Process API requests
 */
async function processAPIRequest(request) {
  // Skip already processed requests
  if (processedRequests.has(request.id)) {
    console.log(`Skipping already processed request: ${request.id}`);
    return;
  }

  try {
    console.log(`Processing request: ${request.id}`);

    // Process the Telegram notification request
    const result = await processTelegramRequest(request);

    // Mark the request as processed
    processedRequests.add(request.id);

    // Update the AO process with the result
    await updateRequestStatus(request.id, result);
  } catch (error) {
    console.error(`Error processing request ${request.id}:`, error);
  }
}

/**
 * Update the status of a request in the AO process
 */
async function updateRequestStatus(requestId, result) {
  try {
    console.log(`Updating request status: ${requestId}`);

    const updateData = {
      requestId,
      result
    };

    const updateResult = await message({
      process: AO_PROCESS_ID,
      tags: [{ name: 'Action', value: 'UpdateRequestStatus' }],
      data: JSON.stringify(updateData),
      signer
    });

    console.log(`Request status updated: ${requestId}`);
    return updateResult;
  } catch (error) {
    console.error(`Error updating request status:`, error);
    return null;
  }
}

/**
 * Check for new API request messages
 */
async function checkForNewMessages() {
  try {
    console.log('Checking for new messages...');

    // Get the latest results
    const latestResults = await results({
      process: AO_PROCESS_ID,
      limit: 100,
      sort: 'DESC',
      after: lastCursor
    });

    if (!latestResults || !latestResults.edges || latestResults.edges.length === 0) {
      console.log('No new messages found');
      return;
    }

    console.log(`Found ${latestResults.edges.length} messages`);

    // Update the last cursor for pagination
    if (latestResults.edges.length > 0) {
      lastCursor = latestResults.edges[0].cursor;
    }

    // Process each result
    for (const edge of latestResults.edges) {
      const result = edge.node;

      // Check if there are any messages
      if (!result.Messages || result.Messages.length === 0) {
        continue;
      }

      // Process each message
      for (const msg of result.Messages) {
        // Log all messages for debugging
        console.log('Message:', {
          Tags: msg.Tags,
          Data: msg.Data ? msg.Data.substring(0, 100) + '...' : 'No data'
        });

        // Check if this is a message with an Action tag
        if (msg.Tags && msg.Tags.find(tag => tag.name === 'Action')) {
          const actionTag = msg.Tags.find(tag => tag.name === 'Action');
          if (!actionTag) continue;

          const action = actionTag.value;

          // Check if this is a SendTelegram action
          if (action === 'SendTelegram') {
            console.log(`Found Telegram notification message with action: ${action}`);

            // Parse the request data
            try {
              const requestData = JSON.parse(msg.Data);
              console.log('Request data:', requestData);

              // Skip already processed requests
              const referenceTag = msg.Tags.find(tag => tag.name === 'Reference');
              if (referenceTag && processedRequests.has(referenceTag.value)) {
                console.log(`Skipping already processed request: ${referenceTag.value}`);
                continue;
              }

              // Create a request object
              const request = {
                id: referenceTag ? referenceTag.value : `telegram-${Date.now()}`,
                type: 'telegram',
                chatId: requestData.chatId,
                message: requestData.message,
                parseMode: requestData.parseMode,
                disableNotification: requestData.disableNotification,
                timestamp: Date.now(),
                status: 'pending'
              };

              // Process the request
              await processAPIRequest(request);

              // Mark the request as processed
              if (referenceTag) {
                processedRequests.add(referenceTag.value);
              }
            } catch (parseError) {
              console.error('Error parsing request data:', parseError);
              console.log('Raw data:', msg.Data);
            }
          }
        }
      }
    }
  } catch (error) {
    console.error('Error checking for new messages:', error);
  }
}

// Initialize the bot
initBot();

// Start the server
app.listen(PORT, () => {
  console.log(`Telegram Bot API server running on port ${PORT}`);
});

// Set up a loop to check for new messages
setInterval(checkForNewMessages, CHECK_INTERVAL * 1000);

console.log(`AO-Telegram Bridge started. Checking every ${CHECK_INTERVAL} seconds...`);

// Run once immediately
checkForNewMessages();
