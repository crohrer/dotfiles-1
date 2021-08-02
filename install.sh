#!/bin/bash
set -u

## ----------------------------------------
##  By default, you don't have any CLI such as git.
##  Run the command below to install dependencies.
##  curl https://raw.githubusercontent.com/ulwlu/dotfiles/master/install.sh | /bin/bash -s -- --init
## ----------------------------------------

if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "MacOS only available."
  exit 1
fi

TESTMODE=false
shopt -s dotglob
EXEPATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1 && pwd)

## ----------------------------------------
##  Functions
## ----------------------------------------
symlink_dotfiles() {
  handle_symlink_from_path() {
    file=$1
    dirpath=$(dirname "${file}") && filename=$(basename "${file}")
    abspath=$(cd "${dirpath}" && pwd)"/${filename}"
    relpath=$(echo "${file}" | sed "s|^\./dotfiles/||")
    target="${HOME}/${relpath}"
    mkdir -p "$(dirname "${target}")"
    ln -sfnv "${abspath}" "${target}"
  }
  export -f handle_symlink_from_path

  bulk_symlink_target=(
    # "./dotfiles/Library/Application Support/Alfred/Alfred.alfredpreferences"
  )

  find_exclude=""
  for i in "${bulk_symlink_target[@]}"; do
    handle_symlink_from_path "${i}"
    find_exclude="${find_exclude} -path \"${i}\" -prune -or "
  done
  find_command="find ./dotfiles ${find_exclude} \( -type l -or -type f \) -exec bash -c 'handle_symlink_from_path \"{}\"' \;"
  eval "${find_command}"
}

configure_system() {
  CWD=${EXEPATH}/system
  osascript -e 'tell application "System Preferences" to quit' > /dev/null 2>&1
  /bin/bash "${CWD}"/macos.sh ${TESTMODE}
}

install_bundle() {
  CWD=${EXEPATH}/bundle
  /bin/bash "${CWD}"/install.sh ${TESTMODE}
}

initialize() {
  if ! ${TESTMODE}; then
    xcode-select --install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    mkdir -p "${HOME}"/.ssh
    ssh-keygen -t rsa -b 4096 -C "c@chrisrohrer.de"
    ssh-keyscan -t rsa github.com >> "${HOME}"/.ssh/known_hosts
    # Password auth is deprecated at 2020/11/13. This can't be automated now.
    # curl -u "ulwlu" --data "{\"title\":\"NewSSHKey\",\"key\":\"`cat ~/.ssh/id_rsa.pub`\"}" https://api.github.com/user/keys
    echo "Please add ~/.ssh/id_rsa.pub into https://github.com/settings/keys manually."

    brew install gh
    gh auth login
    mkdir -p "${HOME}"/projects/dotfiles && cd "$_" || exit 1
    git clone --recursive https://github.com/crohrer/dotfiles-1 .
  fi

  brew tap homebrew/bundle
  brew install zsh
  sudo sh -c 'echo /usr/local/bin/zsh >> /etc/shells'
  sudo chsh -s /usr/local/bin/zsh
  chmod 755 /usr/local/share/zsh
  chmod 755 /usr/local/share/zsh/site-functions

  mkdir -p "${HOME}"/Screenshots
}

usage() {
  cat <<- EOS
    Options for install.sh
    =================================================
    init:     Core initialization"
    bundle:   Package installation"
    system:   MacOS system setting"
    dotfiles: Dotfiles installation"
    all:      All installations (except init)"
EOS
}

## ----------------------------------------
##  Main
## ----------------------------------------
argv=$@

if [[ ${argv[@]} =~ "--help" || $# -eq 0 ]]; then
  usage
  exit 0
fi

if [[ ${argv[@]} =~ "--force" ]]; then
  argv=(${argv[@]/"--force"/})
else
  read -p "Your file will be overwritten. OK? (Y/n): " Ans
  [[ ${argv[@]} =~ "--init" ]] && Ans='Y'
  [[ $Ans != 'Y' ]] && echo 'Canceled' && exit 0
fi

if [[ ${argv[@]} =~ "--test" ]]; then
  TESTMODE=true
  argv=(${argv[@]/"--test"/})
fi

sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2> /dev/null &
for opt in ${argv[@]}; do
  case $opt in
    --init) initialize ;;
    --bundle) install_bundle ;;
    --system) configure_system ;;
    --dotfiles) symlink_dotfiles ;;
    --all)
      symlink_dotfiles
      install_bundle
      configure_system
      ;;
    *) echo "invalid option $1" ;;
  esac
done
