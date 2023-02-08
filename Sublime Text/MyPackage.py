import os
import re
import sublime
import sublime_plugin
import subprocess

def writeSnippet(snippetPath, filePath, componentName):
  snippetFile = open(snippetPath, 'r')

  isContent = False
  lines = []

  for line in snippetFile:
    if '<content><![CDATA[' in line:
      isContent = True
    elif ']]></content>' in line:
      isContent = False
    elif isContent:
      lines.append(line.replace('${TM_FILENAME/\\.js$//}', componentName).replace('\n', ''))

  snippetFile.close()

  file = open(filePath, 'w')
  file.write('\n'.join(lines))
  file.close()

def createComponent(currentFilename, name, filename, stylesFilename, componentSnippetName):
  currentFolder = os.path.dirname(currentFilename)

  componentFolder = os.path.join(currentFolder, name)
  componentFile = os.path.join(componentFolder, filename)
  stylesFile = os.path.join(componentFolder, stylesFilename)

  os.makedirs(componentFolder, 0o777, True)

  userPackages = os.path.join(sublime.packages_path(), 'User')
  componentSnippet = os.path.join(userPackages, componentSnippetName + '.sublime-snippet')
  stylesSnippet = os.path.join(userPackages, 'ReactStyles.sublime-snippet')

  writeSnippet(componentSnippet, componentFile, name)
  writeSnippet(stylesSnippet, stylesFile, name)

class EslintFixCommand(sublime_plugin.TextCommand):
  def run(self, edit):
    if self.view.match_selector(0, 'source.js'):
      filename = self.view.file_name()
      subprocess.run("export NVM_DIR=$HOME/.nvm && if [ -f '/usr/local/opt/nvm/nvm.sh' ]; then . '/usr/local/opt/nvm/nvm.sh'; elif [ -f '/opt/homebrew/opt/nvm/nvm.sh' ]; then . '/opt/homebrew/opt/nvm/nvm.sh'; fi && eslint --fix " + filename, cwd=os.path.dirname(filename), shell=True)

class NewReactNativeIndexComponentCommand(sublime_plugin.WindowCommand):
  _currentFilename = ''

  def onNameSubmit(self, name):
    createComponent(self._currentFilename, name, 'index.js', 'styles.js', 'ReactFunctionalIndexComponent')

  def run(self):
    self._currentFilename = self.window.active_view().file_name()
    self.window.show_input_panel('Component name', '', self.onNameSubmit, None, None)

class NewReactNativeComponentCommand(sublime_plugin.WindowCommand):
  _currentFilename = ''

  def onNameSubmit(self, name):
    createComponent(self._currentFilename, name, name + '.js', name + '.styles.js', 'ReactFunctionalComponent')

  def run(self):
    self._currentFilename = self.window.active_view().file_name()
    self.window.show_input_panel('Component name', '', self.onNameSubmit, None, None)

class ReactRelativePathCommand(sublime_plugin.TextCommand):
  def run(self, edit):
    filename = self.view.file_name()
    pathToSrc = re.sub(r'.*(src|App)\/((\w+\/)+)[\w.]+\.js', r'\2', filename)
    relative = re.sub(r'\w+', '..', pathToSrc)

    cursors = self.view.sel()
    firstCursorLocation = cursors[0].begin()

    self.view.insert(edit, firstCursorLocation, relative)
