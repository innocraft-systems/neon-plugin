# Innocraft Plugin Marketplace

A curated collection of backend development plugins for Claude Code.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [**neon**](plugins/neon/) | Neon serverless PostgreSQL - Drizzle ORM, serverless driver, auth, MCP, vectors |
| [**convex**](plugins/convex/) | Convex reactive backend - functions, database, auth, file storage, scheduling |
| [**kenya-payments**](plugins/kenya-payments/) | Kenya payments - Kopokopo, Daraja (M-Pesa), Pesapal, Intasend |
| [**kra-etims**](plugins/kra-etims/) | KRA eTIMS tax compliance - invoicing, stock, OSCU/VSCU |
| [**whatsapp-business**](plugins/whatsapp-business/) | WhatsApp Business Cloud API - messaging, templates, webhooks |
| [**meta-business**](plugins/meta-business/) | Meta Business Suite - Facebook Pages, Instagram posting, analytics |
| [**whatsapp-status**](plugins/whatsapp-status/) | WhatsApp Status content generator - Nano Banana AI, scheduling |
| [**gemini-ai**](plugins/gemini-ai/) | Google Gemini API - all models, multimodal, Live API, Nano Banana |
| [**bmad-evals**](plugins/bmad-evals/) | BMAD methodology with cross-context persistence - /brun, /bstop, eval framework |
| [**design-system**](plugins/design-system/) | Premium design system enforcement - Firecrawl capture, token extraction, alignment |

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

# Install KRA eTIMS plugin
claude plugin install kra-etims

# Install WhatsApp Business plugin
claude plugin install whatsapp-business

# Install Meta Business plugin
claude plugin install meta-business

# Install WhatsApp Status plugin
claude plugin install whatsapp-status

# Install Gemini AI plugin
claude plugin install gemini-ai

# Install BMAD Evals plugin
claude plugin install bmad-evals

# Install Design System plugin
claude plugin install design-system
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
- `/neon:branch` - Create database branch for dev/test/preview
- `/neon:migrate` - Run Drizzle migrations (generate/migrate/push/studio)

**Agents:** `neon-setup-verifier`, `neon-migration-helper`, `neon-specialist`, `neon-auth-specialist`

[Full documentation](plugins/neon/README.md)

---

### Convex Plugin

Complete Convex reactive backend development.

**Skills:** `convex`

**Commands:**
- `/convex:setup-convex` - Initialize a new Convex project
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

### KRA eTIMS Plugin

Kenya Revenue Authority Electronic Tax Invoice Management System integration.

**Skills:** `etims-integration`, `etims-invoicing`, `etims-stock`

**Capabilities:**
- Device initialization (OSCU/VSCU)
- Sales invoice submission
- Credit/debit notes
- Stock management and item registration
- UNSPSC item classification
- Purchase tracking
- Tax calculations (VAT 16%, zero-rated, exempt)

**Compliance Requirements:**
- All Kenyan businesses must use eTIMS
- Every sale must receive a CU Invoice Number
- Stock movements must be tracked

[Full documentation](plugins/kra-etims/README.md)

---

### WhatsApp Business Plugin

Complete WhatsApp Business Cloud API integration.

**Skills:** `whatsapp-cloud-api`, `whatsapp-templates`, `whatsapp-webhooks`

**Capabilities:**
- Send text, images, documents, locations
- Interactive messages (buttons, lists)
- Message templates for notifications
- Webhooks for receiving messages
- Delivery and read receipts
- Multi-tenant support

**Use Cases:**
- Order notifications and updates
- Customer support automation
- Payment confirmations
- Delivery tracking
- Marketing campaigns

[Full documentation](plugins/whatsapp-business/README.md)

---

### Meta Business Plugin

Facebook Pages and Instagram Business API integration.

**Skills:** `meta-pages`, `meta-instagram`, `meta-insights`

**Capabilities:**
- Facebook Page posting (text, photos, videos, links)
- Instagram posting (images, carousels, reels, stories)
- Post scheduling
- Comment management
- Engagement analytics

[Full documentation](plugins/meta-business/README.md)

---

### WhatsApp Status Plugin

AI-powered content generation for WhatsApp Status.

**Skills:** `status-images`, `status-videos`, `status-scheduler`

**Capabilities:**
- Image generation with Nano Banana (Gemini)
- Product showcases, promo banners, price lists
- Video slideshows and animations
- Scheduling reminders
- Kenya-specific templates (M-Pesa badges, KES formatting)

**Note:** WhatsApp Status cannot be automated - this generates content for manual posting.

[Full documentation](plugins/whatsapp-status/README.md)

---

### Gemini AI Plugin

Complete Google Gemini API integration.

**Skills:** `gemini-models`, `gemini-multimodal`, `gemini-live`

**Models Covered:**
- Gemini 1.5 Flash/Pro (fast, long context)
- Gemini 2.0 Flash (agentic, tool calling)
- Gemini 2.5 Flash/Pro (thinking, image gen)
- Gemini 3 Pro (state-of-the-art)
- Nano Banana (image generation)
- Veo (video generation)
- Live API (real-time voice/video)

**Features:**
- Direct API and OpenRouter support
- Multimodal (vision, audio, video)
- Function calling
- Streaming responses

[Full documentation](plugins/gemini-ai/README.md)

---

### BMAD Evals Plugin

BMAD methodology with cross-context persistence for long-running story execution.

**Skills:** `eval-methodology`

**Commands:**
- `/brun` - Run BMAD story with cross-context persistence harness
- `/bstop` - Stop BMAD story harness
- `/sprint-run` - Run all stories in sprint automatically with dependency tracking
- `/sprint-stop` - Stop the active sprint runner
- `/eval-init` - Initialize eval framework for a project
- `/eval-run` - Run evaluation tasks
- `/eval-report` - Generate evaluation report
- `/eval-task-add` - Add a new evaluation task
- `/eval-cancel` - Cancel active eval loop
- `/eval-help` - Show BMAD-Evals help documentation

**Agents:** `eval-orchestrator`, `eval-analyst`, `eval-grader`

**Features:**
- Cross-context window persistence via Stop hooks
- Task checkpoint tracking
- Git-based progress markers
- Eval framework for testing AI agent performance
- **Smart story location detection** - finds stories from sprint-status.yaml, bmm/config.yaml, or fallback paths

[Full documentation](plugins/bmad-evals/README.md)

---

### Design System Plugin

Premium design system enforcement with Firecrawl inspiration capture.

**Skills:** `premium-design`

**Commands:**
- `/ds-init` - Initialize design system for project
- `/ds-capture <url>` - Capture design tokens from inspiration site via Firecrawl
- `/ds-extract` - Extract design system from prototype UI code
- `/ds-align <file>` - Align component to project's design system
- `/ds-tokens` - View or regenerate design tokens (CSS, Tailwind)

**Agents:** `design-reviewer`

**Features:**
- Anti-AI-slop patterns (distinctive typography, bold colors)
- Spring physics motion, 3-layer shadows
- 8-point grid spacing, OKLCH colors
- Per-project design system storage in `docs/ux/`
- Firecrawl integration for capturing inspiration sites

[Full documentation](plugins/design-system/README.md)

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
