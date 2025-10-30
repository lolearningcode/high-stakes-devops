#!/bin/bash

# Gmail Setup Instructions for Alertmanager
echo "=== Gmail SMTP Setup for CryptoSpins Alerting ==="
echo ""
echo "To enable email alerts, you need to create a Gmail App Password:"
echo ""
echo "1. Go to https://myaccount.google.com/security"
echo "2. Enable 2-Factor Authentication if not already enabled"
echo "3. Go to 'App passwords' section"
echo "4. Generate a new app password for 'Mail'"
echo "5. Copy the 16-character app password"
echo ""
echo "6. Then run this command to update the alertmanager config:"
echo "   ./scripts/update-alertmanager-email.sh YOUR_EMAIL YOUR_APP_PASSWORD"
echo ""
echo "7. Apply the configuration:"
echo "   ./scripts/apply-alertmanager-config.sh"
echo ""