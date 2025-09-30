# 🚀 Vercel Backend Setup Guide

Your backend has been successfully deployed to Vercel! Here's how to complete the setup.

## ✅ **Current Status**

- **Backend URL:** https://backend-ei2tj5mzt-stylepros-projects.vercel.app
- **Status:** Deployed but needs environment variables
- **Authentication:** Currently protected (this is normal)

## 🔧 **Step 1: Set Environment Variables**

You need to set up environment variables for your backend to work properly.

### **Option A: Using Vercel Dashboard (Recommended)**

1. **Go to Vercel Dashboard:**
   - Visit [vercel.com/dashboard](https://vercel.com/dashboard)
   - Find your `backend` project
   - Click on it

2. **Go to Settings:**
   - Click on "Settings" tab
   - Click on "Environment Variables" in the left sidebar

3. **Add These Variables:**
   ```
   Name: MONGO_URL
   Value: mongodb+srv://username:password@cluster.mongodb.net/tailorapp?retryWrites=true&w=majority
   Environment: Production
   
   Name: JWT_SECRET
   Value: your_secure_jwt_secret_here_make_it_long_and_random
   Environment: Production
   
   Name: NODE_ENV
   Value: production
   Environment: Production
   ```

4. **Save and Redeploy:**
   - Click "Save" for each variable
   - Go to "Deployments" tab
   - Click "Redeploy" on the latest deployment

### **Option B: Using Vercel CLI**

```bash
cd backend

# Add MONGO_URL
vercel env add MONGO_URL production
# Enter your MongoDB connection string when prompted

# Add JWT_SECRET
vercel env add JWT_SECRET production
# Enter a secure random string when prompted

# Add NODE_ENV
vercel env add NODE_ENV production
# Enter "production" when prompted

# Redeploy
vercel --prod --yes
```

## 🔗 **Step 2: Get Your MongoDB Connection String**

If you don't have MongoDB Atlas set up yet:

1. **Create MongoDB Atlas Account:**
   - Go to [mongodb.com/atlas](https://mongodb.com/atlas)
   - Sign up for free

2. **Create Cluster:**
   - Click "Build a Database"
   - Choose "FREE" tier
   - Select a region close to you
   - Click "Create"

3. **Create Database User:**
   - Go to "Database Access"
   - Click "Add New Database User"
   - Create username and password
   - Click "Add User"

4. **Whitelist IP Addresses:**
   - Go to "Network Access"
   - Click "Add IP Address"
   - Click "Allow Access from Anywhere" (0.0.0.0/0)
   - Click "Confirm"

5. **Get Connection String:**
   - Go to "Database"
   - Click "Connect" on your cluster
   - Choose "Connect your application"
   - Copy the connection string
   - Replace `<password>` with your database user password

## 🧪 **Step 3: Test Your Backend**

After setting environment variables and redeploying:

### **Test Health Check:**
```bash
curl https://backend-ei2tj5mzt-stylepros-projects.vercel.app/
```

### **Test API Documentation:**
Visit: https://backend-ei2tj5mzt-stylepros-projects.vercel.app/api-docs

### **Test API Endpoints:**
```bash
# Test shops endpoint
curl https://backend-ei2tj5mzt-stylepros-projects.vercel.app/shops

# Test auth endpoint
curl -X POST https://backend-ei2tj5mzt-stylepros-projects.vercel.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"mobileNumber":"1234567890"}'
```

## 🔧 **Step 4: Update Frontend Configuration**

Update your Flutter frontend to point to the new backend:

1. **Edit `lib/Core/Services/Urls.dart`:**
   ```dart
   class Urls {
     static const String baseUrl = 'https://backend-ei2tj5mzt-stylepros-projects.vercel.app';
     // ... rest of your URLs
   }
   ```

2. **Redeploy Frontend:**
   ```bash
   flutter build web --release
   # Copy to static directory and deploy to Vercel
   ```

## 🚨 **Troubleshooting**

### **Authentication Required Error**
This is normal for Vercel deployments. The authentication will be bypassed once you:
1. Set up environment variables
2. Redeploy the application

### **MongoDB Connection Error**
- Check your MongoDB Atlas connection string
- Ensure IP whitelist includes 0.0.0.0/0
- Verify database user credentials

### **Environment Variables Not Working**
- Make sure variables are set for "Production" environment
- Redeploy after adding variables
- Check variable names match exactly (case-sensitive)

## 📊 **Your Backend URLs**

- **API Base URL:** https://backend-ei2tj5mzt-stylepros-projects.vercel.app
- **API Documentation:** https://backend-ei2tj5mzt-stylepros-projects.vercel.app/api-docs
- **Health Check:** https://backend-ei2tj5mzt-stylepros-projects.vercel.app/

## 🎯 **Next Steps**

1. ✅ Set up MongoDB Atlas
2. ✅ Add environment variables to Vercel
3. ✅ Redeploy backend
4. ✅ Test API endpoints
5. ✅ Update frontend configuration
6. ✅ Test full application

## 🔄 **For Future Updates**

To update your backend:

```bash
cd backend
# Make your changes
git add .
git commit -m "Update backend"
git push origin main

# Vercel will automatically redeploy
# Or manually redeploy:
vercel --prod --yes
```

## 🎉 **Success!**

Once you complete these steps, your backend will be:
- ✅ Live and accessible
- ✅ Connected to MongoDB Atlas
- ✅ Ready to serve your Flutter frontend
- ✅ Documented with Swagger UI

Your Tailor App backend is now deployed on Vercel! 🚀
