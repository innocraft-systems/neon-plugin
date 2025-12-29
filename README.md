# Neon Plugin for Claude Code

A comprehensive Claude Code plugin for Neon serverless PostgreSQL integration. Covers Drizzle ORM, serverless driver, ephemeral databases, Neon Auth, unified SDK, MCP server integration, and vector/RAG capabilities with hybrid search.

## Features

- **7 Skills**: Auto-triggering knowledge for Neon components
- **9 Commands**: User-initiated setup workflows
- **2 Agents**: Autonomous validation and migration assistance
- **MCP Integration**: AI assistant database interaction
- **Templates**: Ready-to-use code for common setups

## Installation

### From GitHub (Recommended)

```bash
claude plugins add innocraft-systems/plugin
```

### Local Development

```bash
claude --plugin-dir /path/to/neon-plugin
```

### Copy to Project

Copy the `neon-plugin` folder to your project's `.claude-plugin/` directory.

## Skills

| Skill | Triggers On |
|-------|-------------|
| `neon-drizzle` | Drizzle ORM setup, schemas, migrations |
| `neon-serverless` | Serverless driver, HTTP/WebSocket adapters |
| `neon-toolkit` | Ephemeral databases, testing, CI/CD |
| `neon-auth` | Authentication, Better Auth, RLS |
| `neon-js` | Unified SDK, auth + data client |
| `neon-mcp` | MCP server, AI integration |
| `neon-vector` | pgvector, embeddings, RAG, hybrid search |

## Commands

| Command | Description |
|---------|-------------|
| `/neon:setup-drizzle` | Set up Drizzle ORM with Neon |
| `/neon:setup-auth-nextjs` | Set up Neon Auth for Next.js |
| `/neon:setup-auth-react` | Set up Neon Auth for React SPA |
| `/neon:setup-serverless` | Configure serverless driver |
| `/neon:setup-neon-js` | Set up unified SDK |
| `/neon:create-ephemeral-db` | Create test database |
| `/neon:add-docs` | Add AI rules files |
| `/neon:setup-vector` | Set up vector/RAG infrastructure |
| `/neon:setup-mcp` | Configure MCP server |

## Agents

| Agent | Purpose |
|-------|---------|
| `neon-setup-verifier` | Validates Neon configuration (runs after setup commands) |
| `neon-migration-helper` | Assists with schema changes and migrations |

## Prerequisites

- **Neon Account**: Sign up at [neon.tech](https://neon.tech)
- **API Key** (for toolkit/MCP): Get from Neon Console > Account settings > API keys
- **Node.js 18+**

## Environment Variables

```env
# Database connection
DATABASE_URL=postgresql://user:pass@ep-xxx.us-east-2.aws.neon.tech/neondb?sslmode=require

# For Neon Auth (Next.js)
NEON_AUTH_BASE_URL=https://ep-xxx.neonauth.us-east-2.aws.neon.build/neondb/auth
NEXT_PUBLIC_NEON_AUTH_URL=https://ep-xxx.neonauth.us-east-2.aws.neon.build/neondb/auth

# For Neon JS SDK
NEON_DATA_API_URL=https://ep-xxx.apirest.us-east-2.aws.neon.build/neondb/rest/v1

# For Toolkit/MCP
NEON_API_KEY=your_api_key
```

## MCP Server

This plugin includes MCP configuration for AI assistant integration:

```json
{
  "mcpServers": {
    "neon": {
      "command": "npx",
      "args": ["-y", "@neondatabase/mcp-server-neon", "start", "${NEON_API_KEY}"]
    }
  }
}
```

Set `NEON_API_KEY` environment variable to enable.

## Templates

Located in `templates/`:

- `drizzle/` - Drizzle configuration and schema
- `nextjs-auth/` - Next.js App Router auth setup
- `react-spa-auth/` - React SPA auth setup
- `vector/` - Vector database and hybrid search

## Scripts

Located in `scripts/`:

- `create-ephemeral-db.ts` - Create isolated test database
- `destroy-ephemeral-db.ts` - Clean up ephemeral databases
- `validate-connection.ts` - Test database connectivity

## License

MIT
