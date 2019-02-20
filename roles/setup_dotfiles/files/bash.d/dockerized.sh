# grpcurl
docker pull terakoya76/grpcurl
alias grpcurl='docker run -it --rm terakoya76/grpcurl'

# mitmproxy
docker pull mitmproxy/mitmproxy
alias mitmproxy='docker run -it --rm -v ~/.mitmproxy:/home/mitmproxy/.mitmproxy -p 8080:8080 mitmproxy/mitmproxy'

# ssm-sh
docker pull itsdalmo/ssm-sh
alias ssm-sh='docker run -it --rm itsdalmo/ssm-sh'
