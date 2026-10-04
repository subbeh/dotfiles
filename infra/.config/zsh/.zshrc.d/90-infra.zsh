#!/bin/zsh

# dev tools, k8s: direnv/mise/kubectl each fork a subprocess to generate hooks
# or completions -- defer to zinit's turbo queue so that doesn't block startup.
zinit wait lucid as'null' id-as'defer-infra' atload'
  chkcmd direnv && eval "$(direnv hook zsh)"
  chkcmd mise && eval "$(mise activate zsh)"
  chkcmd kubectl && {
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

    alias k=kubectl
    chkcmd kubecolor && alias k=kubecolor
    alias kns="kubectl config set-context --current --namespace"
    alias kctx="kubectl config use-context"

    source <(kubectl completion zsh)
    chkcmd kubectl-netshoot && {
      source <(kubectl netshoot completion zsh)
      alias kdbgrun="kubectl netshoot run debugger"
      alias kdbg="kubectl netshoot debug"
    }
    compdef k="kubectl"
  }
' for %$ZDOTDIR

# aws
chkcmd aws && complete -C $(which aws_completer) aws
# chkcmd aws-sso-util && eval "$(_AWS_SSO_UTIL_COMPLETE=zsh_source aws-sso-util)"

# terraform
chkcmd terraform && complete -o nospace -C $(which terraform) terraform

# ansible
play() {
  local _popd
  [[ "$(pwd)" != "${XDG_HOMEOPS_DIR:?not set}/ansible" ]] && _popd=1
  ((_popd)) && pushd "${XDG_HOMEOPS_DIR:?not set}/ansible"
  ansible-playbook "playbooks/$@"
  ((_popd)) && popd
}

## completion function for ap command
_play() {
  local playbooks
  playbooks=("${XDG_HOMEOPS_DIR}/ansible/playbooks/"*(N:t))
  _describe 'playbooks' playbooks
}

## Register the completion function
compdef _play play
