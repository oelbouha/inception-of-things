#!/bin/bash
# set -e

sudo apt-get update
sudo apt-get install -y curl

echo "Installing K3s server..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --write-kubeconfig-mode=644 --node-ip=192.168.56.110 --advertise-address=192.168.56.110" sh -

echo "Waiting for K3s service..."
until systemctl is-active --quiet k3s; do
    sleep 2
done


echo "Waiting for Kubernetes API..."

until kubectl get nodes; do
    echo "API not ready..."
    sleep 2
done

echo "API is ready."
echo "Waiting for node token..."

until [ -f /var/lib/rancher/k3s/server/node-token ]; do
    echo "Token not created yet..."
    sleep 2
done

echo "Copying token..."

cat /var/lib/rancher/k3s/server/node-token > /vagrant/token
chmod 644 /vagrant/token

echo "Done."