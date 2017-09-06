function bootstrap-box () {
  local BOX_PATH="/usr/local/share/box/box.sh"
  if [ ! -f "$BOX_PATH" ]; then
    sudo mkdir -p `dirname "$BOX_PATH"`
    sudo wget -O "$BOX_PATH" https://raw.githubusercontent.com/AndrewVos/box/master/box.sh
    sudo chmod +x "$BOX_PATH"
  fi
  source "$BOX_PATH"
}
bootstrap-box

function install-vim () {
  sudo apt install xorg-dev ncurses-dev

  git clone https://github.com/vim/vim.git --depth 1
  cd vim
  ./configure --enable-pythoninterp
  make
  sudo make install
}
satisfy executable "vim"

function install-slink () {
  git clone https://github.com/AndrewVos/slink
  cd slink
  nim compile -d:release slink.nim
  sudo mv slink /usr/local/bin/slink
}
satisfy file "slink" "/usr/local/bin/slink"

satisfy apt "git"
satisfy apt "nim"

if must-install apt "enpass"; then
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

function install-slack () {
  wget https://downloads.slack-edge.com/linux_releases/slack-desktop-2.7.1-amd64.deb
  sudo dpkg -i slack-desktop-2.7.1-amd64.deb
}
satisfy executable "slack"

satisfy apt "docker.io"

satisfy apt "nodejs"

satisfy apt "curl"

if must-install apt "yarn"; then
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  sudo apt-get update
fi
satisfy apt "yarn"

function install-discord () {
  wget -O discord.deb 'https://discordapp.com/api/download?platform=linux&format=deb'
  sudo dpkg -i discord.deb
}
satisfy executable "discord"
