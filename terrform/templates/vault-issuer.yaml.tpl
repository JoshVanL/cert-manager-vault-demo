apiVersion: v1
kind: Namespace
metadata:
  name: ${namespace}
---
apiVersion: cert-manager.io/v1alpha2
kind: Issuer
metadata:
  name: vault
  namespace: ${namespace}
spec:
  vault:
    auth:
      kubernetes:
        role: ${vault_k8s_role}
        mountPath: /v1/auth/${vault_k8s_backend_path}
        secretRef:
          name: ${secret_name}
          key: token
    path: pki_int/sign/${namespace}
    server: http://${vault_address}
