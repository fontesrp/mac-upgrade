#!/bin/bash

getProjectRootDir() {
  local projectPath
  local folders

  projectPath=$(pwd)
  folders=$(echo "$projectPath" | tr '/' "\n")

  for _ in $folders
  do
    if [ -f "$projectPath/package.json" ]
    then
      echo "$projectPath"
      return 0
    else
      # Go up one folder
      projectPath=$(echo "$projectPath" | sed -E 's/(.*)\/.*/\1/g')
    fi
  done

  return 1
}

projectRoot=$(getProjectRootDir)

customEcho() {
  echo -e "♨️ $1" >/dev/stderr
}

cleanAndroid() {
  customEcho 'Cleaning Android project'

  local originalDir
  local androidPath=$projectRoot/android

  originalDir=$(pwd)
  cd "$androidPath"

  # Continue execution if gradle exits with an error
  set +e
  ./gradlew clean &> /dev/null
  # Stop execution on the next error
  set -e

  cd "$originalDir"

  rm -rf \
    "$androidPath/.gradle" \
    "$androidPath/.idea" \
    "$androidPath/android.iml" \
    "$androidPath/app/*.iml" \
    "$androidPath/app/build" \
    "$androidPath/*.iml" \
    "$androidPath/build" \
    "$androidPath/local.properties"
}

cleanAndroidNuclear() {
  customEcho 'Make sure you have installed all dependencies listed here:'
  customEcho 'https://github.com/rock3r/deep-clean#installing-the-script-dependencies'

  local originalDir
  originalDir=$(pwd)

  cd "$projectRoot/android"

  curl \
    'https://raw.githubusercontent.com/rock3r/deep-clean/master/deep-clean.kts' \
    -G \
    -s \
    > deep-clean.kts

  kscript deep-clean.kts --nuke

  rm deep-clean.kts

  cd "$originalDir"
}

cleanIos() {
  customEcho 'Cleaning iOS project'
  local iosPath=$projectRoot/ios
  rm -rf \
    "$iosPath/Pods" \
    "$iosPath/Podfile.lock" \
    "$iosPath/Gemfile.lock"
}

cleanNode() {
  customEcho 'Cleaning Node project'
  rm -rf \
    "$projectRoot/node_modules" \
    "$projectRoot/package-lock.json" \
    "$projectRoot/yarn.lock"
}

# TODO: make sure the script is being run from a React Native project

case "$1" in
  android)
    cleanAndroid
    ;;
  android-nuclear)
    cleanAndroidNuclear
    ;;
  ios)
    cleanIos
    ;;
  node)
    cleanNode
    ;;
  *)
    cleanAndroid
    cleanIos
    cleanNode
    ;;
esac
