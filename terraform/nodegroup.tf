resource "aws_eks_node_group" "voting_nodes" {
  cluster_name    = aws_eks_cluster.voting.name
  node_group_name = "voting-workers"
  node_role_arn   = "arn:aws:iam::117030212282:role/eks-node-role-jenkins"

  subnet_ids = [
    "subnet-08a7bc3710add889a",
    "subnet-0797cae471c1ed04a",
    "subnet-0d2cfa4f4dfb940e4"
  ]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  instance_types = [
    "t3.small"
  ]
}