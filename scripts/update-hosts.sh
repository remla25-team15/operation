#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

set -e

export KUBECONFIG="$(pwd)/provisioning/kubeconfig"

echo -e "${YELLOW}Checking dashboard.local, app.local, and grafana.local IP mapping...${NC}"

# Get the IP from the ingress-nginx-controller
DASHBOARD_IP=$(kubectl get svc ingress-nginx-controller \
  -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$DASHBOARD_IP" ]; then
  echo -e "${RED}Could not retrieve ingress-nginx IP.${NC}"
  exit 1
fi

# Hostnames to ensure are on the same line
HOSTNAMES="dashboard.local app.local grafana.local"

# Check if any of these hostnames exist in /etc/hosts
LINE=$(grep -E "\s+(dashboard\.local|app\.local|grafana\.local)" /etc/hosts || true)

if [ -z "$LINE" ]; then
  # Neither hostname found, add all on a new line
  echo -e "${YELLOW}Adding new entry for $HOSTNAMES to /etc/hosts${NC}"
  echo "$DASHBOARD_IP $HOSTNAMES" | sudo tee -a /etc/hosts > /dev/null
  echo -e "${GREEN}Mapping added.${NC}"
else
  # At least one hostname exists, update line
  CURRENT_IP=$(echo "$LINE" | awk '{print $1}')
  CURRENT_HOSTS=$(echo "$LINE" | cut -d' ' -f2-)

  # Ensure all hostnames are present (avoid duplicates)
  for host in $HOSTNAMES; do
    if ! grep -qw "$host" <<< "$CURRENT_HOSTS"; then
      CURRENT_HOSTS="$CURRENT_HOSTS $host"
    fi
  done

  if [[ "$CURRENT_IP" == "$DASHBOARD_IP" ]]; then
    echo -e "${GREEN}Entry found with correct IP. Ensuring hostnames are complete...${NC}"
  else
    echo -e "${YELLOW}IP differs, updating from $CURRENT_IP to $DASHBOARD_IP${NC}"
  fi

  # Escape dots in hostnames for sed search
  HOSTS_ESCAPED=$(echo "$HOSTNAMES" | sed 's/\./\\./g')

  # Create and escape the replacement line safely
  REPLACEMENT_LINE="${DASHBOARD_IP} ${CURRENT_HOSTS}"
  ESCAPED_REPLACEMENT_LINE=$(echo "$REPLACEMENT_LINE" | tr -d '\n' | sed -e 's/[\/&]/\\&/g')

  # Perform the replacement using escaped variables
  sudo sed -i.bak -E "/\s+(${HOSTS_ESCAPED// /|})/ s/^.*$/${ESCAPED_REPLACEMENT_LINE}/" /etc/hosts
  echo -e "${GREEN}Mapping updated.${NC}"
fi

echo -e "${BLUE}Current relevant entries:${NC}"
grep -E "\s+(dashboard\.local|app\.local|grafana\.local)" /etc/hosts || echo "No entries found."
