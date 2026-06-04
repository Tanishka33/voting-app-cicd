resource "aws_eks_cluster" "voting" {
  name     = "voting-app-cluster"
  role_arn = "REPLACE_LATER"
  version  = "1.33"

  vpc_config {
    subnet_ids = [
      "subnet-REPLACE1",
      "subnet-REPLACE2"
    ]
  }
}