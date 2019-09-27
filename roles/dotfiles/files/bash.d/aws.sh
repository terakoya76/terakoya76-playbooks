lsasg () {
  aws autoscaling describe-auto-scaling-groups | jq -r '.AutoScalingGroups[].AutoScalingGroupName'
}

# TODO: 引数で処理を分ける形に
# ex. --tags
lsasgt () {
  aws autoscaling describe-auto-scaling-groups | jq -c '.AutoScalingGroups[].AutoScalingGroupName'
}

# Need saml2aws
export AWS_PROFILE=saml
sta () {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  saml2aws login --skip-prompt --session-duration 10800
}

