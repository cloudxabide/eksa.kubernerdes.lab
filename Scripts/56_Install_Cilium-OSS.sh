#/bin/bash

#     Purpose: To replace EKS-A included Cilium with Cilium OSS
#        Date: 2024-03-01
#      Status: GTG, I think
#              Ready to test (this is still a bit clunky, therefore it 
#              should be cut-and-paste and interactively installed)
# Assumptions:
#        Todo: Update process to update Cilium and Hubble CLI, if needed
#  References: https://isovalent.com/blog/post/cilium-eks-anywhere/

########################################
########################################
# Install CLI and Tools
########################################
########################################
# Install Cilium CLI
# https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/
install_Cilium_CLI() {
cilium version; echo
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable-v0.14.txt)
#CLI_ARCH=amd64
case $(uname -m) in 
  aarch64) CLI_ARCH=arm64;;
  x86_64) CLI_ARCH=amd64;;
esac

case $(uname) in 
  Linux)  
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum 
    sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
    ;;
  Darwin) 
    curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-darwin-${CLI_ARCH}.tar.gz{,.sha256sum}
    shasum -a 256 -c cilium-darwin-${CLI_ARCH}.tar.gz.sha256sum
    sudo tar xzvfC cilium-darwin-${CLI_ARCH}.tar.gz /usr/local/bin
  ;;
esac

cilium version; echo
}

# Install Hubble CLI
# https://docs.cilium.io/en/stable/observability/hubble/setup/
install_Hubble_CLI() {
export HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
case $(uname) in 
  Darwin)
    HUBBLE_ARCH=amd64
    if [ "$(uname -m)" = "arm64" ]; then HUBBLE_ARCH=arm64; fi
    curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-darwin-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
    shasum -a 256 -c hubble-darwin-${HUBBLE_ARCH}.tar.gz.sha256sum
    sudo tar xzvfC hubble-darwin-${HUBBLE_ARCH}.tar.gz /usr/local/bin
    rm hubble-darwin-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
  ;;
  Linux)
    HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
    HUBBLE_ARCH=amd64
    if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
    curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
    sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
    rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
  ;;
esac
hubble version; echo
}

########################################
########################################
# Start Here
########################################
########################################
cd ~/eksa/$CLUSTER_NAME/latest/
mkdir cilium; cd $_

case $(uname) in
  Darwin) echo "Please follow Foo/Kind_Cilium.md to install Cilium in Kind on your Mac"; exit 0;;
esac

# Add Cilium Helm Repo
helm repo add cilium https://helm.cilium.io/
helm repo update cilium

### PRE-FLIGHT CHECK
#  Replace EKS-A version of Cilium with OSS version
CILIUM_DEFAULT_VERSION=$(cilium version | grep "(default)" | awk -F\: '{ print $2 }' | sed 's/ //')
helm template cilium/cilium --version $CILIUM_DEFAULT_VERSION  \
  --namespace=kube-system \
  --set preflight.enabled=true \
  --set agent=false \
  --set operator.enabled=false \
  > cilium-preflight.yaml
kubectl create -f cilium-preflight.yaml

# Check for the daemonset status - initially will not be ready
# Then start a while loop until the first one starts (and there is no longer a '0' in 
#   the output from the command)
# NOTE:  I need to improve this logic to check for the "DESIRED" number and wait 
#   until the correct number is running
kubectl get daemonset -n kube-system | sed -n '1p;/cilium/p'
while sleep 2; do echo; ( kubectl get daemonset -n kube-system | sed -n '1p;/cilium/p' | grep -w 0; ) || break; done

# Once the daemonset is running, you can delete the preflight check
echo "Note:  delete Cilium PreFlight Check"
kubectl delete -f cilium-preflight.yaml

# Maybe I need to consider the following: https://ambar-thecloudgarage.medium.com/eks-anywhere-jiving-with-cilium-oss-and-bgp-load-balancer-12af1d10099c
#    To deal with teh service accounts, etc...
# NOTE - this next set of steps are a temporary workaround to clean up accounts
clean-up-accounts() {
kubectl delete serviceaccount cilium --namespace kube-system
kubectl delete serviceaccount cilium-operator --namespace kube-system
kubectl delete secret hubble-ca-secret --namespace kube-system
kubectl delete secret hubble-server-certs --namespace kube-system
kubectl delete configmap cilium-config --namespace kube-system
kubectl delete clusterrole cilium
kubectl delete clusterrolebinding cilium
kubectl delete clusterrolebinding cilium-operator
kubectl delete secret cilium-ca --namespace kube-system
kubectl delete service hubble-peer --namespace kube-system
kubectl delete daemonset cilium --namespace kube-system
kubectl delete deployment cilium-operator --namespace kube-system
kubectl delete clusterrole cilium-operator
# The following were new additions (2024-04-21)
kubectl delete role cilium-config-agent -n kube-system # if you ran the pre-flight test
kubectl delete rolebinding cilium-config-agent -n kube-system
# New Addition (2024-07-23)
kubectl delete svc cilium-agent -n kube-system
}
clean-up-accounts

# helm install cilium cilium/cilium --version 1.13.3 \
# NOTE: This needs testing - I *think* this should work for *my* needs.
# Bare Metal Ubuntu: eno1
# VMware + Ubuntu ~= eth0
# Docker/KIND = eth0
# Set the Interface Namee based on which cluster we are managing
case $(kubectl config view --minify -o jsonpath='{.clusters[].name}') in
  kubernerdes-eksa) MYINTERFACE=eno1;;
  vsphere-eksa) MYINTERFACE=eth0;;
  *) MYINTERFACE=eth0;;
esac

[ -z $CILIUM_DEFAULT_VERSION ] && { CILIUM_DEFAULT_VERSION=$(cilium version | grep "(default)" | awk -F\: '{ print $2 }' | sed 's/ //'); }

## NOTE:  Prometheus add-on is not (yet) tested (2024-07-02)    
working() {
helm install cilium cilium/cilium --version $CILIUM_DEFAULT_VERSION \
  --namespace kube-system \
  --set eni.enabled=false \
  --set ipam.mode=kubernetes \
  --set egressMasqueradeInterfaces=$MYINTERFACE \
  --set prometheus.enabled=true \
  --set operator.prometheus.enabled=true \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,icmp,http}" \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true 
}
# https://docs.cilium.io/en/stable/observability/grafana/
testing() {
CILIUM_DEFAULT_VERSION=1.16.5
helm install cilium cilium/cilium --version $CILIUM_DEFAULT_VERSION \
  --namespace kube-system \
  --set egressMasqueradeInterfaces=$MYINTERFACE \
  --set eni.enabled=false \
  --set hubble.enabled=true \
  --set hubble.metrics.enableOpenMetrics=true \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}" \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set ipam.mode=kubernetes \
  --set operator.prometheus.enabled=true \
  --set prometheus.enabled=true 
}

### Validate the install
while sleep 2; do echo; cilium status | egrep 'error' || { echo "Great - LGTM. Let's proceed..."; break; }; done
kubectl get nodes -o wide # make sure all nodes are "READY"
## I recently noticed that I was receiving "Connection timed out" - which seemed to go away after time?
while sleep 2; do { echo "Waiting for connectivity..."; kubectl -n kube-system exec ds/cilium -- cilium-health status | egrep "Connection timed out"; } || break; done 

## Test Cilium Connectivity
echo "Running Cilium Connectivity Test - This will take a few minutes." 
echo "You can tail the output by running: "
echo "tail -f `pwd`/cilium_connectivity_test.out"
date  > cilium_connectivity_test.out
cilium connectivity test >> cilium_connectivity_test.out
date >> cilium_connectivity_test.out
kubectl delete namespace cilium-test-1

# Install Cilium/Hubble enabled Prometheus/Grafana
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.12/examples/kubernetes/addons/prometheus/monitoring-example.yaml
kubectl patch svc grafana -n cilium-monitoring -p '{"spec": {"type": "LoadBalancer"}}'

cd -

exit 0

# Update Cilium and use Ingress Routing

helm upgrade cilium cilium/cilium --version 1.16.5 \
    --namespace kube-system \
    --reuse-values \
    --set ingressController.enabled=true \
    --set ingressController.loadbalancerMode=dedicated

# Troubleshooting, etc...

# This cannot (easily) be scripted, I think?
## terminal 1
kubectl port-forward -n kube-system svc/hubble-relay 4245:80 # For local connectivity (if you're using Docker, maybe?)
## terminal 2
hubble status 
# If hubble relay is not running, run the following:
cilium hubble enable

# This generates a TON of output
hubble observe --server localhost:4245 --follow

kubectl port-forward -n kube-system svc/hubble-ui 12000:80

# kubectl get events -n kube-system

# If you happen to have configured your Cilium (like I did) with the wrong masquerade interface...
cat << EOF1 | tee update_Cilium.yaml
---
egressMasqueradeInterfaces: eno1
EOF1
helm upgrade cilium cilium/cilium -f update_Cilium.yaml  -n kube-system
