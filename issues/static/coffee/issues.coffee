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
			el: @panels.listIssues.$el.find('.issue-list').get 0
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


window.init = (data) ->
	app = new AppRouter
		user: data.user
		issues: data.issues

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