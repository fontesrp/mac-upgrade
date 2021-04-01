#!/bin/bash

closeEveryWindow() {
  osascript -e "
    if application \"$1\" is running then
      tell application \"$1\"
        close every window
      end tell
    end if
  " 2> /dev/null
}

quitApp() {
  osascript -e "
    if application \"$1\" is running then
      quit app \"$1\"
    end if
  "
}

apps=( \
  "Slack" \
  "Microsoft Teams" \
  "Harvest" \
  "Sublime Text"
)

for app in "${apps[@]}"
do
  closeEveryWindow "$app"
  quitApp "$app"
done
