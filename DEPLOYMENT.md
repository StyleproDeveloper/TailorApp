# 🚀 Deployment Guide - Tailor App

This guide will help you deploy your full-stack Tailor App to production so it can be accessed from any device or network.

## 🌐 **Recommended Hosting Setup: Vercel + Railway**

### **Frontend (Flutter Web) → Vercel**
### **Backend (Node.js) → Railway**

---

## 📋 **Prerequisites**

1. **GitHub Repository:** Your code should be pushed to GitHub
2. **Vercel Account:** Sign up at [vercel.com](https://vercel.com)
3. **Railway Account:** Sign up at [railway.app](https://railway.app)
4. **MongoDB Atlas:** Free database at [mongodb.com/atlas](https://mongodb.com/atlas)

---

## 🔧 **Step 1: Prepare Your Code**

### 1.1 Build Flutter Web App
```bash
# Run the deployment script
./scripts/deploy.sh

# Or manually:
flutter build web --release
```

### 1.2 Commit and Push to GitHub
```bash
git add .
git commit -m "Prepare for production deployment"
git push origin main
```

---

## 🎨 **Step 2: Deploy Frontend to Vercel**

### 2.1 Connect to Vercel
1. Go to [vercel.com](https://vercel.com)
2. Click "New Project"
3. Import your GitHub repository
4. Select the root directory

### 2.2 Configure Vercel
- **Framework Preset:** Other
- **Root Directory:** `./` (root)
- **Build Command:** `flutter build web --release`
- **Output Directory:** `build/web`

### 2.3 Deploy
- Click "Deploy"
- Wait for deployment to complete
- Your app will be available at: `https://your-app-name.vercel.app`

---

## ⚙️ **Step 3: Deploy Backend to Railway**

### 3.1 Connect to Railway
1. Go to [railway.app](https://railway.app)
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Choose your repository
5. Select the `backend` folder

### 3.2 Configure Environment Variables
In Railway dashboard, add these environment variables:

```env
PORT=5500
MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/tailorapp
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRE=7d
NODE_ENV=production
CORS_ORIGIN=https://your-app-name.vercel.app
```

### 3.3 Deploy
- Railway will automatically detect it's a Node.js app
- It will run `npm install` and `npm start`
- Your API will be available at: `https://your-backend-name.railway.app`

---

## 🔗 **Step 4: Connect Frontend to Backend**

### 4.1 Update Frontend URLs
1. Go to your Vercel deployment
2. In the project settings, add environment variable:
   - **Name:** `REACT_APP_API_URL`
   - **Value:** `https://your-backend-name.railway.app`

### 4.2 Update CORS in Backend
In your Railway backend, ensure CORS allows your Vercel domain:
```javascript
// In backend/src/app.js
app.use(
  cors({
    origin: ['https://your-app-name.vercel.app', 'http://localhost:8144'],
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    allowedHeaders: 'Content-Type, Authorization',
  })
);
```

---

## 🗄️ **Step 5: Setup MongoDB Atlas**

### 5.1 Create MongoDB Atlas Account
1. Go to [mongodb.com/atlas](https://mongodb.com/atlas)
2. Create a free account
3. Create a new cluster (free tier)

### 5.2 Get Connection String
1. Click "Connect" on your cluster
2. Choose "Connect your application"
3. Copy the connection string
4. Replace `<password>` with your database password
5. Use this string in Railway environment variables

### 5.3 Configure Network Access
1. In Atlas dashboard, go to "Network Access"
2. Add IP address `0.0.0.0/0` (allow all IPs)
3. Or add specific IPs for better security

---

## 🧪 **Step 6: Test Your Deployment**

### 6.1 Test Frontend
- Visit your Vercel URL
- Check if the app loads correctly
- Test navigation and UI

### 6.2 Test Backend
- Visit `https://your-backend-name.railway.app/api-docs`
- Check if Swagger documentation loads
- Test API endpoints

### 6.3 Test Integration
- Try logging in from the frontend
- Check if API calls work
- Test all major features

---

## 🔄 **Step 7: Update URLs for Production**

### 7.1 Update Frontend URLs
```dart
// In lib/Core/Services/Urls.dart
class Urls {
  static const String baseUrl = 'https://your-backend-name.railway.app';
  // ... rest of your URLs
}
```

### 7.2 Redeploy Frontend
```bash
# After updating URLs
git add .
git commit -m "Update URLs for production"
git push origin main
# Vercel will automatically redeploy
```

---

## 📱 **Step 8: Test from Other Devices**

### 8.1 Mobile Testing
- Open your Vercel URL on mobile browser
- Test responsive design
- Check touch interactions

### 8.2 Network Testing
- Test from different networks (WiFi, mobile data)
- Test from different locations
- Check loading times

---

## 🛠️ **Alternative Hosting Options**

### **Option A: Netlify + Render**
- **Frontend:** [netlify.com](https://netlify.com)
- **Backend:** [render.com](https://render.com)

### **Option B: Firebase + Google Cloud**
- **Frontend:** [firebase.google.com](https://firebase.google.com)
- **Backend:** [cloud.google.com](https://cloud.google.com)

### **Option C: AWS**
- **Frontend:** AWS Amplify
- **Backend:** AWS Elastic Beanstalk

---

## 🔧 **Troubleshooting**

### Common Issues:

1. **CORS Errors:**
   - Check CORS configuration in backend
   - Ensure frontend URL is in allowed origins

2. **Environment Variables:**
   - Verify all environment variables are set in Railway
   - Check MongoDB connection string

3. **Build Failures:**
   - Check build logs in Vercel/Railway
   - Ensure all dependencies are in package.json

4. **API Not Working:**
   - Check Railway logs for errors
   - Verify MongoDB connection
   - Test API endpoints directly

---

## 📊 **Monitoring & Maintenance**

### **Vercel:**
- Monitor deployment status
- Check build logs
- Set up custom domain (optional)

### **Railway:**
- Monitor app logs
- Check resource usage
- Set up alerts

### **MongoDB Atlas:**
- Monitor database performance
- Set up backups
- Check connection metrics

---

## 🎉 **You're Live!**

Once deployed, your Tailor App will be accessible from:
- **Frontend:** `https://your-app-name.vercel.app`
- **Backend API:** `https://your-backend-name.railway.app`
- **API Docs:** `https://your-backend-name.railway.app/api-docs`

Share these URLs with your team or clients for testing!

---

## 💰 **Cost Estimation**

### **Free Tier:**
- **Vercel:** Free (with limitations)
- **Railway:** Free (with limitations)
- **MongoDB Atlas:** Free (512MB storage)

### **Paid Tier (Recommended for Production):**
- **Vercel Pro:** $20/month
- **Railway:** $5/month
- **MongoDB Atlas:** $9/month

**Total:** ~$34/month for production hosting
