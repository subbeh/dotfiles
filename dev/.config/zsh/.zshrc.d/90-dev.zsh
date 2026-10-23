#!/bin/zsh

# dev tools, k8s: direnv/mise/kubectl each fork a subprocess to generate hooks
# or completions -- defer to zinit's turbo queue so that doesn't block startup.
# nocd: atload otherwise runs from the plugin dir, so direnv/mise would resolve
# their config there instead of in the shell's cwd.

zinit wait lucid as'null' id-as'defer-infra' nocd atload'
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

  # Redraw the prompt, which was drawn before the env above was loaded.
  zle && zle .reset-prompt
' for %$ZDOTDIR

chkcmd direnv && eval "$(direnv hook zsh)"
chkcmd aws && complete -C $(which aws_completer) aws
