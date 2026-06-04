resource "aws_eks_cluster" "voting" {
  name     = "voting-app-cluster"
  role_arn = "arn:aws:iam::117030212282:role/eks-cluster-role-jenkins"
  version  = "1.33"

  vpc_config {
    subnet_ids = [
      "subnet-08a7bc3710add889a",
      "subnet-0797cae471c1ed04a",
      "subnet-0d2cfa4f4dfb940e4"
    ]
  }
}