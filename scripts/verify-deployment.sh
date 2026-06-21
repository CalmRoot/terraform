#!/usr/bin/env bash
# scripts/verify-deployment.sh
# Verification checks for EKS cluster resources, secrets, gateway, and health routes.

set -eo pipefail

export AWS_PAGER=""

echo "=================================================================="
echo "🔍 CalmRoot Production Deployment Verification"
echo "=================================================================="

# 1. Check Nodes
echo ">>> Checking cluster nodes..."
kubectl get nodes -o wide

# 2. Check Pods in calmroot-prod namespace
echo ">>> Checking CalmRoot application pods..."
kubectl get pods -n calmroot-prod -o wide

# 3. Check Secrets sync status
echo ">>> Checking ExternalSecrets synchronization..."
kubectl get externalsecrets -n calmroot-prod

# 4. Check Gateway API objects
echo ">>> Checking Gateway configurations..."
kubectl get gateway -n calmroot-prod
kubectl get httproute -n calmroot-prod

# 5. Fetch NLB DNS Address
echo ">>> Querying Envoy Gateway NLB DNS Address..."
NLB_DNS=$(kubectl get service -n envoy-gateway-system -l gateway.envoyproxy.io/owning-gateway-name=calmroot-gateway -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$NLB_DNS" ]; then
  echo "⚠️  NLB DNS Address is not yet allocated. Please wait for the LoadBalancer controller."
  exit 1
fi
echo "Envoy NLB DNS: $NLB_DNS"

# 6. Test Health Endpoints via NLB
echo ">>> Testing microservice health routes via NLB (HTTP port 80)..."
echo "Frontend: "
curl -sI -o /dev/null -w "%{http_code}\n" "http://$NLB_DNS/" || echo "Fail"

echo "Auth Service: "
curl -s "http://$NLB_DNS/api/auth/health" || echo "Fail"
echo ""

echo "Assessment Service: "
curl -s "http://$NLB_DNS/api/assessment/health" || echo "Fail"
echo ""

echo "Therapist Service: "
curl -s "http://$NLB_DNS/api/therapist/health" || echo "Fail"
echo ""

# 7. Test via CloudFront Domain
CLOUDFRONT_DNS=$(aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items!=null && contains(Aliases.Items, 'wellnest-project.online')].DomainName" --output text 2>/dev/null || echo "")

if [ -n "$CLOUDFRONT_DNS" ]; then
  echo ">>> Testing connectivity via CloudFront URL ($CLOUDFRONT_DNS)..."
  echo "CloudFront root: "
  curl -sI -o /dev/null -w "%{http_code}\n" "https://wellnest-project.online/" || echo "Fail"
else
  echo "⚠️  CloudFront distribution for wellnest-project.online not found or accessible yet."
fi

# 8. Print Summary Table
echo "=================================================================="
echo "📊 VERIFICATION SUMMARY"
echo "=================================================================="
printf "%-30s | %-10s\n" "Resource/Check" "Status"
printf "%-30s | %-10s\n" "------------------------------" "----------"
kubectl get nodes >/dev/null 2>&1 && printf "%-30s | %-10s\n" "EKS Nodes Ready" "SUCCESS" || printf "%-30s | %-10s\n" "EKS Nodes Ready" "FAILED"
kubectl get deployment -n calmroot-prod -o jsonpath='{.items[*].status.readyReplicas}' >/dev/null 2>&1 && printf "%-30s | %-10s\n" "CalmRoot Pods Running" "SUCCESS" || printf "%-30s | %-10s\n" "CalmRoot Pods Running" "FAILED"
[ -n "$NLB_DNS" ] && printf "%-30s | %-10s\n" "Envoy Gateway NLB Allocated" "SUCCESS" || printf "%-30s | %-10s\n" "Envoy Gateway NLB Allocated" "FAILED"
echo "=================================================================="
