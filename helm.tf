provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "helm_release" "cluster_rbac" {
  count = var.enable_rbac_sso ? 1 : 0
  name  = "cluster-rbac"
  chart = "${path.module}/local_charts/cluster-rbac"

  namespace = var.existing_namespace ? var.custom_namespace : kubernetes_namespace.dbt_cloud.0.metadata.0.name

  set {
    name  = "namespace"
    value = var.existing_namespace ? var.custom_namespace : kubernetes_namespace.dbt_cloud.0.metadata.0.name
  }
}

resource "helm_release" "kube_cleanup_operator" {
  count = var.enable_kube_cleanup_operator ? 1 : 0

  name       = "kube-cleanup-operator"
  repository = "https://charts.lwolf.org"
  chart      = "kube-cleanup-operator"
  version    = "1.0.1"

  namespace = var.existing_namespace ? var.custom_namespace : kubernetes_namespace.dbt_cloud.0.metadata.0.name

  values = [
    <<-EOT
    resources:
      limits:
        cpu: 250m
        memory: 500Mi
      requests:
        cpu: 250m
        memory: 250Mi

    args:
      - --namespace=${var.existing_namespace ? var.custom_namespace : kubernetes_namespace.dbt_cloud.0.metadata.0.name}
      - --dry-run=false
      - --delete-successful-after=1h
      - --delete-failed-after=1h
      - --delete-pending-pods-after=24h
      - --ignore-owned-by-cronjobs=true
      - --legacy-mode=false

    metrics:
      enabled: false
    EOT
  ]
}

resource "helm_release" "reloader" {
  count = var.enable_reloader ? 1 : 0

  name       = "reloader"
  repository = "https://stakater.github.io/stakater-charts"
  chart      = "reloader"
  version    = "0.0.75"

  namespace = var.existing_namespace ? var.custom_namespace : kubernetes_namespace.dbt_cloud.0.metadata.0.name

  set {
    name  = "reloader.logFormat"
    value = "json"
  }
}

resource "helm_release" "datadog" {
  count = var.enable_datadog ? 1 : 0

  name       = "datadog-agent"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"

  namespace = var.existing_namespace ? var.custom_namespace : kubernetes_namespace.dbt_cloud.0.metadata.0.name

  set_sensitive {
    name  = "datadog.apiKey"
    value = var.datadog_api_key
  }

  # optional add ons
  set {
    name  = "datadog.apm.enabled"
    value = var.enable_datadog_apm
  }
  set {
    name  = "clusterAgent.enabled"
    value = var.enable_datadog_cluster_agent
  }
  set {
    name  = "datadog.kubeStateMetricsEnabled"
    value = var.enable_datadog_kube_state_metrics
  }
  set {
    name  = "datadog.processAgent.enabled"
    value = var.enable_datadog_process_agent
  }

  # required settings
  set {
    name  = "datadog.logs.enabled"
    value = true
  }
  set {
    name  = "datadog.logs.containerCollectAll"
    value = true
  }
  set {
    name  = "datadog.leaderElection"
    value = true
  }
  set {
    name  = "datadog.collectEvents"
    value = true
  }
  set {
    name  = "datadog.dogstatsd.useHostPort"
    value = true
  }

  # agent memory
  set {
    name  = "agents.containers.agent.resources.limits.cpu"
    value = "500m"
  }
  set {
    name  = "agents.containers.agent.resources.limits.memory"
    value = var.datadog_agent_memory_limit
  }
  set {
    name  = "agents.containers.agent.resources.requests.cpu"
    value = "250m"
  }
  set {
    name  = "agents.containers.agent.resources.requests.memory"
    value = var.datadog_agent_memory_request
  }

  # process agent memory
  set {
    name  = "agents.containers.processAgent.resources.limits.cpu"
    value = "250m"
  }
  set {
    name  = "agents.containers.processAgent.resources.limits.memory"
    value = "512Mi"
  }
  set {
    name  = "agents.containers.processAgent.resources.requests.cpu"
    value = "125m"
  }
  set {
    name  = "agents.containers.processAgent.resources.requests.memory"
    value = "256Mi"
  }

  # trace agent memory
  set {
    name  = "agents.containers.traceAgent.resources.limits.cpu"
    value = "250m"
  }
  set {
    name  = "agents.containers.traceAgent.resources.limits.memory"
    value = "512Mi"
  }
  set {
    name  = "agents.containers.traceAgent.resources.requests.cpu"
    value = "125m"
  }
  set {
    name  = "agents.containers.traceAgent.resources.requests.memory"
    value = "256Mi"
  }

}
