_path = require 'path'
{exec} = require 'child_process'
{CompositeDisposable, TextEditor} = require 'atom'

module.exports = class SaveAutorun
	config:
		notifications:
			title: 'Notifications'
			description: 'Show notifications when a save triggers commands.'
			type: 'boolean'
			default: true
		timeout:
			title: 'Command Timeout'
			description: 'How much time in milliseconds before a command will time out.'
			type: 'integer'
			default: 0

	# the path to this package
	directory: null

	# the current instance of CompositeDisposable
	subscriptions: null

	# the current instance of SaveDefinitions
	definitions: null

	constructor: ->
		@directory = atom.packages.resolvePackagePath('save-autorun')

	activate: (state) ->
		@subscriptions = new CompositeDisposable

		@subscriptions.add atom.commands.add 'atom-workspace',
			'save-autorun:execute-definitions': => @runDefinitions()

		@subscriptions.add atom.commands.add 'atom-workspace',
			'save-autorun:open-global-definitions': => @definitions.openDefinitions()

		@subscriptions.add atom.workspace.observeTextEditors (textEditor) =>
			@subscriptions.add textEditor.onDidSave (event) => @runDefinitions event['path']

		SaveDefinitions = require './save-definitions'
		@definitions = new SaveDefinitions(@)

	deactivate: ->
		@subscriptions.dispose()

	notifyInfo: (message) -> @notifyInfo message ''
	notifyInfo: (message, details) ->
		if atom.config.get('save-autorun.notifications')
			atom.notifications.addInfo message, detail: details, dismissable: true

	notifyError: (message) -> @notifyError message ''
	notifyError: (message, details) ->
		if atom.config.get('save-autorun.notifications')
			atom.notifications.addError message, detail: details, dismissable: true

	notifySuccess: (message) -> @notifySuccess message ''
	notifySuccess: (message, details) ->
		if atom.config.get('save-autorun.notifications')
			atom.notifications.addSuccess message, detail: details, dismissable: true

	getTimeout: -> atom.config.get('save-autorun.timeout')

	# executes a shell command
	shell: (cmd, dir, callback) ->
		return exec cmd, {cwd: dir, timeout: @getTimeout()}, callback

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

		command = @replaceVar(command, 'project',	projectPath)
		command = @replaceVar(command, 'file',		_path.basename(filePath))
		command = @replaceVar(command, 'name',		_path.basename(filePath, ext))
		command = @replaceVar(command, 'path',		filePath)
		command = @replaceVar(command, 'ext',		ext)
		command = @replaceVar(command, 'dir',		_path.dirname(filePath))
		return command

	runDefinitions: ->
		textEditor = atom.workspace.getActiveTextEditor()
		if textEditor?
			@runDefinitions textEditor.getPath()
		else
			console.warn ("save-autorun: unable to run save scripts on this pane.")

	# executes any possible definitions that this file furfills
	runDefinitions: (filePath) ->
		# TODO: check if 'path' is a file?

		# reload definitions if the definitions file was saved
		if filePath is @definitions.globalFilePath then @definitions.reload()

		# current working directory
		projectPath = @getProjectPath filePath

		if projectPath?
			isProject = true
		else # if there is no projectPath then use filePath instead
			isProject = false
			projectPath = _path.dirname(filePath)

		# collect definitions for this file
		def = @definitions.getDefinitions filePath, projectPath

		# run all defined commands
		#
		if def.commands.length > 0
			startMessage = @notifyInfo 'executing ' + def.commands.length + ' command(s)'
			for rawCommand in def.commands
				tmpCommand = @prepareCommand(rawCommand, filePath, projectPath)
				`const command = tmpCommand`
				@shell command, projectPath, (error, stdout, stderr) =>
					startMessage.dismiss()
					if error
						@notifyError command, error
					else if stderr
						@notifyError command, stderr
					else
						successMessage = @notifySuccess command
						successMessage.dismiss()

		# run all defined scripts
		#
		if def.scripts.length > 0
			@notifyInfo 'executing ' + def.scripts.length + ' scripts(s)', projectPath
			for script in def.scripts
				try
					ext = _path.extname(script)
					require(script)(filePath)
					@notifySuccess script
				catch error
					@notifyError script, error
