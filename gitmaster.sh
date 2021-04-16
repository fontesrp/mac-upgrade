#!/bin/bash

currentBranch=`git rev-parse --abbrev-ref HEAD`
destinationBranch=`[ -z "$1" ] && echo 'master' || echo "$1"`

git fetch --all -p
git fetch -u origin $destinationBranch:$destinationBranch
git checkout $destinationBranch
git branch -D $currentBranch
