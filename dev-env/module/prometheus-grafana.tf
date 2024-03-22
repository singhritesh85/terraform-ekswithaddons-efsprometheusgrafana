###############################################################################################################################
#Create Namespace for Prometheus and Grafana
###############################################################################################################################

data "aws_eks_cluster" "eks_cluster" {
  name = aws_eks_cluster.eksdemo.name 
}

data "aws_eks_cluster_auth" "eks_cluster_demo" {
  name = aws_eks_cluster.eksdemo.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  token                  = data.aws_eks_cluster_auth.eks_cluster_demo.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
#  config_path    = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks_cluster.endpoint
    token                  = data.aws_eks_cluster_auth.eks_cluster_demo.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
#    config_path    = "~/.kube/config"
  }
}

resource "kubernetes_namespace" "monitor_namespace_dev" {

  metadata {
    name = var.monitoring_namespace
  }

  depends_on = [null_resource.kubectl]
}

###############################################################################################################################
#Create Storage Class
###############################################################################################################################

resource "kubernetes_storage_class" "eks_sc" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Delete"     ###"Retain"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.monitoring_efs.id
    directoryPerms   = "700"
  }

  depends_on = [aws_efs_mount_target.eks_efs_1, aws_efs_mount_target.eks_efs_2, aws_efs_mount_target.eks_efs_3, kubernetes_namespace.monitor_namespace_dev]

}


###############################################################################################################################
#Install Prometheus using Helm 
###############################################################################################################################

resource "helm_release" "prometheus_dev" {
  name       = "prometheus"
  chart      = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "25.17.0"
  namespace  = var.monitoring_namespace

  set {
    name  = "alertmanager.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = true
  }

  set {
    name  = "alertmanager.persistence.enabled"                     ###"alertmanager.persistentVolume.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.storageClass"
    value = "efs-sc"        ###"monitoring-efs-${var.env}"
  }

  set {
    name  = "server.persistentVolume.size"
    value = "20Gi"
  }

  set {
    name  = "alertmanager.persistence.storageClass"                ###"alertmanager.persistentVolume.storageClass"
    value = "efs-sc"        ###"monitoring-efs-${var.env}"
  }

  set {
    name  = "alertmanager.persistence.size"  
    value = "10Gi"   
  }

  depends_on = [kubernetes_storage_class.eks_sc]

#  lifecycle {
#    create_before_destroy = true
#  }

#  provisioner "local-exec" {
#    when    = destroy
#    on_failure = continue
#    command = "nohup ${path.module}/namespace-finalizer.sh 2>&1 &"
#  }

}

###############################################################################################################################
#Install Grafana using Helm
###############################################################################################################################

resource "helm_release" "grafana" {
  name       = "grafana"
  chart      = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  version    = "7.3.6"
  namespace  = var.monitoring_namespace

  set {
    name  = "persistence.enabled"
    value = true
  }

  set {
    name  = "persistence.storageClassName"
    value = "efs-sc"           ###"monitoring-efs-${var.env}"
  }

  set {
    name  = "persistence.size"
    value = "20Gi"
  }

  set {
    name  = "initChownData.enabled"
    value = false
  }

  set {
    name  = "adminPassword"
    value = "subje"
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  values = [
    file("${path.module}/grafana.yaml"),
  ]

  depends_on = [helm_release.prometheus_dev]
}

