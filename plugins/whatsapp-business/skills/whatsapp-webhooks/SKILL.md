---
name: whatsapp-webhooks
description: This skill provides guidance for WhatsApp webhook integration. Use when the user asks about "WhatsApp webhook", "receive WhatsApp message", "WhatsApp callback", "message status", "delivery receipt", "read receipt", or needs help setting up webhook endpoints to receive messages and notifications.
---

# WhatsApp Webhooks

Webhooks allow your application to receive incoming messages and delivery status updates. This guide covers setup, verification, and handling webhook events.

## Webhook Setup

### 1. Configure in Meta App Dashboard

1. Go to your app in developers.facebook.com
2. WhatsApp > Configuration > Webhooks
3. Set Callback URL and Verify Token
4. Subscribe to webhook fields

### 2. Required Endpoint

Your server needs two capabilities:

| Method | Purpose |
|--------|---------|
| GET | Webhook verification (one-time) |
| POST | Receive events |

## Webhook Verification

Meta verifies your endpoint ownership:

```bash
GET /webhook?hub.mode=subscribe&hub.verify_token={YOUR_VERIFY_TOKEN}&hub.challenge={CHALLENGE}
```

Your server must:
1. Check `hub.mode` equals "subscribe"
2. Verify `hub.verify_token` matches your token
3. Return `hub.challenge` as plain text

### Node.js Verification

```typescript
import express from 'express';

const app = express();
const VERIFY_TOKEN = process.env.WHATSAPP_VERIFY_TOKEN!;

// Webhook verification (GET)
app.get('/webhook', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode === 'subscribe' && token === VERIFY_TOKEN) {
    console.log('Webhook verified');
    res.status(200).send(challenge);
  } else {
    console.error('Webhook verification failed');
    res.sendStatus(403);
  }
});
```

## Receiving Messages

### Webhook Payload Structure

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "WHATSAPP_BUSINESS_ACCOUNT_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "254712345678",
              "phone_number_id": "PHONE_NUMBER_ID"
            },
            "contacts": [
              {
                "profile": { "name": "Martin" },
                "wa_id": "254712345678"
              }
            ],
            "messages": [
              {
                "from": "254712345678",
                "id": "wamid.HBgLMjU0...",
                "timestamp": "1705320000",
                "type": "text",
                "text": { "body": "Hello, is the Samsung A54 available?" }
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

### Message Types

#### Text Message

```json
{
  "type": "text",
  "text": {
    "body": "Hello, I want to order a phone"
  }
}
```

#### Image Message

```json
{
  "type": "image",
  "image": {
    "mime_type": "image/jpeg",
    "sha256": "abc123...",
    "id": "MEDIA_ID"
  }
}
```

#### Document Message

```json
{
  "type": "document",
  "document": {
    "mime_type": "application/pdf",
    "sha256": "abc123...",
    "id": "MEDIA_ID",
    "filename": "receipt.pdf"
  }
}
```

#### Location Message

```json
{
  "type": "location",
  "location": {
    "latitude": -1.2921,
    "longitude": 36.8219,
    "name": "Customer Location",
    "address": "Nairobi, Kenya"
  }
}
```

#### Interactive Reply (Button)

```json
{
  "type": "interactive",
  "interactive": {
    "type": "button_reply",
    "button_reply": {
      "id": "pickup",
      "title": "Pick Up"
    }
  }
}
```

#### Interactive Reply (List)

```json
{
  "type": "interactive",
  "interactive": {
    "type": "list_reply",
    "list_reply": {
      "id": "samsung-a54",
      "title": "Samsung A54",
      "description": "KES 45,000"
    }
  }
}
```

## Status Updates

### Delivery Status Payload

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "id": "WABA_ID",
      "changes": [
        {
          "value": {
            "messaging_product": "whatsapp",
            "metadata": {
              "display_phone_number": "254712345678",
              "phone_number_id": "PHONE_NUMBER_ID"
            },
            "statuses": [
              {
                "id": "wamid.HBgLMjU0...",
                "status": "delivered",
                "timestamp": "1705320100",
                "recipient_id": "254712345678"
              }
            ]
          },
          "field": "messages"
        }
      ]
    }
  ]
}
```

### Status Types

| Status | Meaning |
|--------|---------|
| sent | Message sent to WhatsApp servers |
| delivered | Delivered to recipient's device |
| read | Recipient opened the message |
| failed | Delivery failed |

### Failed Status with Error

```json
{
  "statuses": [
    {
      "id": "wamid.HBgLMjU0...",
      "status": "failed",
      "timestamp": "1705320100",
      "recipient_id": "254712345678",
      "errors": [
        {
          "code": 131047,
          "title": "Re-engagement message",
          "message": "More than 24 hours have passed since the customer last replied"
        }
      ]
    }
  ]
}
```

## Node.js Implementation

```typescript
import express from 'express';
import crypto from 'crypto';

const app = express();
app.use(express.json());

const VERIFY_TOKEN = process.env.WHATSAPP_VERIFY_TOKEN!;
const APP_SECRET = process.env.WHATSAPP_APP_SECRET!;

// Verify webhook signature
function verifySignature(req: express.Request): boolean {
  const signature = req.headers['x-hub-signature-256'] as string;
  if (!signature) return false;

  const expectedSignature = crypto
    .createHmac('sha256', APP_SECRET)
    .update(JSON.stringify(req.body))
    .digest('hex');

  return signature === `sha256=${expectedSignature}`;
}

// Webhook verification
app.get('/webhook', (req, res) => {
  const mode = req.query['hub.mode'];
  const token = req.query['hub.verify_token'];
  const challenge = req.query['hub.challenge'];

  if (mode === 'subscribe' && token === VERIFY_TOKEN) {
    res.status(200).send(challenge);
  } else {
    res.sendStatus(403);
  }
});

// Webhook handler
app.post('/webhook', async (req, res) => {
  // Verify signature
  if (!verifySignature(req)) {
    console.error('Invalid signature');
    return res.sendStatus(401);
  }

  // Always respond 200 quickly
  res.sendStatus(200);

  // Process webhook asynchronously
  try {
    const body = req.body;

    if (body.object !== 'whatsapp_business_account') {
      return;
    }

    for (const entry of body.entry) {
      for (const change of entry.changes) {
        const value = change.value;

        // Handle incoming messages
        if (value.messages) {
          for (const message of value.messages) {
            await handleIncomingMessage(message, value.contacts?.[0], value.metadata);
          }
        }

        // Handle status updates
        if (value.statuses) {
          for (const status of value.statuses) {
            await handleStatusUpdate(status);
          }
        }
      }
    }
  } catch (error) {
    console.error('Webhook processing error:', error);
  }
});

// Message handler
async function handleIncomingMessage(
  message: any,
  contact: any,
  metadata: any
) {
  const from = message.from;
  const messageId = message.id;
  const timestamp = new Date(parseInt(message.timestamp) * 1000);
  const customerName = contact?.profile?.name || 'Customer';

  console.log(`Message from ${customerName} (${from}):`, message.type);

  // Update messaging window timestamp
  await updateCustomerLastMessage(from, timestamp);

  // Mark as read
  await markMessageAsRead(metadata.phone_number_id, messageId);

  switch (message.type) {
    case 'text':
      await handleTextMessage(from, message.text.body, customerName);
      break;

    case 'image':
    case 'document':
    case 'video':
    case 'audio':
      await handleMediaMessage(from, message.type, message[message.type]);
      break;

    case 'location':
      await handleLocationMessage(from, message.location);
      break;

    case 'interactive':
      await handleInteractiveReply(from, message.interactive);
      break;

    case 'button':
      // Quick reply button response
      await handleButtonReply(from, message.button);
      break;

    default:
      console.log('Unhandled message type:', message.type);
  }
}

// Text message handler
async function handleTextMessage(
  from: string,
  text: string,
  customerName: string
) {
  const lowerText = text.toLowerCase();

  // Simple keyword routing
  if (lowerText.includes('price') || lowerText.includes('bei')) {
    await sendPriceList(from);
  } else if (lowerText.includes('order') || lowerText.includes('buy')) {
    await sendOrderOptions(from);
  } else if (lowerText.includes('location') || lowerText.includes('directions')) {
    await sendShopLocation(from);
  } else if (lowerText.includes('help') || lowerText.includes('msaada')) {
    await sendHelpMenu(from);
  } else {
    // Default response or forward to human
    await sendDefaultResponse(from, customerName);
  }
}

// Interactive reply handler
async function handleInteractiveReply(from: string, interactive: any) {
  if (interactive.type === 'button_reply') {
    const buttonId = interactive.button_reply.id;
    console.log(`Button clicked: ${buttonId}`);

    switch (buttonId) {
      case 'pickup':
        await handlePickupSelection(from);
        break;
      case 'delivery':
        await handleDeliverySelection(from);
        break;
      case 'confirm_order':
        await handleOrderConfirmation(from);
        break;
    }
  } else if (interactive.type === 'list_reply') {
    const itemId = interactive.list_reply.id;
    console.log(`List item selected: ${itemId}`);
    await handleProductSelection(from, itemId);
  }
}

// Status update handler
async function handleStatusUpdate(status: any) {
  const messageId = status.id;
  const newStatus = status.status;
  const recipientId = status.recipient_id;

  console.log(`Message ${messageId} to ${recipientId}: ${newStatus}`);

  // Update message status in database
  await updateMessageStatus(messageId, newStatus);

  if (newStatus === 'failed') {
    const errorCode = status.errors?.[0]?.code;
    console.error(`Delivery failed: ${errorCode}`);

    // Handle specific failures
    if (errorCode === 131047) {
      // Outside 24h window - need template
      await markCustomerNeedsReengagement(recipientId);
    }
  }
}

// Helper: Mark message as read
async function markMessageAsRead(phoneNumberId: string, messageId: string) {
  try {
    await whatsappClient.markAsRead(messageId);
  } catch (error) {
    console.error('Failed to mark as read:', error);
  }
}

app.listen(3000, () => {
  console.log('Webhook server running on port 3000');
});
```

## Download Media

When receiving media messages, download the content:

```typescript
// Get media URL
async function getMediaUrl(mediaId: string): Promise<string> {
  const response = await axios.get(
    `https://graph.facebook.com/v21.0/${mediaId}`,
    {
      headers: { Authorization: `Bearer ${ACCESS_TOKEN}` },
    }
  );
  return response.data.url;
}

// Download media
async function downloadMedia(mediaId: string): Promise<Buffer> {
  const mediaUrl = await getMediaUrl(mediaId);

  const response = await axios.get(mediaUrl, {
    headers: { Authorization: `Bearer ${ACCESS_TOKEN}` },
    responseType: 'arraybuffer',
  });

  return Buffer.from(response.data);
}

// Handle media message
async function handleMediaMessage(
  from: string,
  type: string,
  media: { id: string; mime_type: string; filename?: string }
) {
  console.log(`Received ${type} from ${from}`);

  // Download media
  const buffer = await downloadMedia(media.id);

  // Save to storage
  const filename = media.filename || `${media.id}.${getExtension(media.mime_type)}`;
  await saveToStorage(buffer, filename);

  // Send acknowledgment
  await whatsappClient.sendText(
    from,
    `Received your ${type}. We'll review it shortly.`
  );
}
```

## Multi-Tenant Routing

For SaaS platforms with multiple businesses:

```typescript
interface TenantConfig {
  tenantId: string;
  phoneNumberId: string;
  wabaId: string;
}

// Map phone number IDs to tenants
const tenantMap = new Map<string, TenantConfig>();

async function routeToTenant(metadata: { phone_number_id: string }) {
  const tenant = tenantMap.get(metadata.phone_number_id);

  if (!tenant) {
    console.error('Unknown phone number ID:', metadata.phone_number_id);
    return null;
  }

  return tenant;
}

// In webhook handler
app.post('/webhook', async (req, res) => {
  res.sendStatus(200);

  for (const entry of req.body.entry) {
    for (const change of entry.changes) {
      const metadata = change.value.metadata;
      const tenant = await routeToTenant(metadata);

      if (tenant) {
        // Process for specific tenant
        await processForTenant(tenant, change.value);
      }
    }
  }
});
```

## Webhook Security

### 1. Verify Signature

Always verify the X-Hub-Signature-256 header:

```typescript
function verifyWebhookSignature(
  payload: string,
  signature: string,
  appSecret: string
): boolean {
  const expectedSig = crypto
    .createHmac('sha256', appSecret)
    .update(payload)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature.replace('sha256=', '')),
    Buffer.from(expectedSig)
  );
}
```

### 2. Use HTTPS

Meta requires HTTPS with valid SSL certificate.

### 3. Respond Quickly

Return 200 within 20 seconds or Meta will retry.

```typescript
app.post('/webhook', (req, res) => {
  // Respond immediately
  res.sendStatus(200);

  // Process async
  processWebhookAsync(req.body).catch(console.error);
});
```

## Webhook Fields

Subscribe to these fields in Meta dashboard:

| Field | Events |
|-------|--------|
| messages | Incoming messages, status updates |
| message_template_status_update | Template approval changes |
| account_alerts | Account issues |
| account_review_update | Business verification |
| phone_number_name_update | Display name changes |
| phone_number_quality_update | Quality rating changes |

## Testing Webhooks

### Local Development

Use ngrok for local testing:

```bash
ngrok http 3000
# Use the HTTPS URL in Meta webhook config
```

### Test Payload

```typescript
// Simulate incoming message
const testPayload = {
  object: 'whatsapp_business_account',
  entry: [{
    id: 'WABA_ID',
    changes: [{
      value: {
        messaging_product: 'whatsapp',
        metadata: {
          display_phone_number: '254712345678',
          phone_number_id: 'PHONE_NUMBER_ID',
        },
        contacts: [{
          profile: { name: 'Test Customer' },
          wa_id: '254700000000',
        }],
        messages: [{
          from: '254700000000',
          id: 'wamid.test123',
          timestamp: String(Math.floor(Date.now() / 1000)),
          type: 'text',
          text: { body: 'Hello, test message' },
        }],
      },
      field: 'messages',
    }],
  }],
};
```

## Error Handling

```typescript
app.post('/webhook', async (req, res) => {
  // Always respond 200 to prevent retries
  res.sendStatus(200);

  try {
    await processWebhook(req.body);
  } catch (error) {
    // Log but don't fail
    console.error('Webhook error:', error);

    // Send alert to monitoring
    await alertOps('WhatsApp webhook error', error);

    // Queue for retry if critical
    if (isCriticalMessage(req.body)) {
      await queueForRetry(req.body);
    }
  }
});
```

## Best Practices

1. **Respond fast** - Return 200 immediately, process async
2. **Verify signatures** - Always validate X-Hub-Signature-256
3. **Deduplicate** - Messages may be retried; use message ID
4. **Handle all types** - Don't ignore unknown message types
5. **Track window** - Update 24h window on every message
6. **Mark as read** - Show customers their messages were received
7. **Queue heavy work** - Use job queue for slow operations
