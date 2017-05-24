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
		sequentialExecution:
			title: 'Sequential Execution'
			description: 'Queues commands and executes them one at a time instead of all at the same time.'
			type: 'boolean'
			default: false
		failOnStderr:
			title: 'Fail on STDERR'
			description: 'Show an error even when the command succeeded if it wrote anything to STDERR.'
			type: 'boolean'
			default: false

	# the path to this package
	directory: null

	# the current instance of CompositeDisposable
	subscriptions: null

	# the current instance of SaveDefinitions
	definitions: null

	# the current queue of commands and scripts to execute
	executionQueue: []

	# whether the executionQueue is being processed or not
	queueRunning: false

	constructor: ->
		@directory = atom.packages.resolvePackagePath('save-autorun')

	activate: (state) ->
		@subscriptions = new CompositeDisposable

		@subscriptions.add atom.commands.add 'atom-workspace',
			'save-autorun:execute-definitions': => @runDefinitions()

		@subscriptions.add atom.commands.add 'atom-workspace',
			'save-autorun:open-global-definitions': => @definitions.openDefinitions()

		@subscriptions.add atom.workspace.observeTextEditors (textEditor) =>
			@subscriptions.add textEditor.onDidSave (event) =>
				@runDefinitions event['path']

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

		executionQueue = []

		if def.commands.length
			notification = @notifyInfo 'executing ' +
				def.commands.length + ' command(s)'
			def.commands.forEach (rawCommand, i) =>
				startNotification = notification unless i
				executionQueue.push () =>
					@executeCommand rawCommand, filePath, projectPath, startNotification

		if def.scripts.length
			notification = @notifyInfo 'executing ' +
				def.scripts.length + ' scripts(s)', projectPath
			def.scripts.forEach (script, i) =>
				startNotification = notification unless i
				executionQueue.push () =>
					@executeScript script, filePath, projectPath, startNotification

		return unless executionQueue.length

		if atom.config.get('save-autorun.sequentialExecution')
			@queueCommands executionQueue
		else
			@runAllAtOnce executionQueue

	runAllAtOnce: (commands) ->
		@handlePromise command() for command in commands

	queueCommands: (commands) ->
		# add commands to main execution queue
		commands.forEach (command) => @executionQueue.push command
		@runSequentially() unless @queueRunning

	runSequentially: (recheck=2) ->
		# removes first element of array
		command = @executionQueue.shift()

		@queueRunning = !!command
		unless @queueRunning
			# a race condition can occur where the queue has items but the queue won't
			# run until the next save, this re-checking tries to get rid of that by
			# going over the data a couple times just to be safe.
			@runSequentially recheck - 1 if recheck
			return

		@handlePromise command()
		.then => @runSequentially()

	handlePromise: (promise) ->
		promise
			.then (command) =>
				successNotification = @notifySuccess command
				successNotification.dismiss()
			.catch ({command, reason}) => @notifyError command, reason

	executeCommand: (rawCommand, filePath, projectPath, startNotification) ->
		command = @prepareCommand rawCommand, filePath, projectPath
		new Promise (resolve, reject) =>
			@shell command, projectPath, (error, stdout, stderr) =>
				startNotification.dismiss() if startNotification
				if error
					reject {command, reason: error}
				else if stderr and atom.config.get('save-autorun.failOnStderr')
					reject {command, reason: stderr}
				else
					resolve command

	executeScript: (script, filePath, projectPath, startNotification) ->
		new Promise (resolve, reject) =>
			try
				ext = _path.extname script
				require(script) filePath
				resolve script
			catch error
				reject {command: script, reason: error}
			finally
				startNotification.dismiss() if startNotification
