function check-vim () {
  if [ -f /usr/local/bin/vim ]; then
    return 0
  fi
  return 1
}
function install-vim () {
  sudo apt install xorg-dev
  sudo apt install ncurses-dev

  temp_dir=`mktemp --directory`
  cd $temp_dir
  git clone https://github.com/vim/vim.git --depth 1
  cd vim
  ./configure --enable-pythoninterp
  make
  sudo make install
}

function check-slink () {
  if [ -f /usr/local/bin/slink ]; then
    return 0
  else
    return 1
  fi
}
function install-slink () {
  temp_dir=`mktemp --directory`
  cd $temp_dir

  git clone https://github.com/AndrewVos/slink
  cd slink
  nim compile -d:release slink.nim
  sudo mv slink /usr/local/bin/slink
}

satisfy apt "git"
satisfy apt "nim"

if ! check apt "enpass"; then
  sudo echo "deb http://repo.sinew.in/ stable main" > /etc/apt/sources.list.d/enpass.list
  wget -O - https://dl.sinew.in/keys/enpass-linux.key | sudo apt-key add -
  sudo apt update
fi
satisfy apt "enpass"

satisfy golang "go1.9"
satisfy go-package "github.com/AndrewVos/pwompt"

satisfy package "vim"
satisfy package "slink"

satisfy github "https://github.com/AndrewVos/vimfiles" "$HOME/vimfiles"
if did-install; then
  cd $HOME/vimfiles && ./install.sh
fi

satisfy github "https://github.com/AndrewVos/dotfiles" "$HOME/dotfiles"
if did-install; then
  cd $HOME/dotfiles && slink --really
fi

satisfy github "https://github.com/AndrewVos/box" "$HOME/box"
