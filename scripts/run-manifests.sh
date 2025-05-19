#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

set -e

# Set KUBECONFIG if needed
export KUBECONFIG="$(pwd)/provisioning/kubeconfig"

K8S_DIR="./k8s"
NAMESPACE="default"  
TIMEOUT=300
INTERVAL=5

if [ ! -d "$K8S_DIR" ]; then
  echo -e "${RED}Directory $K8S_DIR does not exist!${NC}"
  exit 1
fi

echo -e "${BLUE}Applying all Kubernetes manifests from $K8S_DIR recursively...${NC}"

# Exclude non-manifest files (e.g., dashboard JSON) from kubectl apply
# Find all YAML/YML files and apply them, skipping .json files
find "$K8S_DIR" \( -name '*.yaml' -o -name '*.yml' \) -exec kubectl apply -f {} \;

# Apply Grafana credentials and Ingress specifically if they exist
GRAFANA_CREDENTIALS_FILE="$K8S_DIR/prometheus/grafana-credentials-secret.yaml"
GRAFANA_INGRESS_FILE="$K8S_DIR/prometheus/grafana-ingress.yaml"

if [ -f "$GRAFANA_CREDENTIALS_FILE" ]; then
  echo -e "${BLUE}Applying Grafana credentials...${NC}"
  kubectl apply -f "$GRAFANA_CREDENTIALS_FILE" || echo -e "${YELLOW}Could not apply Grafana credentials, ensure the file exists and Grafana is deployed in 'monitoring' namespace.${NC}"
fi

if [ -f "$GRAFANA_INGRESS_FILE" ]; then
  echo -e "${BLUE}Applying Grafana Ingress...${NC}"
  kubectl apply -f "$GRAFANA_INGRESS_FILE" || echo -e "${YELLOW}Could not apply Grafana Ingress, ensure the file exists and an Ingress controller is running.${NC}"
fi

# All individual files applied successfully if we reach here
echo -e "${GREEN}All manifests applied successfully.${NC}"

echo -e "${YELLOW}Waiting for all pods to be Running or Succeeded in namespace '$NAMESPACE'...${NC}"

elapsed=0
not_ready_printed=false

while true; do
  # Check pods not in Running or Succeeded states
  not_ready=$(kubectl get pods -n "$NAMESPACE" --no-headers | awk '$3 != "Running" && $3 != "Succeeded" {print $1}')

  if [ -z "$not_ready" ]; then
    echo -e "${GREEN}All pods are Running or Succeeded.${NC}"
    break
  else
    if (( elapsed >= TIMEOUT )); then
      echo -e "${RED}Timeout reached. Some pods are not ready:${NC}"
      echo "$not_ready"
      exit 1
    fi

    if [ "$not_ready_printed" = false ]; then
      echo -e "${YELLOW}Pods not ready yet: ${not_ready}. Waiting...${NC}"
      not_ready_printed=true
    fi

    sleep $INTERVAL
    ((elapsed+=INTERVAL))
  fi
done
