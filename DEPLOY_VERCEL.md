# 🚀 Vercel Deployment Guide for Flutter

## Problem
Vercel doesn't have Flutter pre-installed, causing `flutter: command not found` errors.

## Solutions

### Solution 1: Pre-build Approach (Recommended for Reliability)

1. **Build locally:**
   ```bash
   flutter build web --release
   ```

2. **Commit the build folder:**
   ```bash
   git add build/web
   git commit -m "Add pre-built Flutter web app"
   git push origin master
   ```

3. **Update vercel.json:**
   ```json
   {
     "version": 2,
     "buildCommand": "echo 'Using pre-built Flutter app'",
     "outputDirectory": "build/web"
   }
   ```

4. **Deploy:** Vercel will use the pre-built files.

### Solution 2: Build Script (Current Implementation)

The `build.sh` script attempts to install Flutter during build:
- ✅ Works if Vercel allows enough time/resources
- ⚠️ May timeout on first build (Flutter installation takes time)
- ✅ Subsequent builds are faster (cached)

**To use:**
1. Go to Vercel Dashboard
2. Find project: `tailorapp-static`
3. Click "Redeploy"

### Solution 3: GitHub Actions (Most Reliable)

1. **Add workflow file manually** (requires token with `workflow` scope):
   - File: `.github/workflows/deploy-vercel.yml`
   - See the file in the repo for the workflow

2. **Set up GitHub Secrets:**
   - Go to: Settings → Secrets and variables → Actions
   - Add:
     - `VERCEL_TOKEN`
     - `VERCEL_ORG_ID`
     - `VERCEL_PROJECT_ID`: `prj_FDaEPX9CD8VKTmtHwphpTmqN5Yoe`

3. **Auto-deploys on push to master**

## Current Status

✅ `build.sh` script created and pushed
✅ `vercel.json` updated to use build script
⏳ Ready for Vercel redeploy

## Next Steps

1. **Try Solution 2 first** (build.sh):
   - Go to Vercel Dashboard
   - Redeploy the latest commit
   - Monitor build logs

2. **If Solution 2 fails/timeouts:**
   - Use Solution 1 (pre-build)
   - Or set up Solution 3 (GitHub Actions)

## Build Time Estimates

- **Flutter installation:** ~2-3 minutes
- **Dependencies (flutter pub get):** ~30 seconds
- **Build (flutter build web):** ~1-2 minutes
- **Total:** ~4-6 minutes (first time)
- **Subsequent builds:** ~2-3 minutes (cached)

## Troubleshooting

### Build Timeout
- Vercel free tier: 45 seconds (may not be enough)
- Vercel Pro: 5 minutes (should work)
- **Solution:** Use pre-build approach or GitHub Actions

### Flutter Not Found
- Ensure `build.sh` is executable: `chmod +x build.sh`
- Check build logs for installation errors

### Build Success but 404
- Verify `outputDirectory` is `build/web`
- Check `vercel.json` rewrites configuration

