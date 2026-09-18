#!/bin/zsh

# dev tools
chkcmd direnv && eval "$(direnv hook zsh)"
chkcmd mise && eval "$(mise activate zsh)"

# aws
chkcmd aws && complete -C $(which aws_completer) aws
chkcmd aws-sso-util && eval "$(_AWS_SSO_UTIL_COMPLETE=zsh_source aws-sso-util)"

# k8s
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
  compdef k='kubectl'
}

# terraform
chkcmd terraform && complete -o nospace -C $(which terraform) terraform
