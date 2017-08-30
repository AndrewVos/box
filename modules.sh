function check-git () {
  result=`apt-package-installed "git"`
  return $result
}
function install-git () {
  sudo apt install git
}
MODULES+=(git)

function check-nim () {
  result=`apt-package-installed "nim"`
  return $result
}
function install-nim () {
  sudo apt install nim
}
MODULES+=(nim)

function check-enpass () {
  installed=`apt-package-installed "enpass"`
  return $installed
}
function install-enpass () {
  sudo echo "deb http://repo.sinew.in/ stable main" > /etc/apt/sources.list.d/enpass.list
  wget -O - https://dl.sinew.in/keys/enpass-linux.key | sudo apt-key add -
  sudo apt-get update
  sudo apt-get install enpass
}
MODULES+=(enpass)

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
MODULES+=(vim)

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

  cd -
}
MODULES+=(slink)

function check-dotfiles () {
  if [ -d $HOME/dotfiles ]; then
    return 0
  else
    return 1
  fi
}
function install-dotfiles () {
  cd $HOME
  git clone https://github.com/AndrewVos/dotfiles.git
  cd dotfiles
  slink --really
  cd -
}
MODULES+=(dotfiles)

function check-vimfiles () {
  if [ -d $HOME/vimfiles ]; then
    return 0
  else
    return 1
  fi
}
function install-vimfiles () {
  cd $HOME
  git clone https://github.com/AndrewVos/vimfiles.git
  cd vimfiles
  ./install.sh
  cd -
}
MODULES+=(vimfiles)
