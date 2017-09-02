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
satisfy executable "vim"

function install-slink () {
  temp_dir=`mktemp --directory`
  cd $temp_dir

  git clone https://github.com/AndrewVos/slink
  cd slink
  nim compile -d:release slink.nim
  sudo mv slink /usr/local/bin/slink
}
satisfy file "slink" "/usr/local/bin/slink"

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

satisfy github "https://github.com/AndrewVos/vimfiles" "$HOME/vimfiles"
if did-install; then
  cd $HOME/vimfiles && ./install.sh
fi

satisfy github "https://github.com/AndrewVos/dotfiles" "$HOME/dotfiles"
if did-install; then
  cd $HOME/dotfiles && slink --really
fi

satisfy github "https://github.com/AndrewVos/box" "$HOME/box"

function install-chruby () {
  temp_dir=`mktemp --directory`
  cd $temp_dir
  wget -O chruby-0.3.9.tar.gz https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz
  tar -xzvf chruby-0.3.9.tar.gz
  cd chruby-0.3.9/
  sudo make install
  set +u
  . /usr/local/share/chruby/chruby.sh
  set -u
}
satisfy file "chruby" "/usr/local/share/chruby/chruby.sh"

function install-ruby-install () {
  temp_dir=`mktemp --directory`
  cd $temp_dir
  wget -O ruby-install-0.6.1.tar.gz https://github.com/postmodern/ruby-install/archive/v0.6.1.tar.gz
  tar -xzvf ruby-install-0.6.1.tar.gz
  cd ruby-install-0.6.1/
  sudo make install
}
satisfy executable "ruby-install"

function install-ruby-2-3-0 () {
  ruby-install ruby-2.3.0
}
satisfy file "ruby-2.3.0" "$HOME/.rubies/ruby-2.3.0/bin/ruby"
