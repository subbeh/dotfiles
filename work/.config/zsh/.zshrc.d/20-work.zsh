#!/bin/zsh

hash -d jamf=${JAMF_DIR}
hash -d sess=${JAMF_DIR}/sessions

fpath=("${JAMF_DIR}/cloud-ops-tools/completions" $fpath)
if (($+functions[compdef])); then
  autoload -Uz _cloudtools
  compdef _cloudtools ${${(z)${"$(<'${JAMF_DIR}/cloud-ops-tools/completions/_cloudtools')"%%$'\n'*}}[2,-1]}
fi
