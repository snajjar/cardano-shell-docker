#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# define env
export PS1='\[\033[01;33m\]root\[\033[01;37m\]@\[\033[01;36m\]cardano-shell\[\033[01;37m\]: \[\033[01;32m\]\w \[\033[01;37m\]\$ \[\033[00;37m\]'
export EDITOR="vim"

# alias utilities
alias ll='ls --color=auto -al'
alias ls='ls --color=auto'

