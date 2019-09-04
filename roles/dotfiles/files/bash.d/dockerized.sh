#
# official
#

# jq
alias jq='docker run -it --rm stedolan/jq'

# yq
alias yq='docker run -it --rm mikefarah/yq yq'

# mitmproxy
alias mitmproxy='docker run -it --rm -v ~/.mitmproxy:/home/mitmproxy/.mitmproxy -p 8080:8080 mitmproxy/mitmproxy'

# ssm-sh
alias ssm-sh='docker run -it --rm itsdalmo/ssm-sh'

# mongodb
docker run -d -p 27017:27017 mongo

# redis
docker run -d -p 6379:6379 redis redis-server --appendonly yes

# terraform
TERRAFORM11=hashicorp/terraform:0.11.14
TERRAFORM12=hashicorp/terraform:0.12.7
alias terraform11="docker run -it --rm $TERRAFORM11"
alias terraform12="docker run -it --rm $TERRAFORM12"

#
# personal
#

# kubectl
alias kubectl='docker run -it --rm -e KUBECONFIG=$KUBECONFIG -v $KUBECONFIG:$KUBECONFIG terakoya76/kubectl'

# stern
alias stern='docker run -it --rm -e KUBECONFIG=$KUBECONFIG -v $KUBECONFIG:$KUBECONFIG terakoya76/stern'

# eksctl
alias eksctl='docker run -it --rm -e KUBECONFIG=$KUBECONFIG -v $KUBECONFIG:$KUBECONFIG terakoya76/eksctl'

# terraformer
alias terraformer='docker run -it --rm terakoya76/terraformer'

# grpcurl
alias grpcurl='docker run -it --rm terakoya76/grpcurl'

# iam-policy-json-to-terraform
alias iam-policy-json-to-terraform='docker run -i --rm terakoya76/iam-policy-json-to-terraform'
