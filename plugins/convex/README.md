# Convex Plugin for Claude Code

Complete Convex reactive backend development. Covers functions (queries, mutations, actions), database (schema, indexes), Convex Auth, file storage, scheduling, and real-time reactive backends.

## Features

- **Comprehensive Skill**: Auto-triggering knowledge for all Convex development
- **Setup Commands**: Quick commands for common setup tasks
- **Reference Documentation**: Detailed guides for each Convex feature

## Commands

| Command | Description |
|---------|-------------|
| `/convex:init` | Initialize a new Convex project or add to existing |
| `/convex:setup-auth` | Set up Convex Auth (OAuth, passwords, magic links) |
| `/convex:setup-clerk` | Configure Clerk authentication integration |
| `/convex:add-function` | Create a new query, mutation, action, or HTTP action |
| `/convex:add-cron` | Add a cron job or scheduled function |
| `/convex:deploy` | Deploy functions to production |

## Skill

| Skill | Triggers On |
|-------|-------------|
| `convex` | Convex setup, functions, database, auth, file storage, scheduling |

## Capabilities

### Functions
- Queries (read-only, transactional)
- Mutations (read/write, transactional)
- Actions (external API calls)
- HTTP Actions (REST endpoints)
- Internal functions

### Database
- Schema definition with validators
- Indexes for efficient queries
- Document-relational model
- Real-time subscriptions

### Authentication
- **Convex Auth**: Built-in OAuth, Magic Links, OTPs, Passwords
- **Third-party**: Clerk, Auth0 integration

### File Storage
- Upload/download APIs
- Storage URLs

### Scheduling
- Cron jobs
- Scheduled functions
- Workpool patterns

## Quick Start

```bash
# Create new Convex project
npm create convex@latest

# Or add to existing project
npm install convex
npx convex dev
```

## Reference Documentation

Located in `skills/convex/references/`:

- `functions.md` - Queries, mutations, actions, HTTP actions
- `database.md` - Schema, data types, indexes, reading/writing
- `convex-auth.md` - Built-in authentication setup
- `scheduling.md` - Cron jobs, scheduled functions
- `file-storage.md` - File uploads and downloads
- `third-party-auth.md` - Clerk and Auth0 integration

## Prerequisites

- **Node.js 18+**
- **Convex Account**: Sign up at [convex.dev](https://convex.dev)

## License

MIT
