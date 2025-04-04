#!/bin/bash

#     Purpose:  Configure Ingress (metalLB and emissary)
#        Date:  2024-07-01
#      Status:  GTG | MetalLB may have a hang up - hoping 30 second delay in workflow resolves issue
# Assumptions:
#        Todo:
#  References:

########################### ###########################
# Install MetalLB
# https://metallb.universe.tf/installation/
mkdir ~/eksa/$CLUSTER_NAME/latest/metallb
cd ~/eksa/$CLUSTER_NAME/latest/metallb

# First, see what changes would occur
echo "Note:  Showing differences that will be applied" 
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl diff -f - -n kube-system

# Then, apply those changes
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

# Test without this
cat << EOF2 | tee metallb-ns.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: metallb-system
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/warn: privileged
EOF2
kubectl apply -f metallb-ns.yaml

kubectl config set-context --current --namespace=metallb-system

# TODO: Figure out how to dynamically retrieve this value for current version
METALLB_VERSION=v0.14.9
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml

# Set the CIDR based on which cluster we are managing
case $(kubectl config view --minify -o jsonpath='{.clusters[].name}') in
  kubernerdes-eksa) CIDR_POOL="10.10.13.1-10.10.13.63";;
  vsphere-eksa) CIDR_POOL="10.10.13.64-10.10.13.127";;
esac

cat << EOF4 | tee metallb-config.yaml
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: metallb-system
spec:
  addresses:
  - $CIDR_POOL
  autoAssign: true
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: default
  namespace: metallb-system
spec:
  ipAddressPools:
  - default
EOF4

# NOTE:  make sure that this runs successfully - I have seen it fail at times (and I am not sure why)
#   I cannot figure out how to add a logic-gate here to wait for the correct conditions before proceeding (or.. maybe to retry until successful?)
#  if it does, just rerun
sleep 30
kubectl apply -f metallb-config.yaml
cd -
kubectl config set-context --current --namespace=default

########################### ###########################
# Install Emissary Ingress
# NOTE:  make sure that this runs successfully - I have seen it fail at times (and I am not sure why)

# Add the Repo:
helm repo add datawire https://app.getambassador.io
helm repo update

# Create Namespace and Install:
kubectl create namespace emissary && \
kubectl apply -f https://app.getambassador.io/yaml/emissary/3.9.1/emissary-crds.yaml

kubectl wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system

helm install emissary-ingress --namespace emissary datawire/emissary-ingress && \
kubectl -n emissary wait --for condition=available --timeout=90s deploy -lapp.kubernetes.io/instance=emissary-ingress

exit 0

cleanup() {
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
}

