resource "kubernetes_namespace" "services" {
  count = length(var.service_names)
  metadata {
    name = var.service_names[count.index]
  }
}

resource "kubernetes_service_account" "vault-issuer" {
  count = length(var.service_names)

  metadata {
    name      = "vault-issuer"
    namespace = var.service_names[count.index]
  }

  automount_service_account_token = true
}


resource "vault_policy" "vault-issuer" {
  count = length(var.service_names)
  name  = "${var.service_names[count.index]}"

  policy = <<EOT
path "pki_int/sign/${var.service_names[count.index]}" {
  capabilities = ["read", "update", "list", "delete"]
}

path "pki_int/issue/${var.service_names[count.index]}" {
  capabilities = ["read", "update", "list", "delete"]
}
EOT

}

resource "vault_kubernetes_auth_backend_role" "services" {
  count                            = length(var.service_names)
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = var.service_names[count.index]
  bound_service_account_names      = [kubernetes_service_account.vault-issuer[count.index].metadata[0].name]
  bound_service_account_namespaces = [var.service_names[count.index]]
  policies                         = [vault_policy.vault-issuer[count.index].name]
  ttl                              = 86400
}

data "template_file" "vault-issuer" {
  count    = length(vault_kubernetes_auth_backend_role.services)
  template = file("${path.module}/templates/vault-issuer.yaml.tpl")

  vars = {
    vault_k8s_backend_path = vault_auth_backend.kubernetes.path
    vault_k8s_role         = vault_kubernetes_auth_backend_role.services[count.index].role_name
    namespace              = var.service_names[count.index]
    vault_address          = var.vault_server
    secret_name            = kubernetes_service_account.vault-issuer[count.index].default_secret_name
  }
}

resource "local_file" "vault-issuer" {
  count    = length(var.service_names)
  content  = data.template_file.vault-issuer[count.index].rendered
  filename = "${path.module}/files/vault-issuer-${var.service_names[count.index]}.yaml"
}

resource "null_resource" "vault-issuer" {
  count = length(var.service_names)

  depends_on = [
    helm_release.cert-manager,
    local_file.vault-issuer,
  ]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/files/vault-issuer-${var.service_names[count.index]}.yaml"
  }
}

data "template_file" "service-cert" {
  count    = length(var.service_names)
  template = file("${path.module}/templates/cert.yaml.tpl")

  vars = {
    service_name = var.service_names[count.index]
  }
}

resource "local_file" "service-cert" {
  count    = length(var.service_names)
  content  = data.template_file.service-cert[count.index].rendered
  filename = "${path.module}/files/cert-${var.service_names[count.index]}.yaml"
}

resource "null_resource" "service-cert" {
  count = length(var.service_names)

  depends_on = [
    helm_release.cert-manager,
    local_file.service-cert,
  ]

  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/files/cert-${var.service_names[count.index]}.yaml"
  }
}
