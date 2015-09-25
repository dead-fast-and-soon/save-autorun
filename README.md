# Save Autorun

Automatically run shell commands when you save files.

### Variables

These are a list of variables you can use in command definitions. The variables will be replaced with corresponding information from the saved file.

- `${file}`: the name of the file saved.
- `${name}`: the name of the file saved without the file extension.
- `${path}`: the absolute path to the file saved.
- `${ext}`: the extension of the file saved.
- `${dir}`: the absolute path to the directory containing the file saved.
- `${project}`: the absolute path to the root project directory. if a project doesn't exist, then this variable will be identical to `${dir}`.

If the saved file was within a single Project, then that Project's root directory will be used as the __current working directory__ for its commands. (behavior if a file was within multiple Projects is undefined.)

If the saved file was not within any Project, then the directory containing that file will be used.

### Save Autorun Definitions

When this package is activated, a file `save-autorun.cson` will appear in Atom's config directory. An option `Open SAR Global Definitions` will also appear under the `File` tab to easily access this file.

You can use this file to define globs that trigger shell commands, which work in either a `glob: command` or `glob: [command1, command2]` format.
Example of a valid `save-autorun.cson` config:

```cson
// converts an x.md file into x.html using pandoc
'**.md': 'pandoc ${file} -o ${name}.html'

// compiles a x.less file into x.css using lessc
'**.less': 'lessc ${file} ${name}.css'
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
