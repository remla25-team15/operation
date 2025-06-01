#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

set -e

export KUBECONFIG="$(pwd)/provisioning/kubeconfig"

echo -e "${YELLOW}Checking dashboard.local, app.local, grafana.local and kiali.local IP mapping...${NC}"

# Get the IP from the Istio gateway
ISTIO_IP=$(kubectl get svc istio-ingressgateway \
  -n istio-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$ISTIO_IP" ]; then
  echo -e "${RED}Could not retrieve Istio IP.${NC}"
  exit 1
fi
echo -e "${GREEN}Istio Ingress Gateway IP: $ISTIO_IP${NC}"

# --- Retrieve Generic Ingress Controller IP (specifically ingress-nginx-controller in ingress-nginx) ---
echo -e "${BLUE}Attempting to retrieve Generic Ingress Controller IP from 'ingress-nginx-controller' in 'ingress-nginx' namespace...${NC}"
INGRESS_IP=$(kubectl get svc ingress-nginx-controller \
  -n ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$INGRESS_IP" ]; then
  echo -e "${RED}Could not retrieve Generic Ingress IP. Please ensure 'ingress-nginx-controller' service exists in 'ingress-nginx' namespace and has an external IP.${NC}"
  exit 1
fi
echo -e "${GREEN}Generic Ingress Controller IP: $INGRESS_IP${NC}"

# Hostnames to ensure are on the same line
ISTIO_HOSTNAMES="app.local kiali.local"
INGRESS_HOSTNAMES="dashboard.local grafana.local"

# Combined list of all hostnames managed by this script for filtering
ALL_MANAGED_HOSTNAMES="${ISTIO_HOSTNAMES} ${INGRESS_HOSTNAMES}"

# --- Function to update /etc/hosts file with distinct IP mappings ---
# This function will:
# 1. Create a temporary file.
# 2. Copy all lines from /etc/hosts to the temp file, EXCLUDING lines
#    that contain any of the hostnames managed by this script.
# 3. Append the new, correct mappings (one for Istio, one for Ingress)
#    to the temporary file.
# 4. Overwrite the original /etc/hosts with the content of the temporary file.
update_hosts_file() {
  local istio_ip="$1"
  local ingress_ip="$2"
  local temp_hosts_file=$(mktemp) # Create a unique temporary file

  # Prepare regex for filtering out old managed entries
  # Escapes dots and joins hostnames with '|' for OR matching (e.g., "app\.local|kiali\.local|dashboard\.local|grafana\.local")
  local filter_regex=$(echo "$ALL_MANAGED_HOSTNAMES" | sed 's/\./\\./g' | sed 's/ /|/g')

  # Copy existing /etc/hosts content to a temporary file,
  # excluding any lines that contain the hostnames we manage.
  # `grep -Ev` means "Extended regex, invert match" (i.e., print lines that *do not* match).
  grep -Ev "\s+(${filter_regex})" /etc/hosts > "$temp_hosts_file" || true

  # Append the new, correct entries to the temporary file
  echo "${istio_ip} ${ISTIO_HOSTNAMES}" >> "$temp_hosts_file"
  echo "${ingress_ip} ${INGRESS_HOSTNAMES}" >> "$temp_hosts_file"

  # Overwrite the original /etc/hosts file with the content of the temporary file
  # This requires sudo privileges.
  sudo mv "$temp_hosts_file" /etc/hosts
  sudo chmod 644 /etc/hosts # Ensure correct file permissions

  echo -e "${GREEN}Hosts file updated successfully.${NC}"
}

# --- Execute the update function with the retrieved IPs ---
update_hosts_file "$ISTIO_IP" "$INGRESS_IP"

echo -e "${BLUE}Current relevant entries in /etc/hosts after script execution:${NC}"
# Display only the lines that contain any of the managed hostnames
grep -E "\s+(dashboard\.local|app\.local|grafana\.local|kiali\.local)" /etc/hosts || true
