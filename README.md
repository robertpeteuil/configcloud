# configcloud
## Shell Configuration "dotfiles" for use on Linux Cloud Servers

----

Predefined bash settings, prompt options, and custom aliases/functions that can quickly be cloned and symlinked to $HOME via included installer.

### Download

Login to the remote host, `cd` to the home dir and use `git clone` to copy the files to a new directory named `.configcloud`.  (Whiel it can be downloaded to any directory, the `update-all` function will automatically pull repo updates if it is downloaded into `.configcloud`.  In addition, the git clone parameter `--depth 1` can be used to reduce the size of the download.

```
cd ~
git clone --depth 1 https://github.com/robertpeteuil/configcloud.git .configcloud
```

### Installation

After download, `cd` into the directory and run the installer named `install.sh`.  It supports many parameters including `-h` for help.

``` shell
cd ~/.configcloud

# display help - lists paramaters and options for the installer
./install.sh -h     

# Test-Installation (-t) with Details (-d)
./install.sh -t -d

# Installs the configfiles without overwriting any existing files, and displays details (-d)
./install.sh -d

# installs the configfiles, overrights any existing files (usually '.bash_profile' and '.bashrc'), and displays details (-d)
./install.sh -d -f 
```

Once configfile has been installed, log out & back in to have access to the new settings, alises and functions.  After initial installation, a logout/login step is not required for future updates as you can use the `reload` alias defined in `configcloud`.
