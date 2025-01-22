locals {
  prefix = "${var.project}-${var.env}"
  tags = {
    Environment = var.env
    Project     = var.project
    Terraform   = "true"
  }
}

# network data sources
data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnets" "eks_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  
  filter {
    name   = "tag:Type"
    values = ["app"]
  }
}

# Cluster IAM
resource "aws_iam_role" "cluster_role" {
  name = "${local.prefix}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = local.prefix
  role_arn = aws_iam_role.cluster_role.arn
  version  = var.k8s_version

  vpc_config {
    subnet_ids              = data.aws_subnets.eks_subnets.ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [aws_iam_role_policy_attachment.cluster_policy]
  tags       = local.tags
}

# Node Group IAM
resource "aws_iam_role" "node_role" {
  name = "${local.prefix}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  policy_arn = each.value
  role       = aws_iam_role.node_role.name
}

# Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.prefix}-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = data.aws_subnets.eks_subnets.ids

  instance_types = var.node_instance_types

  scaling_config {
   desired_size = var.node_group_scaling_config.desired_size
    max_size     = var.node_group_scaling_config.max_size
    min_size     = var.node_group_scaling_config.min_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = local.tags

  depends_on = [aws_iam_role_policy_attachment.node_policies]
}

# Auth ConfigMap
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.node_role.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
    ])
  }

  depends_on = [aws_eks_node_group.main]
}