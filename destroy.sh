#!/bin/bash

set -e

function cleanup()
{
    killall kubectl
}

trap cleanup EXIT

kubectl port-forward -n vault svc/vault 8200 &

export VAULT_TOKEN=root
export VAULT_ADDR='http://127.0.0.1:8200'
cd ./terrform
terraform destroy -auto-approve
cd -

kind delete cluster --name vault-demo
docker stop kind-registry
docker rm kind-registry
