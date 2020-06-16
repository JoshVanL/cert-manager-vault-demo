data "template_file" "k8s_auth" {
  template = file("${path.module}/templates/k8s_auth.tpl")

  vars = {
    service_account  = "vault"
    vault_server     = var.vault_server
    k8s_host         = var.k8s_host
  }
}

resource "local_file" "k8s_auth" {
  content  = data.template_file.k8s_auth.rendered
  filename = "${path.module}/files/k8s_auth.sh"
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = "kubernetes"
}

resource "null_resource" "k8s_auth_backend" {
  depends_on = [
    local_file.k8s_auth,
    vault_auth_backend.kubernetes,
  ]

  provisioner "local-exec" {
    command = "${path.module}/files/k8s_auth.sh"
  }
}
