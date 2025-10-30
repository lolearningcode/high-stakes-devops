#!/bin/bash

# Update Alertmanager configuration with Gmail credentials
# Usage: ./update-alertmanager-email.sh your-email@gmail.com your-app-password

EMAIL=$1
APP_PASSWORD=$2

if [ -z "$EMAIL" ] || [ -z "$APP_PASSWORD" ]; then
    echo "Usage: $0 <email@gmail.com> <app-password>"
    echo "Example: $0 cleointhecloud.1@gmail.com abcdwxyzefgh1234"
    exit 1
fi

echo "Updating alertmanager.yaml with Gmail credentials..."

# Update the alertmanager.yaml file
sed -i.bak "s/your-app-password-here/$APP_PASSWORD/g" monitoring/alertmanager.yaml
sed -i.bak "s/cryptospins-alerts@gmail.com/$EMAIL/g" monitoring/alertmanager.yaml

echo "✅ Updated monitoring/alertmanager.yaml with:"
echo "   Email: $EMAIL" 
echo "   App Password: ${APP_PASSWORD:0:4}****${APP_PASSWORD: -4}"
echo ""
echo "Now run: ./scripts/apply-alertmanager-config.sh"