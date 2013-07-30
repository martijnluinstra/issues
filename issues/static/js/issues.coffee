# The app variable is 'global' for this module and contains things like the
# router and the currently logged in user's data.
app = null

class Issue extends Backbone.Model
	initialize: ->
		@comments = new CommentCollection [], issue:this

class Comment extends Backbone.Model

class Label extends Backbone.Model

class IssueCollection extends Backbone.Collection
	model: Issue

	url: '/api/issues/all'

class IssueListView extends Backbone.View
	el: jQuery('#issue-list')

	initialize: ->
		@model.on 'reset', @render, this
		@model.on 'add', @renderIssue, this

	render: (eventName) ->
		# clear all issues from view
		@$el.html ''

		# Render all issues
		@renderIssue issue for issue in @model.models

	renderIssue: (issue) ->
		view = new IssueListItemView model:issue
		@$el.append view.render()
			

class IssueListItemView extends Backbone.View
	tagName: 'li'

	template: _.template jQuery('#tpl-issue-list-item').text()

	initialize: ->
		@$el.addClass 'list-group-item'

	render: (eventName) ->
		@$el.html @template @model.toJSON()

class IssueView extends Backbone.View
	tagName: 'div'

	initialize: ->
		@model.comments.fetch()

	render: (eventName) ->
		@$el.find('.issue-title').text @model.get 'title'

		@$el.find('.issue-description').html @model.get 'description'

		# also initialize a view for the comment list
		commentListView = new CommentListView
			model: @model.comments
			el: @$el.find('.comments')

		commentListView.render()

		return @el

class CommentCollection extends Backbone.Collection
	model: Comment

	initialize: (models, options) ->
		@issue = options.issue
		@url = "/api/issues/#{ @issue.get 'id' }/comments"

class CommentListView extends Backbone.View	
	events:
		# catch the submit-event of the comment form
		'submit form': (evt) ->
			evt.preventDefault()
			@addComment()

		# Also catch the cmd/ctrl+enter key combination on the textarea
		'keypress textarea': (evt) ->
			if evt.keyCode == 13 and (evt.ctrlKey or evt.metaKey)
				@addComment()

	initialize: ->
		@model.on 'add', @renderComment, this

	render: (eventName) ->
		# Render all the comments that are already in the model
		@renderComment comment for comment in @model.models

	renderComment: (comment) ->
		view = new CommentListItemView model:comment
		@$el.find('.comment-list').append view.render()

	addComment: ->
		@model.create
			issue_id: @model.issue.get 'id'
			user: app.user
			text: @$el.find('textarea[name=text]').val()

		@$el.find('form').get(0).reset()	

class CommentListItemView extends Backbone.View
	tagName: 'li'

	template: _.template jQuery('#tpl-comment-list-item').text()

	render: (eventName) ->
		@setElement jQuery @template @model.toJSON()

		return @el

class AppRouter extends Backbone.Router
	initialize: (config) ->
		@route '', 'list'
		@route 'issues/:id', 'showIssue'
		@route 'labels/:name', 'showLabel'

		@user = config.user

		@issueCollection = new IssueCollection config.issues
		@list()

	list: ->
		view = new IssueListView model:@issueCollection
		(jQuery '#issue-list').replaceWith view.render()
		@showPanel '#issue-list-panel'

	showIssue: (id) ->
		issue = @issueCollection.get id
		view = new IssueView
			el: jQuery '#issue-details-panel'
			model:issue
		
		view.render()

		@showPanel '#issue-details-panel'

	showPanel: (id) ->
		jQuery('.issue-tracker > .panel:not([id=label-panel])').hide()
		jQuery(id).show()

window.init = (issues) ->
	# FIXME Temporary user, this data should come from the initialisation
	user = 
		id: 1
		name: 'Jelmer'
		email: 'jelmer@ikhoefgeen.nl'

	app = new AppRouter
		user:user
		issues:issues

	# Hide the new-issue panel for now
	jQuery('#new-issue-panel').hide()

	jQuery('#issue-details-panel').hide()

	# Let Backbone do the routing :)
	Backbone.history.start pushState:true

	# Catch all internal links and route them through the app
	jQuery("a:not([href^='http://'])").click (evt) ->
		evt.preventDefault()
		app.navigate (jQuery this).attr('href'), true

	return app