terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket  = "mindtrack-infra-state"
    key     = "mindtrack/infra/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.mindtrack.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.mindtrack.certificate_authority[0].data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name", aws_eks_cluster.mindtrack.name,
        "--region", var.aws_region,
        "--output", "json"
      ]
    }
  }
}