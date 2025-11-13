# Fix: Update Order Failing - AdditionalCosts Not Allowed

## Issue
Update order is failing with error: `["AdditionalCosts" is not allowed]`

## Root Cause
The production backend on Vercel doesn't have the latest validation fixes that allow `AdditionalCosts` in the update order request.

## Solution: Redeploy Backend on Vercel

### Step 1: Go to Vercel Dashboard
1. Go to https://vercel.com/dashboard
2. Find your **BACKEND** project (not frontend)
3. The project name might be:
   - `backend`
   - `stylepros-backend`
   - Or check the URL: `backend-m5vayhncz-stylepros-projects.vercel.app`

### Step 2: Redeploy Backend
1. Go to **Deployments** tab
2. Find the latest deployment
3. Click **"Redeploy"** button
4. Or click **"Deploy"** → **"Deploy Latest Commit"**

### Step 3: Verify Deployment
1. Wait 2-5 minutes for deployment to complete
2. Check build logs for any errors
3. Test update order again

## What Will Be Fixed
After redeployment, the backend will have:
- ✅ `validateRequest.js` with `allowUnknown: true` (allows AdditionalCosts)
- ✅ `OrderValidation.js` with AdditionalCosts schema
- ✅ Support for AdditionalCosts in update order requests

## Verification
After redeployment, the update order should work with:
- Empty AdditionalCosts array: `AdditionalCosts: []`
- AdditionalCosts with items: `AdditionalCosts: [{additionalCostName: "...", additionalCost: 150}]`

## Latest Commits on GitHub
All fixes are already in GitHub:
- `de71a4b` - Revert: Keep working AdditionalCosts validation
- `582bb14` - Fix: Make AdditionalCosts validation more explicit
- `7242ffc` - Fix: Allow AdditionalCosts in order updates

The backend just needs to be redeployed to pick up these changes!
