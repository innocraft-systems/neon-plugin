---
name: whatsapp-templates
description: This skill provides guidance for WhatsApp message templates. Use when the user asks about "WhatsApp template", "template message", "HSM", "message template approval", "template variables", "WhatsApp broadcast", "bulk WhatsApp", or needs help creating, submitting, or sending template messages.
---

# WhatsApp Message Templates

Templates are pre-approved message formats required for initiating conversations outside the 24-hour window. This guide covers creating, submitting, and sending templates.

## Why Templates?

| Scenario | Message Type Allowed |
|----------|---------------------|
| Customer messaged within 24h | Any message |
| No customer message in 24h+ | **Template only** |
| Bulk notifications | **Template only** |
| Marketing campaigns | **Template only** |

## Template Categories

| Category | Use Case | Approval Time |
|----------|----------|---------------|
| UTILITY | Order updates, receipts, shipping | Fast (hours) |
| AUTHENTICATION | OTP, verification codes | Fast (hours) |
| MARKETING | Promotions, offers, newsletters | Slower (days) |

## Creating Templates

### Via API

```bash
POST /{WABA_ID}/message_templates
Content-Type: application/json
Authorization: Bearer {ACCESS_TOKEN}

{
  "name": "order_confirmation",
  "language": "en",
  "category": "UTILITY",
  "components": [
    {
      "type": "HEADER",
      "format": "TEXT",
      "text": "Order Confirmed!"
    },
    {
      "type": "BODY",
      "text": "Hi {{1}}, your order #{{2}} has been confirmed.\n\nTotal: KES {{3}}\n\nWe'll notify you when it's ready for pickup.",
      "example": {
        "body_text": [
          ["Martin", "12345", "4,500"]
        ]
      }
    },
    {
      "type": "FOOTER",
      "text": "Thank you for shopping with us"
    },
    {
      "type": "BUTTONS",
      "buttons": [
        {
          "type": "URL",
          "text": "Track Order",
          "url": "https://shop.example.com/track/{{1}}",
          "example": ["12345"]
        },
        {
          "type": "PHONE_NUMBER",
          "text": "Call Support",
          "phone_number": "+254712345678"
        }
      ]
    }
  ]
}
```

### Response

```json
{
  "id": "123456789012345",
  "status": "PENDING",
  "category": "UTILITY"
}
```

## Template Components

### Header Types

```json
// Text header
{
  "type": "HEADER",
  "format": "TEXT",
  "text": "Order Update"
}

// Image header
{
  "type": "HEADER",
  "format": "IMAGE",
  "example": {
    "header_handle": ["https://example.com/product.jpg"]
  }
}

// Document header
{
  "type": "HEADER",
  "format": "DOCUMENT",
  "example": {
    "header_handle": ["https://example.com/receipt.pdf"]
  }
}

// Video header
{
  "type": "HEADER",
  "format": "VIDEO",
  "example": {
    "header_handle": ["https://example.com/promo.mp4"]
  }
}
```

### Body with Variables

Variables use `{{1}}`, `{{2}}`, etc.:

```json
{
  "type": "BODY",
  "text": "Hi {{1}}, your payment of KES {{2}} was received on {{3}}. Reference: {{4}}",
  "example": {
    "body_text": [
      ["John", "5,000", "Jan 15, 2024", "PAY123456"]
    ]
  }
}
```

### Button Types

```json
// Quick reply buttons
{
  "type": "BUTTONS",
  "buttons": [
    {
      "type": "QUICK_REPLY",
      "text": "Confirm"
    },
    {
      "type": "QUICK_REPLY",
      "text": "Cancel"
    }
  ]
}

// URL button with variable
{
  "type": "BUTTONS",
  "buttons": [
    {
      "type": "URL",
      "text": "View Receipt",
      "url": "https://shop.example.com/receipts/{{1}}",
      "example": ["RCP12345"]
    }
  ]
}

// Call button
{
  "type": "BUTTONS",
  "buttons": [
    {
      "type": "PHONE_NUMBER",
      "text": "Call Us",
      "phone_number": "+254712345678"
    }
  ]
}
```

## Common Templates for Kenyan Businesses

### Order Confirmation

```json
{
  "name": "order_confirmed_ke",
  "language": "en",
  "category": "UTILITY",
  "components": [
    {
      "type": "BODY",
      "text": "Habari {{1}}! Your order #{{2}} is confirmed.\n\nItems: {{3}}\nTotal: KES {{4}}\n\nPay via M-Pesa Till {{5}} or pick up and pay.\n\nAsante sana!",
      "example": {
        "body_text": [["Martin", "ORD001", "Samsung A54 x1", "45,000", "123456"]]
      }
    },
    {
      "type": "BUTTONS",
      "buttons": [
        {
          "type": "QUICK_REPLY",
          "text": "Track Order"
        }
      ]
    }
  ]
}
```

### Payment Received

```json
{
  "name": "payment_received_mpesa",
  "language": "en",
  "category": "UTILITY",
  "components": [
    {
      "type": "BODY",
      "text": "Payment Confirmed!\n\nHi {{1}}, we received KES {{2}} via M-Pesa.\n\nTransaction: {{3}}\nOrder: #{{4}}\n\nYour order is being processed.",
      "example": {
        "body_text": [["John", "4,500", "SHK12345678", "ORD001"]]
      }
    }
  ]
}
```

### Delivery Update

```json
{
  "name": "delivery_update_ke",
  "language": "en",
  "category": "UTILITY",
  "components": [
    {
      "type": "BODY",
      "text": "Delivery Update\n\nHi {{1}}, your order #{{2}} is {{3}}.\n\n{{4}}\n\nDelivery: {{5}}",
      "example": {
        "body_text": [
          ["Martin", "ORD001", "out for delivery", "Driver: John - 0712345678", "Today by 5pm"]
        ]
      }
    },
    {
      "type": "BUTTONS",
      "buttons": [
        {
          "type": "PHONE_NUMBER",
          "text": "Call Driver",
          "phone_number": "+254712345678"
        }
      ]
    }
  ]
}
```

### OTP/Verification

```json
{
  "name": "otp_verification",
  "language": "en",
  "category": "AUTHENTICATION",
  "components": [
    {
      "type": "BODY",
      "text": "Your verification code is {{1}}. Valid for 10 minutes. Do not share this code."
    },
    {
      "type": "BUTTONS",
      "buttons": [
        {
          "type": "OTP",
          "otp_type": "COPY_CODE",
          "text": "Copy Code"
        }
      ]
    }
  ]
}
```

### Promotional (Marketing)

```json
{
  "name": "weekend_sale_promo",
  "language": "en",
  "category": "MARKETING",
  "components": [
    {
      "type": "HEADER",
      "format": "IMAGE"
    },
    {
      "type": "BODY",
      "text": "Weekend Flash Sale!\n\nHi {{1}}, enjoy up to {{2}}% off on selected items this weekend only!\n\nOffer ends {{3}}.\n\nVisit our shop or order online.",
      "example": {
        "body_text": [["Martin", "30", "Sunday 8pm"]]
      }
    },
    {
      "type": "BUTTONS",
      "buttons": [
        {
          "type": "URL",
          "text": "Shop Now",
          "url": "https://shop.example.com/sale"
        },
        {
          "type": "QUICK_REPLY",
          "text": "Unsubscribe"
        }
      ]
    }
  ]
}
```

## Sending Template Messages

```bash
POST /{PHONE_NUMBER_ID}/messages
Content-Type: application/json
Authorization: Bearer {ACCESS_TOKEN}

{
  "messaging_product": "whatsapp",
  "to": "254712345678",
  "type": "template",
  "template": {
    "name": "order_confirmed_ke",
    "language": {
      "code": "en"
    },
    "components": [
      {
        "type": "body",
        "parameters": [
          { "type": "text", "text": "Martin" },
          { "type": "text", "text": "ORD001" },
          { "type": "text", "text": "Samsung A54 x1" },
          { "type": "text", "text": "45,000" },
          { "type": "text", "text": "123456" }
        ]
      }
    ]
  }
}
```

### With Image Header

```json
{
  "messaging_product": "whatsapp",
  "to": "254712345678",
  "type": "template",
  "template": {
    "name": "weekend_sale_promo",
    "language": { "code": "en" },
    "components": [
      {
        "type": "header",
        "parameters": [
          {
            "type": "image",
            "image": {
              "link": "https://shop.example.com/promo-banner.jpg"
            }
          }
        ]
      },
      {
        "type": "body",
        "parameters": [
          { "type": "text", "text": "Martin" },
          { "type": "text", "text": "30" },
          { "type": "text", "text": "Sunday 8pm" }
        ]
      }
    ]
  }
}
```

### With URL Button Variable

```json
{
  "messaging_product": "whatsapp",
  "to": "254712345678",
  "type": "template",
  "template": {
    "name": "order_confirmation",
    "language": { "code": "en" },
    "components": [
      {
        "type": "body",
        "parameters": [
          { "type": "text", "text": "Martin" },
          { "type": "text", "text": "12345" },
          { "type": "text", "text": "4,500" }
        ]
      },
      {
        "type": "button",
        "sub_type": "url",
        "index": "0",
        "parameters": [
          { "type": "text", "text": "12345" }
        ]
      }
    ]
  }
}
```

## Node.js Implementation

```typescript
interface TemplateParameter {
  type: 'text' | 'currency' | 'date_time' | 'image' | 'document' | 'video';
  text?: string;
  currency?: { fallback_value: string; code: string; amount_1000: number };
  date_time?: { fallback_value: string };
  image?: { link: string };
  document?: { link: string; filename?: string };
  video?: { link: string };
}

interface TemplateComponent {
  type: 'header' | 'body' | 'button';
  sub_type?: 'url' | 'quick_reply';
  index?: string;
  parameters: TemplateParameter[];
}

class WhatsAppTemplates {
  private client: WhatsAppClient;

  constructor(client: WhatsAppClient) {
    this.client = client;
  }

  // Send template message
  async send(
    to: string,
    templateName: string,
    languageCode: string,
    components?: TemplateComponent[]
  ) {
    return this.client.sendTemplate(to, {
      name: templateName,
      language: { code: languageCode },
      components,
    });
  }

  // Order confirmation
  async sendOrderConfirmation(
    to: string,
    customerName: string,
    orderId: string,
    items: string,
    total: string,
    tillNumber: string
  ) {
    return this.send(to, 'order_confirmed_ke', 'en', [
      {
        type: 'body',
        parameters: [
          { type: 'text', text: customerName },
          { type: 'text', text: orderId },
          { type: 'text', text: items },
          { type: 'text', text: total },
          { type: 'text', text: tillNumber },
        ],
      },
    ]);
  }

  // Payment received
  async sendPaymentReceived(
    to: string,
    customerName: string,
    amount: string,
    transactionId: string,
    orderId: string
  ) {
    return this.send(to, 'payment_received_mpesa', 'en', [
      {
        type: 'body',
        parameters: [
          { type: 'text', text: customerName },
          { type: 'text', text: amount },
          { type: 'text', text: transactionId },
          { type: 'text', text: orderId },
        ],
      },
    ]);
  }

  // Delivery update
  async sendDeliveryUpdate(
    to: string,
    customerName: string,
    orderId: string,
    status: string,
    details: string,
    eta: string
  ) {
    return this.send(to, 'delivery_update_ke', 'en', [
      {
        type: 'body',
        parameters: [
          { type: 'text', text: customerName },
          { type: 'text', text: orderId },
          { type: 'text', text: status },
          { type: 'text', text: details },
          { type: 'text', text: eta },
        ],
      },
    ]);
  }

  // OTP code
  async sendOTP(to: string, code: string) {
    return this.send(to, 'otp_verification', 'en', [
      {
        type: 'body',
        parameters: [{ type: 'text', text: code }],
      },
    ]);
  }

  // Marketing with image
  async sendPromotion(
    to: string,
    imageUrl: string,
    customerName: string,
    discount: string,
    expiresAt: string
  ) {
    return this.send(to, 'weekend_sale_promo', 'en', [
      {
        type: 'header',
        parameters: [{ type: 'image', image: { link: imageUrl } }],
      },
      {
        type: 'body',
        parameters: [
          { type: 'text', text: customerName },
          { type: 'text', text: discount },
          { type: 'text', text: expiresAt },
        ],
      },
    ]);
  }
}

// Usage
const templates = new WhatsAppTemplates(whatsappClient);

// Send order confirmation
await templates.sendOrderConfirmation(
  '254712345678',
  'Martin',
  'ORD001',
  'Samsung A54 x1, Phone Case x2',
  '47,000',
  '123456'
);

// Send payment confirmation
await templates.sendPaymentReceived(
  '254712345678',
  'Martin',
  '47,000',
  'SHK123456789',
  'ORD001'
);
```

## Template Status

| Status | Meaning |
|--------|---------|
| PENDING | Under review |
| APPROVED | Ready to use |
| REJECTED | Failed review (see reason) |
| PAUSED | Quality issues |
| DISABLED | Permanently disabled |

### Check Template Status

```bash
GET /{WABA_ID}/message_templates?name=order_confirmed_ke
Authorization: Bearer {ACCESS_TOKEN}
```

## Quality Rating

Templates have quality ratings affecting deliverability:

| Rating | Status | Action |
|--------|--------|--------|
| Green | High quality | None |
| Yellow | Medium quality | Monitor feedback |
| Red | Low quality | Improve or risk pause |

**Tips for high quality:**
1. Don't send to users who haven't opted in
2. Include opt-out option in marketing
3. Keep content relevant and valuable
4. Don't exceed user expectations on frequency

## Rejection Reasons

| Reason | Fix |
|--------|-----|
| Variable mismatch | Ensure example matches placeholders |
| Promotional in UTILITY | Change category to MARKETING |
| Missing opt-out | Add unsubscribe button for marketing |
| Policy violation | Review Meta commerce policies |
| Low quality samples | Provide realistic examples |

## Bulk Messaging

```typescript
// Broadcast to multiple recipients
async function broadcastTemplate(
  whatsapp: WhatsAppClient,
  templateName: string,
  recipients: Array<{ phone: string; params: string[] }>
) {
  const results = [];

  for (const recipient of recipients) {
    try {
      const result = await whatsapp.sendTemplate(recipient.phone, {
        name: templateName,
        language: { code: 'en' },
        components: [{
          type: 'body',
          parameters: recipient.params.map(p => ({ type: 'text', text: p })),
        }],
      });
      results.push({ phone: recipient.phone, success: true, messageId: result.messages[0].id });
    } catch (error) {
      results.push({ phone: recipient.phone, success: false, error });
    }

    // Rate limit: ~80 messages/second max
    await sleep(15);
  }

  return results;
}
```

## Best Practices

1. **Use UTILITY** for transactional - faster approval
2. **Test in sandbox** before production
3. **Provide clear examples** - speeds up approval
4. **Keep it concise** - WhatsApp limits character counts
5. **Localize** - Create templates in local languages (Swahili)
6. **Track opt-ins** - Only message consenting users
