#!/bin/zsh

hash -d jamf=${JAMF_DIR}
hash -d sess=${JAMF_DIR}/sessions

path=("${JAMF_DIR}/repos/cloud-ops-tools/src/scripts" $path)

fpath=("${JAMF_DIR}/repos/cloud-ops-tools/completions" $fpath)
if (($+functions[compdef])); then
  autoload -Uz _cloudtools
  compdef _cloudtools ${${(z)${"$(<"${JAMF_DIR}/repos/cloud-ops-tools/completions/_cloudtools")"%%$'\n'*}}[2,-1]}
fi
