#!/bin/bash

#     Purpose:  Deploy the ECS demo 3-tier App
#        Date:  2025-01-31
#      Status:  GTG | 
# Assumptions:
#        Todo:
#  References: 

# Manually clone
#git clone https://github.com/GIT_OWNER/eks-workshop.git
#git clone https://github.com/GIT_OWNER/ecsdemo-frontend.git
#git clone https://github.com/GIT_OWNER/ecsdemo-nodejs.git
#git clone https://github.com/GIT_OWNER/ecsdemo-crystal.git

cd ${HOME}/eksa/$CLUSTER_NAME/latest
mkdir ecsdemo; cd $_

container_build() {
## Assumptions:
##   the directory you cd to, is named for the project
PROJECTS="ecsdemo-crystal ecsdemo-frontend ecsdemo-nodejs"

for PROJECT in $PROJECTS
do
  cd (PROJECT)
  docker build --platform linux/amd64 -t $(basename `pwd`) .
  docker tag $(basename `pwd`) $GIT_OWNER/$(basename `pwd`)
  # You may need/want to add ":latest" to the tag
  # docker tag $(basename `pwd`) $GIT_OWNER/$(basename `pwd`):latest
  docker push $_
  cd -
done
}

kubectl create ns ecsdemo
kubectl config set-context --current --namespace=ecsdemo

for PROJECT in ecsdemo-nodejs ecsdemo-crystal ecsdemo-frontend
do 
  [ -d $PROJECT ] && { cd $PROJECT; git pull; } || { git clone  https://github.com/$GIT_OWNER/$PROJECT; cd $PROJECT; }
  kubectl apply -f kubernetes/deployment.yaml
  kubectl apply -f kubernetes/service.yaml
  kubectl get deployment $PROJECT
  cd -
done

# Hostname (if using EKS)
URL=$(kubectl get service/ecsdemo-frontend -n ecsdemo -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo -e "Browse to \nhttp://$URL"

# IP (if using EKS Anywhere)
FRONTEND_IP=$(kubectl get service ecsdemo-frontend -o json | jq -r '.status.loadBalancer.ingress[].ip')
echo "Access FrontEnd at: http://$FRONTEND_IP/"

scale_out() {
kubectl scale deployment ecsdemo-nodejs --replicas=3 -n ecsdemo
kubectl scale deployment ecsdemo-crystal --replicas=3 -n ecsdemo
kubectl scale deployment ecsdemo-frontend --replicas=3 -n ecsdemo
}
scale_in() {
kubectl scale deployment ecsdemo-nodejs --replicas=1 -n ecsdemo
kubectl scale deployment ecsdemo-crystal --replicas=1 -n ecsdemo
kubectl scale deployment ecsdemo-frontend --replicas=1 -n ecsdemo
}

while sleep 2; do echo; kubectl get pods | egrep ContainerCreating || break; done
kubectl config set-context --current --namespace=default

exit 0

######################################
######################################
######################################
# To clean up
kubectl delete ns ecsdemo

## TO RUN THE ORIGINAL VERSION
# works, but it is dependent on "AZs" for the visualization
git clone https://github.com/aws-containers/ecsdemo-frontend.git
git clone https://github.com/aws-containers/ecsdemo-nodejs.git
git clone https://github.com/aws-containers/ecsdemo-crystal.git

for PROJECT in ecsdemo-nodejs ecsdemo-crystal ecsdemo-frontend
do
  cd $PROJECT
  kubectl apply -f kubernetes/deployment.yaml
  kubectl apply -f kubernetes/service.yaml
  cd -
done

## Cleanup
for PROJECT in ecsdemo-nodejs ecsdemo-crystal ecsdemo-frontend
do
  cd $PROJECT
  kubectl delete -f kubernetes/deployment.yaml
  kubectl delete -f kubernetes/service.yaml
  cd -
done

