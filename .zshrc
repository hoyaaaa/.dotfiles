# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

alias ls=lsd
alias l='lsd -Al'

# nvim
export EDITOR=nvim
alias vi=nvim
alias vim=nvim

# aws-cli
alias awslogin='aws sso login --profile PowerUserAccess-390700680594'
export AWS_DEFAULT_PROFILE=PowerUserAccess-390700680594

# Secretive
export SSH_AUTH_SOCK=/Users/hoya/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# fzf
source <(fzf --zsh)

# go
export PATH=$HOME/go/bin:$PATH
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
