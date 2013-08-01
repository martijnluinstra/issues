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

initView = (collection) ->
	view = new Backbone.CollectionView
		model: collection
		childView: IssueView

	jQuery(document.body).append view.el

	window.view = view

addDummyIssue = (collection, n) ->
	collection.create
		title: "Issue #{n}"
		description: "Awesome dummy issue #{n}"

jQuery ->
	collection = new IssueCollection []

	for n in [1..5]
		addDummyIssue collection, n

	view = initView collection

	view.render()

	for n in [10..15]
		addDummyIssue collection, n

	view.render()