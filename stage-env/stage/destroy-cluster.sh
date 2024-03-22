#!/bin/bash
terraform state rm module.eks_cluster.helm_release.prometheus_stage
terraform state rm module.eks_cluster.kubernetes_namespace.monitor_namespace_stage
terraform state list
terraform destroy -auto-approve
###################This Script is used to destroy the entire cluster####################################
