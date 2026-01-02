# WhatsApp Business Plugin

Complete WhatsApp Business Cloud API integration for Claude Code.

## Features

- **Cloud API** - Send text, images, documents, locations, and contacts
- **Interactive Messages** - Buttons, lists, and quick replies
- **Templates** - Pre-approved messages for notifications and marketing
- **Webhooks** - Receive messages and delivery status updates
- **Multi-tenant** - Support for SaaS platforms with multiple businesses

## Skills

### whatsapp-cloud-api

Core WhatsApp Cloud API integration:
- Authentication and setup
- Sending all message types
- 24-hour messaging window rules
- Rate limits and error handling

### whatsapp-templates

Message template management:
- Creating and submitting templates
- UTILITY, AUTHENTICATION, MARKETING categories
- Template variables and buttons
- Common templates for Kenyan businesses
- Bulk messaging

### whatsapp-webhooks

Receiving messages and status updates:
- Webhook verification
- Incoming message handling
- Delivery/read receipts
- Media download
- Multi-tenant routing

## Quick Start

### Environment Variables

```bash
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id
WHATSAPP_ACCESS_TOKEN=your_access_token
WHATSAPP_VERIFY_TOKEN=your_webhook_verify_token
WHATSAPP_APP_SECRET=your_app_secret
```

### Send a Message

```typescript
import { WhatsAppClient } from './whatsapp';

const whatsapp = new WhatsAppClient({
  phoneNumberId: process.env.WHATSAPP_PHONE_NUMBER_ID!,
  accessToken: process.env.WHATSAPP_ACCESS_TOKEN!,
});

// Send text
await whatsapp.sendText('254712345678', 'Hello from Martin\'s Shop!');

// Send interactive buttons
await whatsapp.sendButtons(
  '254712345678',
  'Your order is ready! How would you like to receive it?',
  [
    { id: 'pickup', title: 'Pick Up' },
    { id: 'delivery', title: 'Deliver' },
  ]
);
```

### Handle Webhooks

```typescript
import express from 'express';

const app = express();

app.get('/webhook', (req, res) => {
  // Verification
  if (req.query['hub.verify_token'] === process.env.WHATSAPP_VERIFY_TOKEN) {
    res.send(req.query['hub.challenge']);
  } else {
    res.sendStatus(403);
  }
});

app.post('/webhook', (req, res) => {
  res.sendStatus(200);
  // Process messages...
});
```

## Resources

- [Meta WhatsApp Cloud API](https://developers.facebook.com/docs/whatsapp/cloud-api)
- [Message Templates](https://developers.facebook.com/docs/whatsapp/message-templates)
- [Webhooks Reference](https://developers.facebook.com/docs/whatsapp/cloud-api/webhooks)
