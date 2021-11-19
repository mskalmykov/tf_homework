terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63"
    }
  }

  required_version = ">= 0.13.1"

  backend "s3" {
    bucket = "tfstate-mskalmykov-aike2ier"
    key    = "tf-course-homework"
    region = "eu-central-1"
  }

}

provider "aws" {
  profile = "default"
  region  = local.region
  default_tags {
    tags = {
      Name = "tf-course-homework"
    }
  }
}

locals {
  region = "eu-central-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "tf-course-vpc"
  cidr = "10.0.0.0/16"

  azs            = ["${local.region}a", "${local.region}b"]
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

}

module "sg_web_ssh" {
  source = "terraform-aws-modules/security-group/aws"
  name   = "sg_web_ssh"
  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]

  ingress_rules = ["http-80-tcp", "ssh-tcp"]
  egress_rules  = ["all-all"]
}

module "app_server" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name                        = "tf-course-ec2"
  ami                         = "ami-0a49b025fffbbdac6"
  instance_type               = "t2.micro"
  key_name                    = "mskawslearn1-pair1"
  associate_public_ip_address = "true"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [module.sg_web_ssh.security_group_id]

}
