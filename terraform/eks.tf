resource "aws_eks_cluster" "main" {
  name     = "toogle-cluster"
  role_arn = data.aws_iam_role.lab_role.arn
  version  = "1.34"

  vpc_config {
    subnet_ids              = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    endpoint_public_access  = true
    endpoint_private_access = true
    security_group_ids      = [aws_security_group.main.id]
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "toogle-nodes"
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  version         = "1.34"

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  capacity_type  = "ON_DEMAND"

  tags = {
    Project = var.project_name
  }
}
