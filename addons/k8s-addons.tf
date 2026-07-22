resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  timeout          = 900

  values = [
    <<-EOF
    server:
      service:
        type: LoadBalancer
    EOF
  ]
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  wait             = true
  timeout          = 900

  values = [
    <<-EOF
    grafana:
      service:
        type: ClusterIP
    prometheus:
      prometheusSpec:
        serviceMonitorSelectorNilUsesHelmValues: false
    EOF
  ]
}
