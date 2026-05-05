terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.2"
    }
  }
}
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }
}

resource "helm_release" "fluent_bit" {
  name = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart = "aws-for-fluent-bit"
  namespace = kubernetes_namespace.logging.metadata[0].name

  set {
    name = "cloudWatch.enabled"
    value = "true"
  }

  set {
    name = "cloudWatch.region"
    value = var.aws_region
  }

  set {
    name = "cloudWatch.logGroupName"
    value = var.log_group_name
  }

  set {
    name = "serviceAccount.create"
    value = "true"
  }

  set {
    name = "serviceAccount.name"
    value = "aws-for-fluent-bit"
  }

  set {
    name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.fluent_bit_role_arn
  }

  values = [
    jsonencode({
      additionalOutputs = "Auto_Create_Group true"
      hostNetwork = true
      dnsPolicy = "ClusterFirstWithHostNet"
    })
  ]
}