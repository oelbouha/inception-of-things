#!/bin/bash
set -e

echo ">>> Updating packages"
apt-get update -y

echo ">>> Installing Docker"
curl -fsSL https://get.docker.com | sh
usermod -aG docker vagrant

echo ">>> Installing k3d"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo ">>> Installing kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo ">>> Creating k3d cluster"
k3d cluster create iot-cluster \
  -p "80:80@loadbalancer" \
  --agents 1

echo ">>> Waiting for cluster to be ready"
kubectl wait --for=condition=Ready nodes --all --timeout=120s

echo ">>> Creating namespaces"
kubectl create namespace argocd
kubectl create namespace dev

echo ">>> Installing Argo CD"
kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ">>> Waiting for Argo CD to be ready"
kubectl wait --for=condition=available --timeout=300s deployment --all -n argocd

echo ">>> Enabling insecure mode for Argo CD server (HTTP via Ingress)"
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout status deployment argocd-server -n argocd --timeout=120s

echo ">>> Applying Argo CD Ingress"
kubectl apply -f /vagrant/confs/argocd-ingress.yaml

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > /vagrant/pass

echo ">>> Applying Argo CD Application (manages wil-playground + its Ingress via GitOps)"
kubectl apply -f /vagrant/confs/argocd-app.yaml

echo ">>> Done. Cluster and Argo CD are up."