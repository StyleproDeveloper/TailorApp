# Vercel Projects Guide - Understanding Your Deployments

## Expected Projects (2 Total)

### 1. **Frontend Project** (Flutter Web App)
- **Project Name**: `tailorapp-static` or `tailorapp`
- **Root Directory**: `/` (root of repository)
- **Configuration**: `vercel.json` (root)
- **Purpose**: Serves the Flutter web application
- **URL Pattern**: `https://tailorapp-*.vercel.app` or `https://tailorapp-static.vercel.app`

### 2. **Backend Project** (Node.js API)
- **Project Name**: `backend` or `tailorapp-backend`
- **Root Directory**: `/backend` (backend folder)
- **Configuration**: `backend/vercel.json`
- **Purpose**: Serves the Express.js API
- **URL Pattern**: `https://backend-*.vercel.app` or `https://backend-stylepros-projects.vercel.app`

## Why You Might See 3+ Deployments

### Reason 1: Preview Deployments (Normal)
- Vercel automatically creates **preview deployments** for:
  - Pull requests
  - Different branches (if configured)
  - Each commit (if auto-deploy is enabled)
- These are **temporary** and can be ignored or deleted

### Reason 2: Duplicate Projects (Needs Cleanup)
- If you accidentally created the same project twice
- Check Vercel dashboard for duplicate project names

### Reason 3: Root Project Deployed Multiple Times
- If the root directory is being deployed as a separate project
- This shouldn't happen if configured correctly

## How to Check Your Projects

1. **Go to Vercel Dashboard**: https://vercel.com/dashboard
2. **Check Projects Tab**: You should see your projects listed
3. **Look for**:
   - Project names
   - Root directories
   - Deployment URLs

## Recommended Setup

### Keep These 2 Projects:
✅ **Frontend** (root directory)  
✅ **Backend** (backend directory)

### Delete/Disable:
❌ Any duplicate projects  
❌ Preview deployments (they auto-delete after PR merge)

## How to Clean Up

### Option 1: Delete Duplicate Projects
1. Go to Vercel Dashboard
2. Find the duplicate project
3. Go to **Settings** → **General**
4. Scroll down and click **"Delete Project"**

### Option 2: Disable Auto-Deploy for Unwanted Projects
1. Go to project **Settings** → **Git**
2. Disable **"Auto Deploy"** for projects you don't want

### Option 3: Configure Root Directory Correctly
1. Go to project **Settings** → **General**
2. Set **Root Directory**:
   - Frontend: `./` (root)
   - Backend: `./backend`

## Current Configuration

Based on your repository:
- **Root `vercel.json`**: Frontend configuration ✅
- **`backend/vercel.json`**: Backend configuration ✅

Both should be deployed as **separate projects** with correct root directories.

## Next Steps

1. **Check Vercel Dashboard** to identify which 3 projects exist
2. **Verify root directories** are set correctly
3. **Delete any duplicates** if found
4. **Keep only the 2 main projects** (Frontend + Backend)


