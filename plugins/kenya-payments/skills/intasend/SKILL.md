---
name: intasend
description: This skill provides guidance for integrating Intasend payment gateway APIs. Use when the user asks about "Intasend", "Intasend API", "PesaLink API", "bank payouts Kenya", "payment gateway Kenya", "M-Pesa B2C Intasend", "wallet as a service", "checkout API", or needs help with Intasend authentication, STK push, disbursements, or webhooks.
---

# Intasend Payment Gateway Integration

Intasend is a Kenyan payment gateway supporting M-Pesa, cards (Visa/Mastercard), Bitcoin, Google Pay, Apple Pay, and bank transfers (PesaLink).

## Base URLs

| Environment | URL |
|-------------|-----|
| Sandbox | `https://sandbox.intasend.com` |
| Production | `https://payment.intasend.com` |

## Authentication

Intasend uses API keys for authentication.

### Key Types

| Type | Prefix | Usage |
|------|--------|-------|
| Publishable | `ISPubKey_` | Frontend/client-side |
| Secret | `ISSecretKey_` | Backend only |

Keys contain environment indicator:
- `test` = Sandbox
- `live` = Production

### API Key Usage

```bash
POST https://payment.intasend.com/api/v1/{endpoint}
Authorization: Bearer {ISSecretKey_xxx}
Content-Type: application/json
```

Get API keys:
- Sandbox: https://sandbox.intasend.com/account/api-keys/
- Production: https://payment.intasend.com/account/api-keys/

## Payment Collection

### Checkout Link API

Create a payment link for customers.

```bash
POST /api/v1/checkout/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "public_key": "ISPubKey_test_xxx",
  "currency": "KES",
  "amount": 1000,
  "email": "customer@example.com",
  "first_name": "John",
  "last_name": "Doe",
  "phone_number": "254712345678",
  "api_ref": "ORDER-12345",
  "redirect_url": "https://yourapp.com/payment/success",
  "comment": "Payment for Order #12345"
}
```

**Response:**
```json
{
  "id": "checkout-id",
  "url": "https://payment.intasend.com/checkout/xxx/",
  "signature": "xxx",
  "created_at": "2024-01-15T10:30:00Z"
}
```

Redirect customer to `url` for payment.

### M-Pesa STK Push

Initiate M-Pesa payment prompt.

```bash
POST /api/v1/payment/mpesa-stk-push/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "amount": 1000,
  "phone_number": "254712345678",
  "api_ref": "ORDER-12345",
  "narrative": "Payment for order"
}
```

**Response:**
```json
{
  "invoice": {
    "invoice_id": "inv-123",
    "state": "PENDING",
    "provider": "M-PESA",
    "charges": "0",
    "net_amount": 1000,
    "currency": "KES",
    "value": "1000",
    "account": "254712345678",
    "api_ref": "ORDER-12345",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### Query Payment Status

```bash
GET /api/v1/payment/status/?invoice_id={invoice_id}
Authorization: Bearer {secret_key}
```

**Response:**
```json
{
  "invoice": {
    "invoice_id": "inv-123",
    "state": "COMPLETE",
    "provider": "M-PESA",
    "mpesa_reference": "ABC123XYZ",
    "charges": "10",
    "net_amount": 990,
    "currency": "KES",
    "value": "1000"
  }
}
```

### Payment States

| State | Description |
|-------|-------------|
| PENDING | Awaiting payment |
| PROCESSING | Payment in progress |
| COMPLETE | Payment successful |
| FAILED | Payment failed |

## Money Disbursement

### M-Pesa B2C (Send to Mobile)

```bash
POST /api/v1/send-money/mpesa/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "currency": "KES",
  "transactions": [
    {
      "name": "John Doe",
      "account": "254712345678",
      "amount": 1000,
      "narrative": "Salary payment"
    }
  ],
  "requires_approval": "NO"
}
```

**Response:**
```json
{
  "tracking_id": "track-123",
  "status": "Preview and approve",
  "transactions": [
    {
      "status": "Pending",
      "account": "254712345678",
      "amount": 1000,
      "charge": 22
    }
  ],
  "actual_amount": 1022,
  "charge_estimate": 22
}
```

### Approve Transfer

```bash
POST /api/v1/send-money/approve/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "tracking_id": "track-123"
}
```

### M-Pesa B2B (Send to Business)

```bash
POST /api/v1/send-money/mpesa-b2b/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "currency": "KES",
  "transactions": [
    {
      "name": "Business Name",
      "account": "123456",
      "account_type": "PayBill",
      "amount": 5000,
      "narrative": "Invoice payment",
      "account_reference": "INV-001"
    }
  ]
}
```

Account types: `PayBill`, `BuyGoods`, `TillNumber`

### Bank Payouts (PesaLink)

Get bank codes:

```bash
GET /api/v1/send-money/bank-codes/ke/
Authorization: Bearer {secret_key}
```

**Response:**
```json
{
  "banks": [
    { "code": "1", "name": "Kenya Commercial Bank" },
    { "code": "2", "name": "Standard Chartered" },
    { "code": "3", "name": "Barclays Bank Kenya" }
  ]
}
```

Create bank transfer:

```bash
POST /api/v1/send-money/bank/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "currency": "KES",
  "transactions": [
    {
      "name": "John Doe",
      "account": "1234567890",
      "bank_code": "1",
      "amount": 10000,
      "narrative": "Supplier payment"
    }
  ],
  "requires_approval": "NO"
}
```

Bank transfer limits: KES 100 - KES 999,999

## Wallet as a Service

Create and manage wallets for users.

### Create Wallet

```bash
POST /api/v1/wallets/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "currency": "KES",
  "label": "User Wallet",
  "can_disburse": true
}
```

### Fund Wallet

```bash
POST /api/v1/wallets/{wallet_id}/fund/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "amount": 5000,
  "narrative": "Wallet topup"
}
```

### Transfer Between Wallets

```bash
POST /api/v1/wallets/transfer/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "source_wallet_id": "wallet-1",
  "destination_wallet_id": "wallet-2",
  "amount": 1000,
  "narrative": "P2P transfer"
}
```

## Webhooks

### Setup

Configure webhooks in dashboard or via API.

### Event Types

| Category | Events |
|----------|--------|
| Collection | `COLLECTION.NEW`, `COLLECTION.COMPLETE`, `COLLECTION.FAILED` |
| Disbursement | `SEND_MONEY.NEW`, `SEND_MONEY.COMPLETE`, `SEND_MONEY.FAILED` |
| Chargeback | `CHARGEBACK.NEW`, `CHARGEBACK.RESOLVED` |
| Refund | `REFUND.NEW`, `REFUND.COMPLETE` |

### Webhook Payload

```json
{
  "event_type": "COLLECTION.COMPLETE",
  "invoice_id": "inv-123",
  "api_ref": "ORDER-12345",
  "state": "COMPLETE",
  "provider": "M-PESA",
  "value": "1000",
  "currency": "KES",
  "charges": "10",
  "net_amount": "990",
  "mpesa_reference": "ABC123XYZ",
  "account": "254712345678",
  "created_at": "2024-01-15T10:30:00Z"
}
```

### Webhook Security

Verify webhook signature from `X-IntaSend-Signature` header.

## Subscriptions

### Create Plan

```bash
POST /api/v1/subscriptions/plans/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "name": "Premium Plan",
  "amount": 1000,
  "currency": "KES",
  "interval": "MONTHLY",
  "interval_count": 1
}
```

### Create Subscription

```bash
POST /api/v1/subscriptions/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "plan_id": "plan-123",
  "customer_email": "customer@example.com",
  "customer_phone": "254712345678",
  "start_date": "2024-02-01"
}
```

## Refunds

```bash
POST /api/v1/refunds/
Authorization: Bearer {secret_key}
Content-Type: application/json

{
  "invoice_id": "inv-123",
  "amount": 500,
  "reason": "Customer request"
}
```

## Node.js Implementation

```javascript
const axios = require('axios');

class IntasendClient {
  constructor(publishableKey, secretKey, environment = 'sandbox') {
    this.publishableKey = publishableKey;
    this.secretKey = secretKey;
    this.baseUrl = environment === 'sandbox'
      ? 'https://sandbox.intasend.com'
      : 'https://payment.intasend.com';
  }

  async request(method, endpoint, data = null) {
    const config = {
      method,
      url: `${this.baseUrl}${endpoint}`,
      headers: {
        'Authorization': `Bearer ${this.secretKey}`,
        'Content-Type': 'application/json'
      }
    };

    if (data) config.data = data;

    const response = await axios(config);
    return response.data;
  }

  // Collection
  async createCheckout(options) {
    return this.request('POST', '/api/v1/checkout/', {
      public_key: this.publishableKey,
      ...options
    });
  }

  async stkPush(phoneNumber, amount, apiRef, narrative = '') {
    return this.request('POST', '/api/v1/payment/mpesa-stk-push/', {
      phone_number: phoneNumber,
      amount,
      api_ref: apiRef,
      narrative
    });
  }

  async getPaymentStatus(invoiceId) {
    return this.request('GET', `/api/v1/payment/status/?invoice_id=${invoiceId}`);
  }

  // Disbursement
  async sendToMobile(transactions, requiresApproval = 'NO') {
    return this.request('POST', '/api/v1/send-money/mpesa/', {
      currency: 'KES',
      transactions,
      requires_approval: requiresApproval
    });
  }

  async sendToBank(transactions, requiresApproval = 'NO') {
    return this.request('POST', '/api/v1/send-money/bank/', {
      currency: 'KES',
      transactions,
      requires_approval: requiresApproval
    });
  }

  async approveTransfer(trackingId) {
    return this.request('POST', '/api/v1/send-money/approve/', {
      tracking_id: trackingId
    });
  }

  async getBankCodes() {
    return this.request('GET', '/api/v1/send-money/bank-codes/ke/');
  }
}

// Usage
const intasend = new IntasendClient(
  process.env.INTASEND_PUBLISHABLE_KEY,
  process.env.INTASEND_SECRET_KEY,
  'sandbox'
);

// STK Push
const payment = await intasend.stkPush(
  '254712345678',
  1000,
  'ORDER-123',
  'Payment for order'
);

// Check status
const status = await intasend.getPaymentStatus(payment.invoice.invoice_id);

// Send money
const transfer = await intasend.sendToMobile([
  {
    name: 'John Doe',
    account: '254712345678',
    amount: 1000,
    narrative: 'Payment'
  }
]);
```

## Python SDK

```bash
pip install intasend-python
```

```python
from intasend import APIService

service = APIService(
    publishable_key='ISPubKey_test_xxx',
    token='ISSecretKey_test_xxx',
    test=True
)

# STK Push
response = service.collect.mpesa_stk_push(
    phone_number='254712345678',
    amount=1000,
    api_ref='ORDER-123',
    narrative='Payment'
)

# Bank transfer
response = service.transfer.bank(
    currency='KES',
    transactions=[{
        'name': 'John Doe',
        'account': '1234567890',
        'bank_code': '1',
        'amount': 10000,
        'narrative': 'Payment'
    }]
)
```

## SDKs

| Language | Package |
|----------|---------|
| Python | `intasend-python` |
| PHP | `intasend/intasend-php` |
| Node.js | `intasend-node` |

## Error Handling

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Phone number is required"
  }
}
```

Common error codes:
- `INVALID_REQUEST`
- `AUTHENTICATION_ERROR`
- `INSUFFICIENT_BALANCE`
- `RATE_LIMIT_EXCEEDED`

## Resources

- **Developer Portal**: https://developers.intasend.com/
- **API Reference**: https://developers.intasend.com/docs/introduction
- **Dashboard**: https://payment.intasend.com/
- **Sandbox**: https://sandbox.intasend.com/
