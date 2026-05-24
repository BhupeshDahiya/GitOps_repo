#!/bin/bash

echo "=== PURGING HELM RELEASES ==="
helm uninstall fluent-bit -n logging || true
helm uninstall elasticsearch -n logging || true
helm uninstall prometheus -n monitoring || true
helm uninstall metrics-server -n kube-system || true
helm uninstall argocd -n argocd || true
helm uninstall ingress-nginx -n ingress-nginx || true

echo "=== WAITING FOR AWS RESOURCES TO DETACH ==="
echo "Sleeping for 60 seconds to allow the AWS Cloud Controller to delete ELBs and Volumes..."
sleep 60
echo "Done. Safe to run 'terraform destroy' now."