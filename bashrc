#!/bin/bash

#   BASHRC - Bash Settings, Prompt Cust, Config Settings and Sources Additional Files
#
#     This script is a component of ConfigCloud
#       https://github.com/robertpeteuil/configcloud
#
#     Robert Peteuil (c) 2018
#

bashconfigname=".bashrc"
bashconfignum="2.0.8"
bashconfigdate="2018-03-17"


# EXIT IF NOT RUNNING INTERACTIVELY
case $- in
    *i*) ;;
      *) return;;
esac

###### BAIL IF NOT RUNNING BASH
if [ -z "$BASH_VERSION" ]; then
  export PATH
  return &> /dev/null || exit
fi

###### SET PROMPT TYPE
prompt_style="GIT"  # 2-line prompt, displays info for repo dirs
# unset prompt_style  # typical-style prompt
# prompt_style="DEMO"  # prompt for screen-caps, displays only $DEMOHOST
# DEMOHOST used and required if prompt_style="DEMO"
DEMOHOST="Host"

###### VARS
OS=$(uname -s)


###### FUNCTIONS
ver_configfiles() {
  [[ -n $profilename ]] && echo "${profilename} v${profilenum} - ${profiledate}"
  [[ -n $bashconfigname ]] && echo "${bashconfigname} v${bashconfignum} - ${bashconfigdate}"
  [[ -n $aliasfilename ]] && echo "${aliasfilename} v${aliasfilenum} - ${aliasfiledate}"
  [[ -n $cloudrcname ]] && echo "${cloudrcname} v${cloudrcnum} - ${cloudrcdate}"
  return 0
}
sourceIf () {
  if [ -e "$1" ]; then
    . "$1"
  fi
}
pathIf () {
  if [ -d "$1" ] && [[ $PATH != *"$1"* ]]; then
    PATH="$PATH:$1"
  fi
}

###### ADD DIRS TO PATH IF EXIST
pathIf "/usr/local/bin"
pathIf "/usr/local/sbin"
pathIf "$HOME/bin"
pathIf "$HOME/.local/bin"
pathIf "$HOME/scripts"
pathIf "$HOME/pycharm-2017.2.4/bin"
pathIf "/usr/lib/go-1.9/bin"

###### BASH CONFIG
# don't put duplicate lines or lines starting with space in the history.
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
#[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# SET BASH SCRIPT TRACE PROMPT
export PS4='$LINENO + '

# SET FILE DEFAULT MODE
umask 0002

###### SET PROMPT AND DEFINE COLOR VARS
# DETERMINE COLOR CAPABILITY
if [ -x /usr/bin/tput ] && $(tput setaf 1 &> /dev/null); then
  color_enabled=yes
fi

case "$TERM" in
 xterm*) color_enabled=yes;;
 ansi) color_enabled=yes;;
 vt102) color_enabled=yes;;
 linux) color_enabled=yes;;
esac

# SET COLOR VARS
if [ "$color_enabled" = yes ]; then
  COLOR_RESET="\033[0m"
  BLUE="\033[1;34m"
  WHITE="\033[1;37m"
  RED="\033[1;31m"
  GREEN="\033[0;32m"
  YELLOW="\033[0;33m"
  CYAN="\033[0;36m"

  PBLUE="${ESCON}${BLUE}${ESCOFF}"
  PWHITE="${ESCON}${COLOR_RESET}${ESCOFF}"
  PGREEN="${ESCON}${GREEN}${ESCOFF}"
  PRED="${ESCON}${RED}${ESCOFF}"
  PYELLOW="${ESCON}${YELLOW}${ESCOFF}"
  PCYAN="${ESCON}${CYAN}${ESCOFF}"
fi

if [[ $TERM == "linux" ]]; then
  PWHITE="${ESCON}${WHITE}${ESCOFF}"
fi

# SET PROMPT ITEMS
ESCON="\["
ESCOFF="\]"
P_TIME="\@"
P_HOSTNAME="\h"
P_USER="\u"
P_DIR="\w"
P_DIR_SM="\W"
P_SYMBOL="\$ "

###### PROMPT
if [[ $prompt_style == "GIT" ]] && [[ -e "$HOME/.bash-git-prompt/gitprompt.sh" ]]; then
  export PROMPT_COMMAND='echo -ne "\033]1;"$(hostname -s)"\007"'
  GIT_PROMPT_IGNORE_SUBMODULES=1
  GIT_PROMPT_THEME_FILE=~/.bash-git-prompt/custom_config.sh
  . "$HOME/.bash-git-prompt/gitprompt.sh"
elif [[ $prompt_style == "DEMO" ]]; then
  export PROMPT_COMMAND='echo -ne "\033]1;${DEMOHOST}\007"'
  if [ "$(id -u)" -eq 0 ]; then
    export PS1="${PRED}${DEMOHOST}${COLOR_RESET}:${PYELLOW}${P_DIR}${COLOR_RESET}${P_SYMBOL}"
  else
    export PS1="${PGREEN}${DEMOHOST}${COLOR_RESET}:${PCYAN}${P_DIR}${COLOR_RESET}${P_SYMBOL}"
  fi
  export SUDO_PS1="${PRED}${DEMOHOST}${COLOR_RESET}:${PYELLOW}${P_DIR_SM}${COLOR_RESET}${P_SYMBOL}"
else
  export PROMPT_COMMAND='echo -ne "\033]1;"$(hostname -s)"\007"'
  if [ "$(id -u)" -eq 0 ]; then
    export PS1="${PRED}${P_HOSTNAME}${COLOR_RESET}:${PYELLOW}${P_DIR}${COLOR_RESET}${P_SYMBOL}"
  else
    export PS1="${PGREEN}${P_HOSTNAME}${COLOR_RESET}:${PCYAN}${P_DIR}${COLOR_RESET}${P_SYMBOL}"
  fi
  export SUDO_PS1="${PRED}${P_HOSTNAME}${PWHITE}:${PYELLOW}${P_DIR_SM}${COLOR_RESET}${P_SYMBOL}"
fi

# AVOID XTERM-NEW ON DEBIAN
if [[ -f /etc/debian_version ]] ; then
  if [[ "$TERM" == "xterm-new" ]]; then
    export TERM="xterm"
  fi
fi
export GOPATH="${HOME}/go"
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi
if [[ -n "$HUSHLOGIN" ]]; then
  export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:'
fi
if ! shopt -oq posix; then
  sourceIf "/usr/share/bash-completion/bash_completion"
  sourceIf "/etc/bash_completion"
fi
export PATH
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

unset color_enabled

GRC=$(which grc 2>/dev/null)
if [ "$TERM" != dumb ] && [ -n "$GRC" ]; then
  sourceIf "$HOME/.grc/grc.bashrc"
fi

###### SOURCE FILES
sourceIf "$HOME/.cloudrc"
sourceIf "$HOME/.aliases"
