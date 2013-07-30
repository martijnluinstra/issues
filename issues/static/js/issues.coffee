class Issue extends Backbone.Model

class Comment extends Backbone.Model

class Label extends Backbone.Model

class IssueCollection extends Backbone.Collection
	model: Issue

	url: '/api/issues/all'

class IssueListView extends Backbone.View
	tagName: 'ul'

	initialize: ->
		@model.on 'reset', @render, this
		(jQuery @el).addClass 'list-group'

	render: (eventName) ->
		for issue in @model.models
			view = new IssueListItemView model:issue
			(jQuery @el).append view.render()

class IssueListItemView extends Backbone.View
	tagName: 'li'

	template: _.template jQuery('#tpl-issue-list-item').text()

	initialize: ->
		(jQuery @el).addClass 'list-group-item'

	render: (eventName) ->
		(jQuery @el).html @template @model.toJSON()

class IssueView extends Backbone.View
	tagName: 'div'

	template: _.template jQuery('#tpl-issue-details').text()

	render: (eventName) ->
		(jQuery @el).html(@template @model.toJSON()).show()

class AppRouter extends Backbone.Router
	initialize: (config) ->
		@route '', 'list'
		@route 'issues/:id', 'showIssue'
		@route 'labels/:name', 'showLabel'

		@issueCollection = new IssueCollection config.issues
		@list()

	list: ->
		view = new IssueListView model:@issueCollection
		(jQuery '#issue-list').html view.render()

	showIssue: (id) ->
		issue = @issueCollection.get id
		view = new IssueView model:issue
		(jQuery '#issue-details').html view.render()
