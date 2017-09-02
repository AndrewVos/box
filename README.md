# box

Manage your machine configuration in a simple bash DSL.

Run ```box your-package-file``` to install your
packages. Packages that are already installed
will be skipped.

## Work in progress

This is very much a work in progress. It will be fairly stable
but be warned, things may change.

Contributions or bug reports will be very much appreciated!

## Example:

Install some apt packages:

```bash
satisfy apt "git"
satisfy apt "vim"
```

Run some preinstall tasks before installing an apt package:

```bash
if ! check apt "enpass"; then
  sudo echo "deb http://repo.sinew.in/ stable main" > /etc/apt/sources.list.d/enpass.list
  wget -O - https://dl.sinew.in/keys/enpass-linux.key | sudo apt-key add -
  sudo apt update
fi
satisfy apt "enpass"
```

Run some command after install or upgrade:

```bash
satisfy apt "vim"

if did-install; then
  echo "wow cool"
fi

if did-upgrade; then
  echo "an upgrade"
fi
```

Install a golang:

```bash
satisfy golang "go1.9"
```

Install a golang package:

```bash
satisfy go-package "github.com/AndrewVos/pwompt"
```

Clone a github repository somewhere:

```bash
satisfy github "https://github.com/AndrewVos/vimfiles" "$HOME/vimfiles"

if did-install; then
  cd $HOME/vimfiles
  ./install.sh
fi
```

Install a file:

```bash
function install-file () {
  cp file /my/file
}
satisfy file "file" "/my/file"
```

Install an executable:

```bash
function install-thing () {
  sudo wget -O /usr/bin/thing https://example.org/thing
}
satisfy executable "thing"
```
