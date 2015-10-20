## 0.1.0 - First Release

- added save-autorun.cson

## 0.2.0

- added variables

### 0.2.1

- fixed an error being thrown when trying to open the save-autorun.cson via treeview

### 0.2.2

- shell commands now use a saved file's project directory, if there is any
- added a new variable `${project}`
- updated README

### 0.2.3

- added an option to disable notifications
- added a keymap to the `open-global-definitions` command
- `child_process.exec` uses the timeout from the config now
- changed timeout default value to 0
- changed the notification formatting a little

## 0.3.1

- fixed file path separators only using `\\`

## 0.3.2

- fixed commands array assignment (merge 0f60a55)
- fixed mismatched parenthesis (merge 5620ecb)

## 0.3.3

- fixed ${path} using the wrong value (#6)
