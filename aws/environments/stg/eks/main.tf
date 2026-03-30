# -----------------------------------------------------------------------------
# EKS Kubernetes Container Runtime
#
# EKS cluster, managed node groups, addon IAM roles, EFS, ALB controller
# IRSA, and supporting resources.
# Called by container_runtime.tf when enable_eks = true.
# -----------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# =============================================================================
# EKS Cluster
# =============================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.name
  kubernetes_version = "1.33"

  endpoint_public_access  = true
  endpoint_private_access = true

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnets
  control_plane_subnet_ids = var.private_subnets

  ip_family = "ipv4"

  addons = {
    coredns = {
      most_recent              = true
      resolve_conflicts        = "OVERWRITE"
      preserve                 = true
      service_account_role_arn = aws_iam_role.coredns.arn
    }
    kube-proxy = {
      most_recent       = true
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      most_recent              = true
      before_compute           = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = aws_iam_role.vpc_cni.arn
      configuration_values = jsonencode({
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
          MINIMUM_IP_TARGET        = "10"
        }
      })
    }
  }

  eks_managed_node_groups = {
    spot = {
      name            = "spot-node-group"
      use_name_prefix = true
      min_size        = 2
      max_size        = 8
      desired_size    = 2

      ami_type           = "AL2023_x86_64_STANDARD"
      instance_types     = ["m5.large", "m5.xlarge", "m6i.large", "m6i.xlarge"]
      disk_size          = 50
      capacity_type      = "SPOT"
      kubernetes_version = "1.33"

      labels = {
        Environment  = var.env
        InstanceType = "spot"
      }

      tags = {
        "karpenter.sh/capacity-type" = "spot"
      }
    }
  }

  tags = merge(var.tags, {
    "kubernetes.io/cluster/${var.name}" = "owned"
  })
}

# =============================================================================
# Addon IAM Roles (IRSA)
# =============================================================================

resource "aws_iam_role" "coredns" {
  name_prefix = "eks-coredns-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = { Federated = module.eks.oidc_provider_arn }
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:coredns"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role" "vpc_cni" {
  name_prefix = "eks-vpc-cni-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = { Federated = module.eks.oidc_provider_arn }
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:aws-node"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# =============================================================================
# ALB Controller IRSA
# =============================================================================

resource "aws_iam_role" "alb_controller" {
  name_prefix = "eks-alb-controller-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = { Federated = module.eks.oidc_provider_arn }
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "alb_controller_elb" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_iam_role_policy" "alb_controller_ec2" {
  name = "${var.name}-alb-controller-ec2"
  role = aws_iam_role.alb_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ec2:CreateSecurityGroup", "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups", "ec2:DescribeSecurityGroupRules",
        "ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress", "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags", "ec2:DeleteTags",
        "ec2:DescribeInstances", "ec2:DescribeInstanceStatus",
        "ec2:DescribeNetworkInterfaces", "ec2:DescribeVpcs",
        "ec2:DescribeSubnets", "ec2:DescribeAvailabilityZones",
      ]
      Resource = "*"
    }]
  })
}

# =============================================================================
# KMS Key for EBS Encryption
# =============================================================================

module "ebs_kms_key" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 2.0"

  description = "Customer managed key to encrypt EKS managed node group volumes"

  key_administrators = [
    "arn:aws:iam::${var.account_id}:root"
  ]

  key_service_roles_for_autoscaling = [
    "arn:aws:iam::${var.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
    module.eks.cluster_iam_role_arn,
  ]

  aliases = ["eks/${var.name}/ebs"]

  tags = var.tags
}

# =============================================================================
# EFS for Kubernetes Persistent Storage
# =============================================================================

resource "aws_security_group" "efs" {
  name_prefix = "${var.name}-k8s-efs-"
  description = "Security group for Kubernetes EFS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    description     = "NFS from EKS nodes"
    security_groups = [module.eks.cluster_security_group_id]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    description = "NFS from within VPC"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-k8s-efs-sg" })
}

resource "aws_efs_file_system" "k8s" {
  creation_token   = "${var.name}-k8s-efs"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  encrypted  = true
  kms_key_id = module.ebs_kms_key.key_arn

  tags = merge(var.tags, {
    Name    = "${var.name}-k8s-efs"
    Service = "kubernetes"
  })
}

resource "aws_efs_mount_target" "k8s" {
  count           = length(var.private_subnets)
  file_system_id  = aws_efs_file_system.k8s.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "k8s_root" {
  file_system_id = aws_efs_file_system.k8s.id

  root_directory {
    path = "/root"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "755"
    }
  }

  posix_user {
    gid = 0
    uid = 0
  }

  tags = merge(var.tags, {
    Name   = "${var.name}-k8s-efs-root"
    Tenant = "system"
  })
}

# =============================================================================
# EKS Remote Access Security Group
# =============================================================================

resource "aws_security_group" "remote_access" {
  name_prefix = "${var.name}-remote-access-"
  description = "Allow SSH access to EKS nodes from VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-eks-remote" })
}

# =============================================================================
# CloudWatch Log Group
# =============================================================================

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.name}"
  retention_in_days = 14

  tags = merge(var.tags, { Name = "/aws/eks/${var.name}", Purpose = "EKS cluster logs" })
}

# =============================================================================
# AWS Auth Bootstrap
# =============================================================================

resource "null_resource" "bootstrap_aws_auth" {
  provisioner "local-exec" {
    command = <<-EOT
      set +e
      CLUSTER_NAME="${var.name}"
      REGION="${var.region}"
      USER_ARN="arn:aws:iam::${var.account_id}:root"
      MAX_RETRIES=60

      aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
      for i in $(seq 1 $MAX_RETRIES); do
        kubectl get service -n kube-system &>/dev/null && break
        sleep 1
      done
      kubectl patch configmap/aws-auth -n kube-system --type merge \
        -p='{"data":{"mapUsers":"[{\"userarn\":\"'$USER_ARN'\",\"username\":\"admin\",\"groups\":[\"system:masters\"]}]"}}' 2>&1 || true
      set -e
    EOT
  }

  depends_on = [module.eks]

  triggers = {
    cluster_endpoint = module.eks.cluster_endpoint
  }
}
