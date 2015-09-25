_path = require 'path'
{exec} = require 'child_process'
{CompositeDisposable, TextEditor} = require 'atom'

module.exports = class SaveAutorun
	config:
		timeout:
			title: 'Command Timeout'
			description: 'How much time in milliseconds before a command will time out.'
			type: 'integer'
			default: 500

	# the current instance of CompositeDisposable
	subscriptions: null

	# the current instance of SaveDefinitions
	definitions: null

	constructor: ->

	activate: (state) ->
		@subscriptions = new CompositeDisposable

		@subscriptions.add atom.commands.add 'atom-workspace',
			'save-autorun:execute-save-autoruns': => @runDefinitions()

		@subscriptions.add atom.commands.add 'atom-workspace',
			'save-autorun:open-config': => @definitions.open()

		@subscriptions.add atom.workspace.observeTextEditors (textEditor) =>
			@subscriptions.add textEditor.onDidSave (event) => @runDefinitions event['path']

		SaveDefinitions = require './save-definitions'
		@definitions = new SaveDefinitions()

	deactivate: ->
		@subscriptions.dispose()

	# executes a shell command
	shell: (cmd, dir, callback) -> child = exec cmd, cwd: dir, callback

	# replaces envvar-like variable patterns (${var}) with a value
	replaceVar: (command, key, value) ->
		regex = new RegExp('\\$\\{' + key + '\\}', 'ig')
		matches = command.match(regex)
		command = command.replace(regex, value)
		return command

	# tries to get the project path of another path
	# returns null if a project does not exist
	getProjectPath: (filePath) ->
		project = null
		for p in atom.project.getDirectories()
			if(p.contains filePath)
				project = p
				break
		return if project? then project.getPath() else null

	# prepares a command for execution by replacing any variables
	# with editor information
	prepareCommand: (command, filePath, projectPath) ->
		ext = _path.extname(filePath)

		command = @replaceVar(command, 'project',	_path.dirname(projectPath))
		command = @replaceVar(command, 'file',		_path.basename(filePath))
		command = @replaceVar(command, 'name',		_path.basename(filePath, ext))
		command = @replaceVar(command, 'path',		_path.filePath)
		command = @replaceVar(command, 'ext',		ext)
		command = @replaceVar(command, 'dir',		_path.dirname(filePath))
		return command

	runDefinitions: ->
		textEditor = atom.workspace.getActiveTextEditor()
		if textEditor?
			@runDefinitions textEditor.getPath()
		else
			atom.notifications.addError("unable to run save scripts on this pane.")

	# executes any possible definitions that this file furfills
	runDefinitions: (filePath) ->
		# TODO: check if 'path' is a file?

		# reload definitions if the definitions file was saved
		if filePath is @definitions.path() then @definitions.reload()

		projectPath = @getProjectPath filePath

		# current working directory
		# if there is no projectPath then use filePath instead
		projectPath = if projectPath? then projectPath else filePath

		# loop through all defined commands for this file
		commands = @definitions.get filePath
		if commands.length > 0
			errors = 0
			atom.notifications.addInfo 'executing commands in:', detail: cwd
			for rawCommand in commands
				command = @prepareCommand(rawCommand, filePath, projectPath)
				@shell command, projectPath, (error, stdout, stderr) =>
					if not error?
						atom.notifications.addSuccess command
					else
						atom.notifications.addError command, detail: error
						error++
			if errors = 0
				atom.notifications.addSuccess 'all commands executed successfully!'
			else
				atom.notifications.addWarning 'at least one commmand has failed!'
