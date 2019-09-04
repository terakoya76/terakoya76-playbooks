#
# official
#

# jq
docker pull stedolan/jq
alias jq='docker run -it --rm stedolan/jq'

# yq
docker pull mikefarah/yq
alias yq='docker run -it --rm mikefarah/yq yq'

# mitmproxy
docker pull mitmproxy/mitmproxy
alias mitmproxy='docker run -it --rm -v ~/.mitmproxy:/home/mitmproxy/.mitmproxy -p 8080:8080 mitmproxy/mitmproxy'

# ssm-sh
docker pull itsdalmo/ssm-sh
alias ssm-sh='docker run -it --rm itsdalmo/ssm-sh'

# mongodb
docker pull mongo
docker run -d -p 27017:27017 mongo

# redis
docker pull redis
docker run -d -p 6379:6379 redis redis-server --appendonly yes

# terraform
TERRAFORM11=hashicorp/terraform:0.11.14
TERRAFORM12=hashicorp/terraform:0.12.7
docker pull $TERRAFORM11
docker pull $TERRAFORM12
alias terraform11="docker run -it --rm $TERRAFORM11"
alias terraform12="docker run -it --rm $TERRAFORM12"

#
# personal
#

# kubectl
docker pull terakoya76/kubectl
alias kubectl='docker run -it --rm -e KUBECONFIG=$KUBECONFIG -v $KUBECONFIG:$KUBECONFIG terakoya76/kubectl'

# stern
docker pull terakoya76/stern
alias stern='docker run -it --rm -e KUBECONFIG=$KUBECONFIG -v $KUBECONFIG:$KUBECONFIG terakoya76/stern'

# eksctl
docker pull terakoya76/eksctl
alias eksctl='docker run -it --rm -e KUBECONFIG=$KUBECONFIG -v $KUBECONFIG:$KUBECONFIG terakoya76/eksctl'

# terraformer
docker pull terakoya76/terraformer
alias terraformer='docker run -it --rm terakoya76/terraformer'

# grpcurl
docker pull terakoya76/grpcurl
alias grpcurl='docker run -it --rm terakoya76/grpcurl'

# iam-policy-json-to-terraform
docker pull terakoya76/iam-policy-json-to-terraform
alias iam-policy-json-to-terraform='docker run -i --rm terakoya76/iam-policy-json-to-terraform'
