#!/bin/bash

#     Purpose:  Expose a few services with "external IPs" using LoadBalancer
#        Date:  2024-05-16
#      Status:  GTG | Needs work.  I need to figure out how to pass the IPADDR var in to the kubectl patch command
# Assumptions:  Services referenced here were deployed using this steps in this repo
#                 i.e. service name, namespace, port - have to align with values in "ServiceMap" (below)
#        Todo: Need to work on this and figure out how to assign pre-determined addresses to service
#            Likely do an NSLOOKUP to get the IP from DNS, then assign
#  References:

cd ~/eksa/$CLUSTER_NAME/latest/
mkdir service_exposure; cd $_

SERVICEMAPFILE=./SERVICEMAP.csv
cat << EOF2 | tee $SERVICEMAPFILE
#APPNAME|NAMESPACE|PORT
prometheus-k8s|monitoring|9090|10.10.13.3
prometheus-adapter|monitoring|443|10.10.13.4
my-grafana|monitoring|80|10.10.13.5
hubble-ui|kube-system|80|10.10.13.6
trivy-operator|trivy-system|80|10.10.13.7
EOF2

grep -v \# $SERVICEMAPFILE | awk -F"|" '{ print $1" "$2" "$3" "$4 }' | while read -r APPNAME NAMESPACE PORT IPADDR
do
  # Expose using LoadBalancer
  echo "$APPNAME $NAMESPACE $PORT $IPADDR"
  echo "kubectl patch svc $APPNAME -n $NAMESPACE -p '{\"spec\": {\"type\": \"LoadBalancer\"}}'"
  kubectl patch svc $APPNAME -n $NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'

  # Expose using ClusterIP 
  #echo "# kubectl patch svc $APPNAME -n $NAMESPACE -p '{\"spec\": {\"type\": \"ClusterIP\"}}'"
  # kubectl patch svc $APPNAME -n $NAMESPACE -p '{"spec": {"type": "ClusterIP"}}'

  # Expose using LoadBalancer but provide the IP Address (not sure this works)
  #echo "# kubectl patch svc $APPNAME -n $NAMESPACE -p '{\"spec\": {\"type\": \"LoadBalancer\", \"loadBalancerIP\": \"$IPADDR\"}}'"
  #kubectl patch svc $APPNAME -n $NAMESPACE -p '{"spec": {"type": "LoadBalancer", "loadBalancerIP": "$IPADDR"}}'
  echo
done

kubectl get svc -A | grep LoadBalancer
cd -

exit 0

# I will Add these Grafana dashboards 
315 | Kubernetes cluster monitoring (via Prometheus)
1860 | Node Exporter Full
14981 | CoreDNS
18283 | Kubernetes

17813 | Trivy (this doesn't seem to work)
21431 | Cilium (use the Cilium Grafana/Prometheus)
16613 | HubbleUI (use the Cilium Grafana/Prometheus)

# The URL for the prometheus endpoint (to add as a Datasource for Grafana) 
# http://prometheus-k8s.monitoring:9090
