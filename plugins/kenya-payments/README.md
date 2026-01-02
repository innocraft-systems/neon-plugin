# Kenya Payments Plugin

Complete Kenya payment gateway integrations for Claude Code. Covers Kopokopo (K2 Connect), Safaricom Daraja (M-Pesa), Pesapal API 3.0, and Intasend.

## Features

- **4 Skills**: Auto-triggering knowledge for each payment provider
- **Complete API Documentation**: Authentication, endpoints, webhooks
- **Code Examples**: Node.js and Python SDK examples

## Installation

```bash
# Add the marketplace
claude plugin marketplace add innocraft-systems/innocraft-plugin

# Install the plugin
claude plugin install kenya-payments
```

## Skills

| Skill | Triggers On | Features |
|-------|-------------|----------|
| `kopokopo` | "Kopokopo", "K2 Connect", "buy goods" | STK Push, PAY recipients, settlements, webhooks |
| `daraja` | "M-Pesa", "Daraja", "STK Push", "B2C", "C2B" | M-Pesa Express, C2B, B2C, reversals, balance |
| `pesapal` | "Pesapal", "card payments" | Multi-currency, IPN, recurring payments, refunds |
| `intasend` | "Intasend", "PesaLink", "bank payouts" | STK Push, bank transfers, wallets, subscriptions |

## Payment Providers

### Kopokopo (K2 Connect)

M-Pesa integration for buy goods (till) payments.

**Capabilities:**
- M-Pesa STK Push for payment collection
- PAY recipients (mobile wallet, bank account)
- Settlement transfers to bank
- Webhooks for real-time notifications

**Base URLs:**
- Sandbox: `https://sandbox.kopokopo.com`
- Production: `https://api.kopokopo.com`

---

### Safaricom Daraja (M-Pesa)

Official Safaricom M-Pesa API platform.

**Capabilities:**
- M-Pesa Express (STK Push)
- C2B (Customer to Business) - Paybill/Till
- B2C (Business to Customer) - Disbursements
- Transaction status queries
- Account balance
- Reversal API

**Base URLs:**
- Sandbox: `https://sandbox.safaricom.co.ke`
- Production: `https://api.safaricom.co.ke`

---

### Pesapal API 3.0

Multi-currency payment gateway supporting cards and mobile money.

**Capabilities:**
- Card payments (Visa, Mastercard)
- M-Pesa, MTN, Airtel Money
- IPN webhooks
- Recurring payments
- Refunds and cancellations

**Base URLs:**
- Sandbox: `https://cybqa.pesapal.com/pesapalv3`
- Production: `https://pay.pesapal.com/v3`

---

### Intasend

Modern payment gateway with extensive disbursement options.

**Capabilities:**
- Payment collection (M-Pesa, cards, crypto)
- M-Pesa B2C/B2B disbursements
- Bank payouts (PesaLink)
- Wallet as a Service
- Subscription management

**Base URLs:**
- Sandbox: `https://sandbox.intasend.com`
- Production: `https://payment.intasend.com`

## Environment Variables

```env
# Kopokopo
KOPOKOPO_CLIENT_ID=your_client_id
KOPOKOPO_CLIENT_SECRET=your_client_secret
KOPOKOPO_API_KEY=your_api_key

# Daraja (M-Pesa)
MPESA_CONSUMER_KEY=your_consumer_key
MPESA_CONSUMER_SECRET=your_consumer_secret
MPESA_PASSKEY=your_passkey
MPESA_SHORTCODE=your_shortcode

# Pesapal
PESAPAL_CONSUMER_KEY=your_consumer_key
PESAPAL_CONSUMER_SECRET=your_consumer_secret

# Intasend
INTASEND_PUBLISHABLE_KEY=ISPubKey_xxx
INTASEND_SECRET_KEY=ISSecretKey_xxx
```

## Resources

| Provider | Developer Portal |
|----------|------------------|
| Kopokopo | https://developers.kopokopo.com/ |
| Daraja | https://developer.safaricom.co.ke/ |
| Pesapal | https://developer.pesapal.com/ |
| Intasend | https://developers.intasend.com/ |

## License

MIT
