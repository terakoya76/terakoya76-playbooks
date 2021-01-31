# mitmproxy
alias mitmproxy='docker run -it --rm -v ~/.mitmproxy:/home/mitmproxy/.mitmproxy -p 8080:8080 mitmproxy/mitmproxy'

# ssm-sh
alias ssm-sh='docker run -it --rm itsdalmo/ssm-sh'

# conftest
alias conftest='docker run --rm -v $(pwd):/project instrumenta/conftest'

# mongodb
alias mongo='docker run --rm -p 27017:27017 mongo'

# redis
alias redis='docker run --rm -p 6379:6379 redis redis-server --appendonly yes'
