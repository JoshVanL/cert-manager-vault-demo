#!/bin/bash

set -e

if [[ $(kind get clusters -q | wc -c) -eq 0 ]]; then
  kind create cluster
fi

function cleanup()
{
    killall kubectl
}

trap cleanup EXIT

kubectl apply -f ./k8s/secrets/secrets.yaml
kubectl apply -f ./k8s/vault.yaml
kubectl rollout status -n vault deployment vault

kubectl port-forward -n vault svc/vault 8200 &

export VAULT_TOKEN=root
export VAULT_ADDR='http://127.0.0.1:8200'
cd ./terrform
terraform apply -auto-approve
cd -

kubectl rollout status deployment -n cert-manager cert-manager-webhook

kubectl apply -f ./k8s/kube-oidc-proxy.yaml
kubectl apply -f ./k8s/oidc-issuer.yaml
kubectl apply -f ./k8s/rbac.yaml
kubectl apply -f ./k8s/knet-stress.yaml
kubectl apply -f ./k8s/bad-cert.yaml
