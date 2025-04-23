// bot.ts
// Telegram Bot implementation

import TelegramBot from 'node-telegram-bot-api';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Get the Telegram Bot Token from environment variables
const token = process.env.TELEGRAM_BOT_TOKEN;

if (!token) {
  console.error('TELEGRAM_BOT_TOKEN is not defined in .env file');
  process.exit(1);
}

// Create a new Telegram Bot instance
const bot = new TelegramBot(token, { polling: true });

// Map to store chat IDs for users
const userChatIds = new Map<string, string>();

// Initialize the bot
export function initBot(): void {
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
export async function sendNotification(
  chatId: string,
  message: string,
  options: {
    parseMode?: 'Markdown' | 'HTML';
    disableNotification?: boolean;
  } = {}
): Promise<boolean> {
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

// Get the bot instance
export function getBot(): TelegramBot {
  return bot;
}

// Get the chat ID for a user
export function getChatId(userId: string): string | undefined {
  return userChatIds.get(userId);
}

// Set the chat ID for a user
export function setChatId(userId: string, chatId: string): void {
  userChatIds.set(userId, chatId);
}

// Export the bot
export default bot;
