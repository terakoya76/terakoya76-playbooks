tf-move() {
  pj_from=$1
  pj_from=$2

  # backup tfstate
  pushd $pj_from
  terraform state pull > tfstate
  popd

  pushd $pj_to
  terraform state pull > tfstate
  popd

  # select resources
  msg=" 移動対象のリソースを選んでください（複数可）"
  tgt_rsc=$(terraform state list -state=${pj_from}tfstate | peco --prompt $msg)

  for rsc in $tgt_rsc; do
    echo "terraform state mv -state=${pj_from}tfstate -state-out=${pj_to}tfstate $rsc $rsc"
    terraform state mv -state=${pj_from}tfstate -state-out=${pj_to}tfstate $rsc $rsc
  done

  # push local tfstate
  pushd $pj_from
  terraform state push tfstate
  popd

  pushd $pj_to
  terraform state push tfstate
  popd

  # check no-plan
  pushd $pj_from
  terraform plan
  popd

  pushd $pj_to
  terraform plan
  popd
}
