resource "local_file" "script" {
  count    = var.create_admin_console_script ? 1 : 0
  filename = "./kots_install.sh"
  content  = <<EOT
#!/bin/bash
set -euo pipefail

aws eks --region ${var.aws_region} update-kubeconfig --name ${local.cluster_name}

kubectl config set-context --current --namespace=${local.k8s_namespace}

[[ -x $(which kubectl-kots) ]] || curl https://kots.io/install | bash

set -v

kubectl kots install ${local.app_and_channel} \
  --namespace ${local.k8s_namespace} \
  --license-file ${var.license_file_path} \
  --shared-password ${var.admin_console_password} \
  --config-values ${local_file.config.0.filename} \
  --port-forward=false \
  --skip-preflights \
  --wait-duration=10m


EOT
  provisioner "local-exec" {
    command = "./kots_install.sh"
  }
  depends_on = [module.eks, local_file.config, kubernetes_namespace.kots_app]
}

resource "local_file" "patch" {
  count    = 1
  filename = "./patch_kots_service.sh"
  content  = <<EOT
#!/bin/bash
set -euo pipefail

kubectl patch service -n ${local.k8s_namespace} kotsadm -p '{"spec":{"type":"NodePort"}}'
kubectl patch ingress -n ${local.k8s_namespace} kotsadm-ingress -p '{"spec":{"rules":[{"host":"${var.kotsadm_fqdn}","http":{"paths":[{"backend":{"service":{"name":"kotsadm","port":{"number":3000}}},"path":"/","pathType":"Prefix"}]}}]}}'
kubectl patch service -n ${local.k8s_namespace} sentry -p '{"spec":{"type":"NodePort"}}'
kubectl patch ingress -n ${local.k8s_namespace} sentry-ingress -p '{"spec":{"rules":[{"host":"${var.sentry_fqdn}","http":{"paths":[{"backend":{"service":{"name":"sentry","port":{"number":9000}}},"path":"/","pathType":"Prefix"}]}}]}}'
EOT
  provisioner "local-exec" {
    command = "./patch_kots_service.sh"
  }
  depends_on = [local_file.script, kubernetes_ingress.sentry_ingress, kubernetes_ingress.kotsadm_ingress, helm_release.external_dns]
}

resource "local_file" "config" {
  count    = var.create_admin_console_script ? 1 : 0
  filename = "./config.yaml"
  content  = <<-EOT
apiVersion: kots.io/v1beta1
kind: ConfigValues
metadata:
  name: kots-sentry
spec:
  values:
    admin_username:
      value: ${var.sentry_admin_username}
    admin_password:
      value: ${var.sentry_admin_password}
status: {}
EOT
}
