provider "aws" {
region = var.region
}

#provider "kubernetes" {
#  host     = aws_eks_cluster.eksdemo.api_endpoint     ###data.civo_kubernetes_cluster.cluster.api_endpoint
#  config_path    = "~/.kube/config"

#  depends_on = [aws_eks_cluster.eksdemo,aws_eks_node_group.eksnode]
 
#}

#provider "helm" {
#  kubernetes {
#    config_path = "~/.kube/config"
#  }
#}
