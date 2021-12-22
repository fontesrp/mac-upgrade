#!/bin/bash

versionRegex='([[:digit:]]+\.){2}[[:digit:]]+'

customEcho() {
  echo "♨️  $1"
}

extractVersion() {
  sed -E "s/.*v($versionRegex).*/\\1/g"
}

fixSublimePackage() {
  local latestNode=$1

  local sublimePrefsFolder="$HOME/Library/Application Support/Sublime Text 3/Packages/User"
  local linterPrefsFile="$sublimePrefsFolder/SublimeLinter.sublime-settings"
  local prettierPrefsFile="$sublimePrefsFolder/JsPrettier.sublime-settings"

  customEcho "Updating path for Sublime JsPrettier (latest node $latestNode)"
  sed \
    -i '' \
    -E "s/(node\\/v)$versionRegex/\\1$latestNode/g" \
    "$prettierPrefsFile"

  customEcho "Updating path for Sublime Linter (latest node $latestNode)"
  sed \
    -i '' \
    -E "s/(node\\/v)$versionRegex/\\1$latestNode/g" \
    "$linterPrefsFile"
}

getAllNodeVersions() {
  nvm ls --no-colors --no-alias | \
  grep -E '^[[:space:]-]>?[[:space:]]+v' | \
  extractVersion | \
  sort -V
}

getGlobalNpmPackages() {
  npm ls -g --depth=0 --parseable | \
  grep node_modules/ | \
  grep -v /npm$ | \
  sed -E 's/.*node_modules\/(.*)$/\1/g'
}

getLatestNode() {
  getAllNodeVersions | tail -1
}

getNpmDepsToReinstall() {
  local npmDeps=''

  for dep in $(getGlobalNpmPackages)
  do
    npmDeps="$npmDeps$dep "
  done

  echo "$npmDeps"
}

getOlderNodes() {
  getAllNodeVersions | sed -E '$ d'
}

globalNpm() {
  local originalDir
  originalDir=$(pwd)

  cd "$HOME" || return
  customEcho "Running \"npm i -g $1\""
  # shellcheck disable=SC2086
  npm i -g $1
  cd "$originalDir" || return
}

homebrew() {
  customEcho 'Running "brew update"'
  brew update
  customEcho 'Running "brew upgrade"'
  brew upgrade
}

homeNodeModules() {
  rm -f "$HOME/node_modules"
  ln -s "$HOME/.nvm/versions/node/v$1/lib/node_modules" "$HOME/node_modules"
}

installLatestNode() {
  customEcho 'Running "nvm install --lts --latest-npm"'
  nvm install --lts --latest-npm
}

nodeViaNvm() {
  export NVM_DIR=$HOME/.nvm
  # shellcheck disable=SC1091
  . '/usr/local/opt/nvm/nvm.sh'

  local npmDeps
  npmDeps=$(getNpmDepsToReinstall)

  # TODO: install the latest release of every lts version in the system
  installLatestNode

  globalNpm "$npmDeps"

  local latestNode
  latestNode=$(getLatestNode)

  fixSublimePackage "$latestNode"

  homeNodeModules "$latestNode"

  # TODO: keep only latest version of each major release
  for verion in $(getOlderNodes)
  do
    customEcho "Running \"nvm uninstall $verion\""
    nvm uninstall "$verion"
  done
}

ruby() {
  local RVM_SCRIPTS_DIR=$HOME/.rvm/scripts/rvm
  # shellcheck disable=SC1090
  source "$RVM_SCRIPTS_DIR"

  customEcho 'Running "rvm get stable"'
  rvm get stable

  customEcho 'Running "gem install cocoapods"'
  gem install cocoapods
  gem install cocoapods-user-defined-build-types

  customEcho 'Running "pod repo update"'
  pod repo update
}

homebrew
ruby
nodeViaNvm
