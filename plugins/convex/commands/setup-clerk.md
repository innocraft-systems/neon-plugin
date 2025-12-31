---
name: setup-clerk
description: Set up Clerk authentication integration with Convex
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
---

# Set Up Clerk with Convex

Configure Clerk as the authentication provider for your Convex application.

## Instructions

1. Check prerequisites:
   - Verify `convex/` directory exists
   - Verify project has a frontend framework (Next.js, React, etc.)

2. Install Clerk SDK:
   ```bash
   # For Next.js
   npm install @clerk/nextjs

   # For React
   npm install @clerk/clerk-react
   ```

3. Guide user to create Clerk account and application:
   - Go to clerk.com and create an account
   - Create a new application
   - Get the Publishable Key and Secret Key

4. Set up environment variables:
   ```bash
   # Add to .env.local
   NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_...
   CLERK_SECRET_KEY=sk_...
   ```

5. Create `convex/auth.config.ts`:
   ```typescript
   export default {
     providers: [
       {
         domain: process.env.CLERK_JWT_ISSUER_DOMAIN,
         applicationID: "convex",
       },
     ],
   };
   ```

6. Configure Clerk JWT template in Clerk Dashboard:
   - Go to JWT Templates in Clerk Dashboard
   - Create new template named "convex"
   - Set issuer to your Clerk domain
   - Add claims as needed

7. Set Convex environment variable:
   ```bash
   npx convex env set CLERK_JWT_ISSUER_DOMAIN https://<your-clerk-domain>.clerk.accounts.dev
   ```

8. Set up Clerk Provider in frontend:

   **Next.js (App Router):**
   ```typescript
   // app/layout.tsx
   import { ClerkProvider } from "@clerk/nextjs";
   import { ConvexProviderWithClerk } from "convex/react-clerk";
   import { ConvexReactClient } from "convex/react";
   import { useAuth } from "@clerk/nextjs";

   const convex = new ConvexReactClient(process.env.NEXT_PUBLIC_CONVEX_URL!);

   export default function RootLayout({ children }) {
     return (
       <ClerkProvider>
         <ConvexProviderWithClerk client={convex} useAuth={useAuth}>
           {children}
         </ConvexProviderWithClerk>
       </ClerkProvider>
     );
   }
   ```

   **React:**
   ```typescript
   // src/main.tsx
   import { ClerkProvider, useAuth } from "@clerk/clerk-react";
   import { ConvexProviderWithClerk } from "convex/react-clerk";
   import { ConvexReactClient } from "convex/react";

   const convex = new ConvexReactClient(import.meta.env.VITE_CONVEX_URL);

   ReactDOM.createRoot(document.getElementById("root")!).render(
     <ClerkProvider publishableKey={import.meta.env.VITE_CLERK_PUBLISHABLE_KEY}>
       <ConvexProviderWithClerk client={convex} useAuth={useAuth}>
         <App />
       </ConvexProviderWithClerk>
     </ClerkProvider>
   );
   ```

9. Create helper for authenticated functions:
   ```typescript
   // convex/users.ts
   import { query, mutation } from "./_generated/server";

   export const getMe = query({
     args: {},
     handler: async (ctx) => {
       const identity = await ctx.auth.getUserIdentity();
       if (!identity) return null;

       return await ctx.db
         .query("users")
         .withIndex("by_token", (q) =>
           q.eq("tokenIdentifier", identity.tokenIdentifier)
         )
         .unique();
     },
   });
   ```

10. Print next steps:
    - Add Clerk components (`<SignInButton>`, `<UserButton>`)
    - Use `ctx.auth.getUserIdentity()` in functions
    - Reference `references/third-party-auth.md` for advanced patterns

## Tips

- Clerk handles all UI components for auth
- User data syncs automatically via JWT
- Consider storing user data in Convex for custom fields
