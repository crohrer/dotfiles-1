#! /bin/bash
set -u
EXEPATH=$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd)

## ========== Brew Bundle ==========
brew upgrade
brew bundle --file "${EXEPATH}"/Brewfile

## ========== Npm ==========
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash
nvm install node
npm install -g $(cat "${EXEPATH}"/Npmfile)

## ========== Zsh ==========
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
cp "${EXEPATH}"/chrisrohrer.zsh-theme "${HOME}"/.oh-my-zsh/themes/chrisrohrer.zsh-theme
source "${HOME}"/.zshrc

## ========== VSCode ==========
if ! ${TESTMODE}; then
  for plugin in $(cat "${EXEPATH}"/Vsplug); do
    code --install-extension "${plugin}"
  done
fi
