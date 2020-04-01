#
# official
#

# mitmproxy
alias mitmproxy='docker run -it --rm -v ~/.mitmproxy:/home/mitmproxy/.mitmproxy -p 8080:8080 mitmproxy/mitmproxy'

# ssm-sh
alias ssm-sh='docker run -it --rm itsdalmo/ssm-sh'

# conftest
alias conftest='docker run --rm -v $(pwd):/project instrumenta/conftest'

# mongodb
docker run -d -p 27017:27017 mongo

# redis
docker run -d -p 6379:6379 redis redis-server --appendonly yes

# terraform
TERRAFORM11=hashicorp/terraform:0.11.14
TERRAFORM12=hashicorp/terraform:0.12.7
alias terraform11="docker run --rm -v $(pwd):/project $TERRAFORM11"
alias terraform12="docker run --rm -v $(pwd):/project $TERRAFORM12"

#
# personal
#

# terraformer
alias terraformer='docker run --rm terakoya76/terraformer'

# iam-policy-json-to-terraform
alias iam-policy-json-to-terraform='docker run --rm terakoya76/iam-policy-json-to-terraform'
