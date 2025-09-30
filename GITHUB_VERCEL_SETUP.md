# 🚀 GitHub-Vercel Integration Setup Guide

This guide will help you set up automatic deployments from GitHub to Vercel for your Tailor App.

## 📋 Current Project Information

### Vercel Projects
- **Frontend Project**: `tailorapp-static`
  - **Project ID**: `prj_FDaEPX9CD8VKTmtHwphpTmqN5Yoe`
  - **URL**: https://tailorapp-static.vercel.app

- **Backend Project**: `backend`
  - **Project ID**: `prj_YoMui4g2ZmRAMbk4Vayz9xCASRrc`
  - **URL**: https://backend-stylepros-projects.vercel.app

## 🔧 Setup Steps

### Step 1: Get Vercel Token

1. Go to [Vercel Account Tokens](https://vercel.com/account/tokens)
2. Click "Create Token"
3. Name it "GitHub Actions"
4. Copy the token (you'll need it for GitHub secrets)

### Step 2: Get Vercel Org ID

Run this command to get your org ID:
```bash
vercel whoami
```

Look for the `orgId` in the output.

### Step 3: Set Up GitHub Secrets

1. Go to your GitHub repository: https://github.com/StyleproDeveloper/TailorApp
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"** and add these secrets:

#### Required Secrets:
- **VERCEL_TOKEN**: Your Vercel token from Step 1
- **VERCEL_ORG_ID**: Your org ID from Step 2
- **VERCEL_PROJECT_ID**: `prj_FDaEPX9CD8VKTmtHwphpTmqN5Yoe` (frontend)
- **VERCEL_BACKEND_PROJECT_ID**: `prj_YoMui4g2ZmRAMbk4Vayz9xCASRrc` (backend)

### Step 4: Commit and Push

The GitHub Actions workflow is already set up in `.github/workflows/deploy.yml`. Just commit and push your changes:

```bash
git add .
git commit -m "Add GitHub-Vercel integration"
git push origin main
```

## 🎯 How It Works

### Automatic Deployment Triggers:
- **Push to main/master branch**: Deploys both frontend and backend
- **Pull requests**: Creates preview deployments

### Deployment Process:
1. **Frontend**: 
   - Installs Flutter dependencies
   - Builds Flutter web app
   - Deploys to Vercel

2. **Backend**:
   - Installs Node.js dependencies
   - Deploys to Vercel as serverless functions

## 🔍 Monitoring Deployments

### GitHub Actions:
- Go to your repository's **Actions** tab
- Watch the deployment progress in real-time
- See build logs and any errors

### Vercel Dashboard:
- Visit [Vercel Dashboard](https://vercel.com/dashboard)
- See deployment history and status
- Monitor performance and analytics

## 🚨 Troubleshooting

### Common Issues:

1. **Build Failures**:
   - Check the Actions tab for error logs
   - Ensure all dependencies are in `pubspec.yaml` and `package.json`

2. **Environment Variables**:
   - Backend environment variables are already set in Vercel
   - Frontend uses the backend URL from `Urls.dart`

3. **Deployment Not Triggered**:
   - Ensure you're pushing to the correct branch (main/master)
   - Check that GitHub secrets are properly set

## 🎉 Benefits

✅ **Automatic Deployments**: No manual deployment needed
✅ **Preview Deployments**: Test changes before merging
✅ **Rollback Capability**: Easy to revert to previous versions
✅ **Build Logs**: Full visibility into deployment process
✅ **Team Collaboration**: Everyone can see deployment status

## 📱 Your Live URLs

After setup, your app will be available at:
- **Frontend**: https://tailorapp-static.vercel.app
- **Backend**: https://backend-stylepros-projects.vercel.app

## 🔄 Testing the Setup

1. Make a small change to your code (e.g., update a comment)
2. Commit and push to GitHub
3. Go to the Actions tab in your GitHub repository
4. Watch the automatic deployment happen!
5. Visit your live URLs to see the changes

---

**Need Help?** Check the [GitHub Actions documentation](https://docs.github.com/en/actions) or [Vercel documentation](https://vercel.com/docs).
