#!/bin/bash

# Homebrew
echo "Running 'brew update'"
brew update

echo "Running 'brew upgrade'"
brew upgrade

# Ruby
RVM_SCRIPTS_DIR="$HOME/.rvm/scripts/rvm"
source $RVM_SCRIPTS_DIR

echo "Running 'rvm get stable'"
rvm get stable

echo "Running 'gem install cocoapods'"
gem install cocoapods

echo "Running 'pod repo update'"
pod repo update

# Node
export NVM_DIR="$HOME/.nvm"
. "/usr/local/opt/nvm/nvm.sh"

npmDeps=""

for dep in `npm ls -g --depth=0 --parseable | perl -nle 'm/.*\/(.*?)$/; print $1'`
do
  if [ "$dep" != "lib" ] && [ "$dep" != "npm" ]
  then
    npmDeps="$npmDeps$dep "
  fi
done

echo "Running 'nvm install --lts --latest-npm'"
nvm install --lts --latest-npm

echo "Running 'npm i -g $npmDeps'"
npm i -g $npmDeps

for verion in `ls -1 $NVM_DIR/versions/node | sort -V | sed \\$d`
do
  echo "Running 'nvm uninstall $verion'"
  nvm uninstall $verion
done
