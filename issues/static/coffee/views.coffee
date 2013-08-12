class IssueListItemView extends Backbone.View
	template: jQuery('#tpl-issue-list-item').detach()

	initialize: ->
		@setElement @template.clone().get 0

		@listenTo @model, 'change', @render

		@labelView = new Backbone.CollectionView
			childView: InlineLabelListItemView
			model: @model.labels
			el: @$ '.issue-labels'

	render: (eventName) ->
		@$('.issue-link').attr 'href', "/issues/#{@model.get 'id'}"
		@$('.issue-title').text @model.get 'title'
		@$('.issue-description').text @model.strip 'description'
		@$el.toggleClass 'issue-completed', !! @model.get 'completed'
		@labelView.render()

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

		'dblclick .issue-title': (evt) ->
			evt.preventDefault()
			@$el.addClass 'editable'

		'click .finish-editing-issue-button': (evt) ->
			evt.preventDefault()
			@$('.edit-issue').submit()

		# Finish editing issue button:
		# This submits the data form the edit form and hides it again
		'submit .edit-issue': (evt) ->
			evt.preventDefault()
			@model.save @$('.edit-issue').serializeObject(), patch: yes
			@$el.removeClass 'editable'

		'click .label-issue-button': (evt) ->
			@labelDropdownView.toggle evt.target
	
	initialize: ->
		console.assert @model?, 'IssueView has no model'

		@setElement @template.clone().get 0

		@listenTo @model, 'change', @render

		@commentListView = new CommentListView
			model: @model.comments
			el: @$ '.comment-list'

		@labelListView = new Backbone.CollectionView
			childView: InlineLabelListItemView
			model: @model.labels
			el: @$ '.issue-labels'

		@labelDropdownView = new DropdownLabelListView
			model: app.labelCollection
			selected: @model.labels
			el: @$ '.label-dropdown'

		@model.comments.fetch()

	render: (eventName) ->
		@$('.read-issue .issue-title').text @model.get 'title'
		@$('.read-issue .issue-description').html @model.get 'description'

		@$('.edit-issue .issue-title').val @model.get 'title'
		@$('.edit-issue .issue-description').val @model.get 'description'

		@$el.toggleClass 'loading', !@model.get 'added'
		@$el.toggleClass 'issue-completed', !! @model.get 'completed'

		@commentListView.render()
		@labelListView.render()
		@labelDropdownView.render()

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


class InlineLabelListItemView extends Backbone.View
	tagName: 'span'

	initialize: ->
		@listenTo @model, 'change', @render

	render: ->
		if @model.has 'colour'
			@$el.css
				'color': bestContrastingColour @model.get 'colour'
				'background-color': @model.get 'colour'

		@$el.text @model.get 'name'


class LabelListItemView extends Backbone.View
	tagName: 'li'

	initialize: ->
		@$el.addClass 'list-group-item'
		
		@$el.html '<span class="swatch"></span><a></a>'
		@swatch = @$ '.swatch'
		@link = @$ 'a'
		
		@listenTo @model, 'change', @render

	render: ->
		if @model.has 'colour'
			@swatch.css
				'background-color': @model.get 'colour'

		@link.attr 'href', "/labels/#{encodeURIComponent @model.get 'name'}"
		@link.text @model.get 'name'


class DropdownLabelListItemView extends Backbone.View
	template: jQuery('#tpl-dropdown-label-list-item').detach()

	events:
		# Add or remove a label from the issue
		'change .label-selected': (evt) ->
			if evt.target.checked
				@selected.add @model
			else
				@selected.remove @model

	initialize: ->
		@setElement @template.clone().get 0

		@listenTo @model, 'change', @render

	render: ->
		if @model.has 'colour'
			@$el.css
				'color': bestContrastingColour @model.get 'colour'
				'background-color': @model.get 'colour'

		@$('.label-name').text @model.get 'name'
		@$('.label-selected').attr 'checked', !! @selected.get @model.get 'id'


class DropdownLabelListView extends Backbone.CollectionView
	childView: DropdownLabelListItemView

	template: jQuery('#tpl-dropdown-label-list').detach()

	events:
		'keyup .label-filter': (evt) ->
			if evt.keyCode == 27
				# If the filter is not yet cleared, clear it
				if @filterField.val() != ''
					@filterField.val ''
				# Second press closes the filter field
				else
					@hide()

				evt.preventDefault()

			
			if evt.keyCode == 13
				evt.preventDefault()
				@hide()

			if evt.keyCode == 40
				evt.preventDefault()
				@$('.label-list li:visible input').first().focus()

			defer => @filter @filterField.val()

		'click .create-new-label-button': ->
			label = @model.create
				name: @filterField.val()

			# If creating a label went successfully, add it to the issue
			if label
				@selected.add label

		'keydown .label-list input': (evt) ->
			if evt.keyCode == 40
				evt.preventDefault()
				jQuery(evt.target).closest('li').next('.visible').find('input,button').focus()

			if evt.keyCode == 38
				evt.preventDefault()
				jQuery(evt.target).closest('li').prev('.visible').find('input,button').focus()

			if evt.keyCode == 27
				evt.preventDefault()
				@hide()
	
	initialize: (options) ->
		super options

		@selected = options.selected
		@listenTo @selected, 'add', @updateChildren
		@listenTo @selected, 'remove', @updateChildren

		@setElement @template.clone().get 0
		@filterField = @$ '.label-filter'
		@createLabelButton = @$ '.create-new-label-button'

		@$el.hide()
		jQuery(document.body).append @el

	createChildView: (model) ->
		view = super model
		view.selected = @selected
		return view

	appendChildView: (el) ->
		jQuery(el).addClass 'visible'
		@$('.label-list').append el

	updateChildren: ->
		for cid, child in @children
			child.render()

	filter: (query) ->
		pattern = new RegExp '.*' + query.split('').join('.*') + '.*', 'i'

		for cid, child of @children
			child.$el.toggleClass 'visible', pattern.test child.model.get 'name'
		
		if query != ''
			@createLabelButton.text "Create label '#{query}'"
			@createLabelButton.show()
		else
			@createLabelButton.hide()

	show: (parent) ->
		# Position the popover
		parent_pos = jQuery(parent).offset()

		@$el.css
			top: parent_pos.top + jQuery(parent).height() + 12
			left: parent_pos.left + jQuery(parent).width() / 2 - @$el.width() / 2

		# Clear the filter field
		@filterField.val ''

		# Show all elements
		@filter ''

		# Show the popover
		@$el.show()

		# .. and focus the filter field
		defer => @filterField.focus()

	hide: ->
		@$el.hide()
		@selected.save()

	toggle: (parent) ->
		if @$el.is ':visible'
			@hide()
		else
			@show parent

