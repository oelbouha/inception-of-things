#!/bin/bash

apt update

apt install -y curl

echo "installing k3s"

curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

echo "Waiting for K3s service..."

until systemctl is-active --quiet k3s; do
    sleep 2
done

echo "deploying kubernetes dashboard"

kubectl apply -f /vagrant/confs/app1-deployment.yaml
kubectl apply -f /vagrant/confs/app1-service.yaml

kubectl apply -f /vagrant/confs/app2-deployment.yaml
kubectl apply -f /vagrant/confs/app2-service.yaml

kubectl apply -f /vagrant/confs/app3-deployment.yaml
kubectl apply -f /vagrant/confs/app3-service.yaml

kubectl apply -f /vagrant/confs/ingress.yaml

echo "checking k3s status"
kubectl get nodes