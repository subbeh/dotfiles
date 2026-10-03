# ==========================================
# /root/.bashrc
# ==========================================

# 1. Global Definitions (Source system-wide defaults if they exist)
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
elif [ -f /etc/bash.bashrc ]; then
  . /etc/bash.bashrc
fi

# 2. Safety Aliases (Prevents accidental deletions or overwrites)
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ln='ln -i'

# 3. Convenience Aliases
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'

# 4. High-Visibility Root Prompt (Red prompt to warn you that you are root)
# Displays: [root@hostname /current/dir]#
export PS1="\[\e[1;31m\][\u@\h \W]#\[\e[0m\] "

# 5. History Customization (For administrative auditing)
export HISTSIZE=5000
export HISTFILESIZE=10000
export HISTCONTROL=ignoredups:erasedups
export HISTTIMEFORMAT="%F %T " # Timestamps for when root commands were run

# 6. Misc
export EDITOR=vim
alias vi=vim
