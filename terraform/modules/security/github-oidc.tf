# GitHub Actions OIDC Integration

# Check if OIDC provider already exists to prevent duplication error, but since we are doing standard IaC:
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# In case it doesn't exist, we can use the data source or provision it.
# To make it robust and idempotent, we'll provision the provider if not registered,
# but using a data source is safer if we ran the helper script. Let's make sure it imports/references it.
# Let's create the IAM role.
data "aws_iam_role" "github_actions" {
  name = "calmroot-github-actions-role"
}
