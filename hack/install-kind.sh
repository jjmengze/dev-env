#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

HELM_VERSION=3.5.0
ROOT=$(dirname "${BASH_SOURCE[0]}")/..

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root"
  exit 1
fi

if [ ! -f "/usr/local/bin/kind" ]; then
  curl -Lo ./kind "https://github.com/kubernetes-sigs/kind/releases/download/v0.7.0/kind-$(uname)-amd64"
  chmod a+x ./kind
  sudo mv ./kind /usr/local/bin/kind
fi

set +o errexit
kubectl get node &>/dev/null

if [ ${?} -ne 0 ]; then
  set -o errexit

  echo "Maybe lose kubernetes cluster"
  kind delete cluster

  echo "---------------creating kubernetes cluster---------------"
  cat >"${ROOT}"/hack/kind.yaml <<EOF
kind: Cluster
apiVersion: kind.sigs.k8s.io/v1alpha3
nodes:
- role: control-plane
  extraPortMappings:
    - containerPort: 30000
      hostPort: 30000
      listenAddress: "0.0.0.0"
      protocol: tcp
    - containerPort: 30036
      hostPort: 30036
      listenAddress: "0.0.0.0"
      protocol: tcp
    - containerPort: 30422
      hostPort: 30422
      listenAddress: "0.0.0.0"
      protocol: tcp
    - containerPort: 30222
      hostPort: 30222
      listenAddress: "0.0.0.0"
      protocol: tcp
- role: worker
- role: worker
EOF

  kind create cluster --config "${ROOT}"/hack/kind.yaml
  chown -R $(users):"staff" ${HOME}/.kube/
fi

kubectl get node

if [ ! -f "/usr/local/bin/helm" ]; then
  curl -Lo ./helm.tar.gz https://get.helm.sh/helm-v"${HELM_VERSION}"-darwin-amd64.tar.gz
  tar -zxvf ./helm.tar.gz
  mv darwin-amd64/helm /usr/local/bin/helm
  rm -rf darwin-amd64 helm.tar.gz
fi

helm version

# install redis
echo "==============install redis=================="

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-redis \
  --set password=redis \
  --set master.service.type=NodePort \
  --set master.service.nodePort=30000 \
  -f "${ROOT}"/hack/redis-values.yaml \
  bitnami/redis

kubectl get pod,svc

echo "==============install mysql=================="

#kubectl apply -f https://raw.githubusercontent.com/vitessio/vitess/master/examples/operator/operator.yaml
helm install my-mysql \
  --set auth.rootPassword=mysql \
  --set primary.service.type=NodePort \
  --set primary.service.nodePort=30036 \
  -f "${ROOT}"/hack/mysql-values.yaml \
  bitnami/mysql

echo "==============install NATS=================="
helm install my-nats \
  --set client.service.type=NodePort \
  --set cluster.service.nodePort=30422 \
  --set cluster.service.type=NodePort \
  --set cluster.service.nodePort=30222 \
  -f "${ROOT}"/hack/nats-values.yaml \
  bitnami/nats

echo "==============enjoy your dev env ;) =================="
