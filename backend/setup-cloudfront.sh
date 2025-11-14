#!/bin/bash

# Script to help set up CloudFront for HTTPS

echo "☁️ CloudFront HTTPS Setup"
echo "========================"
echo ""

cd "$(dirname "$0")"
export PATH="$HOME/.local/bin:$PATH"

# Get Elastic Beanstalk URL
EB_URL=$(eb status 2>/dev/null | grep CNAME | awk '{print $2}')

if [ -z "$EB_URL" ]; then
    echo "❌ Could not find Elastic Beanstalk URL"
    echo "Please run: eb status"
    exit 1
fi

echo "Elastic Beanstalk URL: $EB_URL"
echo ""

# CloudFront Console URL
CLOUDFRONT_URL="https://console.aws.amazon.com/cloudfront/v3/home#/distributions/create"

echo "🔗 Opening CloudFront Console..."
echo ""
echo "Direct link: $CLOUDFRONT_URL"
echo ""
echo "📋 Step-by-Step Configuration:"
echo ""
echo "1. Origin Settings:"
echo "   - Origin Domain: $EB_URL"
echo "   - Name: tailorapp-backend-origin"
echo "   - Origin Protocol: HTTP only"
echo "   - Origin Port: 80"
echo ""
echo "2. Default Cache Behavior:"
echo "   - Viewer Protocol Policy: Redirect HTTP to HTTPS"
echo "   - Allowed HTTP Methods: GET, HEAD, OPTIONS, PUT, POST, PATCH, DELETE"
echo "   - Cache Policy: CachingDisabled (for API endpoints)"
echo "   - Origin Request Policy: AllViewer (forward all headers)"
echo ""
echo "3. Distribution Settings:"
echo "   - Price Class: Use Only North America and Europe (cheapest)"
echo "   - SSL Certificate: Default CloudFront Certificate (free)"
echo "   - Default Root Object: (leave empty)"
echo ""
echo "4. Click 'Create Distribution'"
echo ""
echo "5. Wait 10-15 minutes for deployment"
echo ""
echo "6. After deployment, copy the Distribution Domain Name"
echo "   (It will look like: d1234567890.cloudfront.net)"
echo ""
echo "7. Update frontend URL to: https://[distribution-domain]"
echo ""

# Try to open in browser
if command -v open &> /dev/null; then
    echo "Opening browser..."
    open "$CLOUDFRONT_URL"
elif command -v xdg-open &> /dev/null; then
    echo "Opening browser..."
    xdg-open "$CLOUDFRONT_URL"
else
    echo "Please copy the URL above and open it in your browser"
fi

echo ""
echo "✅ After CloudFront is deployed, I'll help you update the frontend URL!"

