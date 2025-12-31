---
name: deploy
description: Deploy Convex functions to production
allowed-tools:
  - Bash
  - Read
  - Glob
---

# Deploy to Production

Deploy your Convex functions and schema to production.

## Instructions

1. Verify the project is ready for deployment:
   - Check `convex/` directory exists
   - Check for `convex.json` configuration
   - Ensure no TypeScript errors in convex directory

2. Run type check on Convex functions:
   ```bash
   npx tsc --noEmit -p convex/tsconfig.json
   ```

3. If there are pending schema changes, warn the user:
   - Schema changes may affect production data
   - Recommend testing on a preview deployment first

4. Deploy to production:
   ```bash
   npx convex deploy
   ```

5. If environment variables need to be set:
   ```bash
   npx convex env set VARIABLE_NAME value --prod
   ```

6. Verify deployment:
   - Check Convex dashboard for deployment status
   - Verify functions are listed correctly
   - Check for any deployment errors

7. Print post-deployment checklist:
   - [ ] Verify functions work in production
   - [ ] Check environment variables are set
   - [ ] Monitor logs for errors: `npx convex logs --prod`
   - [ ] Update frontend CONVEX_URL if needed

## Tips

- Use `npx convex deploy --preview <name>` for preview deployments
- Preview deployments are great for testing schema migrations
- Always test in preview before deploying breaking changes
- Use `npx convex logs --prod` to monitor production logs
