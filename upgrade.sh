#!/bin/bash

versionRegex='([[:digit:]]{2}\.){2}[[:digit:]]{1,}'

extract_version() {
  sed -E "s/.*v($versionRegex).*/\\1/g" $1
}

get_all_node_versions() {
  nvm ls --no-colors | \
  grep -E '^[ -]>? +v' | \
  extract_version | \
  sort -V
}

get_latest_node() {
  get_all_node_versions | \
  tail -1
}

get_older_nodes() {
  get_all_node_versions | \
  sed -E '$ d'
}

upgrade_echo() {
  echo "♨️  $1"
}

# Homebrew
upgrade_echo 'Running "brew update"'
brew update

upgrade_echo 'Running "brew upgrade"'
brew upgrade

# Ruby
RVM_SCRIPTS_DIR="$HOME/.rvm/scripts/rvm"
source $RVM_SCRIPTS_DIR

upgrade_echo 'Running "rvm get stable"'
rvm get stable

upgrade_echo 'Running "gem install cocoapods"'
gem install cocoapods

upgrade_echo 'Running "pod repo update"'
pod repo update

# Node
export NVM_DIR="$HOME/.nvm"
. '/usr/local/opt/nvm/nvm.sh'

npmDeps=''

for dep in `npm ls -g --depth=0 --parseable | grep node_modules/ | perl -nle 'm/.*node_modules\/(.*?)$/; print $1'`
do
  if [ "$dep" != 'lib' ] && [ "$dep" != 'npm' ]
  then
    npmDeps="$npmDeps$dep "
  fi
done

# TODO: install the latest release of every lts version in the system
upgrade_echo 'Running "nvm install --lts --latest-npm"'
nvm install --lts --latest-npm

upgrade_echo "Running \"npm i -g $npmDeps\""
npm i -g $npmDeps

upgrade_echo 'Updating path for Sublime JsPrettier'
sublimePrefsFile="$HOME/Library/Application Support/Sublime Text 3/Packages/User/JsPrettier.sublime-settings"
latestNode=`get_latest_node`
sed \
  -i '' \
  -E "s/(node\\/v)$versionRegex/\\1$latestNode/g" \
  "$sublimePrefsFile"

# TODO: keep only latest version of each major release
for verion in `get_older_nodes`
do
  upgrade_echo "Running \"nvm uninstall $verion\""
  nvm uninstall $verion
done
