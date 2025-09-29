# 🚀 Deployment Guide - Tailor App

This guide covers deploying your Tailor App to production using GitHub, Railway (backend), and Vercel (frontend).

## 📋 Prerequisites

- GitHub repository
- Railway account (for backend)
- Vercel account (for frontend)
- MongoDB Atlas account (for production database)

## 🔧 Setup Instructions

### 1. GitHub Repository Setup

1. **Push your code to GitHub:**
   ```bash
   git add .
   git commit -m "Initial commit with deployment setup"
   git push origin main
   ```

2. **Enable GitHub Actions:**
   - Go to your repository settings
   - Navigate to "Actions" → "General"
   - Ensure "Allow all actions and reusable workflows" is selected

### 2. Railway Backend Setup

1. **Create Railway account:**
   - Visit [railway.app](https://railway.app)
   - Sign up with GitHub

2. **Deploy backend:**
   - Click "New Project"
   - Select "Deploy from GitHub repo"
   - Choose your repository
   - Select the `backend` folder as the root directory
   - Railway will automatically detect it's a Node.js project

3. **Configure environment variables:**
   - Go to your Railway project settings
   - Add these environment variables:
     ```
     NODE_ENV=production
     PORT=5500
     MONGODB_URI=your_mongodb_atlas_connection_string
     JWT_SECRET=your_jwt_secret_key
     ```

4. **Get Railway credentials:**
   - Go to Railway project settings
   - Copy your `RAILWAY_TOKEN` and `RAILWAY_SERVICE_ID`

### 3. Vercel Frontend Setup

1. **Create Vercel account:**
   - Visit [vercel.com](https://vercel.com)
   - Sign up with GitHub

2. **Deploy frontend:**
   - Click "New Project"
   - Import your GitHub repository
   - Configure build settings:
     - **Framework Preset:** Other
     - **Root Directory:** `./` (root)
     - **Build Command:** `flutter build web --release`
     - **Output Directory:** `build/web`

3. **Get Vercel credentials:**
   - Go to Vercel project settings
   - Copy your `VERCEL_TOKEN`, `VERCEL_ORG_ID`, and `VERCEL_PROJECT_ID`

### 4. GitHub Secrets Configuration

Add these secrets to your GitHub repository:

1. **Go to repository settings → Secrets and variables → Actions**

2. **Add the following secrets:**
   ```
   RAILWAY_TOKEN=your_railway_token
   RAILWAY_SERVICE_ID=your_railway_service_id
   VERCEL_TOKEN=your_vercel_token
   VERCEL_ORG_ID=your_vercel_org_id
   VERCEL_PROJECT_ID=your_vercel_project_id
   ```

### 5. MongoDB Atlas Setup

1. **Create MongoDB Atlas cluster:**
   - Visit [mongodb.com/atlas](https://mongodb.com/atlas)
   - Create a free cluster
   - Get your connection string

2. **Configure database access:**
   - Add your IP address to the whitelist
   - Create a database user
   - Update the connection string with credentials

## 🔄 Automated Deployment

Once everything is set up, deployment happens automatically:

1. **Push to main branch:**
   ```bash
   git add .
   git commit -m "Deploy to production"
   git push origin main
   ```

2. **GitHub Actions will:**
   - Build and test the backend
   - Build the Flutter frontend
   - Deploy backend to Railway
   - Deploy frontend to Vercel
   - Notify deployment status

## 🌐 Production URLs

After successful deployment, you'll have:

- **Frontend:** `https://your-app.vercel.app`
- **Backend:** `https://your-app.railway.app`
- **API Docs:** `https://your-app.railway.app/api-docs`

## 🔧 Manual Deployment

If you prefer manual deployment:

### Backend (Railway)
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login to Railway
railway login

# Deploy backend
cd backend
railway up
```

### Frontend (Vercel)
```bash
# Install Vercel CLI
npm install -g vercel

# Deploy frontend
vercel --prod
```

## 🐛 Troubleshooting

### Common Issues

1. **Build Failures:**
   - Check GitHub Actions logs
   - Ensure all dependencies are in package.json
   - Verify Flutter version compatibility

2. **Environment Variables:**
   - Double-check all secrets are set correctly
   - Ensure MongoDB connection string is valid
   - Verify Railway and Vercel tokens are correct

3. **CORS Issues:**
   - Update backend CORS settings for production domain
   - Check frontend API URLs point to Railway backend

4. **Database Connection:**
   - Verify MongoDB Atlas cluster is running
   - Check IP whitelist includes Railway's IPs
   - Ensure database user has proper permissions

### Debugging Steps

1. **Check deployment logs:**
   - Railway: Project dashboard → Deployments
   - Vercel: Project dashboard → Functions
   - GitHub: Actions tab → Workflow runs

2. **Test endpoints:**
   ```bash
   # Test backend health
   curl https://your-app.railway.app/
   
   # Test API endpoint
   curl https://your-app.railway.app/api/shops
   ```

3. **Verify environment variables:**
   - Railway: Project settings → Variables
   - Vercel: Project settings → Environment Variables

## 📊 Monitoring

### Railway Monitoring
- View logs in Railway dashboard
- Monitor resource usage
- Set up alerts for downtime

### Vercel Monitoring
- Check function logs
- Monitor performance metrics
- Set up error tracking

## 🔄 Updates and Maintenance

### Regular Updates
1. **Dependencies:**
   ```bash
   # Update backend dependencies
   cd backend && npm update
   
   # Update Flutter dependencies
   flutter pub upgrade
   ```

2. **Security:**
   - Regularly update JWT secrets
   - Monitor for security vulnerabilities
   - Keep dependencies up to date

### Backup Strategy
- MongoDB Atlas provides automatic backups
- Keep code backups in GitHub
- Document environment configurations

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review GitHub Actions logs
3. Check Railway and Vercel documentation
4. Verify all environment variables are set correctly

## 🎉 Success!

Once deployed, your Tailor App will be live and accessible worldwide! The automated deployment ensures that every push to the main branch will automatically update your production application.
