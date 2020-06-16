resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "null_resource" "cert-manager-crds" {
  depends_on = [kubernetes_namespace.cert-manager]

  provisioner "local-exec" {
    command = "kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.crds.yaml"
  }
}

resource "helm_release" "cert-manager" {
  depends_on = [null_resource.cert-manager-crds]
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert-manager.metadata[0].name
  version    = "0.15.0"

  set {
    name  = "featureGates"
    value = "ExperimentalCertificateControllers=true"
  }
}
