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


jQuery.fn.offsetTo = (parent) ->
	el = jQuery this
	position =
		top: 0
		left: 0

	while el.length and (el.get 0) != parent
		p = el.position()
		position.top += p.top
		position.left += p.left
		el = el.parent()

	return position


jQuery.fn.isOrIsChildOf = (parent) ->
	el = jQuery this

	loop
		if (el.get 0) == parent
			return yes

		el = el.parent()
		
		if not el.length
			return no


jQuery(document).ajaxStart ->
	NProgress.start()

jQuery(document).ajaxStop ->
	NProgress.done()


# Get an attribute of the model with all the HTML tags stripped.
# Note: don't use this on untrusted input (e.g. still do server
# side cleaning on the input, please!)
Backbone.Model::strip = (attribute) ->
	jQuery("<p>#{@get attribute}</p>").wrap('p').text()

Backbone.Collection::containsWhere = (attributes) ->
	@findWhere attributes isnt null

defer = (fn) ->
	setTimeout fn, 1

loadPopup = (url) ->
	overlay = jQuery '<div class="overlay hidden"></div>'

	catchEscapeKey = (evt) ->
		if evt.keyCode == 27
			evt.preventDefault()
			evt.stopPropagation()
			hide()

	hide = ->
		# Remove the popup from view (animation)
		overlay.addClass 'hidden'

		# Remove DOM event listeners
		jQuery(document).off 'keyup', catchEscapeKey

		# Schedule cleanup
		setTimeout (-> overlay.remove()), 500

	# Clicking on the overlay dismisses the overlay
	overlay.click (evt) ->
		hide() if evt.target == overlay.get 0

	# Pressing the [escape]-button dismisses the overlay
	jQuery(document).on 'keyup', catchEscapeKey

	jQuery(document.body).append overlay

	jQuery.ajax
		url: url
		success: (response) ->
			panel = jQuery(response).filter '.panel'
			panel.addClass 'popup'

			# add a close button to the popup
			closeButton = panel.find('.panel-title').append '<button type="button" class="close" data-dismiss="popup">&times;</button>'
			closeButton.click hide

			# mark all links as external
			panel.find('a[href]').attr 'rel', 'external'

			# add the popup to the overlay
			overlay.append panel
			defer -> overlay.removeClass 'hidden'


class Panel
	constructor: (el) ->
		# Mixin events
		_.extend this, Backbone.Events

		@$el = jQuery el

	render: (view) ->
		# Clear the current view (if necessary)
		@clear()
		
		# Set-up and render the new view
		@view = view
		@view.render()
		@view.$el.appendTo @$el

		@trigger 'render', @view
		# Delay adding the class 'visible' to enforce css transitions
		defer => @$el.addClass 'visible'

	clear: ->
		if @view?
			@view.remove()
			@view = null

	hide: ->
		if not @isVisible()
			return

		@trigger 'hide', @view
		@$el.removeClass 'visible'
		# Remove the view from the DOM (so it can't receive updates and catch
		# events while no longer visible nor active.)
		setTimeout (=> @clear), 500

	isVisible: ->
		return @$el.hasClass 'visible'


# An Overlay Panel is just a panel that can be dismissed by clicking on the
# backgrond or pressing escape.
class OverlayPanel extends Panel
	constructor: (el) ->
		super el

		@$el.on 'click', (evt) =>
			if evt.target == @$el.get 0
				@hide()

		jQuery(document).on 'keyup', (evt) =>
			if evt.keyCode == 27 and @isVisible()
				evt.stopPropagation()
				evt.preventDefault()
				@hide()		

class AppRouter extends Backbone.Router
	initialize: (config) ->
		window.app = this;

		@route '', ->
			@navigate '/todo', true

		@route /^issues\/new$/, 'newIssue'
		@route /^issues\/(\d+)$/, 'showIssue'
		@route /^labels\/([^\/]+)$/, 'listIssuesWithLabel'
		@route /^inbox$/, 'listInboxIssues'
		@route /^todo$/, 'listTodoIssues'
		@route /^archive$/, 'listAllIssues'

		@user = config.user

		@labelCollection = new LabelCollection config.labels

		@issueCollection = new IssueCollection config.issues,
			parse: yes

		@issueCollection.url = '/api/issues' # (Cannot be passed as an option
			# because then it will also be passed to all the issues preloaded)

		@todoCollection = @issueCollection.subcollection
			filter: (issue) ->
				not issue.get 'completed'

		@inboxCollection = @issueCollection.subcollection
			filter: (issue) ->
				not issue.get 'accepted'

		# Give the subcollection its own API endpoint for efficient fetching of
		# issues.
		@todoCollection.url = '/api/issues/todo'

		@inboxCollection.url = '/api/issues/inbox'
		
		@listPanel = new Panel '#list-panel'

		@detailPanel = new OverlayPanel '#detail-panel'
		
		@labelListView = new Backbone.CollectionView
			childView: LabelListItemView
			model: @labelCollection
			el: jQuery('#label-panel .label-list').get 0

		@labelListView.render()

		@listTodoIssues()

		# Set the title of the window to the last rendered panel.
		setTitle = (view) ->
			window.document.title = "#{view.title()} – Issues"

		@listPanel.on 'render', setTitle
		@detailPanel.on 'render', setTitle

		@listPanel.on 'render', =>
			@detailPanel.hide()

		# When the details panel is hidden, return focus, url and title to
		# the active list panel.
		@detailPanel.on 'hide', =>
			app.navigate @listPanel.view.url
			setTitle @listPanel.view

	listTodoIssues: ->
		@todoCollection.fetch()
		view = new IssueListView
			model: @todoCollection
		view.url = '/todo'
		view.title = -> 'Todo'
		@listPanel.render view

	listInboxIssues: ->
		@inboxCollection.fetch()
		view = new IssueListView
			model: @inboxCollection
		view.url = '/inbox'
		view.title = -> 'Inbox'
		@listPanel.render view

	listAllIssues: ->
		@issueCollection.fetch()
		view = new IssueListView
			model: @issueCollection
		view.url = '/archive'
		view.title = -> 'Archive'
		@listPanel.render view

	listIssuesWithLabel: (name) ->
		label = @labelCollection.findWhere name: name

		collection = @issueCollection.subcollection
			filter: (issue) ->
				issue.labels.containsWhere id: label.get 'id'

		collection.url = "/api/labels/#{label.get 'id'}"
		collection.fetch()
		
		view = new IssueListView
			model: collection
		view.url = '/labels/' + encodeURIComponent name
		view.title = -> name
		@listPanel.render view

	newIssue: ->
		view = new NewIssueView
			model: @issueCollection
		view.url = '/issues/new'
		@detailPanel.render view

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

		setTimeout (-> issue.mark_read()), 1000


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
		if jQuery(this).attr('rel') == 'external'
			return;

		if jQuery(this).attr('rel') == 'popup'
			evt.preventDefault()
			return loadPopup jQuery(this).attr 'href'

		evt.preventDefault()
		app.navigate (jQuery(this).attr 'href'), true

	return app