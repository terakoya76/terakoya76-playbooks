lsasg () {
  aws autoscaling describe-auto-scaling-groups | jq -r '.AutoScalingGroups[].AutoScalingGroupName'
}

# TODO: 引数で処理を分ける形に
# ex. --tags
lsasgt () {
  aws autoscaling describe-auto-scaling-groups | jq -c '.AutoScalingGroups[].AutoScalingGroupName'
}
