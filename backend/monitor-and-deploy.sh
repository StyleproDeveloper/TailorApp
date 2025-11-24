#!/bin/bash
echo "🔍 Monitoring environment status..."
while true; do
  STATUS=$(aws elasticbeanstalk describe-environments --environment-names tailorapp-env --region ap-south-1 --query 'Environments[0].[Status,HealthStatus]' --output text 2>/dev/null)
  echo "[$(date +%H:%M:%S)] Status: $STATUS"
  
  if echo "$STATUS" | grep -q "Ready"; then
    echo ""
    echo "✅ Environment is Ready! Deploying new version..."
    aws elasticbeanstalk update-environment --environment-name tailorapp-env --version-label "v-20251116-185509" --region ap-south-1
    echo "✅ Deployment initiated!"
    break
  fi
  
  sleep 30
done
