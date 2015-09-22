minimatch = require 'minimatch' 		# for matching files to globs
fs = require 'fs'						# for writing / reading files
CSON = require 'cson-safe'				# for parsing CSON
exec = require('child_process').exec	# for executing commands

{CompositeDisposable} 	= require 'atom'
{TextEditor} 			= require 'atom'

# a container for shell methods
Shell =
	# callback (error, stdout, stderr)
	exec: (cmd, dir, callback) ->
		child = exec cmd, cwd: dir, callback

# a container for config methods
Config =
	cson: {}
	# gets the path of the main config file
	getConfigPath: ->
		return atom.getConfigDirPath() + '\\save-autorun.cson'

	# reads from the main config file, or creates one if it doesn't exist
	loadConfig: ->
		configFile = @getConfigPath()
		try
			stats = fs.statSync configFile
			@cson = CSON.parse fs.readFileSync(configFile)
		catch
			CSON.writeFileSync configFile, {}
		console.log @cson

	# gets all commands that apply to this file
	getCommands: (file) ->
		commands = []
		relative = atom.project.relativize(file)
		for glob, v of @cson
			match = minimatch(relative, glob)
			# console.log('minimatching ' + relative + ' to ' + glob)
			if match
				if (v instanceof Array)
					for cmd in v
						commands.push cmd
				else
					commands.push v.toString()
		return commands

module.exports = SaveAutorun =

	config:
		timeout:
			title: 'Command Timeout'
			description: 'How much time in milliseconds before a command will time out.'
			type: 'integer'
			default: 500

	configDir: null
	subscriptions: null
	textEditor: null

	activate: (state) ->
		Config.loadConfig()

		@subscriptions = new CompositeDisposable

		@subscriptions.add atom.commands.add 'atom-workspace',
			'save-autorun:execute-save-autoruns': => @executeSaveScript()

		@subscriptions.add atom.workspace.observeTextEditors (textEditor) =>
			@subscriptions.add textEditor.onDidSave (event) => @executeSaveScript(textEditor)

	deactivate: ->
		@subscriptions.dispose

	executeSaveScript: ->
		textEditor = atom.workspace.getActiveTextEditor()
		if textEditor?
			@executeSaveScript textEditor
		else
			atom.notifications.addError("unable to run save scripts on this pane.")

	executeSaveScript: (textEditor) ->
		if textEditor?
			filepath = textEditor.getPath()
			directory = filepath.substring(0, filepath.lastIndexOf '\\') + '\\'
			commands = Config.getCommands(filepath)
			#console.log('commands for file ' + filepath + ': \n' + commands)
			for cmd in commands
				Shell.exec cmd, directory, (error, stdout, stderr) =>
					if error is null
						atom.notifications.addSuccess "successfully executed command", detail: cmd + '\n' + stdout
					else
						atom.notifications.addError "failed to execute command", detail: cmd + '\n' + error
