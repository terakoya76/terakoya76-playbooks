#
# official
#

# jq
docker pull stedolan/jq

# yq
docker pull mikefarah/yq

# mitmproxy
docker pull mitmproxy/mitmproxy

# ssm-sh
docker pull itsdalmo/ssm-sh

# mongodb
docker pull mongo

# redis
docker pull redis

# terraform
TERRAFORM11=hashicorp/terraform:0.11.14
TERRAFORM12=hashicorp/terraform:0.12.7
docker pull $TERRAFORM11
docker pull $TERRAFORM12

#
# personal
#

# kubectl
docker pull terakoya76/kubectl

# stern
docker pull terakoya76/stern

# eksctl
docker pull terakoya76/eksctl

# terraformer
docker pull terakoya76/terraformer

# grpcurl
docker pull terakoya76/grpcurl

# iam-policy-json-to-terraform
docker pull terakoya76/iam-policy-json-to-terraform
