path = require 'path'
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
			'save-autorun:open-config': => @definitions.load()

		@subscriptions.add atom.workspace.observeTextEditors (textEditor) =>
			@subscriptions.add textEditor.onDidSave (event) => @runDefinitions(textEditor)

		SaveDefinitions = require './save-definitions'
		@definitions = new SaveDefinitions()

	deactivate: ->
		@subscriptions.dispose()

	openConfig: ->
		atom.workspace.open(config.path())

	# executes a shell command
	shell: (cmd, dir, callback) -> child = exec cmd, cwd: dir, callback

	# replaces envvar-like variable patterns (${var}) with a value
	replaceVar: (command, key, value) ->
		regex = new RegExp('\\$\\{' + key + '\\}', 'ig')
		matches = command.match(regex)
		command = command.replace(regex, value)
		return command

	# prepares a command for execution by replacing any variables
	# with editor information
	prepareCommand: (command, textEditor) ->

		filepath = textEditor.getPath()
		ext = path.extname(filepath)

		command = @replaceVar(command, 'file', path.basename(filepath))
		command = @replaceVar(command, 'name', path.basename(filepath, ext))
		command = @replaceVar(command, 'ext', ext)
		command = @replaceVar(command, 'dir', path.dirname(filepath))
		command = @replaceVar(command, 'path', filepath)

		return command

	runDefinitions: ->
		textEditor = atom.workspace.getActiveTextEditor()
		if textEditor?
			@runDefinitions textEditor
		else
			atom.notifications.addError("unable to run save scripts on this pane.")

	runDefinitions: (textEditor) ->
		if textEditor?
			filepath = textEditor.getPath()

			# reload definitions if the definitions file was saved
			if filepath is @definitions.path()
				@definitions.reload()

			# loop through all defined commands for this file
			commands = @definitions.get textEditor.getPath()
			if commands.length > 0
				for rawCommand in commands
					command = @prepareCommand(rawCommand, textEditor)
					@shell command, path.dirname(filepath), (error, stdout, stderr) =>
						if not error?
							atom.notifications.addInfo command
						else
							atom.notifications.addError command, detail: error
