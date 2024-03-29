#!/bin/bash

versionRegex='([[:digit:]]+\.){2}[[:digit:]]+'

customEcho() {
  echo -e "♨️ $1" >/dev/stderr
}

extractVersion() {
  sed -E "s/.*v($versionRegex).*/\\1/g"
}

fixSublimePackage() {
  local latestNode=$1

  local sublimePrefsFolder="$HOME/Library/Application Support/Sublime Text/Packages/User"
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
  local usrBin=/usr/local/bin
  local nodeFolder=$HOME/.nvm/versions/node/v$1
  local nodeBin=$nodeFolder/bin

  rm -f "$HOME/node_modules"
  ln -s "$nodeFolder/lib/node_modules" "$HOME/node_modules"

  rm -f "$usrBin/node"
  ln -s "$nodeBin/node" "$usrBin/node"

  rm -f "$usrBin/npm"
  ln -s "$nodeBin/npm" "$usrBin/npm"

  rm -f "$usrBin/npx"
  ln -s "$nodeBin/npx" "$usrBin/npx"
}

installLatestNode() {
  customEcho 'Running "nvm install --lts --latest-npm"'
  nvm install --lts --latest-npm
  nvm use --lts
}

nodeViaNvm() {
  export NVM_DIR=$HOME/.nvm
  # shellcheck disable=SC1091
  . '/opt/homebrew/opt/nvm/nvm.sh'

  nvm use --lts

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
  # for verion in $(getOlderNodes)
  # do
  #   customEcho "Running \"nvm uninstall $verion\""
  #   nvm uninstall "$verion"
  # done
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
  gem install bundler

  customEcho 'Running "pod repo update"'
  pod repo update
}

homebrew
ruby
nodeViaNvm
