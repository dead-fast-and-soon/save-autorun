# Save Autorun

Automatically run shell commands when you save files.

The first time this package is activated, a file `save-autorun.cson` will appear in Atom's config directory. You can use this file to define rules, which work in either a `glob: command` or `glob: [command1, command2]`.

For example, this is a rule defining an `.html` file to be compiled with Pandoc when an `.md` file is saved.

```
'**.md': 'pandoc index.md -o index.html'
```

(At the moment, there's no variables to use in the command, but that'll come soon)
