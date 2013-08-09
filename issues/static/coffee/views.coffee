class IssueListItemView extends Backbone.View
	tagName: 'li'

	template: _.template jQuery('#tpl-issue-list-item').text()

	initialize: ->
		@listenTo @model, 'change', @render

	render: (eventName) ->
		@$el.html @template
			id: @model.escape 'id'
			title: @model.escape 'title'
			description: @model.strip 'description'

		@$el.addClass 'list-group-item'
		@$el.toggleClass 'issue-completed', !! @model.get 'completed'

	isSelected: ->
		@$('input[type=checkbox]').get(0).checked


class IssueListView extends Backbone.CollectionView
	childView: IssueListItemView

	template: jQuery('#tpl-issue-list-panel').detach()

	events:
		# 'Close' selection button
		'click .close-issues-button': (evt) ->
			evt.preventDefault()

			for cid, child of @children
				if child.isSelected()
					child.model.save (completed: yes), patch: yes

	initialize: ->
		# Initialize the CollectionView (register model listeners)
		super()

		# Create the actual DOM by cloning our template
		@setElement @template.clone().get 0

	# Override CollectionView's appendChildView to append it to the
	# issue-list element, not the root element.
	appendChildView: (el) ->
		@$('.issue-list').append el


class IssueView extends Backbone.View
	template: jQuery('#tpl-issue-details-panel').detach()

	events:
		# catch the submit-event of the comment form
		'submit .comments form': (evt) ->
			evt.preventDefault()
			@addComment()

		# Also catch the cmd/ctrl+enter key combination on the textarea
		'keypress textarea': (evt) ->
			if evt.keyCode == 13 and evt.ctrlKey
				evt.preventDefault()
				@addComment()

		# Close issue button
		'click .close-issue-button': (evt) ->
			evt.preventDefault()
			@model.save ('completed': yes), patch: yes

		# Reopen issue button
		'click .reopen-issue-button': (evt) ->
			evt.preventDefault()
			@model.save ('completed': no), patch: yes

		# Edit issue button:
		# This causes the edit form to appear
		'click .edit-issue-button': (evt) ->
			evt.preventDefault()
			@$el.addClass 'editable'

		# Finish editing issue button:
		# This submits the data form the edit form and hides it again
		'submit .edit-issue': (evt) ->
			evt.preventDefault()
			@model.save @$('.edit-issue').serializeObject(), patch: yes
			@$el.removeClass 'editable'
	
	initialize: ->
		console.assert @model?, 'IssueView has no model'

		@setElement @template.clone().get 0

		@listenTo @model, 'change', @render

		@commentListView = new CommentListView
			model: @model.comments
			el: @$ '.comment-list'

		@model.comments.fetch()

	render: (eventName) ->
		@$('.read-issue .issue-title').text @model.get 'title'
		@$('.read-issue .issue-description').html @model.get 'description'

		@$('.edit-issue .issue-title').val @model.get 'title'
		@$('.edit-issue .issue-description').val @model.get 'description'

		@$el.toggleClass 'issue-completed', !! @model.get 'completed'
		@commentListView.render()

	addComment: ->
		data =
			issue_id: @model.get 'id'
			user: app.user
			text: @$('.comments form textarea[name=text]').val(),
		
		options = 
			validate: yes

		if @model.comments.create data, options
			@$('.comments form').get(0).reset()

	remove: ->
		@commentListView.remove()
		super()


class CommentListItemView extends Backbone.View
	tagName: 'li'

	template: _.template jQuery('#tpl-comment-list-item').text()

	initialize: ->
		@listenTo @model, 'change', @render

	render: (eventName) ->
		@$el.html @template @model.toJSON()


class CommentListView extends Backbone.CollectionView
	childView: CommentListItemView
