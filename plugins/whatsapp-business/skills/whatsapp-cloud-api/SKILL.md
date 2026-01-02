---
name: whatsapp-cloud-api
description: This skill provides guidance for integrating with WhatsApp Business Cloud API. Use when the user asks about "WhatsApp API", "WhatsApp Business", "send WhatsApp message", "WhatsApp integration", "Meta Cloud API", "WhatsApp for business", or needs help with WhatsApp messaging setup, authentication, or sending messages.
---

# WhatsApp Business Cloud API

Meta's WhatsApp Business Cloud API enables businesses to send and receive messages programmatically. This guide covers setup, authentication, and messaging.

## Base URL

```
https://graph.facebook.com/v21.0
```

## Prerequisites

| Item | Description | How to Get |
|------|-------------|------------|
| Meta Business Account | Business verification | business.facebook.com |
| WhatsApp Business Account | WABA ID | Meta Business Suite |
| Phone Number ID | Your business number | WhatsApp Manager |
| Access Token | API authentication | Meta App Dashboard |

## Setup Steps

1. **Create Meta App** - developers.facebook.com/apps
2. **Add WhatsApp Product** - Enable WhatsApp in your app
3. **Add Phone Number** - Register or use test number
4. **Generate Token** - Create permanent access token
5. **Configure Webhooks** - Set up message receiving

## Authentication

All requests require a Bearer token:

```bash
curl -X POST \
  'https://graph.facebook.com/v21.0/{PHONE_NUMBER_ID}/messages' \
  -H 'Authorization: Bearer {ACCESS_TOKEN}' \
  -H 'Content-Type: application/json' \
  -d '{...}'
```

### Permanent Access Token

System User tokens don't expire. Create via:
1. Business Settings > System Users
2. Generate Token with `whatsapp_business_messaging` permission

## Sending Messages

### Text Message

```bash
POST /{PHONE_NUMBER_ID}/messages
Content-Type: application/json
Authorization: Bearer {ACCESS_TOKEN}

{
  "messaging_product": "whatsapp",
  "recipient_type": "individual",
  "to": "254712345678",
  "type": "text",
  "text": {
    "preview_url": false,
    "body": "Hello from Martin's Shop! Your order is ready for pickup."
  }
}
```

### Response

```json
{
  "messaging_product": "whatsapp",
  "contacts": [
    {
      "input": "254712345678",
      "wa_id": "254712345678"
    }
  ],
  "messages": [
    {
      "id": "wamid.HBgLMjU0NzEyMzQ1Njc4FQIAERgSQjM0..."
    }
  ]
}
```

## Message Types

### Image Message

```json
{
  "messaging_product": "whatsapp",
  "to": "254712345678",
  "type": "image",
  "image": {
    "link": "https://example.com/product.jpg",
    "caption": "Your ordered item"
  }
}
```

### Document Message

```json
{
  "messaging_product": "whatsapp",
  "to": "254712345678",
  "type": "document",
  "document": {
    "link": "https://example.com/receipt.pdf",
    "filename": "Receipt_001.pdf",
    "caption": "Your purchase receipt"
  }
}
```

### Location Message

```json
{
  "messaging_product": "whatsapp",
  "to": "254712345678",
  "type": "location",
  "location": {
    "longitude": 36.8219,
    "latitude": -1.2921,
    "name": "Martin's Electronics",
    "address": "Tom Mboya Street, Nairobi"
  }
}
```

### Contact Message

```json
{
  "messaging_product": "whatsapp",
  "to": "254712345678",
  "type": "contacts",
  "contacts": [
    {
      "name": {
        "formatted_name": "Martin's Shop",
        "first_name": "Martin's",
        "last_name": "Shop"
      },
      "phones": [
        {
          "phone": "+254712345678",
          "type": "WORK"
        }
      ]
    }
  ]
}
```

## Interactive Messages

### Button Message

```json
{
  "messaging_product": "whatsapp",
  "to": "254712345678",
  "type": "interactive",
  "interactive": {
    "type": "button",
    "header": {
      "type": "text",
      "text": "Order Confirmation"
    },
    "body": {
      "text": "Your order #123 is ready. Would you like to pick up or have it delivered?"
    },
    "footer": {
      "text": "Martin's Electronics"
    },
    "action": {
      "buttons": [
        {
          "type": "reply",
          "reply": {
            "id": "pickup",
            "title": "Pick Up"
          }
        },
        {
          "type": "reply",
          "reply": {
            "id": "deliver",
            "title": "Deliver"
          }
        }
      ]
    }
  }
}
```

### List Message

```json
{
  "messaging_product": "whatsapp",
  "to": "254712345678",
  "type": "interactive",
  "interactive": {
    "type": "list",
    "header": {
      "type": "text",
      "text": "Our Products"
    },
    "body": {
      "text": "Browse our available products:"
    },
    "footer": {
      "text": "Tap to select"
    },
    "action": {
      "button": "View Products",
      "sections": [
        {
          "title": "Phones",
          "rows": [
            {
              "id": "samsung-a54",
              "title": "Samsung A54",
              "description": "KES 45,000"
            },
            {
              "id": "iphone-14",
              "title": "iPhone 14",
              "description": "KES 120,000"
            }
          ]
        },
        {
          "title": "Accessories",
          "rows": [
            {
              "id": "case-001",
              "title": "Phone Case",
              "description": "KES 1,000"
            }
          ]
        }
      ]
    }
  }
}
```

## 24-Hour Messaging Window

**Critical Rule:** You can only send free-form messages within 24 hours of the customer's last message.

| Scenario | Allowed Message Types |
|----------|----------------------|
| Within 24h of customer message | Any message type |
| Outside 24h window | Template messages only |

```typescript
// Check if within messaging window
function canSendFreeformMessage(lastCustomerMessageAt: Date): boolean {
  const windowMs = 24 * 60 * 60 * 1000; // 24 hours
  return Date.now() - lastCustomerMessageAt.getTime() < windowMs;
}
```

## Node.js Implementation

```typescript
import axios from 'axios';

interface WhatsAppConfig {
  phoneNumberId: string;
  accessToken: string;
  version?: string;
}

class WhatsAppClient {
  private config: WhatsAppConfig;
  private baseUrl: string;

  constructor(config: WhatsAppConfig) {
    this.config = config;
    this.baseUrl = `https://graph.facebook.com/${config.version || 'v21.0'}`;
  }

  private async request(endpoint: string, data: object) {
    const response = await axios.post(
      `${this.baseUrl}/${this.config.phoneNumberId}${endpoint}`,
      data,
      {
        headers: {
          'Authorization': `Bearer ${this.config.accessToken}`,
          'Content-Type': 'application/json',
        },
      }
    );
    return response.data;
  }

  // Send text message
  async sendText(to: string, text: string) {
    return this.request('/messages', {
      messaging_product: 'whatsapp',
      recipient_type: 'individual',
      to,
      type: 'text',
      text: { body: text },
    });
  }

  // Send image
  async sendImage(to: string, imageUrl: string, caption?: string) {
    return this.request('/messages', {
      messaging_product: 'whatsapp',
      to,
      type: 'image',
      image: {
        link: imageUrl,
        caption,
      },
    });
  }

  // Send document
  async sendDocument(to: string, docUrl: string, filename: string, caption?: string) {
    return this.request('/messages', {
      messaging_product: 'whatsapp',
      to,
      type: 'document',
      document: {
        link: docUrl,
        filename,
        caption,
      },
    });
  }

  // Send interactive buttons
  async sendButtons(
    to: string,
    body: string,
    buttons: Array<{ id: string; title: string }>,
    header?: string,
    footer?: string
  ) {
    return this.request('/messages', {
      messaging_product: 'whatsapp',
      to,
      type: 'interactive',
      interactive: {
        type: 'button',
        header: header ? { type: 'text', text: header } : undefined,
        body: { text: body },
        footer: footer ? { text: footer } : undefined,
        action: {
          buttons: buttons.map(btn => ({
            type: 'reply',
            reply: { id: btn.id, title: btn.title },
          })),
        },
      },
    });
  }

  // Send list menu
  async sendList(
    to: string,
    body: string,
    buttonText: string,
    sections: Array<{
      title: string;
      rows: Array<{ id: string; title: string; description?: string }>;
    }>,
    header?: string,
    footer?: string
  ) {
    return this.request('/messages', {
      messaging_product: 'whatsapp',
      to,
      type: 'interactive',
      interactive: {
        type: 'list',
        header: header ? { type: 'text', text: header } : undefined,
        body: { text: body },
        footer: footer ? { text: footer } : undefined,
        action: {
          button: buttonText,
          sections,
        },
      },
    });
  }

  // Send location
  async sendLocation(
    to: string,
    latitude: number,
    longitude: number,
    name?: string,
    address?: string
  ) {
    return this.request('/messages', {
      messaging_product: 'whatsapp',
      to,
      type: 'location',
      location: { latitude, longitude, name, address },
    });
  }

  // Mark message as read
  async markAsRead(messageId: string) {
    return this.request('/messages', {
      messaging_product: 'whatsapp',
      status: 'read',
      message_id: messageId,
    });
  }
}

// Usage
const whatsapp = new WhatsAppClient({
  phoneNumberId: process.env.WHATSAPP_PHONE_NUMBER_ID!,
  accessToken: process.env.WHATSAPP_ACCESS_TOKEN!,
});

// Send order notification
await whatsapp.sendText(
  '254712345678',
  'Hi! Your order #123 has been confirmed. We will notify you when it\'s ready.'
);

// Send product image
await whatsapp.sendImage(
  '254712345678',
  'https://shop.example.com/products/samsung-a54.jpg',
  'Samsung Galaxy A54 - KES 45,000'
);

// Send delivery options
await whatsapp.sendButtons(
  '254712345678',
  'Your order is ready! How would you like to receive it?',
  [
    { id: 'pickup', title: 'Pick Up' },
    { id: 'delivery', title: 'Deliver to Me' },
  ],
  'Order Ready',
  'Martin\'s Electronics'
);
```

## Rate Limits

| Tier | Messages/Day | How to Increase |
|------|--------------|-----------------|
| Unverified | 250 | Verify business |
| Tier 1 | 1,000 | Quality rating |
| Tier 2 | 10,000 | Maintain quality |
| Tier 3 | 100,000 | High volume |
| Tier 4 | Unlimited | Enterprise |

## Error Handling

```typescript
try {
  await whatsapp.sendText(to, message);
} catch (error) {
  if (axios.isAxiosError(error)) {
    const waError = error.response?.data?.error;

    switch (waError?.code) {
      case 131026:
        // Message failed to send - retry
        break;
      case 131047:
        // Re-engagement message - need template
        console.log('Outside 24h window, use template');
        break;
      case 131051:
        // Invalid phone number
        break;
      case 100:
        // Invalid parameter
        break;
    }
  }
}
```

## Common Error Codes

| Code | Description | Solution |
|------|-------------|----------|
| 131026 | Message undeliverable | Check phone number validity |
| 131047 | Re-engagement required | Use template message |
| 131051 | Invalid recipient | Verify phone format |
| 131052 | Media download error | Check media URL accessibility |
| 100 | Invalid parameter | Review request payload |
| 190 | Access token expired | Refresh token |

## Phone Number Format

Always use international format without `+`:

```typescript
function formatPhoneNumber(phone: string): string {
  // Remove all non-digits
  let cleaned = phone.replace(/\D/g, '');

  // Kenya: Add country code if missing
  if (cleaned.startsWith('0')) {
    cleaned = '254' + cleaned.slice(1);
  }
  if (cleaned.startsWith('7') && cleaned.length === 9) {
    cleaned = '254' + cleaned;
  }

  return cleaned;
}

// Examples:
// '0712345678' -> '254712345678'
// '+254712345678' -> '254712345678'
// '712345678' -> '254712345678'
```

## Multi-Tenant Architecture

For SaaS platforms serving multiple businesses:

```typescript
interface TenantWhatsAppConfig {
  tenantId: string;
  phoneNumberId: string;
  accessTokenEncrypted: string;
  wabaId: string;
}

// Store each tenant's WhatsApp credentials
async function createTenantClient(tenant: TenantWhatsAppConfig) {
  return new WhatsAppClient({
    phoneNumberId: tenant.phoneNumberId,
    accessToken: await decrypt(tenant.accessTokenEncrypted),
  });
}
```
