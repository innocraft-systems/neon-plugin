---
name: daraja
description: This skill provides guidance for integrating Safaricom Daraja M-Pesa APIs. Use when the user asks about "M-Pesa", "Daraja API", "STK Push", "Lipa Na M-Pesa", "M-Pesa Express", "B2C payments", "C2B payments", "Safaricom API", "paybill integration", or needs help with M-Pesa authentication, callbacks, or transaction queries.
---

# Safaricom Daraja (M-Pesa) Integration

Daraja is Safaricom's M-Pesa API platform enabling STK Push, C2B, B2C, and other mobile money transactions in Kenya.

## Base URLs

| Environment | URL |
|-------------|-----|
| Sandbox | `https://sandbox.safaricom.co.ke` |
| Production | `https://api.safaricom.co.ke` |

## Authentication

Daraja uses OAuth 2.0 for authentication.

### Get Access Token

```bash
GET /oauth/v1/generate?grant_type=client_credentials
Authorization: Basic {base64(consumer_key:consumer_secret)}
```

**Response:**
```json
{
  "access_token": "0A0v8OgxqqoocblflR7r",
  "expires_in": "3599"
}
```

Token is valid for 1 hour (3600 seconds).

### Generate Authorization Header

```javascript
const credentials = Buffer.from(
  `${consumerKey}:${consumerSecret}`
).toString('base64');

// Use in request
headers: {
  'Authorization': `Basic ${credentials}`
}
```

## M-Pesa Express (STK Push)

Initiates payment prompt on customer's phone.

### Endpoint

```bash
POST /mpesa/stkpush/v1/processrequest
Authorization: Bearer {access_token}
Content-Type: application/json
```

### Request Body

```json
{
  "BusinessShortCode": "174379",
  "Password": "MTc0Mzc5YmZiMjc5ZjlhYTliZGJjZjE1OGU5N2RkNzFhNDY3Y2QyZTBjODkzMDU5YjEwZjc4ZTZiNzJhZGExZWQyYzkxOTIwMjQwMTE1MTIzMDQ1",
  "Timestamp": "20240115123045",
  "TransactionType": "CustomerPayBillOnline",
  "Amount": 1,
  "PartyA": "254712345678",
  "PartyB": "174379",
  "PhoneNumber": "254712345678",
  "CallBackURL": "https://yourapp.com/callback",
  "AccountReference": "Order123",
  "TransactionDesc": "Payment for Order"
}
```

### Parameters

| Parameter | Description | Format |
|-----------|-------------|--------|
| BusinessShortCode | Paybill or Till number | 5-6 digits |
| Password | Base64(ShortCode + Passkey + Timestamp) | Base64 string |
| Timestamp | Transaction time | YYYYMMDDHHMMSS |
| TransactionType | `CustomerPayBillOnline` or `CustomerBuyGoodsOnline` | String |
| Amount | Payment amount (whole numbers) | Integer |
| PartyA | Customer phone | 2547XXXXXXXX |
| PartyB | Business shortcode | 5-6 digits |
| PhoneNumber | Phone for STK prompt | 2547XXXXXXXX |
| CallBackURL | Callback endpoint | HTTPS URL |
| AccountReference | Account/order reference | Max 12 chars |
| TransactionDesc | Description | Max 13 chars |

### Generate Password

```javascript
function generatePassword(shortcode, passkey, timestamp) {
  const data = shortcode + passkey + timestamp;
  return Buffer.from(data).toString('base64');
}

function getTimestamp() {
  const now = new Date();
  return now.toISOString()
    .replace(/[-:TZ.]/g, '')
    .slice(0, 14);
}
```

### Response

```json
{
  "MerchantRequestID": "29115-34620561-1",
  "CheckoutRequestID": "ws_CO_191220191020363925",
  "ResponseCode": "0",
  "ResponseDescription": "Success. Request accepted for processing",
  "CustomerMessage": "Success. Request accepted for processing"
}
```

### Callback Payload (Success)

```json
{
  "Body": {
    "stkCallback": {
      "MerchantRequestID": "29115-34620561-1",
      "CheckoutRequestID": "ws_CO_191220191020363925",
      "ResultCode": 0,
      "ResultDesc": "The service request is processed successfully.",
      "CallbackMetadata": {
        "Item": [
          { "Name": "Amount", "Value": 1.00 },
          { "Name": "MpesaReceiptNumber", "Value": "NLJ7RT61SV" },
          { "Name": "TransactionDate", "Value": 20240115102115 },
          { "Name": "PhoneNumber", "Value": 254712345678 }
        ]
      }
    }
  }
}
```

### Callback Payload (Failed/Cancelled)

```json
{
  "Body": {
    "stkCallback": {
      "MerchantRequestID": "8555-67195-1",
      "CheckoutRequestID": "ws_CO_27072017151044001",
      "ResultCode": 1032,
      "ResultDesc": "Request cancelled by user"
    }
  }
}
```

### Common Result Codes

| Code | Description |
|------|-------------|
| 0 | Success |
| 1 | Insufficient balance |
| 1032 | Cancelled by user |
| 1037 | Timeout/unreachable |
| 1025 | System error |
| 2001 | Wrong PIN |

## STK Push Query

Check status of an STK Push request.

```bash
POST /mpesa/stkpushquery/v1/query
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "BusinessShortCode": "174379",
  "Password": "base64_password",
  "Timestamp": "20240115123045",
  "CheckoutRequestID": "ws_CO_191220191020363925"
}
```

## C2B (Customer to Business)

### Register URLs

Register validation and confirmation URLs for C2B payments.

```bash
POST /mpesa/c2b/v1/registerurl
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "ShortCode": "600000",
  "ResponseType": "Completed",
  "ConfirmationURL": "https://yourapp.com/confirmation",
  "ValidationURL": "https://yourapp.com/validation"
}
```

**ResponseType Options:**
- `Completed` - Accept all transactions
- `Cancelled` - Reject if validation fails

### Validation Request (from M-Pesa)

```json
{
  "TransactionType": "Pay Bill",
  "TransID": "ABC123",
  "TransTime": "20240115123045",
  "TransAmount": "1000",
  "BusinessShortCode": "600000",
  "BillRefNumber": "Account123",
  "InvoiceNumber": "",
  "OrgAccountBalance": "",
  "ThirdPartyTransID": "",
  "MSISDN": "254712345678",
  "FirstName": "John",
  "MiddleName": "",
  "LastName": "Doe"
}
```

### Validation Response

```json
{
  "ResultCode": "0",
  "ResultDesc": "Accepted"
}
```

To reject: `"ResultCode": "C2B00011"`

### Confirmation Request (from M-Pesa)

Same payload as validation - confirms transaction completion.

## B2C (Business to Customer)

Disburse funds to M-Pesa users.

```bash
POST /mpesa/b2c/v1/paymentrequest
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "InitiatorName": "testapi",
  "SecurityCredential": "encrypted_password",
  "CommandID": "BusinessPayment",
  "Amount": 1000,
  "PartyA": "600000",
  "PartyB": "254712345678",
  "Remarks": "Salary payment",
  "QueueTimeOutURL": "https://yourapp.com/timeout",
  "ResultURL": "https://yourapp.com/result",
  "Occasion": "Monthly salary"
}
```

### CommandID Options

| CommandID | Description |
|-----------|-------------|
| BusinessPayment | Standard B2C |
| SalaryPayment | Salary disbursement |
| PromotionPayment | Promotional payment |

### Security Credential

Encrypt initiator password with M-Pesa public certificate:

```javascript
const crypto = require('crypto');
const fs = require('fs');

function generateSecurityCredential(password) {
  const certificate = fs.readFileSync('ProductionCertificate.cer');
  const encrypted = crypto.publicEncrypt(
    {
      key: certificate,
      padding: crypto.constants.RSA_PKCS1_PADDING
    },
    Buffer.from(password)
  );
  return encrypted.toString('base64');
}
```

## Transaction Status

Query status of any transaction.

```bash
POST /mpesa/transactionstatus/v1/query
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "Initiator": "testapi",
  "SecurityCredential": "encrypted_password",
  "CommandID": "TransactionStatusQuery",
  "TransactionID": "ABC123XYZ",
  "PartyA": "600000",
  "IdentifierType": "4",
  "ResultURL": "https://yourapp.com/result",
  "QueueTimeOutURL": "https://yourapp.com/timeout",
  "Remarks": "Status check",
  "Occasion": "Query"
}
```

## Account Balance

Query M-Pesa account balance.

```bash
POST /mpesa/accountbalance/v1/query
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "Initiator": "testapi",
  "SecurityCredential": "encrypted_password",
  "CommandID": "AccountBalance",
  "PartyA": "600000",
  "IdentifierType": "4",
  "Remarks": "Balance query",
  "QueueTimeOutURL": "https://yourapp.com/timeout",
  "ResultURL": "https://yourapp.com/result"
}
```

## Reversal

Reverse a completed transaction.

```bash
POST /mpesa/reversal/v1/request
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "Initiator": "testapi",
  "SecurityCredential": "encrypted_password",
  "CommandID": "TransactionReversal",
  "TransactionID": "ABC123XYZ",
  "Amount": 1000,
  "ReceiverParty": "600000",
  "ReceiverIdentifierType": "11",
  "ResultURL": "https://yourapp.com/result",
  "QueueTimeOutURL": "https://yourapp.com/timeout",
  "Remarks": "Reversal request",
  "Occasion": "Refund"
}
```

## Node.js Implementation

```javascript
const axios = require('axios');

class MpesaClient {
  constructor(consumerKey, consumerSecret, environment = 'sandbox') {
    this.consumerKey = consumerKey;
    this.consumerSecret = consumerSecret;
    this.baseUrl = environment === 'sandbox'
      ? 'https://sandbox.safaricom.co.ke'
      : 'https://api.safaricom.co.ke';
  }

  async getAccessToken() {
    const auth = Buffer.from(
      `${this.consumerKey}:${this.consumerSecret}`
    ).toString('base64');

    const response = await axios.get(
      `${this.baseUrl}/oauth/v1/generate?grant_type=client_credentials`,
      { headers: { Authorization: `Basic ${auth}` } }
    );

    return response.data.access_token;
  }

  async stkPush(options) {
    const token = await this.getAccessToken();
    const timestamp = this.getTimestamp();
    const password = this.generatePassword(
      options.shortcode,
      options.passkey,
      timestamp
    );

    const response = await axios.post(
      `${this.baseUrl}/mpesa/stkpush/v1/processrequest`,
      {
        BusinessShortCode: options.shortcode,
        Password: password,
        Timestamp: timestamp,
        TransactionType: 'CustomerPayBillOnline',
        Amount: options.amount,
        PartyA: options.phone,
        PartyB: options.shortcode,
        PhoneNumber: options.phone,
        CallBackURL: options.callbackUrl,
        AccountReference: options.accountRef,
        TransactionDesc: options.description
      },
      { headers: { Authorization: `Bearer ${token}` } }
    );

    return response.data;
  }

  getTimestamp() {
    return new Date().toISOString()
      .replace(/[-:TZ.]/g, '')
      .slice(0, 14);
  }

  generatePassword(shortcode, passkey, timestamp) {
    return Buffer.from(`${shortcode}${passkey}${timestamp}`).toString('base64');
  }
}

// Usage
const mpesa = new MpesaClient(
  process.env.MPESA_CONSUMER_KEY,
  process.env.MPESA_CONSUMER_SECRET
);

const result = await mpesa.stkPush({
  shortcode: '174379',
  passkey: process.env.MPESA_PASSKEY,
  amount: 1,
  phone: '254712345678',
  callbackUrl: 'https://yourapp.com/callback',
  accountRef: 'Order123',
  description: 'Payment'
});
```

## Test Credentials

| Parameter | Value |
|-----------|-------|
| Shortcode | 174379 |
| Passkey | bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919 |
| Test Phone | 254708374149 |

Get full test credentials: https://developer.safaricom.co.ke/test_credentials

## Resources

- **Developer Portal**: https://developer.safaricom.co.ke/
- **API Documentation**: https://developer.safaricom.co.ke/Documentation
- **Sandbox Dashboard**: https://developer.safaricom.co.ke/MyApps
