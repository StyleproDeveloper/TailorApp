# 🚀 Backend Deployment Guide - Railway

This guide will help you deploy your Tailor App backend to Railway.

## 📋 Prerequisites

1. **Railway Account** - Sign up at [railway.app](https://railway.app)
2. **MongoDB Atlas Account** - For production database
3. **Railway CLI** - For deployment (optional)

## 🔧 Step 1: Setup MongoDB Atlas

1. **Create MongoDB Atlas Cluster:**
   - Go to [mongodb.com/atlas](https://mongodb.com/atlas)
   - Create a free cluster
   - Get your connection string

2. **Configure Database Access:**
   - Add your IP address to the whitelist (or use 0.0.0.0/0 for all IPs)
   - Create a database user
   - Note down the connection string

## 🚀 Step 2: Deploy to Railway

### Option A: Using Railway Web Interface (Recommended)

1. **Go to Railway Dashboard:**
   - Visit [railway.app/dashboard](https://railway.app/dashboard)
   - Click "New Project"

2. **Deploy from GitHub:**
   - Select "Deploy from GitHub repo"
   - Choose your `StyleproDeveloper/TailorApp` repository
   - Select the `backend` folder as the root directory

3. **Configure Environment Variables:**
   - Go to your project settings
   - Add these environment variables:
     ```
     MONGO_URL=mongodb+srv://username:password@cluster.mongodb.net/tailorapp?retryWrites=true&w=majority
     JWT_SECRET=your_secure_jwt_secret_here
     NODE_ENV=production
     PORT=5500
     ```

4. **Deploy:**
   - Railway will automatically detect it's a Node.js project
   - It will run `npm install` and `npm start`
   - Your backend will be deployed!

### Option B: Using Railway CLI

1. **Install Railway CLI:**
   ```bash
   npm install -g @railway/cli
   ```

2. **Login to Railway:**
   ```bash
   railway login
   ```

3. **Deploy from Backend Directory:**
   ```bash
   cd backend
   railway up
   ```

4. **Set Environment Variables:**
   ```bash
   railway variables set MONGO_URL="your_mongodb_connection_string"
   railway variables set JWT_SECRET="your_jwt_secret"
   railway variables set NODE_ENV="production"
   ```

## 🔗 Step 3: Get Your Backend URL

After deployment, Railway will provide you with a URL like:
- `https://your-app-name.railway.app`

## 📊 Step 4: Test Your Backend

1. **Health Check:**
   ```bash
   curl https://your-app-name.railway.app/
   ```

2. **API Documentation:**
   Visit: `https://your-app-name.railway.app/api-docs`

3. **Test API Endpoints:**
   ```bash
   # Test shops endpoint
   curl https://your-app-name.railway.app/api/shops
   
   # Test auth endpoint
   curl -X POST https://your-app-name.railway.app/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{"mobileNumber":"1234567890"}'
   ```

## 🔧 Step 5: Update Frontend Configuration

Update your frontend to point to the new backend URL:

1. **Edit `lib/Core/Services/Urls.dart`:**
   ```dart
   class Urls {
     static const String baseUrl = 'https://your-app-name.railway.app';
     // ... rest of your URLs
   }
   ```

2. **Redeploy Frontend:**
   ```bash
   flutter build web --release
   # Copy to static directory and deploy to Vercel
   ```

## 🛠️ Troubleshooting

### Common Issues

1. **MongoDB Connection Error:**
   - Check your MongoDB Atlas connection string
   - Ensure IP whitelist includes Railway's IPs
   - Verify database user has proper permissions

2. **Environment Variables Not Set:**
   - Double-check all required environment variables are set
   - Ensure no typos in variable names

3. **Build Failures:**
   - Check Railway deployment logs
   - Ensure all dependencies are in package.json
   - Verify Node.js version compatibility

### Debugging Commands

```bash
# Check Railway logs
railway logs

# Check deployment status
railway status

# View environment variables
railway variables
```

## 📈 Monitoring

1. **Railway Dashboard:**
   - Monitor resource usage
   - View deployment logs
   - Check error rates

2. **MongoDB Atlas:**
   - Monitor database performance
   - Check connection metrics
   - Set up alerts

## 🔄 Updates and Maintenance

### Deploying Updates

1. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "Update backend"
   git push origin main
   ```

2. **Railway Auto-Deploy:**
   - Railway will automatically detect changes
   - It will redeploy your backend

### Environment Management

- **Development:** Use local MongoDB
- **Production:** Use MongoDB Atlas
- **Staging:** Create a separate Railway project

## 🎉 Success!

Once deployed, your backend will be:
- ✅ Accessible at `https://your-app-name.railway.app`
- ✅ Connected to MongoDB Atlas
- ✅ Ready to serve your Flutter frontend
- ✅ Documented at `/api-docs`

## 📞 Support

If you encounter issues:
1. Check Railway deployment logs
2. Verify MongoDB Atlas connection
3. Review environment variables
4. Check Railway documentation: [docs.railway.app](https://docs.railway.app)
