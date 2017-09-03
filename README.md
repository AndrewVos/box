# box

Manage your machine configuration in a simple bash DSL.

Run ```box your-package-file``` to install your
packages. Packages that are already installed
will be skipped.

## Work in progress

This is very much a work in progress. It will be fairly stable
but be warned, things may change.

Contributions or bug reports will be very much appreciated!

* auto-gen TOC:
{:toc}

## Usage

Box allows you to configure a machine by "satisfying" dependencies.

To satisfy an `apt` dependency, for example, do `satisfy apt "package-name"`.
This will ensure that the package is installed and is the latest version.

To check if a package will be installed or upgraded you can call `must-install`
or `must-upgrade` before your `satisfy` command.

To check if a package was installed or upgraded, you can use `did-install` and
`did-upgrade`.

For `file` and `executable` tasks, box will execute a custom function
which installs the file or executable. The custom function will be generated
from the first parameter.

## Dependency examples

### APT packages

```bash
satisfy apt "git"
satisfy apt "vim"
```

### Golang

```bash
satisfy golang "go1.9"
```

### Golang packages

```bash
satisfy go-package "github.com/AndrewVos/pwompt"
```

### Github repositories

```bash
satisfy github "https://github.com/AndrewVos/vimfiles" "$HOME/vimfiles"

if did-install; then
  cd $HOME/vimfiles
  ./install.sh
fi
```

### Files

```bash
function install-my-file () {
  cp file /my/file
}
satisfy file "my-file" "/my/file"
```

### Executables

```bash
function install-thing () {
  sudo wget -O /usr/bin/thing https://example.org/thing
}
satisfy executable "thing"
```

## Hooks

### Preinstall hooks

```bash
if will-install apt "enpass"; then
  sudo echo "deb http://repo.sinew.in/ stable main" > /etc/apt/sources.list.d/enpass.list
  wget -O - https://dl.sinew.in/keys/enpass-linux.key | sudo apt-key add -
  sudo apt update
fi

if will-upgrade apt "enpass"; then
  echo "Upgrading enpass, no further action required"
fi

satisfy apt "enpass"
```

### Postinstall hooks

```bash
satisfy apt "vim"

if did-install; then
  echo "vim was installed"
fi

if did-upgrade; then
  echo "vim was upgraded"
fi
```
