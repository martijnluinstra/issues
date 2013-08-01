Backbone.sync = ->
	# do nothing :)

class Issue extends Backbone.Model
	defaults:
		title: 'Unnamed Issue'
		description: 'No description given'

class IssueCollection extends Backbone.Collection
	model: Issue

class IssueView extends Backbone.View
	events:
		'click .delete': ->
			@model.destroy()

	template: _.template jQuery('#tpl-issue').text()

	initialize: ->
		@listenTo @model, 'change', @update

	render: ->
		@$el.html @template()
		@update()

	update: ->
		@$('.issue-title').text @model.get 'title'
		@$('.issue-description').text @model.get 'description'

class CollectionView extends Backbone.View
	constructor: (options) ->
		@children = []
		
		if not options.childView?
			console.error 'childView option is missing'

		{@childView} = options

		super options

	initialize: ->
		@listenTo @model, 'add', @addChildView
		@listenTo @model, 'remove', @removeChildModel

	addChildView: (childModel) ->
		console.log 'new childModel', childModel, 'added to', this

		childModel._view = new @childView
			model: childModel

		childModel._view.render()

		@children.push childModel._view
		@$el.append childModel._view.$el

	removeChildModel: (childModel) ->
		console.log 'childModel', childModel, 'removed from', this

		index = @children.indexOf childModel._view

		# is this one of our views?
		if index == -1
			return

		# Let the view remove itself
		childModel._view.remove()

		# and remove it from our index
		@children.splice index, 1

	remove: ->
		# First, neatly remove all the children.
		# (But intentionally bypass the removeChildModel method)
		for child in @children
			child.remove()

		# And then the rest :)
		super()

jQuery ->
	window.collection = new IssueCollection []

	window.view = new CollectionView
		model: collection
		childView: IssueView

	jQuery(document.body).append view.el

	issue_1 = collection.create
		title: 'Issue 1'
		description: 'Awesome'

	issue_2 = collection.create
		title: 'Issue 2'
		description: 'Less awesome'

	