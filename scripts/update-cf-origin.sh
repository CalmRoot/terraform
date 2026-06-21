#!/usr/bin/env bash
# scripts/update-cf-origin.sh
# Fetches the active EKS Envoy NLB DNS, downloads the CloudFront distribution configuration,
# updates the origin endpoints, and applies the change back to AWS.

set -euo pipefail

export AWS_PAGER=""

echo "=================================================================="
echo "🌐 Updating CloudFront Origin to Target Envoy NLB DNS"
echo "=================================================================="

# 1. Fetch NLB DNS Address
echo "Fetching NLB DNS from Kubernetes..."
NLB_DNS=$(kubectl get service -n envoy-gateway-system \
  -l gateway.envoyproxy.io/owning-gateway-name=calmroot-gateway \
  -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$NLB_DNS" ]; then
  echo "❌ Error: Could not retrieve EKS NLB DNS. Check your kubectl context."
  exit 1
fi
echo "Active NLB DNS: $NLB_DNS"

# 2. Fetch CloudFront Distribution ID
echo "Locating CloudFront distribution ID for wellnest-project.online..."
DIST_ID=$(aws cloudfront list-distributions --query \
  "DistributionList.Items[?Aliases.Items!=null && contains(Aliases.Items, 'wellnest-project.online')].Id" \
  --output text)

if [ -z "$DIST_ID" ] || [ "$DIST_ID" == "None" ]; then
  echo "❌ Error: Could not locate CloudFront distribution ID for 'wellnest-project.online'."
  exit 1
fi
echo "CloudFront Distribution ID: $DIST_ID"

# 3. Get current configuration and ETag
echo "Fetching current CloudFront configuration..."
CONFIG_OUTPUT=$(aws cloudfront get-distribution-config --id "$DIST_ID")
ETAG=$(echo "$CONFIG_OUTPUT" | grep -oP '"ETag":\s*"\K[^"]+' || echo "")

if [ -z "$ETAG" ]; then
  # Alternative parsing using jq
  ETAG=$(echo "$CONFIG_OUTPUT" | jq -r '.ETag')
fi
echo "Current ETag: $ETAG"

# Write the actual configuration block to a file
echo "$CONFIG_OUTPUT" | jq '.DistributionConfig' > temp-config.json

# 4. Modify configuration JSON using jq to update origin DomainName
echo "Modifying origins to point to new NLB DNS..."
jq --arg nlb "$NLB_DNS" '
  .Origins.Items = (.Origins.Items | map(
    if .Id == "calmroot-nlb-origin" or .Id == "calmroot-frontend-origin" then
      .DomainName = $nlb
    else
      .
    end
  ))
' temp-config.json > updated-config.json

# 5. Apply the update
echo "Submitting updated configuration to AWS..."
aws cloudfront update-distribution \
    --id "$DIST_ID" \
    --if-match "$ETAG" \
    --distribution-config file://updated-config.json > /dev/null

# Clean up
rm -f temp-config.json updated-config.json

echo "=================================================================="
echo "🎉 CloudFront distribution updated successfully!"
echo "Origin domain updated to: $NLB_DNS"
echo "It may take a few minutes for the update to propagate globally."
echo "=================================================================="
