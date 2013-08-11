class Backbone.CollectionView extends Backbone.View
	tagName: 'ol'

	constructor: (options) ->
		@children = {}

		if options.childView?
			@childView = options.childView

		if not @childView?
			console.error 'childView option is missing'

		super options

	initialize: ->
		@listenTo @model, 'add', @addChildView
		@listenTo @model, 'remove', @removeChildModel

	createChildView: (model) ->
		new @childView
			model: model

	appendChildView: (el) ->
		@$el.append el

	addChildView: (childModel) ->
		view = @createChildView childModel

		view.render()

		@children[childModel.cid] = view
		@appendChildView view.el

	removeChildModel: (childModel) ->
		if not @children[childModel.cid]?
			return false

		# Let the view remove itself
		@children[childModel.cid].remove()
		
		# and remove it from our index
		delete @children[childModel.cid]

	render: ->
		@clear()

		for model in @model.models
			if not @children[model.cid]?
				@addChildView model

	remove: ->
		# First, neatly remove all the children.
		# (But intentionally bypass the removeChildModel method)
		@clear()

		# And then the rest :)
		super()

	clear: ->
		for cid, child of @children
			child.remove()

		@children = {}
