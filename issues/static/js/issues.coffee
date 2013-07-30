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

		# Refresh comments collection (till we have push requests ;) )
		@model.comments.fetch()

	render: (eventName) ->
		(jQuery @el).html(@template @model.toJSON()).show()

		(jQuery @el).find('.comments').replaceWith @commentListView.render()

		return @el

class CommentCollection extends Backbone.Collection
	model: Comment

	initialize: (models, options) ->
		@issue = options.issue
		@url = "/api/issues/#{ @issue.get 'id' }/comments"

class CommentListView extends Backbone.View	
	template: _.template jQuery('#tpl-comment-list').text()

	initialize: ->
		@model.on 'add', @renderComment, this

	render: (eventName) ->
		@el = jQuery(@template issue:@model.issue)

		# submit callback
		addComment = =>
			@model.create
				issue_id: @model.issue.get 'id'
				user: app.user
				text: @el.find('textarea[name=text]').val()

			@el.find('form').get(0).reset()

		# catch the submit-event of the comment form
		@el.find('form').submit (evt) ->
			addComment()
			evt.preventDefault()

		# Also catch the cmd/ctrl+enter key combination on the textarea
		@el.find('textarea[name=text]').keydown (evt) ->
			if evt.keyCode == 13 and (evt.ctrlKey or evt.metaKey)
				addComment()
			
		
		# Render all the comments that are already in the model
		@renderComment comment for comment in @model.models

		return @el

	renderComment: (comment) ->
		view = new CommentListItemView model:comment
		@el.find('.comment-list').append view.render()

class CommentListItemView extends Backbone.View
	tagName: 'li'

	template: _.template jQuery('#tpl-comment-list-item').text()

	render: (eventName) ->
		@el = jQuery @template @model.toJSON()

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

	showIssue: (id) ->
		issue = @issueCollection.get id
		view = new IssueView model:issue
		(jQuery '#issue-details').replaceWith view.render()

window.init = (issues) ->
	# FIXME Temporary user, this data should come from the initialisation
	user = 
		id: 1
		name: 'Jelmer'
		email: 'jelmer@ikhoefgeen.nl'

	app = new AppRouter
		user:user
		issues:issues

	# Let Backbone do the routing :)
	Backbone.history.start pushState:true

	# Catch all internal links and route them through the app
	jQuery("a:not([href^='http://'])").click (evt) ->
		evt.preventDefault()
		app.navigate (jQuery this).attr('href'), true

	return app