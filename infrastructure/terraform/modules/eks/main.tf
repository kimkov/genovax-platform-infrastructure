module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.31"

  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = var.kms_key_arn
  }

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  enable_irsa               = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Transferring network settings (IPv6, etc.)
  cluster_ip_family = lookup(var.kubernetes_networking_config, "ip_family", "ipv4")

  cluster_addons = {
    vpc-cni = {
      enable_network_policy = true
      most_recent           = true
    }
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    aws-secrets-store-csi-driver = {
      most_recent = true
    }
  }

  # Dynamically configuring EBS-encrypted node groups
  eks_managed_node_groups = {
    for k, v in var.node_groups : k => merge({
      instance_types = ["m6i.large"]
      capacity_type  = "ON_DEMAND"

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 50
            volume_type           = "gp3"
            encrypted             = true
            kms_key_id            = var.kms_key_arn
            delete_on_termination = true
          }
        }
      }
    }, v)
  }

  # Fargate Profiles for Isolating PHI Data
  fargate_profiles = var.fargate_profiles
}
