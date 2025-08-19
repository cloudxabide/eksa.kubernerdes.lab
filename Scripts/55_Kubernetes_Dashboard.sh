#!/bin/bash

#     Purpose:  To install Kubernetes Dashboard
#        Date:  2025-08-19
#      Status:  GTG 
# Assumptions:
#        Todo:  Test that this works
#  References:
#               https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

############### ############### ############### ###############
## Kubernetes Dashbaord (WIP)
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
kubectl -n kubernetes-dashboard patch svc kubernetes-dashboard-kong-proxy -p='{"spec": {"type": "LoadBalancer"}}'

mkdir kubernetes-dashboard; cd $_

# https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
cat << EOF3 | tee kubernetes-dashboard-sa.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF3
kubectl apply -f kubernetes-dashboard-sa.yaml

cat << EOF5 | tee kubernetes-dashboard-clusterrolebinding.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF5
kubectl apply -f kubernetes-dashboard-clusterrolebinding.yaml

# kubectl -n kubernetes-dashboard create token admin-user
cat << EOF6 | tee kubernetes-dashboard-sa-token.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: "admin-user"   
type: kubernetes.io/service-account-token  
EOF6
kubectl apply -f kubernetes-dashboard-sa-token.yaml

kubectl create clusterrolebinding admin-user --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:admin-user

kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d > kubernetes-dashboard-token.out
echo $(kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} |  base64 -d)
cd -

# NOTE: THIS DOESN'T WORK AS MetalLB has not been enabled yet and therefore kong-proxy does not have a "public" IP
#K8s_DASHBOARD=$(kubectl get svc kubernetes-dashboard-kong-proxy -n kubernetes-dashboard -o jsonpath='{.status.loadBalancer.ingress[].ip}')
#echo -e "Access Kubernetes Dashboard at: \nhttps://$K8s_DASHBOARD"
echo $( kubectl get ingress k8s-dashbaoard-ingress -o jsonpath='{.spec.rules[*].host}')
exit 0


clean_up() {
kubectl delete namesapce kubernetes-dashboard
}


