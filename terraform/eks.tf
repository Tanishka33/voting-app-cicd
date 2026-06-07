resource "aws_eks_cluster" "voting" {

  name     = var.cluster_name

  role_arn = "arn:aws:iam::117030212282:role/eks-cluster-role-jenkins"

  version = "1.33"

  bootstrap_self_managed_addons = false


  vpc_config {

    subnet_ids = [

      "subnet-08a7bc3710add889a",

      "subnet-0797cae471c1ed04a",

      "subnet-0d2cfa4f4dfb940e4"

    ]

  }


  tags = {

    Environment = "dev"

    Project = "voting"

  }


  lifecycle {

    ignore_changes = [

      access_config,

      kubernetes_network_config,

      bootstrap_self_managed_addons,

      upgrade_policy,

      certificate_authority,

      endpoint,

      identity,

      platform_version,

      status

    ]

  }

}