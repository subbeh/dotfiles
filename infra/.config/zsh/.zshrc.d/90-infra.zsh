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

# just: complete home-ops recipe arguments (terraform stacks, ansible playbooks),
# which just's own completer can't do; everything else falls through to it.
chkcmd terraform && {
  _just_homeops() {
    case ${words[CURRENT - 1]} in
    tf::*)
      compadd -- "${XDG_HOMEOPS_DIR}"/terraform/*(N/:t)
      return
      ;;
    ansible::playbook)
      compadd -- "${XDG_HOMEOPS_DIR}"/ansible/playbooks/*.yaml(N:t:r)
      return
      ;;
    esac
    if ((! $+functions[_clap_dynamic_completer_just])); then
      source <(JUST_COMPLETE=zsh just)
      # The generated script registers its own completer for just; take it back.
      compdef _just_homeops just
    fi
    _clap_dynamic_completer_just "$@"
  }
  compdef _just_homeops just
}
