#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

set -e

SCRIPTS_DIR="./scripts"
PROVISION_ARG=""

# Check if --provision argument was passed
if [[ "$1" == "--provision" ]]; then
    PROVISION_ARG="--provision"
fi


function cleanup() {
    echo -e "\n${YELLOW}You pressed Ctrl+C.${NC}"
    while true; do
        read -rp "Do you want to (e)xit or (d)estroy VMs and exit? [e/d]: " choice
        case "$choice" in
            e|E)
                echo -e "${YELLOW}Exiting without destroying VMs.${NC}"
                exit 0
                ;;
            d|D)
                echo -e "${YELLOW}Destroying Vagrant VMs...${NC}"
                cd provisioning || {
                    echo -e "${RED}Cannot change directory to provisioning, aborting cleanup.${NC}"
                    exit 1
                }
                vagrant destroy -f
                echo -e "${GREEN}VMs destroyed. Cleanup complete.${NC}"
                exit 0
                ;;
            *)
                echo "Invalid option. Please enter 'e' to exit or 'd' to destroy."
                ;;
        esac
    done
}

trap cleanup INT TERM

echo -e "${BLUE}Starting provisioning...${NC}"
bash "${SCRIPTS_DIR}/run-provisioning.sh" $PROVISION_ARG || {
    echo -e "${RED}Provisioning failed. Exiting.${NC}"
    exit 1
}

# Set KUBECONFIG for this session
export KUBECONFIG="$(pwd)/provisioning/kubeconfig"

# Enable sidecar injection 
kubectl label ns default istio-injection=enabled

echo -e "${BLUE}Deploying monitoring with Helm...${NC}"
helm upgrade --install monitoring ./helm/monitoring-chart || {
    echo -e "${RED}Helm deployment failed. Exiting.${NC}"
    exit 1
}

echo -e "${BLUE}Deploying application with Helm...${NC}"
helm upgrade --install myapp ./helm/app-chart || {
    echo -e "${RED}Helm deployment failed. Exiting.${NC}"
    exit 1
}

echo -e "${BLUE}Updating /etc/hosts...${NC}"
bash "${SCRIPTS_DIR}/update-hosts.sh" || {
    echo -e "${RED}Failed to update hosts. Exiting.${NC}"
    exit 1
}

echo -e "${YELLOW}Fetching Kubernetes Dashboard token...${NC}"
DASHBOARD_NS="kubernetes-dashboard"
SA_NAME="admin-user"

TOKEN=$(kubectl -n "$DASHBOARD_NS" create token "$SA_NAME" 2>/dev/null || true)

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Failed to retrieve Dashboard token.${NC}"
else
    echo -e "${GREEN}Dashboard token:${NC}"
    echo -e "${TOKEN}"
fi

echo -e "${YELLOW}Dashboard URL:${NC} https://dashboard.local/"
echo -e "${YELLOW}App URL:${NC} http://myapp.app.local/"
echo -e "${YELLOW}Grafana URL:${NC} http://grafana.local/ (Credentials: admin / admin - PLEASE CHANGE PASSWORD)"
echo -e "${YELLOW}Kiali URL:${NC} http://kiali.local/"
echo -e "${YELLOW}Prometheus URL:${NC} http://prometheus.local/"
echo -e "${BLUE}\nPress Ctrl+C to stop and destroy the Vagrant VMs.${NC}"

while true; do
    sleep 5
done
one
