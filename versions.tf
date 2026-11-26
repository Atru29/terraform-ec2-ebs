terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Etiqueta todo lo que crea este proyecto, para encontrarlo y borrarlo fácil.
  default_tags {
    tags = {
      Project = "ec2-ebs-lab"
    }
  }
}
