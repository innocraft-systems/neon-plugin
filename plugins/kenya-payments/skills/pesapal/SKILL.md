---
name: pesapal
description: This skill provides guidance for integrating Pesapal API 3.0 payment gateway. Use when the user asks about "Pesapal", "Pesapal API 3.0", "card payments Kenya", "multi-currency payments", "Pesapal IPN", "Pesapal webhooks", "payment redirect", or needs help with Pesapal authentication, order submission, or transaction status queries.
---

# Pesapal API 3.0 Integration

Pesapal provides a unified payment gateway supporting M-Pesa, cards (Visa/Mastercard), and mobile money across East Africa.

## Base URLs

| Environment | URL |
|-------------|-----|
| Sandbox | `https://cybqa.pesapal.com/pesapalv3` |
| Production | `https://pay.pesapal.com/v3` |

## Authentication

Pesapal uses JWT tokens for authentication.

### Get Access Token

```bash
POST /api/Auth/RequestToken
Content-Type: application/json
Accept: application/json

{
  "consumer_key": "your_consumer_key",
  "consumer_secret": "your_consumer_secret"
}
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiryDate": "2024-01-15T12:29:30.5177702Z",
  "error": null,
  "status": "200",
  "message": "Request processed successfully"
}
```

Token expires in **5 minutes**. Use as Bearer token:
```
Authorization: Bearer {token}
```

## Integration Flow

1. Get access token
2. Register IPN URL (one-time)
3. Submit order request
4. Redirect customer to payment page
5. Receive callback/IPN notification
6. Query transaction status

## Register IPN URL

Register webhook endpoint for payment notifications.

```bash
POST /api/URLSetup/RegisterIPN
Authorization: Bearer {token}
Content-Type: application/json

{
  "url": "https://yourapp.com/pesapal/ipn",
  "ipn_notification_type": "GET"
}
```

**Response:**
```json
{
  "url": "https://yourapp.com/pesapal/ipn",
  "created_date": "2024-01-15T07:50:22.2825997Z",
  "ipn_id": "84740ab4-3cd9-47da-8a4f-dd1db53494b5",
  "ipn_notification_type_description": "GET",
  "ipn_status": 1,
  "ipn_status_description": "Active",
  "error": null,
  "status": "200"
}
```

Save the `ipn_id` - required for order submissions.

### Get IPN List

```bash
GET /api/URLSetup/GetIpnList
Authorization: Bearer {token}
```

## Submit Order Request

Create a payment request.

```bash
POST /api/Transactions/SubmitOrderRequest
Authorization: Bearer {token}
Content-Type: application/json

{
  "id": "ORDER-12345",
  "currency": "KES",
  "amount": 1000.00,
  "description": "Payment for Order #12345",
  "callback_url": "https://yourapp.com/payment/callback",
  "notification_id": "84740ab4-3cd9-47da-8a4f-dd1db53494b5",
  "redirect_mode": "TOP_WINDOW",
  "cancellation_url": "https://yourapp.com/payment/cancelled",
  "branch": "Main Store",
  "billing_address": {
    "email_address": "customer@example.com",
    "phone_number": "0712345678",
    "country_code": "KE",
    "first_name": "John",
    "middle_name": "",
    "last_name": "Doe",
    "line_1": "123 Main Street",
    "line_2": "",
    "city": "Nairobi",
    "state": "Nairobi",
    "postal_code": "00100",
    "zip_code": ""
  }
}
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | String | Yes | Unique merchant order reference (max 50 chars) |
| currency | String | Yes | ISO currency code (KES, USD, etc.) |
| amount | Float | Yes | Payment amount |
| description | String | Yes | Order description (max 100 chars) |
| callback_url | String | Yes | Redirect URL after payment |
| notification_id | GUID | Yes | IPN URL ID from registration |
| redirect_mode | String | No | TOP_WINDOW or PARENT_WINDOW |
| cancellation_url | String | No | Redirect if payment cancelled |
| billing_address | Object | Yes | Customer details |

**Billing Address:**
- `email_address` OR `phone_number` required
- Other fields optional

**Response:**
```json
{
  "order_tracking_id": "b945e4af-80a5-4ec1-8706-e03f8332fb04",
  "merchant_reference": "ORDER-12345",
  "redirect_url": "https://cybqa.pesapal.com/pesapaliframe/PesapalIframe3/Index/?OrderTrackingId=b945e4af-80a5-4ec1-8706-e03f8332fb04",
  "error": null,
  "status": "200"
}
```

Redirect customer to `redirect_url` or embed as iframe.

## Callback Handling

After payment, customer redirects to `callback_url` with parameters:

```
https://yourapp.com/payment/callback
  ?OrderTrackingId=b945e4af-80a5-4ec1-8706-e03f8332fb04
  &OrderMerchantReference=ORDER-12345
  &OrderNotificationType=CALLBACKURL
```

**Important:** Callback does NOT include payment status. Query status via API.

## IPN Notification

Pesapal sends IPN to registered URL:

```
GET/POST https://yourapp.com/pesapal/ipn
  ?OrderTrackingId=b945e4af-80a5-4ec1-8706-e03f8332fb04
  &OrderMerchantReference=ORDER-12345
  &OrderNotificationType=IPNCHANGE
```

### IPN Response Required

```json
{
  "orderNotificationType": "IPNCHANGE",
  "orderTrackingId": "b945e4af-80a5-4ec1-8706-e03f8332fb04",
  "orderMerchantReference": "ORDER-12345",
  "status": 200
}
```

Status: `200` (success) or `500` (error, will retry)

## Get Transaction Status

Query payment status.

```bash
GET /api/Transactions/GetTransactionStatus?orderTrackingId={tracking_id}
Authorization: Bearer {token}
```

**Response:**
```json
{
  "payment_method": "MPESA",
  "amount": 1000,
  "created_date": "2024-01-15T10:30:00.000Z",
  "confirmation_code": "ABC123XYZ",
  "payment_status_description": "Completed",
  "description": "Payment for Order #12345",
  "message": "Request processed successfully",
  "payment_account": "2547XXXXXXXX",
  "call_back_url": "https://yourapp.com/payment/callback",
  "status_code": 1,
  "merchant_reference": "ORDER-12345",
  "payment_status_code": "1",
  "currency": "KES",
  "error": null,
  "status": "200"
}
```

### Status Codes

| Code | Status |
|------|--------|
| 0 | INVALID |
| 1 | COMPLETED |
| 2 | FAILED |
| 3 | REVERSED |

### Payment Methods

- MPESA
- CARD (Visa/Mastercard)
- MTN
- TIGO
- AIRTEL

## Recurring Payments

Create subscription payments.

```bash
POST /api/Transactions/SubmitRecurringPayment
Authorization: Bearer {token}
Content-Type: application/json

{
  "id": "SUB-12345",
  "currency": "KES",
  "amount": 500.00,
  "description": "Monthly subscription",
  "callback_url": "https://yourapp.com/subscription/callback",
  "notification_id": "ipn-id",
  "billing_address": {
    "email_address": "customer@example.com",
    "phone_number": "0712345678",
    "first_name": "John",
    "last_name": "Doe"
  },
  "subscription_details": {
    "start_date": "2024-02-01",
    "end_date": "2025-02-01",
    "frequency": "MONTHLY"
  }
}
```

## Refund Request

Request a refund for completed payment.

```bash
POST /api/Transactions/RefundRequest
Authorization: Bearer {token}
Content-Type: application/json

{
  "confirmation_code": "ABC123XYZ",
  "amount": 500.00,
  "username": "admin",
  "remarks": "Customer requested refund"
}
```

## Order Cancellation

Cancel a pending order.

```bash
POST /api/Transactions/CancelOrder
Authorization: Bearer {token}
Content-Type: application/json

{
  "order_tracking_id": "b945e4af-80a5-4ec1-8706-e03f8332fb04"
}
```

## Node.js Implementation

```javascript
const axios = require('axios');

class PesapalClient {
  constructor(consumerKey, consumerSecret, environment = 'sandbox') {
    this.consumerKey = consumerKey;
    this.consumerSecret = consumerSecret;
    this.baseUrl = environment === 'sandbox'
      ? 'https://cybqa.pesapal.com/pesapalv3'
      : 'https://pay.pesapal.com/v3';
    this.token = null;
    this.tokenExpiry = null;
  }

  async getToken() {
    if (this.token && this.tokenExpiry > new Date()) {
      return this.token;
    }

    const response = await axios.post(
      `${this.baseUrl}/api/Auth/RequestToken`,
      {
        consumer_key: this.consumerKey,
        consumer_secret: this.consumerSecret
      }
    );

    this.token = response.data.token;
    this.tokenExpiry = new Date(response.data.expiryDate);
    return this.token;
  }

  async registerIPN(url, notificationType = 'GET') {
    const token = await this.getToken();

    const response = await axios.post(
      `${this.baseUrl}/api/URLSetup/RegisterIPN`,
      { url, ipn_notification_type: notificationType },
      { headers: { Authorization: `Bearer ${token}` } }
    );

    return response.data;
  }

  async submitOrder(order) {
    const token = await this.getToken();

    const response = await axios.post(
      `${this.baseUrl}/api/Transactions/SubmitOrderRequest`,
      order,
      { headers: { Authorization: `Bearer ${token}` } }
    );

    return response.data;
  }

  async getTransactionStatus(orderTrackingId) {
    const token = await this.getToken();

    const response = await axios.get(
      `${this.baseUrl}/api/Transactions/GetTransactionStatus`,
      {
        params: { orderTrackingId },
        headers: { Authorization: `Bearer ${token}` }
      }
    );

    return response.data;
  }
}

// Usage
const pesapal = new PesapalClient(
  process.env.PESAPAL_CONSUMER_KEY,
  process.env.PESAPAL_CONSUMER_SECRET
);

// Register IPN (one-time)
const ipn = await pesapal.registerIPN('https://yourapp.com/ipn');

// Submit order
const order = await pesapal.submitOrder({
  id: `ORDER-${Date.now()}`,
  currency: 'KES',
  amount: 1000,
  description: 'Test payment',
  callback_url: 'https://yourapp.com/callback',
  notification_id: ipn.ipn_id,
  billing_address: {
    email_address: 'customer@example.com',
    first_name: 'John',
    last_name: 'Doe'
  }
});

// Redirect customer
console.log('Redirect to:', order.redirect_url);
```

## Error Handling

```json
{
  "error": {
    "type": "invalid_request_error",
    "code": "invalid_merchant",
    "message": "Invalid merchant credentials"
  },
  "status": "500"
}
```

Common error types:
- `invalid_request_error`
- `authentication_error`
- `api_error`
- `validation_error`

## Test Credentials

Get sandbox keys: https://developer.pesapal.com/api3-demo-keys.txt

## Resources

- **Developer Portal**: https://developer.pesapal.com/
- **API Reference**: https://developer.pesapal.com/how-to-integrate/e-commerce/api-30-json/api-reference
- **Postman Collection**: https://documenter.getpostman.com/view/6715320/UyxepTv1
