resource "helm_release" "cert_manager" {
  name             = "${var.prefix}-cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "${var.prefix}-cert-manager"
  create_namespace = true
  version          = "v1.13.0"

  set = [{
    name  = "installCRDs"
    value = "true"
  }]
  wait = true
}

resource "kubernetes_namespace_v1" "arc_namespace" {
  metadata {
    name = "${var.prefix}-runners"
  }
}

resource "kubernetes_secret_v1" "github_app_secret" {
  metadata {
    name      = "${var.prefix}-secret"
    namespace = kubernetes_namespace_v1.arc_namespace.metadata[0].name
  }

  data = {
    github_app_id              = var.gh_app_id
    github_app_installation_id = var.gh_app_installation_id
    github_app_private_key     = file("github_app_key.pem")
  }

  type = "Opaque"
}

resource "helm_release" "arc_controller" {
  name             = var.prefix
  namespace        = "${var.prefix}-systems"
  create_namespace = true
  
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  
  depends_on = [helm_release.cert_manager]
}

resource "helm_release" "arc_runners" {
  name       = "${var.prefix}-runner-${var.cloud_provider}"
  namespace  = kubernetes_namespace_v1.arc_namespace.metadata[0].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "runner-scale-set"
  depends_on = [helm_release.arc_controller, kubernetes_secret_v1.github_app_secret]

  values = [
    yamlencode({
      githubConfigUrl    = "https://github.com/{var.github_owner}"
      githubConfigSecret = kubernetes_secret_v1.github_app_secret.metadata[0].name
      minRunners         = 3
      maxRunners         = 5
      runnerScaleSetLabels = [
        var.cloud_provider
      ]
    })
  ]
}
