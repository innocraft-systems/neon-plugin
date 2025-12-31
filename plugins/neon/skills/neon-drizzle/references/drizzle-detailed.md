# Drizzle ORM with Neon - Detailed Reference

Advanced configuration and patterns for using Drizzle ORM with Neon serverless PostgreSQL.

## WebSocket Pool Configuration

For long-running Node.js servers that need connection pooling and transactions:

```typescript
// src/db/index.ts
import { drizzle } from 'drizzle-orm/neon-serverless';
import { Pool, neonConfig } from '@neondatabase/serverless';
import ws from 'ws';

// Required for Node.js environments
neonConfig.webSocketConstructor = ws;

// Create connection pool
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 10, // Maximum connections in pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

export const db = drizzle({ client: pool });

// Graceful shutdown
process.on('SIGTERM', async () => {
  await pool.end();
});
```

### Pool Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `max` | 10 | Maximum number of clients in pool |
| `min` | 0 | Minimum number of idle clients |
| `idleTimeoutMillis` | 10000 | Close idle clients after this time |
| `connectionTimeoutMillis` | 0 | Timeout for new connections (0 = no timeout) |
| `allowExitOnIdle` | false | Allow process to exit when pool is idle |

## HTTP Transactions

The HTTP adapter supports transactions via the `transaction` method:

```typescript
import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';

const sql = neon(process.env.DATABASE_URL!);
const db = drizzle({ client: sql });

// HTTP transaction (uses Neon's transaction API)
const result = await db.transaction(async (tx) => {
  const user = await tx.insert(users)
    .values({ name: 'Alice', email: 'alice@example.com' })
    .returning();

  await tx.insert(profiles)
    .values({ userId: user[0].id, bio: 'Hello world' });

  return user[0];
});
```

### Transaction Isolation Levels

```typescript
await db.transaction(async (tx) => {
  // Your queries
}, {
  isolationLevel: 'serializable', // 'read committed' | 'repeatable read' | 'serializable'
  accessMode: 'read write', // 'read only' | 'read write'
  deferrable: true, // Only for serializable read-only transactions
});
```

## Migration Workflows

### Development Workflow

```bash
# 1. Make schema changes in src/db/schema.ts

# 2. Generate migration files
npm run db:generate

# 3. Review generated SQL in drizzle/ folder

# 4. Apply to development database
npm run db:push  # Direct push (dev only)
# OR
npm run db:migrate  # Run migrations
```

### Production Workflow with Neon Branching

```bash
# 1. Create a branch for testing
neon branches create --name migration-test

# 2. Get branch connection string
neon connection-string migration-test

# 3. Apply migration to branch
DATABASE_URL="branch-url" npm run db:migrate

# 4. Test application against branch

# 5. If successful, apply to main branch
npm run db:migrate

# 6. Delete test branch
neon branches delete migration-test
```

### CI/CD Pipeline Example

```yaml
# .github/workflows/migrate.yml
name: Database Migration

on:
  push:
    branches: [main]
    paths:
      - 'drizzle/**'
      - 'src/db/schema.ts'

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install dependencies
        run: npm ci

      - name: Create Neon branch
        id: branch
        uses: neondatabase/create-branch-action@v5
        with:
          project_id: ${{ secrets.NEON_PROJECT_ID }}
          api_key: ${{ secrets.NEON_API_KEY }}
          branch_name: preview/${{ github.sha }}

      - name: Run migrations on branch
        run: npm run db:migrate
        env:
          DATABASE_URL: ${{ steps.branch.outputs.db_url }}

      - name: Run tests
        run: npm test
        env:
          DATABASE_URL: ${{ steps.branch.outputs.db_url }}

      - name: Apply to production
        if: success()
        run: npm run db:migrate
        env:
          DATABASE_URL: ${{ secrets.DATABASE_URL }}

      - name: Delete branch
        if: always()
        uses: neondatabase/delete-branch-action@v3
        with:
          project_id: ${{ secrets.NEON_PROJECT_ID }}
          api_key: ${{ secrets.NEON_API_KEY }}
          branch: preview/${{ github.sha }}
```

## Custom Migration Scripts

For complex migrations that need data transformations:

```typescript
// scripts/migrate-data.ts
import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';
import { users, profiles } from '../src/db/schema';
import { sql } from 'drizzle-orm';

const client = neon(process.env.DATABASE_URL!);
const db = drizzle({ client });

async function migrateData() {
  // Example: Split full_name into first_name and last_name
  const allUsers = await db.select().from(users);

  for (const user of allUsers) {
    if (user.fullName) {
      const [firstName, ...rest] = user.fullName.split(' ');
      const lastName = rest.join(' ');

      await db.update(users)
        .set({ firstName, lastName })
        .where(sql`id = ${user.id}`);
    }
  }

  console.log(`Migrated ${allUsers.length} users`);
}

migrateData().catch(console.error);
```

Run with: `npx tsx scripts/migrate-data.ts`

## Troubleshooting Common Issues

### "relation does not exist"

**Cause:** Schema not applied to database.

**Solution:**
```bash
# Check current database state
npx drizzle-kit studio

# Apply schema
npm run db:push  # Development
npm run db:migrate  # Production
```

### "column X of relation Y already exists"

**Cause:** Migration trying to add a column that exists.

**Solution:**
```bash
# Pull current schema from database
npx drizzle-kit pull

# Compare with your schema.ts and resolve differences

# Regenerate migrations
rm -rf drizzle/
npm run db:generate
```

### "SSL SYSCALL error: EOF detected"

**Cause:** Connection dropped, usually due to idle timeout.

**Solution:**
```typescript
// For pooled connections
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  idleTimeoutMillis: 20000, // Reduce idle timeout
  keepAlive: true,
  keepAliveInitialDelayMillis: 10000,
});
```

### "too many connections"

**Cause:** Connection limit exceeded.

**Solution:**
```typescript
// 1. Use HTTP adapter for serverless (no persistent connections)
import { drizzle } from 'drizzle-orm/neon-http';

// 2. Or reduce pool size
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 5, // Reduce max connections
});

// 3. Ensure connections are released
// Always use try/finally or the pool handles it automatically
```

### "prepared statement X already exists"

**Cause:** Connection reuse with prepared statements.

**Solution:**
```typescript
// Disable prepared statements for serverless
const db = drizzle({
  client: sql,
  logger: true,
});

// Or use a unique statement name per query
```

### Migration stuck or timing out

**Cause:** Large table modifications or locks.

**Solution:**
```sql
-- Check for blocking queries
SELECT pid, query, state, wait_event_type
FROM pg_stat_activity
WHERE state != 'idle';

-- Cancel blocking query if needed
SELECT pg_cancel_backend(pid);
```

### WebSocket connection fails in serverless

**Cause:** WebSocket not supported in edge runtime.

**Solution:**
```typescript
// Use HTTP adapter for edge/serverless
import { drizzle } from 'drizzle-orm/neon-http';
import { neon } from '@neondatabase/serverless';

const sql = neon(process.env.DATABASE_URL!);
const db = drizzle({ client: sql });
```

## Performance Tips

### Use Indexes Effectively

```typescript
// Schema with indexes
export const posts = pgTable('posts', {
  id: serial('id').primaryKey(),
  title: text('title').notNull(),
  authorId: integer('author_id').references(() => users.id),
  createdAt: timestamp('created_at').defaultNow(),
  status: text('status').default('draft'),
}, (table) => [
  index('posts_author_idx').on(table.authorId),
  index('posts_status_created_idx').on(table.status, table.createdAt),
]);
```

### Batch Operations

```typescript
// Insert multiple rows efficiently
await db.insert(users).values([
  { name: 'Alice', email: 'alice@example.com' },
  { name: 'Bob', email: 'bob@example.com' },
  { name: 'Charlie', email: 'charlie@example.com' },
]);

// Batch update with CASE
await db.execute(sql`
  UPDATE users
  SET status = CASE
    WHEN last_login < NOW() - INTERVAL '30 days' THEN 'inactive'
    ELSE 'active'
  END
`);
```

### Select Only Needed Columns

```typescript
// Instead of selecting all columns
const users = await db.select().from(users);

// Select only what you need
const users = await db.select({
  id: users.id,
  name: users.name,
}).from(users);
```

### Use Prepared Statements for Repeated Queries

```typescript
import { sql } from 'drizzle-orm';

const getUserById = db
  .select()
  .from(users)
  .where(sql`id = ${sql.placeholder('id')}`)
  .prepare('get_user_by_id');

// Execute multiple times efficiently
const user1 = await getUserById.execute({ id: 1 });
const user2 = await getUserById.execute({ id: 2 });
```
