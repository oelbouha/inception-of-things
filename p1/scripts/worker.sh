#!/bin/bash
# set -e

echo "Installing dependencies..."

sudo apt-get update
sudo apt-get install -y curl

echo "Waiting for server token..."

while [ ! -f /vagrant/token ]; do
    echo "Token not created yet..."
    sleep 2
done

TOKEN=$(cat /vagrant/token)

echo "Installing K3s agent..."

curl -sfL https://get.k3s.io | \
K3S_URL="https://192.168.56.110:6443" \
K3S_TOKEN="$TOKEN" \
sh -

echo "Worker joined the cluster."