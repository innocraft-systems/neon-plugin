---
name: add-cron
description: Add a cron job or scheduled function to your Convex project
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
argument-hint: "<name> <schedule>"
---

# Add Cron Job

Create a scheduled function that runs on a cron schedule.

## Instructions

1. Parse arguments:
   - `<name>`: Cron job name (e.g., `cleanupOldData`, `sendDailyDigest`)
   - `<schedule>`: Cron expression or interval (e.g., `"0 0 * * *"`, `"every 1 hour"`)

2. Check if `convex/crons.ts` exists:
   - If not, create it with the cron router setup
   - If exists, add the new cron job

3. Create the internal function that the cron will call:
   ```typescript
   // convex/scheduled.ts (or appropriate file)
   import { internalMutation, internalAction } from "./_generated/server";

   export const cronJobName = internalMutation({
     args: {},
     handler: async (ctx) => {
       // Cron job logic here
       console.log("Cron job running at", new Date().toISOString());

       // Example: Clean up old records
       const oldRecords = await ctx.db
         .query("logs")
         .filter((q) => q.lt(q.field("createdAt"), Date.now() - 30 * 24 * 60 * 60 * 1000))
         .collect();

       for (const record of oldRecords) {
         await ctx.db.delete(record._id);
       }
     },
   });
   ```

4. Create or update `convex/crons.ts`:
   ```typescript
   import { cronJobs } from "convex/server";
   import { internal } from "./_generated/api";

   const crons = cronJobs();

   // Using cron expression
   crons.cron(
     "job description",
     "0 0 * * *", // Daily at midnight UTC
     internal.scheduled.cronJobName
   );

   // OR using interval syntax
   crons.interval(
     "job description",
     { hours: 1 }, // Every hour
     internal.scheduled.cronJobName
   );

   export default crons;
   ```

5. Explain cron schedule options:

   **Cron expression format:** `minute hour day month weekday`

   | Expression | Description |
   |------------|-------------|
   | `* * * * *` | Every minute |
   | `0 * * * *` | Every hour |
   | `0 0 * * *` | Daily at midnight |
   | `0 0 * * 0` | Weekly on Sunday |
   | `0 0 1 * *` | Monthly on the 1st |

   **Interval options:**
   ```typescript
   { seconds: 30 }
   { minutes: 5 }
   { hours: 1 }
   { days: 1 }
   ```

6. Important notes:
   - Cron functions must be internal (use `internalMutation` or `internalAction`)
   - Times are in UTC
   - Minimum interval is 1 second (but be mindful of costs)
   - Use `internalAction` if you need to call external APIs

7. For one-time scheduled tasks, show alternative:
   ```typescript
   // Schedule from a mutation
   await ctx.scheduler.runAfter(
     60 * 1000, // 1 minute from now
     internal.scheduled.someFunction,
     { arg: "value" }
   );

   // Schedule at specific time
   await ctx.scheduler.runAt(
     new Date("2024-12-31T23:59:59Z").getTime(),
     internal.scheduled.newYearFunction,
     {}
   );
   ```

8. Print deployment note:
   - Crons are automatically deployed with `npx convex dev` or `npx convex deploy`
   - View scheduled jobs in Convex dashboard

## Tips

- Use internal functions to prevent external access
- Consider timezone when scheduling daily tasks
- Reference `references/scheduling.md` for advanced patterns
- Use the Convex dashboard to monitor cron executions
