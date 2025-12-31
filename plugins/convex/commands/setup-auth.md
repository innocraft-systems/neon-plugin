---
name: setup-auth
description: Set up Convex Auth for authentication (OAuth, Magic Links, Passwords)
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
argument-hint: "[--github | --google | --password | --magic-link]"
---

# Set Up Convex Auth

Configure Convex Auth for built-in authentication that stores all data in your Convex database.

## Instructions

1. Check prerequisites:
   - Verify `convex/` directory exists
   - Verify project is initialized with Convex

2. Install dependencies:
   ```bash
   npm install @convex-dev/auth @auth/core@0.37.0
   ```

3. Run the auth setup command:
   ```bash
   npx @convex-dev/auth
   ```
   This creates the necessary files automatically.

4. Determine which providers to configure based on flags:
   - `--github`: GitHub OAuth
   - `--google`: Google OAuth
   - `--password`: Email/password authentication
   - `--magic-link`: Magic link (passwordless email)
   - No flag: Ask user which providers they want

5. Create/update `convex/auth.ts`:
   ```typescript
   import { convexAuth } from "@convex-dev/auth/server";
   // Import providers based on user selection
   import GitHub from "@auth/core/providers/github";
   import Google from "@auth/core/providers/google";
   import { Password } from "@convex-dev/auth/providers/Password";

   export const { auth, signIn, signOut, store, isAuthenticated } = convexAuth({
     providers: [
       // Add selected providers
       GitHub,
       Google,
       Password,
     ],
   });
   ```

6. Update `convex/schema.ts` to include auth tables:
   ```typescript
   import { authTables } from "@convex-dev/auth/server";
   import { defineSchema, defineTable } from "convex/server";
   import { v } from "convex/values";

   export default defineSchema({
     ...authTables,
     // Your other tables...
   });
   ```

7. Set up environment variables:
   - For OAuth providers, guide user to create OAuth apps
   - Add to Convex dashboard: `npx convex env set AUTH_GITHUB_ID <value>`
   - Required vars depend on selected providers

8. Create client-side auth setup for React:
   ```typescript
   // src/main.tsx or app entry
   import { ConvexAuthProvider } from "@convex-dev/auth/react";

   // Wrap app with ConvexAuthProvider
   ```

9. Print provider-specific setup instructions:
   - GitHub: Create OAuth App at github.com/settings/developers
   - Google: Create credentials at console.cloud.google.com
   - Password/Magic Link: Configure email provider (Resend recommended)

## Tips

- Reference `references/convex-auth.md` for detailed configuration
- OAuth apps need callback URL: `https://<deployment>.convex.site/api/auth/callback/<provider>`
- For password reset, email provider is required
