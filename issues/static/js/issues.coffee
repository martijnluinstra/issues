class Issue extends Backbone.Model
	initialize: ->
		@comments = new CommentCollection [], issue:this

class Comment extends Backbone.Model

class Label extends Backbone.Model

class IssueCollection extends Backbone.Collection
	model: Issue

	url: '/api/issues/all'

class IssueListView extends Backbone.View
	tagName: 'ul'

	initialize: ->
		@el.id = 'issue-list'
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

	initialize: (options)->
		@commentListView = new CommentListView model:@model.comments
		@model.comments.fetch()

	render: (eventName) ->
		(jQuery @el).html(@template @model.toJSON()).show()

		(jQuery @el).find('.comments-list').replaceWith @commentListView.render()

		return @el

class CommentCollection extends Backbone.Collection
	model: Comment

	initialize: (models, options) ->
		@issue = options.issue
		@url = "/api/issues/#{ @issue.get 'id' }/comments"

class CommentListView extends Backbone.View	
	tagName: 'ul'

	initialize: ->
		@model.on 'add', @addComment, this

	render: (eventName) ->
		@addComment comment for comment in @model.models
		return @el

	addComment: (comment) ->
		view = new CommentListItemView model:comment
		jQuery(@el).append view.render()

class CommentListItemView extends Backbone.View
	tagName: 'li'

	template: _.template jQuery('#tpl-comment-list-item').text()

	render: (eventName) ->
		jQuery(@el).html @template @model.toJSON()

class AppRouter extends Backbone.Router
	initialize: (config) ->
		@route '', 'list'
		@route 'issues/:id', 'showIssue'
		@route 'labels/:name', 'showLabel'

		@issueCollection = new IssueCollection config.issues
		@list()

	list: ->
		view = new IssueListView model:@issueCollection
		(jQuery '#issue-list').replaceWith view.render()

	showIssue: (id) ->
		issue = @issueCollection.get id
		view = new IssueView model:issue
		(jQuery '#issue-details').replaceWith view.render()

init = (issues) ->
	app = new AppRouter issues:issues

	Backbone.history.start pushState:true

	jQuery("a:not([href^='http://'])").click (evt) ->
		evt.preventDefault()
		app.navigate (jQuery this).attr('href'), true