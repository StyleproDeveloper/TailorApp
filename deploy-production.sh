#!/bin/bash

# Production Deployment Script
# This script helps deploy the Tailor App to production

set -e  # Exit on error

echo "🚀 Tailor App - Production Deployment"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "package.json" ] && [ ! -d "backend" ]; then
    echo -e "${RED}❌ Error: Please run this script from the project root directory${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Pre-Deployment Checklist${NC}"
echo ""

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  You have uncommitted changes${NC}"
    echo ""
    echo "Would you like to:"
    echo "1) Commit all changes and deploy"
    echo "2) Deploy without committing (not recommended)"
    echo "3) Cancel and commit manually"
    echo ""
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            echo ""
            echo -e "${GREEN}📝 Committing changes...${NC}"
            git add .
            read -p "Enter commit message (or press Enter for default): " commit_msg
            if [ -z "$commit_msg" ]; then
                commit_msg="Deploy to production: Trial period, S3 integration, Payment edit features"
            fi
            git commit -m "$commit_msg"
            echo -e "${GREEN}✅ Changes committed${NC}"
            ;;
        2)
            echo -e "${YELLOW}⚠️  Proceeding without committing...${NC}"
            ;;
        3)
            echo -e "${YELLOW}Cancelled. Please commit manually and run again.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Exiting.${NC}"
            exit 1
            ;;
    esac
fi

echo ""
echo -e "${GREEN}✅ Pre-deployment checks passed${NC}"
echo ""

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo -e "${YELLOW}📦 Vercel CLI not found. Installing...${NC}"
    npm install -g vercel
fi

# Check if logged in to Vercel
if ! vercel whoami &> /dev/null; then
    echo -e "${YELLOW}🔐 Please login to Vercel first:${NC}"
    echo "   vercel login"
    echo ""
    read -p "Press Enter after logging in to continue..."
fi

echo ""
echo -e "${GREEN}✅ Vercel authentication verified${NC}"
echo ""

# Deploy Backend
echo -e "${YELLOW}📦 Deploying Backend...${NC}"
cd backend

# Check if .env file exists (for reference)
if [ -f ".env" ]; then
    echo -e "${GREEN}✅ Found .env file (will use Vercel environment variables)${NC}"
else
    echo -e "${YELLOW}⚠️  No .env file found. Make sure environment variables are set in Vercel dashboard${NC}"
fi

echo ""
echo -e "${YELLOW}Deploying backend to Vercel production...${NC}"
vercel --prod --yes

BACKEND_URL=$(vercel ls --prod | grep backend | head -1 | awk '{print $2}' || echo "Check Vercel dashboard for URL")

echo ""
echo -e "${GREEN}✅ Backend deployed!${NC}"
echo -e "${GREEN}🔗 Backend URL: https://${BACKEND_URL}${NC}"

cd ..

# Deploy Frontend
echo ""
echo -e "${YELLOW}📦 Building Frontend...${NC}"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter to build the frontend.${NC}"
    echo "   Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Build Flutter web app
echo "Building Flutter web app..."
flutter build web --release

if [ ! -d "build/web" ]; then
    echo -e "${RED}❌ Build failed. build/web directory not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend built successfully${NC}"

# Update API URL in built files (optional - better to update source)
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Update frontend API URL${NC}"
echo "Before deploying frontend, update:"
echo "  lib/Core/Services/Urls.dart"
echo "  Set baseUrl to: https://${BACKEND_URL}"
echo ""
read -p "Have you updated the API URL? (y/n): " updated_url

if [ "$updated_url" != "y" ]; then
    echo -e "${YELLOW}⚠️  Please update the API URL and rebuild:${NC}"
    echo "  1. Edit lib/Core/Services/Urls.dart"
    echo "  2. Run: flutter build web --release"
    echo "  3. Run this script again"
    exit 1
fi

# Rebuild if URL was updated
if [ "$updated_url" == "y" ]; then
    echo "Rebuilding with updated API URL..."
    flutter build web --release
fi

echo ""
echo -e "${YELLOW}Deploying frontend to Vercel production...${NC}"
vercel --prod --yes

FRONTEND_URL=$(vercel ls --prod | grep -v backend | head -1 | awk '{print $2}' || echo "Check Vercel dashboard for URL")

echo ""
echo -e "${GREEN}✅ Frontend deployed!${NC}"
echo -e "${GREEN}🔗 Frontend URL: https://${FRONTEND_URL}${NC}"

echo ""
echo "======================================"
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo "======================================"
echo ""
echo "📋 Deployment Summary:"
echo "  Backend:  https://${BACKEND_URL}"
echo "  Frontend: https://${FRONTEND_URL}"
echo ""
echo "📝 Next Steps:"
echo "  1. Test backend health: curl https://${BACKEND_URL}/health"
echo "  2. Test login functionality"
echo "  3. Verify S3 image uploads"
echo "  4. Test trial period system"
echo "  5. Monitor logs: vercel logs --follow"
echo ""
echo -e "${YELLOW}⚠️  Don't forget to:${NC}"
echo "  - Set all environment variables in Vercel dashboard"
echo "  - Verify MongoDB connection"
echo "  - Check S3 bucket CORS settings"
echo "  - Test all critical features"
echo ""

