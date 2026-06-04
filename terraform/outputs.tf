output "cluster_name" {
    value = aws_eks_cluster.voting.name
}

output "cluster_endpoint" {
    value = aws_eks_cluster.voting.endpoint
}