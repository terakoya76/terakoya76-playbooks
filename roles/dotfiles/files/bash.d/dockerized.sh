# grpcurl
docker pull terakoya76/grpcurl
alias grpcurl='docker run -it --rm terakoya76/grpcurl'

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
