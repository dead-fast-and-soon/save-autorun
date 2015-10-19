# Save Autorun

Automatically run commands and or scripts when you save files.
```cson
# converts an x.md file into x.html using pandoc
'**/*.md': 'pandoc ${file} -o ${name}.html'

# compiles a x.less file into x.css using lessc
'**/*.less': 'lessc ${file} ${name}.css'
```
### Variables

These are a list of variables you can use in command definitions. The variables will be replaced with corresponding information from the saved file.

- `${file}`: the name of the file saved.
- `${name}`: the name of the file saved without the file extension.
- `${ext}`: the extension of the file saved.
- `${dir}`: the absolute path to the directory containing the file saved.
- `${project}`: the absolute path to the root project directory. if a project doesn't exist, then this variable will be identical to `${dir}`.

If the saved file was within a single Project, then that Project's root directory will be used as the __current working directory__ for its commands. (behavior if a file was within multiple Projects is undefined.)

If the saved file was not within any Project, then the directory containing that file will be used.

### Save Definitions

_(To all users who previously used a `save-autorun.cson` for global definitions prior to version 0.3, please convert your definitions to the newly generated `.save.cson`)_

When this package is activated, a file `.save.cson` will appear in Atom's config directory. An option `Open Save Definitions` will also appear under the `File` tab to easily access this file.

A newly generated `.save.cson` will give you:
```cson
"*": {}
```
Under `"*"` (the global group), you can define shell commands by using a glob as a key and a command as the value. Any file saved that matches that glob will trigger that command:
```cson
"*": {
	"**/*.less": "lessc ${file} ${name}.css"
}
```
You can also define multiple commands to be used by using an array of commands as the value instead of just one:
```cson
"*":
	"**/*.less": [
		"lessc ${file} ${name}.css"
		"(another command)"
	]
```
You can also define both commands and scripts to trigger by using an object with a `command` key and `script` key as the value. For scripts, the value can be a path to a `.coffee` file that is absolute or relative to the file saved: (note that the value for `command` and `script` can also be a string or an array of strings)
```cson
"*": {
	"**/*.less":
		command: [
			"lessc ${file} ${name}.css"
			"(another command)"
		]
		script: "save.coffee"
}
```
Information on what goes in a save script is in the [Save Scripts](#save-scripts) section.

---

In addition, you can make project-specific groups (as opposed to the `"*"` group) by using the absolute path to the project folder as the key:
```cson
"*": {}
"C:\Git\Project\":
	"**/*.less": "lessc ${file} ${name}.css"
```
### Project-Specific Save Definitions
If desired, you can also make your own `.save.cson` file in the root of your project folder. Please note that the format the definitions is not exactly the same as the global `.save.cson` file, the only difference being that you do not need to define groups such as `"*"`. Therefore, this is a valid project-specific `.save.cson`:
```cson
"**/*.less": "lessc ${file} ${name}.css"
```
Note that if this file exists, then the global `.save.cson` will be ignored.

As an added bonus, you can also create a `.save.coffee` file in the root of your project folder. This file will be run any time any file in that project folder is saved.

### Save Scripts
(this feature isn't fully planned out yet)

A save script is a single function with the path to the file saved as the first argument.
```coffee
module.exports = (file) ->
	atom.notifications.addSuccess "file saved!"
```

### Settings

- `save-autorun.notifications`: show notifications when a save triggers commands.
- `save-autorun.timeout`: the amount of time in ms until a command times out

### Keybindings

```cson
'atom-workspace':
	'ctrl-alt-s': 'save-autorun:open-global-definitions'
```

The `open-global-definitions` command is binded for easy access to the global definitions file.

### Requirements

- `minimatch`: used to match the files to GLOBs.
- `season`: used to read/write CSON.
