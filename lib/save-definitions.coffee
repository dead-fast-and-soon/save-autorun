season = require 'season'
minimatch = require 'minimatch'

module.exports = class SaveDefinitions
	cson = null

	constructor: ->
		@reload()

	path: -> return atom.getConfigDirPath() + '\\save-autorun.cson'
	# reads from the main config file, or creates one if it doesn't exist
	open: -> atom.workspace.open(@path())

	reload: ->
		try
			@cson = season.readFileSync(@path())
		catch # rewrite config
			@cson = {}
			season.writeFileSync @path(), {}

	get: (file) ->
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
