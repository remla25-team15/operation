#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

set -e  # Exit immediately if a command exits with a non-zero status

# Step 1: Navigate to the provisioning directory
cd provisioning || { echo -e "${RED}Directory 'provisioning' not found...${NC}"; exit 1; }

# Step 2: Start Vagrant and wait for it to complete
echo "Starting Vagrant..."
vagrant up || { echo -e "${RED}Vagrant up failed${NC}"; exit 1; }

# Step 3: Wait for Ansible ping to succeed for all nodes
echo "Waiting for Ansible ping to succeed on all nodes..."

# Try up to 10 times with a 10-second interval
MAX_RETRIES=10
SUCCESS=false
for i in $(seq 1 $MAX_RETRIES); do
    echo "Attempt $i..."
    if ansible all -m ping | grep -q 'SUCCESS'; then
        echo -e "${GREEN}Ansible ping successful.${NC}"
        SUCCESS=true
        break
    fi
    sleep 10
done

if [ "$SUCCESS" != true ]; then
    echo -e "${RED}Ansible ping failed after $MAX_RETRIES attempts${NC}"
    exit 1
fi

# Step 4: Retrieve Kubernetes admin config
echo "Retrieving kubeconfig from ctrl node..."
vagrant ssh ctrl -c "sudo cat /etc/kubernetes/admin.conf" > ../kubeconfig || {
    echo -e "${RED}Failed to retrieve kubeconfig...${NC}"
    exit 1
}

# Step 5: Set the KUBECONFIG environment variable
export KUBECONFIG=$(pwd)/kubeconfig
echo "KUBECONFIG set to $KUBECONFIG"

# Step 6: Check if all nodes are ready
echo -e "${YELLOW}Waiting for all nodes to be Ready...${NC}"

TIMEOUT=120  # max seconds to wait
INTERVAL=5   # seconds between checks
elapsed=0
printed_message=false

while true; do
  not_ready_nodes=$(kubectl get nodes --no-headers | awk '$2 != "Ready" {print $1}')
  
  if [ -z "$not_ready_nodes" ]; then
    echo -e "${GREEN}All nodes are Ready.${NC}"
    break
  else
    if [ "$printed_message" = false ]; then
      echo -e "${YELLOW}Waiting for nodes to be Ready. Not ready nodes: $not_ready_nodes${NC}"
      printed_message=true
    fi

    if (( elapsed >= TIMEOUT )); then
      echo -e "${RED}Timeout waiting for nodes to become Ready. Not ready nodes:${NC}"
      echo "$not_ready_nodes"
      exit 1
    fi

    sleep $INTERVAL
    ((elapsed+=INTERVAL))
  fi
done

# Step 7: Run finalization playbook
echo -e "${YELLOW}Running finalization playbook...${NC}"
ansible-playbook finalization.yml || {
    echo -e "${RED}Finalization playbook failed.${NC}"
    exit 1
}
echo -e "${GREEN}Finalization playbook completed successfully.${NC}"
