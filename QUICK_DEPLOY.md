# 🚀 Quick Production Deployment

## ⚡ Fast Track Deployment (5 minutes)

### Step 1: Commit All Changes

```bash
cd /Users/dhivyan/TailorApp
git add .
git commit -m "Production deployment: Trial period, S3 integration, Payment edit"
git push origin master
```

### Step 2: Deploy Backend to Vercel

```bash
cd backend

# Make sure you're logged in
vercel login

# Deploy to production
vercel --prod --yes
```

**After deployment, note your backend URL** (e.g., `https://backend-xxxxx.vercel.app`)

### Step 3: Set Environment Variables in Vercel

Go to: [Vercel Dashboard](https://vercel.com/dashboard) → Your Project → Settings → Environment Variables

**Add these variables for Production, Preview, and Development:**

```
MONGO_URL=mongodb+srv://StylePro:stylePro123@stylepro.5ttc1.mongodb.net/
NODE_ENV=production
JWT_SECRET=your-secure-random-secret-key-change-this
PORT=5500
AWS_ACCESS_KEY_ID=YOUR_AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=YOUR_AWS_SECRET_ACCESS_KEY
AWS_REGION=ap-south-1
FRONTEND_URL=https://your-frontend-domain.vercel.app
```

### Step 4: Update Frontend API URL (if needed)

If deploying to a new backend URL, update `lib/Core/Services/Urls.dart`:

```dart
// Change line 22 to your new backend URL
final url = 'https://your-new-backend-url.vercel.app';
```

### Step 5: Build and Deploy Frontend

```bash
cd /Users/dhivyan/TailorApp

# Build Flutter web app
flutter build web --release

# Deploy to Vercel
vercel --prod --yes
```

### Step 6: Verify Deployment

1. **Test Backend Health:**
   ```bash
   curl https://your-backend-url.vercel.app/health
   ```

2. **Test Login:**
   - Open frontend URL
   - Try logging in with a test account

3. **Test Features:**
   - Create a new shop (should set trial dates)
   - Upload an image (should go to S3)
   - Edit a payment (should work)
   - Check trial expiration logic

---

## 🔍 Troubleshooting

### Backend not responding?
- Check Vercel logs: `vercel logs --follow`
- Verify environment variables are set
- Check MongoDB connection string

### CORS errors?
- Verify `FRONTEND_URL` is set correctly
- Check CORS headers in `backend/api/index.js`

### S3 upload fails?
- Verify AWS credentials are correct
- Check S3 bucket CORS configuration
- Verify bucket exists for the shop

---

## ✅ Post-Deployment Checklist

- [ ] Backend health check passes
- [ ] User can login successfully
- [ ] New shop creation sets trial dates
- [ ] Image upload works (S3)
- [ ] Payment edit works
- [ ] Trial expiration redirects to subscribe page
- [ ] All environment variables set
- [ ] MongoDB connection working
- [ ] S3 buckets created for existing shops

---

## 📞 Need Help?

Check the detailed guide: `PRODUCTION_DEPLOYMENT_GUIDE.md`

