# mac-upgrade

I'm using this repo to store all the shell files I crete to automate my daily tasks. The main utility is to upgrade all my developer apps

# Requirements

Upgrade requires:

- [Homebrew](https://brew.sh)
- [RVM](https://rvm.io)
- [NVM](https://github.com/nvm-sh/nvm)

# NVM

This will only upgrade NVM if it was installed using

```bash
brew install nvm
```

# Installation

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/fontesrp/mac-upgrade/master/install.sh)"
```

# Running

The scripts are installed with their names minus the `.sh` extension. For example:

```bash
upgrade
```

# License

This project is available under the MIT License. For more information, check the [LICENSE](./LICENSE) file.
