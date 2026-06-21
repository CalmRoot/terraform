#!/usr/bin/env bash
# scripts/bootstrap-cluster.sh
# Bootstraps the EKS cluster with all system tools and configures ArgoCD for GitOps deployment.

set -euo pipefail

# Disable AWS CLI interactive paging
export AWS_PAGER=""

CLUSTER_NAME="calmroot-prod"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="006805625766"
NAMESPACE="calmroot-prod"

echo "=================================================================="
echo "☸️  Bootstrapping CalmRoot EKS Cluster and GitOps Setup"
echo "=================================================================="

# 1. Update kubeconfig
echo "Updating kubeconfig for EKS cluster '$CLUSTER_NAME'..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION"

# 2. Clean up manual Gateway API CRDs to avoid Helm Server-Side Apply conflicts
echo "Cleaning up manual Gateway API CRDs..."
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml --ignore-not-found=true

# 3. Install Metrics Server
echo "Installing Metrics Server..."
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update
helm upgrade --install metrics-server metrics-server/metrics-server \
  -n kube-system \
  --set args[0]=--kubelet-insecure-tls \
  --wait --timeout 3m

# 4. Install External Secrets Operator (ESO)
echo "Installing External Secrets Operator..."
helm repo add external-secrets https://charts.external-secrets.io
helm repo update
helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${AWS_ACCOUNT_ID}:role/calmroot-external-secrets-role" \
  --wait --timeout 3m

# 5. Install AWS Load Balancer Controller
echo "Retrieving VPC ID for EKS cluster..."
VPC_ID=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query "cluster.resourcesVpcConfig.vpcId" --output text)
echo "Found VPC ID: $VPC_ID"

echo "Installing AWS Load Balancer Controller..."
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="arn:aws:iam::${AWS_ACCOUNT_ID}:role/calmroot-aws-lb-controller-role" \
  --set vpcId="$VPC_ID" \
  --set region="$AWS_REGION" \
  --wait --timeout 3m

# 6. Install Envoy Gateway
echo "Installing Envoy Gateway..."
helm upgrade --install envoy-gateway oci://docker.io/envoyproxy/gateway-helm \
  --version v1.3.0 \
  -n envoy-gateway-system --create-namespace \
  --wait --timeout 3m

# Wait for Envoy Gateway deploy to finish
kubectl wait --for=condition=available deployment/envoy-gateway -n envoy-gateway-system --timeout=120s

# 7. Install ArgoCD
echo "Installing ArgoCD..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd \
  -n argocd --create-namespace \
  -f argocd/install/argocd-values.yaml \
  --wait --timeout 5m

# Wait for ArgoCD server pods
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=120s

# 8. Retrieve ArgoCD initial admin password
echo "Retrieving ArgoCD Initial Admin Password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

# 9. Link GitHub Repo secret to ArgoCD (private repo access using PAT)
if [ -z "${MANIFEST_REPO_PAT:-}" ]; then
  echo "⚠️  MANIFEST_REPO_PAT is not set in shell environment."
  read -rsp "Please enter your GitHub PAT (with repo read permissions): " MANIFEST_REPO_PAT
  echo ""
fi

echo "Creating GitHub Repository secret in ArgoCD..."
kubectl create secret generic calmroot-repo \
  -n argocd \
  --from-literal=type=git \
  --from-literal=url="https://github.com/Bharath-1602/CalmRoot.git" \
  --from-literal=username="Bharath-1602" \
  --from-literal=password="$MANIFEST_REPO_PAT" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl label secret calmroot-repo \
  -n argocd \
  "argocd.argoproj.io/secret-type=repository" --overwrite

# 10. Apply ArgoCD AppProject and Application Manifests
echo "Applying ArgoCD calmroot project..."
kubectl apply -f argocd/project.yaml

echo "Applying ArgoCD calmroot application..."
kubectl apply -f argocd/application.yaml

echo "=================================================================="
echo "🎉 CalmRoot Bootstrap Complete!"
echo "=================================================================="
echo "ArgoCD URL: Access internally or forward port:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:80"
echo "ArgoCD Username: admin"
echo "ArgoCD Password: $ARGOCD_PASSWORD"
echo ""
echo "Next Steps:"
echo "1. Run scripts/update-secrets.sh to update production secrets."
echo "2. Push a code change or trigger the service CI/CD pipelines."
echo "3. Run scripts/update-cf-origin.sh to link CloudFront to EKS NLB."
echo "=================================================================="
