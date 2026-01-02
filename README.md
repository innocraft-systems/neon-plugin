# Innocraft Plugin Marketplace

A curated collection of backend development plugins for Claude Code.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [**neon**](plugins/neon/) | Neon serverless PostgreSQL - Drizzle ORM, serverless driver, auth, MCP, vectors |
| [**convex**](plugins/convex/) | Convex reactive backend - functions, database, auth, file storage, scheduling |
| [**kenya-payments**](plugins/kenya-payments/) | Kenya payments - Kopokopo, Daraja (M-Pesa), Pesapal, Intasend |

## Installation

### Add the Marketplace

```bash
# Add the marketplace
claude plugin marketplace add innocraft-systems/innocraft-plugin
```

### Install Individual Plugins

```bash
# Install Neon plugin
claude plugin install neon

# Install Convex plugin
claude plugin install convex

# Install Kenya Payments plugin
claude plugin install kenya-payments
```

### Local Development

```bash
# Test a specific plugin
claude --plugin-dir /path/to/innocraft-plugin/plugins/neon
claude --plugin-dir /path/to/innocraft-plugin/plugins/convex
```

## Plugin Details

### Neon Plugin

Complete Neon serverless PostgreSQL integration.

**Skills:** `neon-drizzle`, `neon-serverless`, `neon-toolkit`, `neon-auth`, `neon-js`, `neon-mcp`, `neon-vector`

**Commands:**
- `/neon:setup-drizzle` - Set up Drizzle ORM
- `/neon:setup-auth-nextjs` - Set up Neon Auth for Next.js
- `/neon:setup-auth-react` - Set up Neon Auth for React SPA
- `/neon:setup-serverless` - Configure serverless driver
- `/neon:setup-neon-js` - Set up unified SDK
- `/neon:create-ephemeral-db` - Create test database
- `/neon:setup-vector` - Set up vector/RAG infrastructure
- `/neon:setup-mcp` - Configure MCP server
- `/neon:add-docs` - Add Neon best practices documentation

**Agents:** `neon-setup-verifier`, `neon-migration-helper`

[Full documentation](plugins/neon/README.md)

---

### Convex Plugin

Complete Convex reactive backend development.

**Skills:** `convex`

**Commands:**
- `/convex:init` - Initialize a new Convex project
- `/convex:setup-auth` - Set up Convex Auth (OAuth, passwords, magic links)
- `/convex:setup-clerk` - Configure Clerk authentication
- `/convex:add-function` - Create a new function (query/mutation/action)
- `/convex:add-cron` - Add a cron job or scheduled function
- `/convex:deploy` - Deploy functions to production

**Capabilities:**
- Functions (queries, mutations, actions, HTTP actions)
- Database (schema, indexes, reading/writing data)
- Convex Auth (OAuth, Magic Links, OTPs, Passwords)
- File storage
- Scheduling (cron jobs, scheduled functions)
- Third-party auth (Clerk, Auth0)

[Full documentation](plugins/convex/README.md)

---

### Kenya Payments Plugin

Complete Kenya payment gateway integrations.

**Skills:** `kopokopo`, `daraja`, `pesapal`, `intasend`

**Providers:**
- **Kopokopo (K2 Connect)** - M-Pesa buy goods, STK Push, PAY recipients
- **Safaricom Daraja** - M-Pesa Express, C2B, B2C, reversals
- **Pesapal API 3.0** - Cards, M-Pesa, MTN, recurring payments
- **Intasend** - M-Pesa, PesaLink bank payouts, wallets

**Capabilities:**
- STK Push payment collection
- B2C disbursements (salary, refunds)
- C2B paybill/till integration
- Bank transfers (PesaLink)
- Webhooks and IPN notifications
- Multi-currency support

[Full documentation](plugins/kenya-payments/README.md)

---

## Adding New Plugins

To add a new plugin to this marketplace:

1. Create a new directory under `plugins/`:
   ```
   plugins/your-plugin/
   ├── .claude-plugin/
   │   └── plugin.json
   ├── skills/
   ├── commands/
   ├── agents/
   └── README.md
   ```

2. Update `.claude-plugin/marketplace.json`:
   ```json
   {
     "plugins": [
       // ... existing plugins
       {
         "name": "your-plugin",
         "source": "plugins/your-plugin",
         "description": "Your plugin description"
       }
     ]
   }
   ```

3. Commit and push to the repository.

## License

MIT
