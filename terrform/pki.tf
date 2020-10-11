# Configuring PKI resources on Vault

resource "vault_pki_secret_backend" "pki" {
  path                  = "pki"
  max_lease_ttl_seconds = "315360000"
}

resource "vault_pki_secret_backend_root_cert" "pki" {
  depends_on = [vault_pki_secret_backend.pki]

  backend            = vault_pki_secret_backend.pki.path
  type               = "exported"
  format             = "pem_bundle"
  private_key_format = "der"
  key_type           = "rsa"
  key_bits           = 2048
  common_name        = "cert-manager.io"
  ttl                = "315360000"
}

resource "vault_pki_secret_backend" "pki_int" {
  path                  = "pki_int"
  max_lease_ttl_seconds = "157680000"
}

resource "vault_pki_secret_backend_intermediate_cert_request" "pki_int" {
  depends_on = [vault_pki_secret_backend.pki_int]

  backend     = vault_pki_secret_backend.pki_int.path
  type        = "exported"
  common_name = "cert-manager.io"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "pki" {
  depends_on = [vault_pki_secret_backend_intermediate_cert_request.pki_int]

  backend = vault_pki_secret_backend.pki.path

  csr         = vault_pki_secret_backend_intermediate_cert_request.pki_int.csr
  common_name = "cert-manager.io"
  ttl         = "157680000"
  format      = "pem_bundle"
}

resource "vault_pki_secret_backend_intermediate_set_signed" "pki_int" {
  backend = vault_pki_secret_backend.pki_int.path

  certificate = vault_pki_secret_backend_root_sign_intermediate.pki.certificate
}

resource "vault_pki_secret_backend_role" "services" {
  count              = length(var.service_names)
  backend            = vault_pki_secret_backend.pki_int.path
  name               = var.service_names[count.index]
  ttl                = 86400
  require_cn         = "false"
  allow_any_name     = "false"
  allow_bare_domains = "true"
  allow_glob_domains = "false"
  allowed_domains    = ["${var.service_names[count.index]}.svc.cluster.local"]
  allow_subdomains   = "true"
  generate_lease     = "true"
}

resource "vault_pki_secret_backend_config_urls" "config_urls_root" {
  backend                 = vault_pki_secret_backend.pki.path
  issuing_certificates    = ["http://${var.vault_server}/v1/pki/ca"]
  crl_distribution_points = ["http://${var.vault_server}/v1/pki/crl"]
}

resource "vault_pki_secret_backend_config_urls" "config_urls_int" {
  backend                 = vault_pki_secret_backend.pki_int.path
  issuing_certificates    = ["http://${var.vault_server}/v1/pki_int/ca"]
  crl_distribution_points = ["http://${var.vault_server}/v1/pki_int/crl"]
}
