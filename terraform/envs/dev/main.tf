# -------------------------
# IAM Role for EKS Node Group
# -------------------------
resource "aws_iam_role" "node_group_role" {
  name = "${var.cluster_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "worker_node" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# -------------------------
# VPC Module
# -------------------------
module "vpc" {
  source = "../../modules/vpc"

  name                 = "tc2-dev"
  cidr_block           = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  tags                 = var.tags
}

# -------------------------
# EKS Cluster Module
# -------------------------
module "eks" {
  source = "../../modules/eks"

  cluster_name    = var.cluster_name
  subnet_ids      = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  vpc_id          = module.vpc.vpc_id
  cluster_version = var.cluster_version
  tags            = var.tags
}

# -------------------------
# Node Group Module
# -------------------------
module "node_group" {
  source = "../../modules/node-group"

  cluster_name    = module.eks.cluster_name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = module.vpc.private_subnet_ids
  # we could rely on defaults, but wiring explicitly is clearer:
  desired_size   = 1
  min_size       = 1
  max_size       = 4
  instance_types = ["t3.small"]
  tags           = var.tags
}

# -------------------------
# ECR Module for app image
# -------------------------
module "ecr" {
  source = "../../modules/ecr"

  name         = "hello-python"
  scan_on_push = true
  tags         = var.tags
}
# -------------------------
# Jenkkins EC2 Module
# -------------------------
resource "aws_security_group" "jenkins_sg" {
  name   = "jenkins-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["100.36.249.35/32"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["100.36.249.35/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  owners = ["amazon"]
}
module "jenkins_ec2" {
  source = "../../modules/jenkins-ec2"

  name                 = "tc2-jenkins"
  ami_id               = data.aws_ami.amazon_linux.id
  subnet_id            = module.vpc.public_subnet_ids[0]
  key_name             = "1PU-east-1"
  security_group_ids   = [aws_security_group.jenkins_sg.id]
  tags                 = var.tags
  iam_instance_profile = aws_iam_instance_profile.jenkins_ec2_profile.name

}

