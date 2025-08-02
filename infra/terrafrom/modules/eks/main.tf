resource "aws_iam_role" "controller_node_role" {
  name = var.controller_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = ["sts:AssumeRole"]
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "controller_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.controller_node_role.name
}

resource "aws_iam_role_policy_attachment" "controller_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.controller_node_role.name
}

resource "aws_eks_cluster" "eks_controller_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.controller_node_role.arn
  version  = var.cluster_version

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true

    subnet_ids = var.vpc_subnet_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.controller_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.controller_AmazonEKSServicePolicy,
  ]
}

resource "aws_iam_role" "worker_node_role" {
  name = var.worker_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker_node_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker_node_role.name
}

resource "aws_eks_node_group" "worker_node" {
  cluster_name    = aws_eks_cluster.eks_controller_cluster.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.worker_node_role.arn
  subnet_ids      = var.worker_node_subnet_ids

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
  ]
}
