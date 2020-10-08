data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
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

USERDATA
}

resource "aws_iam_policy" "nodes_kubernetes" {
  name   = "nodes.kubernetes.${var.namespace}-${var.environment}"
  policy = data.aws_iam_policy_document.nodes_kubernetes.json
}

data "aws_iam_policy_document" "nodes_kubernetes" {
  statement {
    actions = [
      "ec2:Describe*",
    ]

    resources = ["*"]
  }

  statement {
    actions = ["route53:GetChange"]

    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    sid = "kmsAllow"

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:Describe*",
      "kms:Get*",
      "kms:List*",
    ]

    resources = [
      "*"
    ]
  }
}
