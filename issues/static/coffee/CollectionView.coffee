class Backbone.CollectionView extends Backbone.View
	constructor: (options) ->
		@children = []

		if options.childView?
			@childView = options.childView

		if not @childView?
			console.error 'childView option is missing'

		super options

	initialize: ->
		@listenTo @model, 'add', @addChildView
		@listenTo @model, 'remove', @removeChildModel

	addChildView: (childModel) ->
		#console.log 'new childModel', childModel, 'added to', this

		childModel._view = new @childView
			model: childModel

		childModel._view.render()

		@children.push childModel._view
		@$el.append childModel._view.$el

	removeChildModel: (childModel) ->
		#console.log 'childModel', childModel, 'removed from', this

		index = @children.indexOf childModel._view

		# is this one of our views?
		if index == -1
			return

		# Let the view remove itself
		childModel._view.remove()
		childModel._view = null

		# and remove it from our index
		@children.splice index, 1

	render: ->
		for model in @model.models
			if not model._view
				@addChildView model

	remove: ->
		# First, neatly remove all the children.
		# (But intentionally bypass the removeChildModel method)
		for child in @children
			child.remove()

		# And then the rest :)
		super()