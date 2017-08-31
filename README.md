# box

Manage your machine configuration in a simple bash DSL.

Run ```box your-package-file``` to install your
packages. Packages that are already installed
will be skipped.

## Example:

Install some apt packages:

```bash
apt-package "git"
apt-package "vim"
```

Run some preinstall tasks before installing an apt package:

```bash
function preinstall-enpass () {
  sudo echo "deb http://repo.sinew.in/ stable main" > /etc/apt/sources.list.d/enpass.list
  wget -O - https://dl.sinew.in/keys/enpass-linux.key | sudo apt-key add -
  sudo apt update
}
apt-package "enpass"
```

Run some command after install or upgrade:

```bash
apt-package "vim"

if did-install; then
  echo "wow cool"
fi

if did-upgrade; then
  echo "an upgrade"
fi
```

Install a golang:

```bash
golang "go1.9"
```

Install a golang package:

```bash
go-package "github.com/AndrewVos/pwompt"
```

Install a custom package:

```bash
function verify-vimfiles () {
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
}

custom-package "vim"
```
