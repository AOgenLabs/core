// bridge.ts
// Bridge for connecting AO processes with the Telegram bot

import { readFileSync } from 'node:fs';
import { message, results, createDataItemSigner } from '@permaweb/aoconnect';
import axios from 'axios';
import dotenv from 'dotenv';
import {
  Tag,
  ResultsResponse,
  TelegramNotificationRequest,
  APIResponse,
  UpdateRequestData
} from './types.js';

// Load environment variables
dotenv.config();

// Configuration
const AO_PROCESS_ID = process.env.AO_PROCESS_ID || '';
const TELEGRAM_API_URL = 'http://localhost:3003/api/telegram/send';
const CHECK_INTERVAL = parseInt(process.env.CHECK_INTERVAL || '10');
const ARWEAVE_WALLET_PATH = process.env.ARWEAVE_WALLET_PATH || '';

if (!AO_PROCESS_ID) {
  console.error('AO_PROCESS_ID is not defined in .env file');
  process.exit(1);
}

if (!ARWEAVE_WALLET_PATH) {
  console.error('ARWEAVE_WALLET_PATH is not defined in .env file');
  process.exit(1);
}

// Load Arweave wallet
let wallet: any;
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
const processedRequests = new Set<string>();

// Track the last cursor for pagination
let lastCursor: string | null = null;

/**
 * Process Telegram notification requests
 */
async function processTelegramRequest(request: TelegramNotificationRequest): Promise<APIResponse> {
  try {
    console.log(`Processing Telegram notification request: ${request.id}`);
    console.log(`Sending to chat ID: ${request.chatId}`);
    console.log(`Message: ${request.message}`);

    // Make the API request
    const response = await axios({
      method: 'post',
      url: TELEGRAM_API_URL,
      data: {
        chatId: request.chatId,
        message: request.message,
        parseMode: request.parseMode,
        disableNotification: request.disableNotification
      }
    });

    console.log(`Telegram API response: ${response.status}`);

    return {
      success: true,
      status: response.status,
      data: response.data
    };
  } catch (error: any) {
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
async function processAPIRequest(request: TelegramNotificationRequest): Promise<void> {
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
async function updateRequestStatus(requestId: string, result: APIResponse): Promise<any> {
  try {
    console.log(`Updating request status: ${requestId}`);

    const updateData: UpdateRequestData = {
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
async function checkForNewMessages(): Promise<void> {
  try {
    console.log('Checking for new messages...');

    // Get the latest results
    const latestResults = (await results({
      process: AO_PROCESS_ID,
      limit: 100,
      sort: 'DESC',
      // @ts-ignore - 'after' is supported but not in the type definition
      after: lastCursor
    })) as ResultsResponse;

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
        if (msg.Tags && msg.Tags.find((tag: Tag) => tag.name === 'Action')) {
          const actionTag = msg.Tags.find((tag: Tag) => tag.name === 'Action');
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
              const referenceTag = msg.Tags.find((tag: Tag) => tag.name === 'Reference');
              if (referenceTag && processedRequests.has(referenceTag.value)) {
                console.log(`Skipping already processed request: ${referenceTag.value}`);
                continue;
              }

              // Create a request object
              const request: TelegramNotificationRequest = {
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

// Export the functions
export {
  checkForNewMessages,
  processAPIRequest,
  processTelegramRequest,
  updateRequestStatus
};
