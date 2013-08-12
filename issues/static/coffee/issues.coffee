# The app variable is 'global' for this module and contains things like the
# router and the currently logged in user's data.
app = null

# Serializes a form element to a JavaScript object. Note that
# this will fail when a form contains multiple elements with
# the same name.
jQuery.fn.serializeObject = ->
	data = {}
	jQuery(jQuery(this).serializeArray()).each (i, pair) ->
		data[pair.name] = pair.value

	data

# Get an attribute of the model with all the HTML tags stripped.
# Note: don't use this on untrusted input (e.g. still do server
# side cleaning on the input, please!)
Backbone.Model::strip = (attribute) ->
	jQuery("<p>#{@get attribute}</p>").wrap('p').text()

Backbone.Collection::containsWhere = (attributes) ->
	@findWhere attributes is not null

defer = (fn) ->
	setTimeout fn, 1


class Panel
	constructor: (el) ->
		@$el = jQuery el

	render: (view) ->
		if @view? and @view != view
			@view.remove()

		@view = view
		@view.render()
		@view.$el.appendTo @$el

	show: ->
		@$el.show()

	hide: ->
		@$el.hide()


class NewIssuePanel extends Panel
	constructor: (el, @model) ->
		super el
		@$el.on 'submit', 'form', (evt) =>
			# Prevent the form from actually being submitted
			evt.preventDefault()
			
			data = jQuery(evt.target).serializeObject()

			# When the issue is saved (and has an id), go to it.
			options =
				success: (issue) ->
					app.navigate "/issues/#{issue.get 'id'}", true

			# Clear the form if the issue was created
			issue = new Issue
			if issue.save data, options
				@model.add issue
				evt.target.reset()


class AppRouter extends Backbone.Router
	initialize: (config) ->
		@route '', ->
			@navigate '/todo', true

		@route /^issues\/new$/, 'newIssue'
		@route /^issues\/(\d+)$/, 'showIssue'
		@route /^labels\/([^\/]+)$/, 'listIssuesWithLabel'
		@route /^todo$/, 'listTodoIssues'
		@route /^archive$/, 'listAllIssues'

		@user = config.user

		@issueCollection = new IssueCollection config.issues
		@issueCollection.url = '/api/issues' # (Cannot be passed as an option
			# because then it will also be passed to all the issues preloaded)

		@todoCollection = @issueCollection.subcollection
			filter: (issue) ->
				not issue.get 'completed'

		# Give the subcollection its own API endpoint for efficient fetching of
		# issues.
		@todoCollection.url = '/api/issues/todo'
		
		@labelCollection = new LabelCollection config.labels

		@panels =
			newIssue:   new NewIssuePanel '#new-issue-panel', @issueCollection
			showIssue:  new Panel '#issue-details-panel'
			listIssues: new Panel '#issue-list-panel'

		@labelListView = new Backbone.CollectionView
			childView: LabelListItemView
			model: @labelCollection
			el: jQuery('#label-panel .label-list').get 0

		@labelListView.render()

		# Hide all panels
		@showPanel null

	listTodoIssues: ->
		@todoCollection.fetch()
		@listIssues @todoCollection

	listAllIssues: ->
		@issueCollection.fetch()
		@listIssues @issueCollection

	listIssuesWithLabel: (label) ->
		collection = @issueCollection.subcollection
			filter: (issue) ->
				issue.labels.containsWhere name: label

		collection.url = "/api/labels/#{encodeURIComponent(label)}"
		collection.fetch()
		@listIssues collection

	listIssues: (collection) ->
		view = new IssueListView
			model: collection

		@showPanel 'listIssues', view

	newIssue: ->
		@showPanel 'newIssue'

	showIssue: (id) ->
		# First, try to get the issue from our global collection
		issue = @issueCollection.get id

		# If it isn't there (collection not yet loaded or something) try to
		# fetch it manually
		if not issue
			issue = new Issue id: id
			issue.fetch()
		
		# Give it a view and render it
		view = new IssueView
			model: issue

		@showPanel 'showIssue', view

	showPanel: (id, view) ->
		for name, panel of @panels
			if name == id
				if view? then panel.render view
				panel.show()
			else
				panel.hide()


window.init = (data) ->
	app = new AppRouter
		user: data.user
		issues: data.issues
		labels: data.labels

	# Hide the new-issue panel for now
	jQuery('#new-issue-panel').hide()

	jQuery('#issue-details-panel').hide()

	# Let Backbone do the routing :)
	Backbone.history.start pushState:true

	# Catch all internal links and route them through the app
	jQuery(document.body).on 'click', 'a', (evt) ->
		# This one is not part of the app, reroute!
		if jQuery(this).data('external')
			return;

		evt.preventDefault()
		app.navigate (jQuery this).attr('href'), true

	return app