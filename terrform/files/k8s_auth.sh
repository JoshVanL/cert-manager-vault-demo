#!/bin/bash

set -e

export VAULT_SA_NAME=$(kubectl get sa vault -n vault -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -n vault -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -n vault -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="https://10.96.0.1:443" \
  kubernetes_ca_cert="$SA_CA_CRT"
