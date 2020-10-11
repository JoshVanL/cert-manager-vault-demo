#!/bin/bash

set -e

if [[ $(kind get clusters -q | wc -c) -eq 0 ]]; then
  reg_name='kind-registry'
  reg_port='5000'

  running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
  if [ "${running}" != 'true' ]; then
    docker run \
      -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
      registry:2
  fi

  cat <<EOF | kind create cluster --name vault-demo --config=-
  kind: Cluster
  apiVersion: kind.x-k8s.io/v1alpha4
  containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
      endpoint = ["http://${reg_name}:${reg_port}"]
EOF

  # connect the registry to the cluster network
  docker network connect "kind" "${reg_name}"

  for node in $(kind get nodes); do
    kubectl annotate node "${node}" "kind.x-k8s.io/registry=localhost:${reg_port}";
  done
fi

docker push localhost:5000/ping-pong:v0.0.1

function cleanup()
{
    killall kubectl
}

trap cleanup EXIT

#kubectl apply -f ./k8s/secrets/secrets.yaml
kubectl apply -f ./k8s/vault.yaml
kubectl rollout status -n vault deployment vault

kubectl port-forward -n vault svc/vault 8200 &

export VAULT_TOKEN=root
export VAULT_ADDR='http://127.0.0.1:8200'
cd ./terrform
terraform apply -auto-approve
cd -

kubectl rollout status deployment -n cert-manager cert-manager-webhook

kubectl apply -f ./k8s/rbac.yaml
kubectl apply -f ./k8s/ping-pong.yaml
#kubectl apply -f ./k8s/bad-cert.yaml
