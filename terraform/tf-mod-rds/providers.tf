provider "aws" {
  version = ">= 2.28.1"
  region  = var.region
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_ca_certificate)
  token                  = data.terraform_remote_state.eks.outputs.cluster_token
  load_config_file       = false
  version                = "~> 1.11"
}

provider "random" {
  version = "~> 2.1"
}