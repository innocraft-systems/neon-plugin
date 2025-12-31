---
name: init
description: Initialize a new Convex project or add Convex to an existing project
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
argument-hint: "[--new | --existing]"
---

# Initialize Convex Project

Set up Convex in a new or existing project.

## Instructions

1. Determine the initialization type:
   - If `--new` flag: Create a new project with Convex
   - If `--existing` flag: Add Convex to existing project
   - Otherwise: Check if package.json exists to determine

2. For new project:
   ```bash
   npm create convex@latest
   ```
   Guide user through the prompts if needed.

3. For existing project:
   ```bash
   npm install convex
   npx convex dev
   ```

4. Verify the setup created:
   - `convex/` directory exists
   - `convex/_generated/` directory exists
   - `convex.json` configuration file

5. Create initial schema if not exists:
   ```typescript
   // convex/schema.ts
   import { defineSchema, defineTable } from "convex/server";
   import { v } from "convex/values";

   export default defineSchema({
     // Add your tables here
   });
   ```

6. Set up environment:
   - Ensure `.env.local` has `CONVEX_DEPLOYMENT` (set by `convex dev`)
   - Add `.env.local` to `.gitignore` if not present

7. Print next steps:
   - Run `npx convex dev` to start development
   - Define schema in `convex/schema.ts`
   - Create functions in `convex/` directory
   - Reference the convex skill for detailed documentation

## Tips

- Recommend TypeScript for best developer experience
- Suggest installing ESLint plugin: `npm install -D @convex-dev/eslint-plugin`
- For React projects, wrap app with `ConvexProvider`
