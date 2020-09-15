data "aws_availability_zones" "available" {
}

locals {
  cluster_name = "eks-${var.stage}"
  common_name  = "${var.cloudflare_host}.${var.cloudflare_zone}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.50.0"

  name = "vpc_${var.stage}"
  azs  = data.aws_availability_zones.available.names

  cidr                 = var.cidr
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = var.enable_dns_hostnames

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = list(var.cidr)
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "12.2.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.17"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  tags = {
    Environment = var.stage
    Region      = var.region
  }

  worker_groups = [
    {
      name                 = "worker-group-1"
      instance_type        = var.instance_type
      root_volume_size     = var.root_volume_size
      asg_desired_capacity = var.asg_desired_capacity
    }
  ]

  worker_additional_security_group_ids = [aws_security_group.all_worker_mgmt.id]
}

resource "kubernetes_namespace" "ingress-nginx" {
  metadata {
    annotations = {
      name = "ingress-nginx"
    }
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress-nginx" {
  name       = "ingress-nginx"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  namespace  = "ingress-nginx"
}

data "kubernetes_service" "ingress_nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
}

data "cloudflare_zones" "domain" {
  filter {
    name   = var.cloudflare_zone
    status = "active"
  }
}

resource "cloudflare_record" "host" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = var.cloudflare_host
  value   = data.kubernetes_service.ingress_nginx.load_balancer_ingress[0].hostname
  type    = "CNAME"
  ttl     = var.cloudflare_ttl
  proxied = var.cloudflare_proxied
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "cert" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
    common_name  = local.common_name
    organization = var.organization_name
  }

  validity_period_hours = 87600

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "kubernetes_secret" "tls" {
  metadata {
    name = replace("${var.cloudflare_host}-tls", ".", "-")
  }

  data = {
    "tls.crt" = tls_self_signed_cert.cert.cert_pem
    "tls.key" = tls_private_key.private_key.private_key_pem
  }

  type = "kubernetes.io/tls"
}