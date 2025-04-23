// server.ts
// Server for handling Telegram notification requests

import express from "express";
import cors from "cors";
import { sendNotification } from "./bot.js";
import { TelegramNotificationRequest } from "./types.js";

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
app.post("/api/telegram/send", async (req, res) => {
    try {
        const { chatId, message, parseMode, disableNotification } =
            req.body as TelegramNotificationRequest;

        // Validate required fields
        if (!chatId) {
            return res.status(400).json({ error: "Chat ID is required" });
        }

        if (!message) {
            return res.status(400).json({ error: "Message is required" });
        }

        console.log(`Sending Telegram notification to: ${chatId}`);
        console.log(`Message: ${message}`);

        // Send the notification
        const success = await sendNotification(chatId, message, {
            parseMode,
            disableNotification,
        });

        if (success) {
            return res.status(200).json({
                success: true,
                message: "Telegram notification sent successfully",
            });
        } else {
            return res.status(500).json({
                success: false,
                error: "Failed to send Telegram notification",
            });
        }
    } catch (error) {
        console.error("Error sending Telegram notification:", error);
        return res
            .status(500)
            .json({ error: "Failed to send Telegram notification" });
    }
});

// Health check endpoint
app.get("/api/telegram/health", (_req, res) => {
    res.json({
        status: "ok",
        timestamp: new Date().toISOString(),
    });
});

// Export the app
export default app;
