# A collection of various shell utilities.

autoload colors && colors

# Abstract different ways to copy to the clipboard.
if [ -n "$SSH_CONNECTION" ] ; then
  # Use OSC-52 to set the clipboard
  alias copy='base64 | xargs -0 printf "\033]52;c;%s\a"'
elif [ "`uname`" = "Darwin" ]; then
  # Use pbcopy to set the clipboard
  alias copy='pbcopy'
elif which xclip &> /dev/null; then
  # Use xclip to set the clipboard
  alias copy='xclip -selection c'
fi

# Abstract different ways to paste from the clipboard.
# TODO: Use OSC-52 to get the clipboard, not widely supported though
if [ "`uname`" = "Darwin" ]; then
  # Use pbpaste to get the clipboard
  alias paste='pbpaste'
elif which xclip &> /dev/null; then
  # Use xclip to get the clipboard
  alias paste='xclip -selection c -o'
fi

# Passthrough an escape sequences tmux doesn't know about.
tmux-dcs-passthrough() {
  local escape_sequence=$1
  if [ -n "$TMUX" ]; then
    # Replace single \x1b or \033 with two, this is required for tmux to
    # properly pass-through the escape sequence.
    escape_sequence=${escape_sequence//\\x1b/\\x1b\\x1b}
    escape_sequence=${escape_sequence//\\033/\\x1b\\x1b}
    printf '\x1bPtmux;\x1b'"$escape_sequence"'\x1b\\'
  else
    printf "$escape_sequence"
  fi
}

# OSC 9 - Post a notification - supported by iTerm2, kitty, WezTerm, others?
notify() {
  tmux-dcs-passthrough '\x1b]9;'"$*"'\x7'
}

# Send a desktop notification when long running commands complete.
notify_command_threshold=60
notify_ignore_list=(
  bash
  bat
  btop
  cat
  cmatrix
  fg
  gh
  git
  glab
  htop
  ipython
  man
  nvim
  ping
  podman
  python
  session
  slides
  ssh
  sudo
  sudoedit
  tmux
  top
  vi
  vim
  watch
  zsh
)

notify-ignore() {
  for ignore in $notify_ignore_list; do
    if [[ "$1" = "$ignore"* ]]; then
      return 0
    fi
  done
  return 1
}

notify-preexec() {
  if notify-ignore $1; then
    return
  fi
  notify_command_start=`date +%s`
  notify_command=$1
}
add-zsh-hook preexec notify-preexec

notify-precmd() {
  if ! [[ -z $notify_command_start ]]; then
    local notify_command_end=`date +%s`
    local notify_command_time=$(($notify_command_end - $notify_command_start))
    if [[ $notify_command_time -gt $notify_command_threshold ]]; then
      notify "completed: $notify_command"
    fi
    unset notify_command
    unset notify_command_start
  fi
}
add-zsh-hook precmd notify-precmd

# Detect the type and extract an archive file.
extract() {
  if [ -f $1 ]; then
    case $1 in
      *.tar.bz2)  tar xvjf $1 ;;
      *.tar.gz)   tar xvzf $1 ;;
      *.tar.xz)   [ `"uname"` = "Darwin" ] && tar xvJf $1 || tar xf $1 ;;
      *.bz2)      bunzip2 $1 ;;
      *.rar)      unrar x $1 ;;
      *.gz)       gunzip $1 ;;
      *.tar)      tar xvf $1 ;;
      *.tbz2)     tar xvjf $1 ;;
      *.tgz)      tar xvzf $1 ;;
      *.zip)      unzip $1 ;;
      *.Z)        uncompress $1 ;;
      *.7z)       7zr x $1 ;;
      *)          echo "$fg[red]error:$reset_color unable to extract '$1'" ;;
    esac
  else
    echo "$fg[red]error:$reset_color file not found '$1'"
  fi
}

# if which bat &> /dev/null; then
#   # Wrap bat to specify a theme, always enable color, pipe the output to less.
#   # Both --theme and --color can be specified multiple times and will override
#   # these defaults.
#   bat() {
#     command bat --theme='TwoDark' --color always --paging auto "$@"
#   }
# elif which batcat &> /dev/null; then
#   bat() {
#     command batcat --theme='TwoDark' --color always --paging auto "$@"
#   }
# fi

# if which docker-machine &> /dev/null; then
#   # Wrap the docker command to print a message if a docker-machine is not
#   # running, rather than just stating it can not find it's socket.
#   docker() {
#     command docker "$@"
#     if ! docker-machine active &> /dev/null; then
#       echo "$fg[red]error:$reset_color no active host found, run:" \
#            "docker-machine start <machine>"
#       return 1
#     fi
#   }

  # Wrap the docker-machine command to automatically update the environment.
  # When a machine is started, set the environment variables provided by
  # docker-machine env <machine>. When a machine is stopped, unset the same
  # variables.
#   docker-machine() {
#     command docker-machine "$@"
#     if [ "start" = "$1" ]; then
#       eval `docker-machine env $2`
#     elif [ "stop" = "$1" ]; then
#       unset DOCKER_MACHINE_NAME
#       unset DOCKER_CERT_PATH
#       unset DOCKER_HOST
#       unset DOCKER_TLS_VERIFY
#     fi
#   }
# fi

ls-iommu() {
  $HOME/.config/zsh/ls-iommu.sh | sort -n
}

# Fuzzy history search with fzf
function .fzf-history-search() {
  local selected
  selected=$(
    cat $HISTFILE |         # get entire history
    sed 's/ *[0-9]* *//' |  # remove cruft
    awk '!seen[$0]++' |     # remove duplicates
    fzf --layout=reverse --tac --cycle  --info=hidden \
        --border=rounded --height=50%
  )
  if [[ -n "$selected" ]]; then
    BUFFER="$selected"
    zle end-of-line
  fi
  zle reset-prompt
}
zle -N .fzf-history-search
bindkey '^R' .fzf-history-search
