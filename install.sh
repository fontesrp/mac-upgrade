#!/bin/bash

gitHubUsername=fontesrp
gitHubRepoName=mac-upgrade
gitHubRepoPath=$gitHubUsername/$gitHubRepoName
gitHubBranch=master

customEcho() {
  echo "♨️  $1"
}

downloadFile() {
  curl \
    "https://raw.githubusercontent.com/$gitHubRepoPath/$gitHubBranch/$1" \
    -s \
    -G \
    -H 'Accept: text/plain'
}

getRepoTree() {
  curl \
    "https://api.github.com/repos/$gitHubRepoPath/git/trees/$gitHubBranch" \
    -s \
    -G \
    -H 'Accept: application/vnd.github.v3+json' \
    2>&1
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

repoTree=$(getRepoTree)

for file in $(getScriptsFromJsonTree "$repoTree")
do
  saveFileAsScript "$file"
done
