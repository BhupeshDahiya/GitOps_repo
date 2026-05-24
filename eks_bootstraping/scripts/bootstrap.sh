#!/bin/bash
set -e

echo "=== CREATING NAMESPACES ==="
kubectl create namespace ingress-nginx --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -

echo "=== ADDING HELM REPOSITORIES ==="
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add argo https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update

echo "=== DEPLOYING INGRESS CONTROLLER ==="
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx \
  -f ingress-nginx/values.yaml

echo "Waiting for Ingress to provision AWS LoadBalancer..."
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx

echo "=== DEPLOYING ARGOCD ==="
helm upgrade --install argocd argo/argo-cd \
  -n argocd \
  -f argocd/values.yaml

echo "=== DEPLOYING METRICS SERVER ==="
helm upgrade --install metrics-server bitnami/metrics-server \
  -n kube-system \
  --set apiService.create=true

  echo "=== DEPLOYING PROMETHEUS/GRAFANA ==="
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f monitoring/values.yaml

echo "=== DEPLOYING ELASTICSEARCH ==="
helm upgrade --install elasticsearch bitnami/elasticsearch \
  -n logging \
  -f logging/elasticsearch-values.yaml

echo "Waiting for Elasticsearch to initialize (This takes a minute)..."
kubectl rollout status statefulset/elasticsearch-master -n logging

echo "=== DEPLOYING FLUENT BIT ==="
helm upgrade --install fluent-bit fluent/fluent-bit \
  -n logging \
  -f logging/fluentbit-values.yaml