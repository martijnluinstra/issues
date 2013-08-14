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
		# Mixin events
		_.extend this, Backbone.Events

		@$el = jQuery el

	render: (view) ->
		if @view? and @view != view
			@view.remove()

		if @view != view
			@view = view
			@view.render()
			@view.$el.appendTo @$el

		@trigger 'render'
		@show()

	show: ->
		@trigger 'show'
		@$el.show()

	hide: ->
		@trigger 'hide'
		@$el.hide()


class AppRouter extends Backbone.Router
	initialize: (config) ->
		window.app = this;
		
		@route '', ->
			@navigate '/todo', true

		@route /^issues\/new$/, 'newIssue'
		@route /^issues\/(\d+)$/, 'showIssue'
		@route /^labels\/([^\/]+)$/, 'listIssuesWithLabel'
		@route /^todo$/, 'listTodoIssues'
		@route /^archive$/, 'listAllIssues'

		@user = config.user

		@labelCollection = new LabelCollection config.labels

		@issueCollection = new IssueCollection config.issues
		@issueCollection.url = '/api/issues' # (Cannot be passed as an option
			# because then it will also be passed to all the issues preloaded)

		@todoCollection = @issueCollection.subcollection
			filter: (issue) ->
				not issue.get 'completed'

		# Give the subcollection its own API endpoint for efficient fetching of
		# issues.
		@todoCollection.url = '/api/issues/todo'
		
		@listPanel = new Panel '#list-panel'

		@detailPanel = new Panel '#detail-panel'
		
		@labelListView = new Backbone.CollectionView
			childView: LabelListItemView
			model: @labelCollection
			el: jQuery('#label-panel .label-list').get 0

		@labelListView.render()

		@listPanel.on 'render', =>
			@detailPanel.hide()

	listTodoIssues: ->
		@todoCollection.fetch()
		@listIssues @todoCollection

	listAllIssues: ->
		@issueCollection.fetch()
		@listIssues @issueCollection

	listIssuesWithLabel: (name) ->
		label = @labelCollection.findWhere name: name

		collection = @issueCollection.subcollection
			filter: (issue) ->
				issue.labels.containsWhere id: label.get 'id'

		collection.url = "/api/labels/#{label.get 'id'}"
		collection.fetch()
		@listIssues collection

	listIssues: (collection) ->
		@listPanel.render new IssueListView
			model: collection

	newIssue: ->
		@detailPanel.render new NewIssueView
			model: @issueCollection

	showIssue: (id) ->
		# First, try to get the issue from our global collection
		issue = @issueCollection.get id

		# If it isn't there (collection not yet loaded or something) try to
		# fetch it manually
		if not issue
			issue = new Issue id: id
			issue.fetch()
		
		# Give it a view and render it
		@detailPanel.render new IssueView
			model: issue


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