resource "aws_eks_cluster" "voting" {
  name     = "voting-app-cluster"
  role_arn = "arn:aws:iam::117030212282:role/eks-cluster-role-jenkins"
  version  = "1.33"

  vpc_config {
    subnet_ids = [
      "subnet-REPLACE1",
      "subnet-REPLACE2"
    ]
  }
}