# The app variable is 'global' for this module and contains things like the
# router and the currently logged in user's data.
app = null

jQuery.fn.serializeObject = ->
	data = {}
	jQuery(jQuery(this).serializeArray()).each (i, pair) ->
		data[pair.name] = pair.value

	data

class Issue extends Backbone.Model
	defaults:
		id: null
		title: ''
		description: ''

	initialize: ->
		@comments = new CommentCollection [], issue:this

class Comment extends Backbone.Model

class Label extends Backbone.Model

class IssueCollection extends Backbone.Collection
	model: Issue

	url: '/api/issues'

class IssueListView extends Backbone.View
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
	initialize: ->
		@model.comments.fetch()

	render: (eventName) ->
		console.log 'rending to', @$el.get(0)

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

class Panel
	constructor: (el) ->
		@$el = jQuery el

	show: ->
		@$el.show()

	hide: ->
		@$el.hide()

class NewIssuePanel extends Panel
	constructor: (el, @model) ->
		super el
		@$el.on 'submit', 'form', (evt) =>
			evt.preventDefault()
			@createIssue jQuery(evt.target).serializeObject()
			evt.target.reset()

	createIssue: (data) ->
		@model.create data,
			wait: yes
			success: (model, reponse) ->
				model.set 'id', response

class AppRouter extends Backbone.Router
	initialize: (config) ->
		@route '', 'list'
		@route /^issues\/new$/, 'newIssue'
		@route /^issues\/(\d+)$/, 'showIssue'
		@route /^labels\/([a-zA-Z0-9-]+)$/, 'showLabel'

		@user = config.user

		@issueCollection = new IssueCollection config.issues

		@panels =
			newIssue:   new NewIssuePanel '#new-issue-panel', @issueCollection
			showIssue:  new Panel '#issue-details-panel'
			listIssues: new Panel '#issue-list-panel'

		# Hide all panels
		@showPanel null

		@list()

	list: ->
		view = new IssueListView
			el: @panels.listIssues.$el.find('.issue-list').get(0)
			model: @issueCollection
		view.render()
		@showPanel 'listIssues'

	newIssue: ->
		@showPanel 'newIssue'

	showIssue: (id) ->
		issue = @issueCollection.get id
		view = new IssueView
			el: @panels.showIssue.$el
			model: issue
		
		view.render()

		@showPanel 'showIssue'

	showPanel: (id) ->
		for name, panel of @panels
			if name == id then panel.show() else panel.hide()


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
	jQuery(document.body).on 'click', 'a', (evt) ->
		evt.preventDefault()
		app.navigate (jQuery this).attr('href'), true

	return app