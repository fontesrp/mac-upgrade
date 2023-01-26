#!/bin/bash

gitHubUsername=fontesrp
gitHubRepoName=mac-upgrade
gitHubRepoPath=$gitHubUsername/$gitHubRepoName
gitHubBranch=master

customEcho() {
  echo -e "♨️ $1" >/dev/stderr
}

downloadFile() {
  curl \
    "https://raw.githubusercontent.com/$gitHubRepoPath/$gitHubBranch/$1" \
    -s \
    -G \
    -H 'Accept: text/plain'
}

encodeURIComponent() {
  node -e 'console.log(encodeURIComponent(process.argv[1]))' "$1"
}

getCustomRepoTree() {
  curl \
    "$1" \
    -s \
    -G \
    -H 'Accept: application/vnd.github.v3+json' \
    2>&1
}

getRepoTree() {
  getCustomRepoTree "https://api.github.com/repos/$gitHubRepoPath/git/trees/$gitHubBranch"
}

getScriptsFromJsonTree() {
  local parseJson="
    console.log(
      JSON.parse(process.argv[1])
        .tree.map(({ path }) => \`\${path}\`)
        .filter(path => path.endsWith('.sh') && !path.startsWith('install'))
        .join('\\n')
    )
  "
  node -e "$parseJson" "$1"
}

getSublimeTextFilesFromJsonTree() {
  local parseJson="
    console.log(
      JSON.parse(process.argv[1])
        .tree.map(({ path }) => \`\${path}\`)
        .join('\\n')
    )
  "
  node -e "$parseJson" "$1"
}

getSublimeTextFolderUrl() {
  local parseJson="
    console.log(JSON.parse(process.argv[1]).tree.find(({ path }) => path === '$2').url)
  "
  node -e "$parseJson" "$1"
}

saveFileAsScript() {
  local filename=$1
  local scriptName
  local scriptPath

  scriptName=$(echo "$filename" | sed -E 's/([[:alpha:]]+)\.sh/\1/g')
  scriptPath=/usr/local/bin/$scriptName
  customEcho "installing $scriptName"

  rm -f "$scriptPath"
  downloadFile "$filename" > "$scriptPath"
  chmod +x "$scriptPath"
}

saveSublimeTextFile() {
  local applicationSupport="$HOME/Library/Application Support"
  local filename=$1
  local filePath
  local fileUri
  local folderUri=$2
  local sublimePrefsFolder
  local userPackagesDir="Packages/User"

  if [ -d "$applicationSupport/Sublime Text 3" ]
  then
    sublimePrefsFolder="$applicationSupport/Sublime Text 3"
  else
    sublimePrefsFolder="$applicationSupport/Sublime Text"
  fi

  sublimePrefsFolder="$sublimePrefsFolder/$userPackagesDir"
  filePath="$sublimePrefsFolder/$filename"
  fileUri="$folderUri/$(encodeURIComponent "$filename")"

  rm -f "$filePath"
  downloadFile "$fileUri" > "$filePath"
}

installScripts() {
  local file

  for file in $(getScriptsFromJsonTree "$1")
  do
    saveFileAsScript "$file"
  done
}

installSublimeConfigs() {
  local file
  local folderName='Sublime Text'
  local folderRepoUrl
  local folderUri
  local sublimeTree

  folderRepoUrl=$(getSublimeTextFolderUrl "$1" "$folderName")
  sublimeTree=$(getCustomRepoTree "$folderRepoUrl")
  folderUri=$(encodeURIComponent "$folderName")

  for file in $(getSublimeTextFilesFromJsonTree "$sublimeTree")
  do
    saveSublimeTextFile "$file" "$folderUri"
  done
}

repoTree=$(getRepoTree)

installScripts "$repoTree"
installSublimeConfigs "$repoTree"
