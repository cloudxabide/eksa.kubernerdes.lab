#! /bin/bash
# govc calls to configure a user with minimal permissions
set -x
set -e

EKSA_USER='<Username>@<UserDomain>'
USER_ROLE='EKSAUserRole'
GLOBAL_ROLE='EKSAGlobalRole'
ADMIN_ROLE='EKSACloudAdminRole'

FOLDER_VM='/YourDatacenter/vm/YourVMFolder'
FOLDER_TEMPLATES='/YourDatacenter/vm/Templates'

NETWORK='/YourDatacenter/network/YourNetwork'
DATASTORE='/YourDatacenter/datastore/YourDatastore'
RESOURCE_POOL='/YourDatacenter/host/Cluster-01/Resources/YourResourcePool'

govc role.create "$GLOBAL_ROLE" $(curl https://raw.githubusercontent.com/aws/eks-anywhere/main/pkg/config/static/globalPrivs.json | jq .[] | tr '\n' ' ' | tr -d '"')

govc role.create "$USER_ROLE" $(curl https://raw.githubusercontent.com/aws/eks-anywhere/main/pkg/config/static/eksUserPrivs.json | jq .[] | tr '\n' ' ' | tr -d '"')

govc role.create "$ADMIN_ROLE" $(curl https://raw.githubusercontent.com/aws/eks-anywhere/main/pkg/config/static/adminPrivs.json | jq .[] | tr '\n' ' ' | tr -d '"')

govc permissions.set -group=false -principal "$EKSA_USER"  -role "$GLOBAL_ROLE" /

govc permissions.set -group=false -principal "$EKSA_USER"  -role "$ADMIN_ROLE" "$FOLDER_VM"

govc permissions.set -group=false -principal "$EKSA_USER"  -role "$ADMIN_ROLE" "$FOLDER_TEMPLATES"

govc permissions.set -group=false -principal "$EKSA_USER"  -role "$USER_ROLE" "$NETWORK"

govc permissions.set -group=false -principal "$EKSA_USER"  -role "$USER_ROLE" "$DATASTORE"

govc permissions.set -group=false -principal "$EKSA_USER"  -role "$USER_ROLE" "$RESOURCE_POOL"

