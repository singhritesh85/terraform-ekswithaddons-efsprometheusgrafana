#!/bin/bash
terraform state rm module.eks_cluster.helm_release.prometheus_dev
terraform state rm module.eks_cluster.kubernetes_namespace.monitor_namespace_dev
terraform state list
terraform destroy -auto-approve
###################This Script is used to destroy the entire cluster####################################
