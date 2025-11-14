#!/bin/bash

# Script to help set up HTTPS for Elastic Beanstalk
# This opens the AWS Console for manual configuration (easiest method)

echo "🔒 HTTPS Setup for Elastic Beanstalk"
echo "===================================="
echo ""

# Get environment details
cd "$(dirname "$0")"
export PATH="$HOME/.local/bin:$PATH"

ENV_NAME="tailorapp-env"
REGION="ap-south-1"

echo "Environment: $ENV_NAME"
echo "Region: $REGION"
echo ""

# Get environment ID
ENV_ID=$(eb status $ENV_NAME 2>/dev/null | grep "Environment ID" | awk '{print $3}')

if [ -z "$ENV_ID" ]; then
    echo "❌ Could not find environment. Please run: eb status"
    exit 1
fi

echo "Environment ID: $ENV_ID"
echo ""

# Construct console URL
CONSOLE_URL="https://${REGION}.console.aws.amazon.com/elasticbeanstalk/home?region=${REGION}#/environment/dashboard?applicationName=tailor-app-backend&environmentId=${ENV_ID}"

echo "🔗 Opening AWS Console..."
echo ""
echo "Direct link: $CONSOLE_URL"
echo ""
echo "📋 Steps to configure HTTPS:"
echo "1. Click the link above (or copy-paste in browser)"
echo "2. In the left sidebar, click 'Configuration'"
echo "3. Scroll down and click 'Edit' on 'Load balancer'"
echo "4. Click 'Add listener'"
echo "5. Configure:"
echo "   - Port: 443"
echo "   - Protocol: HTTPS"
echo "   - SSL certificate: Request new certificate or use existing"
echo "6. Click 'Apply'"
echo "7. Wait 2-3 minutes for update"
echo ""
echo "💡 Tip: For production, use a custom domain with SSL certificate"
echo ""

# Try to open in browser (macOS)
if command -v open &> /dev/null; then
    echo "Opening browser..."
    open "$CONSOLE_URL"
elif command -v xdg-open &> /dev/null; then
    echo "Opening browser..."
    xdg-open "$CONSOLE_URL"
else
    echo "Please copy the URL above and open it in your browser"
fi

echo ""
echo "✅ After HTTPS is configured, update frontend URL to use https://"

