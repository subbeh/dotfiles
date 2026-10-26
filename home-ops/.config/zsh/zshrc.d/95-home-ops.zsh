#!/bin/zsh

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
