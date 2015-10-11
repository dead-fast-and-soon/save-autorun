season = require 'season'
fs = require 'fs'
minimatch = require 'minimatch'
_path = require 'path'

module.exports = class SaveDefinitions

	# the current instance of SaveAutorun
	pkg: null

	sep: _path.sep

	paths: {}

	# the read default definition files (initialized in constructor)
	defaults: {}

	constructor: (@pkg) ->
		@paths =
			global: atom.getConfigDirPath() + @sep + '.save.cson'

		@defaults =
			global:  fs.readFileSync(@pkg.directory + @sep + ".global.save.cson", "utf8")
			project: fs.readFileSync(@pkg.directory + @sep + ".project.save.cson", "utf8")

		@cson = @parseDefinitions()

	# reads from the main config file, or creates one if it doesn't exist
	openDefinitions: ->
		atom.workspace.open(@paths.global)

	fileExists: (filePath) ->
		try
			fs.statSync(filePath)
			return true
		catch error
			return false

	parseDefinitions: (filePath = @paths.global) ->
		isGlobal = filePath is @globalFilePath
		if @fileExists filePath
			cson = season.readFileSync(filePath)
		else # rewrite config
			cson = {}
			content = if isGlobal then @defaults.global else @defaults.project
			fs.writeFile filePath, content, (err) ->
				if err?
					atom.notifications.addError 'unable to create ' + filePath,
						err
		return cson

	relativePath: (filePath) ->
		relativePath = _path.relative(_path.resolve('.'), filePath)
		return relativePath

	getGlobalDefinitions: (filePath) -> @getGlobalDefinitions filePath null

	getGlobalDefinitions: (filePath, projectPath) ->
		def = {commands: [], scripts: []}
		dir = _path.dirname(filePath)
		for group, o of @cson
			if group is "*" or group is projectPath
				for glob, obj of o
					match = minimatch(atom.project.relativize(filePath), glob)
					if match
						tempDef = @_parseDefinitionObject obj, dir
						def.commands.concat(tempDef.commands)
						def.scripts.concat(tempDef.scripts)
		return def

	getDefinitions: (filePath, projectPath) ->
		if not projectPath?
			console.log ('save-autorun: not a project, getting globals')
			return @getGlobalDefinitions filePath, null

		@projectFilePath = _path.resolve(projectPath, '.save.cson')

		if not @fileExists @projectFilePath
			console.log ('save-autorun: project .save.cson doesn\'t exist, getting globals')
			return @getGlobalDefinitions filePath, projectPath

		cson = season.readFileSync @projectFilePath
		# read project .save.cson
		def = {commands: [], scripts: []}
		dir = _path.dirname(filePath)
		for glob, obj of cson
			match = minimatch(atom.project.relativize(filePath), glob)
			if match
				tempDef = @_parseDefinitionObject obj, dir
				def.commands = def.commands.concat(tempDef.commands)
				def.scripts = def.scripts.concat(tempDef.scripts)
		return def

	_parseDefinitionObject: (obj, dir) ->
		def = {commands: [], scripts: []}
		if (obj instanceof Object)
			if obj.command?
				if obj.command instanceof Array
					for command in obj.command
						def.commands.push command
				else
					def.commands.push obj.command.toString()
			if obj.script?
				if obj.script instanceof Array
					for script in obj.script
						def.script.push _path.resolve(dir, script)
				else
					def.scripts.push _path.resolve(dir, obj.script.toString())
		# read each line as a command
		else if (obj instanceof Array)
			for command in obj
				def.commands.push command
		# convert to string and save as command
		else
			def.commands.push obj.toString()
		return def;
