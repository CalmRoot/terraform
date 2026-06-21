# PASS 1: Core Infrastructure (no dependencies)

module "security" {
  source          = "./modules/security"
  project_name    = var.project_name
  vpc_id          = module.vpc.vpc_id
  vpc_cidr        = var.vpc_cidr
  aws_account_id  = var.aws_account_id
  github_username = var.github_username
  github_repo     = var.github_repo
}

module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
  kms_key_arn  = module.security.kms_key_arn
}

module "dynamodb" {
  source      = "./modules/dynamodb"
  kms_key_arn = module.security.kms_key_arn
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
  kms_key_arn  = module.security.kms_key_arn
}

module "secrets" {
  source       = "./modules/secrets"
  project_name = var.project_name
  kms_key_arn  = module.security.kms_key_arn
}

module "eks" {
  source                = "./modules/eks"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  kms_key_arn           = module.security.kms_key_arn
  aws_account_id        = var.aws_account_id
  users_table_arn       = module.dynamodb.users_table_arn
  sessions_table_arn    = module.dynamodb.sessions_table_arn
  templates_table_arn   = module.dynamodb.assessment_templates_table_arn
  assessments_table_arn = module.dynamodb.assessments_table_arn
  mood_logs_table_arn   = module.dynamodb.mood_logs_table_arn
  patients_table_arn    = module.dynamodb.therapist_patients_table_arn
  s3_clinical_notes_arn = module.s3.clinical_notes_bucket_arn
  s3_exports_arn        = module.s3.exports_bucket_arn

  eks_cluster_version    = var.eks_cluster_version
  eks_node_instance_type = var.eks_node_instance_type
  eks_node_min_size      = var.eks_node_min_size
  eks_node_max_size      = var.eks_node_max_size
  eks_node_desired_size  = var.eks_node_desired_size
  k8s_namespace          = var.k8s_namespace
}

module "waf" {
  source       = "./modules/waf"
  project_name = var.project_name
}

# PASS 2: Route53 Zone ONLY (just the zone)

module "route53" {
  source       = "./modules/route53"
  project_name = var.project_name
  domain_name  = var.domain_name
}

# PASS 3: ACM Certificate (needs zone_id)

module "acm" {
  source      = "./modules/acm"
  domain_name = var.domain_name
  zone_id     = module.route53.zone_id
  depends_on  = [module.route53]
}

# PASS 4: CloudFront (needs cert + WAF)

module "cloudfront" {
  source                   = "./modules/cloudfront"
  project_name             = var.project_name
  domain_name              = var.domain_name
  certificate_arn          = module.acm.certificate_arn
  waf_arn                  = module.waf.web_acl_arn
  kms_key_arn              = module.security.kms_key_arn
  nlb_dns_name             = var.nlb_dns_name
  cloudfront_secret_header = var.cloudfront_secret_header
  depends_on               = [module.acm, module.waf]
}

# PASS 5: Route53 Records (needs CloudFront)

resource "aws_route53_record" "apex" {
  zone_id = module.route53.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }
  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "www" {
  zone_id = module.route53.zone_id
  name    = "www.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = [var.domain_name]
}

# PASS 6: Monitoring

module "monitoring" {
  source                     = "./modules/monitoring"
  project_name               = var.project_name
  kms_key_arn                = module.security.kms_key_arn
  alert_email                = var.alert_email
  eks_cluster_name           = module.eks.cluster_name
  cloudfront_distribution_id = module.cloudfront.distribution_id
  waf_web_acl_name           = module.waf.web_acl_name
  depends_on                 = [module.eks, module.cloudfront]
}

module "bastion" {
  source                = "./modules/bastion"
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  public_subnet_id      = module.vpc.public_subnet_ids[0]
  bastion_instance_type = var.bastion_instance_type
  cluster_name          = module.eks.cluster_name
  aws_region            = var.aws_region
  depends_on            = [module.eks]
}

module "lambda" {
  source         = "./modules/lambda"
  project_name   = var.project_name
  aws_account_id = var.aws_account_id
  kms_key_arn    = module.security.kms_key_arn
  sns_topic_arn  = module.monitoring.sns_topic_arn
  ops_email      = var.alert_email

  depends_on = [module.security, module.monitoring]
}

