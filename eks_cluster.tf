data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "kubernetes_namespace" "dbt_cloud" {
  metadata {
    name = "dbt-cloud-${var.namespace}-${var.environment}"
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

data "aws_ami" "eks_worker_ami_1_15" {
  filter {
    name   = "name"
    values = ["ubuntu-eks/k8s_1.15/images/*"]
  }

  most_recent = true
  owners      = ["099720109477"]

  tags = map(
    "Name", "eks_worker_ami_1_15",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

locals {
  # use built-in policies when posssible
  aws_worker_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess",
    "arn:aws:iam::aws:policy/CloudWatchFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "12.2.0"

  create_eks = true

  cluster_version = "1.15"
  cluster_name    = "${var.namespace}-${var.environment}"
  vpc_id          = var.vpc_id
  subnets         = var.private_subnets

  worker_groups_launch_template = [
    {
      name = "primary-worker-group-1-${var.k8s_node_size}"

      # override ami_id for this launch template
      ami_id = data.aws_ami.eks_worker_ami_1_15.id

      instance_type        = var.k8s_node_size
      asg_desired_capacity = var.k8s_node_count
      asg_min_size         = var.k8s_node_count
      asg_max_size         = var.k8s_node_count

      suspended_processes = ["AZRebalance"]

      key_name                      = "${var.namespace}-${var.environment}"
      additional_security_group_ids = [aws_security_group.internal.id]
      kubelet_extra_args            = local.kubelet_extra_args
      pre_userdata                  = local.bionic_1_15_node_userdata

      enabled_metrics = [
        "GroupStandbyInstances",
        "GroupTotalInstances",
        "GroupPendingInstances",
        "GroupTerminatingInstances",
        "GroupDesiredCapacity",
        "GroupInServiceInstances",
        "GroupMinSize",
        "GroupMaxSize",
      ]
    },
  ]

  workers_role_name           = "${var.namespace}-${var.environment}-workers-role"
  workers_additional_policies = local.aws_worker_policy_arns

  cluster_log_retention_in_days = 0
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  cluster_endpoint_private_access = true

  manage_aws_auth = true
  map_roles = [
    {
      rolearn  = "arn:aws:iam::850607893674:role/${var.namespace}-${var.environment}-workers-role"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:masters", "system:bootstrappers"]
    },
  ]

  write_kubeconfig = false

  tags = map(
    "Name", "eks",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

locals {
  kubelet_extra_args = <<DATA
--cpu-cfs-quota=false
--kube-reserved 'cpu=250m,memory=1Gi,ephemeral-storage=1Gi'
--system-reserved 'cpu=250m,memory=0.5Gi,ephemeral-storage=1Gi'
--eviction-hard 'memory.available<0.1Gi,nodefs.available<10%'
--minimum-container-ttl-duration='5m'
DATA


  bionic_1_15_node_userdata = <<USERDATA
#!/bin/bash -xe

# IMPORTANT NODE CONFIGURATION
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_time
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 10 > /proc/sys/net/ipv4/tcp_keepalive_probes


# INSTALL IMPORTANT THINGS
apt-get -y remove docker.io
apt-get -y update
apt-get -y install \
  apt-transport-https \
  binutils \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository -y \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
apt-get -y install docker-ce docker-ce-cli containerd.io nfs-common
echo '{"bridge":"none","log-driver":"json-file","log-opts":{"max-size":"10m","max-file":"10"},"live-restore":true,"max-concurrent-downloads":10}' > /etc/docker/daemon.json

service docker restart


# CONFIGURE UNATTENDED UPGRADES
sed -i \
  -e 's#//\(.*\)\("$${distro_id}:$${distro_codename}-updates";\)#  \1\2#' \
  -e 's#//\(Unattended-Upgrade::Remove-Unused-Kernel-Packages \)"false";#\1"true";#' \
  /etc/apt/apt.conf.d/50unattended-upgrades

cat << EOF > /etc/apt/apt.conf.d/10periodic
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
EOF

mkdir -p /etc/systemd/system/apt-daily-upgrade.timer.d
cat << EOF > /etc/systemd/system/apt-daily-upgrade.timer.d/override.conf
[Timer]
OnCalendar=
OnCalendar=Wed *-*-* 15:00:00 UTC
RandomizedDelaySec=0
EOF

systemctl daemon-reload


# INSTALL VANTA
VANTA_KEY="dmz1px6yc5mh8tkw2rkh1zq871pwhfeadxju8n5xgg3e0haepe90" \
  bash -c \
    "$(curl -L https://raw.githubusercontent.com/VantaInc/vanta-agent-scripts/257eb25381a96a5544fa8c7c3374fb55071b965e/install-linux.sh)"

USERDATA
}
