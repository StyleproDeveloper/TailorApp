# Vercel Deployment Guide

## Current Issue
Auto-deployment from GitHub is not working. Manual deployment needed.

## Solution: Manual Deployment via Vercel Dashboard

### Step 1: Check Project Connection
1. Go to https://vercel.com/dashboard
2. Check if project exists
3. If not, create new project

### Step 2: Connect GitHub Repository
1. Go to Project Settings → Git
2. Click "Connect Git Repository"
3. Select: StyleproDeveloper/TailorApp
4. Select branch: **master** (important!)
5. Enable "Auto Deploy"

### Step 3: Configure Build Settings
- **Framework Preset**: Other
- **Build Command**: `chmod +x build.sh && bash build.sh`
- **Output Directory**: `build/web`
- **Install Command**: `echo 'Install handled in build script'`
- **Root Directory**: `./`

### Step 4: Deploy
1. Go to "Deployments" tab
2. Click "Deploy" button
3. Or click "Redeploy" on existing deployment

## Alternative: Vercel CLI Deployment

```bash
cd /Users/dhivyan/TailorApp
vercel login
vercel --prod
```

## Verify Deployment
- Check Vercel dashboard for build logs
- Wait 2-5 minutes for build to complete
- Test the deployed app URL

## Latest Commits on GitHub
- bb12a21 - Trigger Vercel deployment
- d8a441e - Fix Vercel deployment issues
- All features are in the code!
