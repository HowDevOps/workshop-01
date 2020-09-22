data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "howdevops-terraform-states"
    key    = "tf-mod-eks/terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_security_group" "allow_internal" {
  name        = "allow_internal"
  description = "Allow internal inbound traffic"
  vpc_id      = data.terraform_remote_state.eks.outputs.vpc_id

  ingress {
    description = "Any from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = data.terraform_remote_state.eks.outputs.public_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  instance_name = var.instance_name == "" ? "${var.db_engine}-${var.stage}" : var.instance_name
}

resource "random_password" "password" {
  length           = 16
  special          = false
  override_special = "_%@"
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = local.instance_name

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  major_engine_version = var.db_major_engine_version
  family               = var.db_engine_family
  instance_class       = var.instance_type
  allocated_storage    = var.allocated_storage
  storage_encrypted    = false

  name     = var.db_name
  port     = var.db_port
  username = var.db_username
  password = random_password.password.result

  vpc_security_group_ids = [aws_security_group.allow_internal.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  multi_az = true

  backup_retention_period = var.backup_retention_period

  subnet_ids = data.terraform_remote_state.eks.outputs.private_subnets

  # Snapshot name upon DB deletion
  final_snapshot_identifier = local.instance_name

  # Database Deletion Protection
  deletion_protection = var.deletion_protection

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8"
    },
    {
      name  = "character_set_server"
      value = "utf8"
    }
  ]
}

resource "kubernetes_secret" "rds_user" {
  metadata {
    name = local.instance_name
  }

  data = {
    "username" = var.db_username
    "password" = random_password.password.result
  }
}

resource "kubernetes_config_map" "rds_cluster" {
  metadata {
    name = local.instance_name
  }

  data = {
    db_host = module.db.this_db_instance_endpoint
    db_name = var.db_name
  }
}