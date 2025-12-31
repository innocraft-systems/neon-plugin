---
name: add-function
description: Create a new Convex function (query, mutation, action, or HTTP action)
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
argument-hint: "<type> <name> [--file <filename>]"
---

# Add Convex Function

Create a new Convex function with proper typing and structure.

## Instructions

1. Parse arguments:
   - `<type>`: query | mutation | action | http
   - `<name>`: Function name (e.g., `getUser`, `createPost`)
   - `--file`: Optional filename (defaults to inferring from name)

2. Determine the file location:
   - If `--file` specified, use that file in `convex/` directory
   - Otherwise, infer from function name (e.g., `getUser` -> `convex/users.ts`)

3. Check if file exists:
   - If exists, append the new function
   - If not, create new file with proper imports

4. Generate function based on type:

   **Query:**
   ```typescript
   import { query } from "./_generated/server";
   import { v } from "convex/values";

   export const functionName = query({
     args: {
       // Define arguments
     },
     handler: async (ctx, args) => {
       // Read from database
       return await ctx.db.query("tableName").collect();
     },
   });
   ```

   **Mutation:**
   ```typescript
   import { mutation } from "./_generated/server";
   import { v } from "convex/values";

   export const functionName = mutation({
     args: {
       // Define arguments
     },
     handler: async (ctx, args) => {
       // Write to database
       return await ctx.db.insert("tableName", { ...args });
     },
   });
   ```

   **Action:**
   ```typescript
   import { action } from "./_generated/server";
   import { v } from "convex/values";

   export const functionName = action({
     args: {
       // Define arguments
     },
     handler: async (ctx, args) => {
       // Call external APIs, then use runMutation/runQuery for database
       const result = await fetch("https://api.example.com/...");
       return result.json();
     },
   });
   ```

   **HTTP Action:**
   ```typescript
   import { httpAction } from "./_generated/server";

   export const functionName = httpAction(async (ctx, request) => {
     // Handle HTTP request
     const body = await request.json();

     return new Response(JSON.stringify({ success: true }), {
       status: 200,
       headers: { "Content-Type": "application/json" },
     });
   });
   ```

5. If HTTP action, remind user to register in `convex/http.ts`:
   ```typescript
   import { httpRouter } from "convex/server";
   import { functionName } from "./filename";

   const http = httpRouter();
   http.route({
     path: "/api/endpoint",
     method: "POST",
     handler: functionName,
   });
   export default http;
   ```

6. Ask user for:
   - Function arguments (what data it needs)
   - For queries/mutations: which table(s) it operates on
   - For actions: what external API it calls

7. Generate appropriate argument validators using `v.*` syntax.

## Tips

- Queries are for reading data (automatically cached and reactive)
- Mutations are for writing data (transactional)
- Actions are for external API calls (not transactional)
- Use internal functions for scheduled jobs
- Reference the convex skill for detailed patterns
