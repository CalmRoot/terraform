#!/usr/bin/env bash
# scripts/get-nlb-dns.sh
# Fetches the DNS address of the Network Load Balancer created by Envoy Gateway.

set -eo pipefail

kubectl get service \
  -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-name=calmroot-gateway \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
echo ""
