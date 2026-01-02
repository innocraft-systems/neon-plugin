---
name: kopokopo
description: This skill provides guidance for integrating Kopokopo (K2 Connect) payment APIs. Use when the user asks about "Kopokopo", "K2 Connect", "Kopo Kopo API", "buy goods payments", "till payments Kenya", "M-Pesa STK push via Kopokopo", "PAY recipients", or needs help with Kopokopo webhooks, settlement transfers, or mobile wallet payments.
---

# Kopokopo (K2 Connect) Integration

Kopokopo K2 Connect API enables M-Pesa payment integration for buy goods transactions, disbursements, and settlement transfers in Kenya.

## Base URLs

| Environment | URL |
|-------------|-----|
| Sandbox | `https://sandbox.kopokopo.com` |
| Production | `https://api.kopokopo.com` |

## Authentication

Kopokopo uses OAuth 2.0 client credentials flow.

### Get Access Token

```bash
POST /oauth/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&client_id={CLIENT_ID}&client_secret={CLIENT_SECRET}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600
}
```

Use the token in subsequent requests:
```
Authorization: Bearer {access_token}
```

## Receive Payments (STK Push)

Initiate M-Pesa STK push to collect payments from customers.

### Create Payment Request

```bash
POST /api/v1/incoming_payments
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "payment_channel": "M-PESA STK Push",
  "till_number": "K123456",
  "subscriber": {
    "first_name": "John",
    "last_name": "Doe",
    "phone_number": "+254712345678",
    "email": "john@example.com"
  },
  "amount": {
    "currency": "KES",
    "value": "1000"
  },
  "metadata": {
    "order_id": "ORD-12345"
  },
  "callback_url": "https://yourapp.com/webhooks/kopokopo"
}
```

**Response (202 Accepted):**
```
Location: https://sandbox.kopokopo.com/api/v1/incoming_payments/abc123
```

### Query Payment Status

```bash
GET /api/v1/incoming_payments/{id}
Authorization: Bearer {access_token}
```

## Send Money (PAY)

### Step 1: Add PAY Recipient

#### Mobile Wallet Recipient

```bash
POST /api/v1/pay_recipients
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "type": "mobile_wallet",
  "first_name": "Jane",
  "last_name": "Doe",
  "email": "jane@example.com",
  "phone_number": "+254712345678",
  "network": "Safaricom"
}
```

**Response (201 Created):**
```
Location: https://sandbox.kopokopo.com/api/v1/pay_recipients/c7f300c0-f1ef-4151-9bbe-005005aa3747
```

#### Bank Account Recipient

```bash
POST /api/v1/pay_recipients
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "type": "bank_account",
  "account_name": "Jane Doe",
  "account_number": "1234567890",
  "bank_branch_ref": "branch-ref-id",
  "settlement_method": "EFT"
}
```

### Step 2: Create Payment

```bash
POST /api/v1/payments
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "destination_reference": "c7f300c0-f1ef-4151-9bbe-005005aa3747",
  "destination_type": "mobile_wallet",
  "amount": {
    "currency": "KES",
    "value": "5000"
  },
  "description": "Salary payment",
  "callback_url": "https://yourapp.com/webhooks/payment"
}
```

## Settlement Transfers

Transfer funds from Kopokopo to your bank account.

### Create Transfer

```bash
POST /api/v1/transfers
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "amount": {
    "currency": "KES",
    "value": "10000"
  },
  "destination_type": "merchant_bank_account",
  "destination_reference": "settlement-account-id",
  "callback_url": "https://yourapp.com/webhooks/transfer"
}
```

## Webhooks

### Subscription Setup

```bash
POST /api/v1/webhook_subscriptions
Content-Type: application/json
Authorization: Bearer {access_token}

{
  "event_type": "buygoods_transaction_received",
  "url": "https://yourapp.com/webhooks/kopokopo",
  "scope": "till",
  "scope_reference": "K123456"
}
```

### Event Types

| Event | Description |
|-------|-------------|
| `buygoods_transaction_received` | Payment received on till |
| `b2b_transaction_received` | B2B payment received |
| `merchant_to_merchant_received` | M2M transfer received |
| `settlement_transfer_completed` | Transfer to bank completed |
| `customer_created` | New customer registered |

### Webhook Payload Example

```json
{
  "topic": "buygoods_transaction_received",
  "id": "webhook-event-id",
  "created_at": "2024-01-15T10:30:00Z",
  "event": {
    "type": "Buygoods Transaction",
    "resource": {
      "id": "txn-123",
      "amount": "100.0",
      "currency": "KES",
      "status": "Received",
      "system": "Lipa Na M-PESA",
      "reference": "ABC123XYZ",
      "till_number": "K123456",
      "sender_phone_number": "+254712345678",
      "sender_first_name": "John",
      "sender_last_name": "Doe"
    }
  },
  "_links": {
    "self": "https://api.kopokopo.com/api/v1/webhook_events/webhook-event-id"
  }
}
```

### Signature Verification

Verify webhook authenticity using the `X-KopoKopo-Signature` header:

```javascript
const crypto = require('crypto');

function verifyWebhook(payload, signature, apiKey) {
  const expectedSignature = crypto
    .createHmac('sha256', apiKey)
    .update(JSON.stringify(payload))
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expectedSignature)
  );
}
```

## SDKs

| Language | Package |
|----------|---------|
| Node.js | `k2-connect-node` |
| Python | `k2-connect-python` |
| Ruby | `k2-connect-ruby` |
| PHP | `kopokopo/k2-connect-php` |
| Flutter/Dart | `k2-connect-flutter` |

### Node.js Example

```javascript
const K2 = require('k2-connect-node');

const options = {
  clientId: process.env.KOPOKOPO_CLIENT_ID,
  clientSecret: process.env.KOPOKOPO_CLIENT_SECRET,
  apiKey: process.env.KOPOKOPO_API_KEY,
  baseUrl: 'https://sandbox.kopokopo.com'
};

const k2 = new K2(options);

// Get access token
const tokenService = k2.TokenService;
const { access_token } = await tokenService.getToken();

// STK Push
const stkService = k2.StkService;
stkService.setAccessToken(access_token);

const stkOptions = {
  tillNumber: 'K123456',
  firstName: 'John',
  lastName: 'Doe',
  phoneNumber: '+254712345678',
  email: 'john@example.com',
  currency: 'KES',
  amount: 1000,
  callbackUrl: 'https://yourapp.com/webhook',
  metadata: { orderId: 'ORD-123' }
};

const response = await stkService.initiateIncomingPayment(stkOptions);
```

### Python Example

```python
from k2connect import K2

k2 = K2(
    client_id=os.environ['KOPOKOPO_CLIENT_ID'],
    client_secret=os.environ['KOPOKOPO_CLIENT_SECRET'],
    api_key=os.environ['KOPOKOPO_API_KEY'],
    base_url='https://sandbox.kopokopo.com'
)

# Get token
token_service = k2.TokenService
access_token = token_service.get_access_token()

# STK Push
stk_service = k2.StkService
stk_service.set_access_token(access_token)

response = stk_service.receive_mpesa_payments(
    till_number='K123456',
    first_name='John',
    last_name='Doe',
    phone='+254712345678',
    email='john@example.com',
    amount='1000',
    currency='KES',
    callback_url='https://yourapp.com/webhook'
)
```

## Test Credentials

Get sandbox credentials at: https://sandbox.kopokopo.com

Contact: api-support@kopokopo.com

## Resources

- **Developer Portal**: https://developers.kopokopo.com/
- **API Reference**: https://api-docs.kopokopo.com/
- **Postman Collection**: Available in developer portal
