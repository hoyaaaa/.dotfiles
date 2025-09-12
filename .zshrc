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
