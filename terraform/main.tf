terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket  = "bedrock-terraform-state-026138522504"
    key     = "prod/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.region                                                               
                                                                              
  default_tags {
    tags = {    
      Project = "karatu-2025-capstone"
    }              
  }                                                                             
}

module "vpc" {
  source = "./modules/vpc"

  title  = var.title
  vpc_name = "${var.title}-vpc"
  cluster_name = "${var.title}-cluster"
}

module "eks" {
  source = "./modules/eks"

  cluster_name = "${var.title}-cluster"
  subnet_ids   = module.vpc.private_subnet_ids
  dev_user_arn = module.iam.dev_user_arn
}

module "rds" {                                                                         
  source = "./modules/rds"

  title              = var.title                                                          
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id                                                  
}                                                                                      

module "dynamodb" {
  source = "./modules/dynamodb"

  title = var.title
}

module "iam" {
  source = "./modules/iam"

  title              = var.title
  assets_bucket_name = "bedrock-assets-alt-soe-025-4161"
}

module "lambda" {
  source = "./modules/lambda"

  title              = var.title
  assets_bucket_name = "bedrock-assets-alt-soe-025-4161"
  lambda_source_path = "${path.root}/../lambda"
}