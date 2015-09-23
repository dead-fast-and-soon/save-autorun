# Save Autorun

Automatically run shell commands when you save files.

#### NOTE
At this is a pre-release, the variables feature is not implmented yet.

---

### Save Autorun Rules Definitions

The first time this package is activated, a file `save-autorun.cson` will appear in Atom's config directory. You can use this file to define save autorun rules, which work in either a `glob: command` or `glob: [command1, command2]`.
Example of a valid `save-autorun.cson` config:

```cson
// converts an x.md file into x.html using pandoc
'**.md': 'pandoc index.md -o index.html'

// compiles a x.less file into x.css using lessc
'**.less'
```
