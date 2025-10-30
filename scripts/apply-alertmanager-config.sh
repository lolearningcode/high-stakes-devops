#!/bin/bash

# Apply Alertmanager configuration as Kubernetes secret
echo "Applying Alertmanager configuration..."

# Create the secret from the alertmanager.yaml file
kubectl -n monitoring create secret generic alertmanager-kube-prom-kube-prometheus-alertmanager \
  --from-file=alertmanager.yml=monitoring/alertmanager.yaml \
  --dry-run=client -o yaml | kubectl apply -f -

if [ $? -eq 0 ]; then
    echo "✅ Alertmanager configuration applied successfully!"
    echo ""
    echo "Restarting Alertmanager to pick up new configuration..."
    kubectl rollout restart statefulset/alertmanager-kube-prom-kube-prometheus-alertmanager -n monitoring
    
    echo ""
    echo "Checking Alertmanager status..."
    kubectl get pods -n monitoring | grep alertmanager
    
    echo ""
    echo "🎉 Email alerting is now configured!"
    echo "   Target email: cleointhecloud.1@gmail.com"
    echo "   Test alerts by scaling down the API: kubectl scale deploy cryptospins-api --replicas=0"
else
    echo "❌ Failed to apply Alertmanager configuration"
    exit 1
fi