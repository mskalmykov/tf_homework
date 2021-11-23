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

module "eks" {
  source           = "terraform-aws-modules/eks/aws"
  cluster_name     = "my_eks"
  cluster_version  = "1.21"
  vpc_id           = module.vpc.vpc_id
  subnets          = module.vpc.public_subnets
  write_kubeconfig = false
  worker_groups = [
    {
      instance_type        = "t2.small"
      key_name             = "mskawslearn1-pair1"
      asg_desired_capacity = 2
      asg_max_size         = 3
    }
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "aws_ecr_repository" "my-ecr" {
  name = "my-ecr"

  image_scanning_configuration {
    scan_on_push = true
  }
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = "my-db"

  engine            = "mariadb"
  engine_version    = "10.5.12"
  instance_class    = "db.t2.micro"
  allocated_storage = 20

  name     = "nhltop"
  username = "nhltop"
  password = "$(var.DB_PASSWORD)"
  port     = "3306"

  skip_final_snapshot = true

  #vpc_security_group_ids = ["sg-12345678"]

  # DB subnet group
  subnet_ids           = module.vpc.public_subnets
  family = "mariadb10.5"
  major_engine_version = "10.5"

}

#module "sg_web_ssh" {
#  source = "terraform-aws-modules/security-group/aws"
#  name   = "sg_web_ssh"
#  vpc_id = module.vpc.vpc_id
#
#  ingress_cidr_blocks = ["0.0.0.0/0"]
#
#  ingress_rules = ["http-80-tcp", "ssh-tcp"]
#  egress_rules  = ["all-all"]
#}

#module "app_server" {
#  source = "terraform-aws-modules/ec2-instance/aws"
#
#  name                        = "tf-course-ec2"
#  ami                         = "ami-0a49b025fffbbdac6"
#  instance_type               = "t2.micro"
#  key_name                    = "mskawslearn1-pair1"
#  associate_public_ip_address = "true"
#  subnet_id                   = module.vpc.public_subnets[0]
#  vpc_security_group_ids      = [module.sg_web_ssh.security_group_id]
#
#}
