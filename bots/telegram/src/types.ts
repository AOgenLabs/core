// types.ts
// Type definitions for the Telegram Bot

export interface Tag {
  name: string;
  value: string;
}

export interface Message {
  Tags: Tag[];
  Data: string;
  From?: string;
}

export interface ResultNode {
  Messages: Message[];
}

export interface ResultEdge {
  cursor: string;
  node: ResultNode;
}

export interface ResultsResponse {
  edges: ResultEdge[];
}

export interface TelegramNotificationRequest {
  id: string;
  type: 'telegram';
  chatId: string;
  message: string;
  parseMode?: 'Markdown' | 'HTML';
  disableNotification?: boolean;
  timestamp: number;
  status: string;
}

export interface APIResponse {
  success: boolean;
  status?: number;
  data?: any;
  error?: string;
}

export interface UpdateRequestData {
  requestId: string;
  result: APIResponse;
}
