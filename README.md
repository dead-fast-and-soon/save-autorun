# Save Autorun

Automatically run shell commands when you save files.

---
### Variables

__NOTE: At this is a pre-release, this feature is not implmented yet.__

These are a list of variables you can use in command definitions. The variables will be replaced with corresponding information from the saved file.

The current working directory _should_ be the project folder containing the saved file.

- `${file}`: the relative path to the file saved.
- `${name}`: the relative path to the file saved without the file extension.
- `${path}`: the relative path to the directory containing the file saved.
- `${abs_file}`: the full path of the file saved.
- `${abs_name}`: the full path of the file saved without the file extension.
- `${abs_path}`: the full path to the directory containing the file saved.


### Rule Definitions
The first time this package is activated, a file `save-autorun.cson` will appear in Atom's config directory. You can use this file to define save autorun rules, which work in either a `glob: command` or `glob: [command1, command2]`.
Example of a valid `save-autorun.cson` config:

```cson
// converts an x.md file into x.html using pandoc
'**.md': 'pandoc ${file} -o ${name}.html'

// compiles a x.less file into x.css using lessc
'**.less': 'lessc ${file} ${name}.css'
```
