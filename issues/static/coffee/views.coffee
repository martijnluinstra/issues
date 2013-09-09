templatify = (id) ->
	element = jQuery "##{id}"
	element.detach()
	element.removeAttr 'id'
	return -> element.clone().get 0

class IssueListItemView extends Backbone.View
	template: templatify 'tpl-issue-list-item'

	initialize: ->
		@setElement @template()

		@listenTo @model, 'change', @render

		@labelView = new Backbone.CollectionView
			childView: InlineLabelListItemView
			model: @model.labels
			el: @$ '.issue-labels'

	render: (eventName) ->
		@$('.issue-link').attr 'href', "/issues/#{@model.get 'id'}"
		@$('.issue-title').text @model.get 'title'
		@$('.issue-description').text @model.strip 'description'
		
		@$el.toggleClass 'issue-missed-deadline', (@model.has 'deadline') and \
			not (@model.get 'completed') and \
			moment(@model.get 'deadline').isBefore()
		@$el.toggleClass 'issue-completed', !! @model.get 'completed'
		@$el.toggleClass 'issue-is-public', !! @model.get 'public'
		@$el.toggleClass 'issue-is-private', ! @model.get 'public'
		
		@labelView.render()

	isSelected: ->
		@$('input[type=checkbox]').get(0).checked

	remove: ->
		@labelView.remove()
		super()


class IssueListView extends Backbone.CollectionView
	childView: IssueListItemView

	template: templatify 'tpl-issue-list-panel'

	title: -> 'Issues'

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
		@setElement @template()

	# Override CollectionView's appendChildView to append it to the
	# issue-list element, not the root element.
	appendChildView: (el) ->
		@$('.issue-list').append el


class IssueView extends Backbone.View
	template: templatify 'tpl-issue-details-panel'

	title: -> @model.get 'title'

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

			data = @$('.edit-issue').serializeObject()
			data.deadline = if data.deadline? then moment data.deadline else null
			data.public = data.public?

			@model.save data, patch: yes
			@$el.removeClass 'editable'

		'click .label-issue-button': (evt) ->
			@labelDropdownView.toggle evt.target
	
	initialize: ->
		console.assert @model?, 'IssueView has no model'

		@setElement @template()

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

		@$el.append @labelDropdownView.el

		@model.comments.fetch()

		@$el.find('.edit-issue .issue-deadline').pickadate
			firstDay: 1
			format: 'yyyy/mm/dd'

	render: (eventName) ->
		@$('.read-issue .issue-title').text @model.get 'title'
		@$('.read-issue .issue-description').html @model.get 'description'

		if @model.has 'added'
			@$('.read-issue .issue-added').text "Added #{moment(@model.get 'added').fromNow()} by #{@model.get('owner').name}"
			@$('.read-issue .issue-added').attr 'title', moment(@model.get 'added').calendar()

		@$('.read-issue .issue-deadline').text if @model.has 'deadline' then "Deadline #{moment(@model.get 'deadline').fromNow()}" else "No deadline"
		@$('.read-issue .issue-deadline').attr 'title', if @model.has 'deadline' then moment(@model.get 'deadline').calendar() else ""
		@$('.read-issue .issue-visibility').text if @model.get 'public' then 'Public issue' else 'Private issue'

		@$('.edit-issue .issue-title').val @model.get 'title'
		@$('.edit-issue .issue-description').val @model.get 'description'
		@$('.edit-issue .issue-deadline').val if @model.has 'deadline' then moment(@model.get 'deadline').format 'YYYY-MM-DD'
		@$('.edit-issue .issue-visibility').get(0).checked = @model.get 'public'

		@$el.toggleClass 'loading', !@model.get 'added'
		@$el.toggleClass 'issue-completed', !! @model.get 'completed'
		@$el.toggleClass 'issue-is-public', !! @model.get 'public'
		@$el.toggleClass 'issue-is-private', ! @model.get 'public'

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
		@labelListView.remove()
		@labelDropdownView.remove()
		super()


class NewIssueView extends Backbone.View
	template: templatify 'tpl-new-issue-panel'

	title: -> 'New Issue'

	events:
		'submit form': (evt) ->
			# Prevent the form from actually being submitted
			evt.preventDefault()
			
			data = jQuery(evt.target).serializeObject()

			# When the issue is saved (and has an id), go to it.
			options =
				success: (issue) ->
					window.app.navigate "/issues/#{issue.get 'id'}", true

			# Clear the form if the issue was created
			issue = new Issue
			if issue.save data, options
				@model.add issue
				evt.target.reset()

	initialize: ->
		@setElement @template()

	render: ->
		# Auto-focus the title field, but only after a delay used for the
		# animation of the OverlayPanel which shows this view. (This feels
		# quite dirty. Fix me.)
		setTimeout (=> @$('input[name=title]').get(0).focus()), 500


class CommentListItemView extends Backbone.View
	template: templatify 'tpl-comment-list-item'

	initialize: ->
		@setElement @template()
		@listenTo @model, 'change', @render

	render: (eventName) ->
		@$('time[pubdate]').text moment(@model.get 'time').fromNow()
		@$('time[pubdate]').attr 'title', moment(@model.get 'time').calendar()
		@$('.gravatar').attr 'src', (@model.get 'user').gravatar
		@$('.comment-text').text @model.get 'text'
		@$('.user-name').text (@model.get 'user').name


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
	template: templatify 'tpl-label-list-item'

	events:
		# show label context menu when the swatch is clicked
		'click .swatch': (evt) ->
			if @contextMenu and @contextMenu.isVisible()
				@contextMenu.hide()
			else
				@contextMenu = new LabelContextMenu model: @model
				@contextMenu.render()
				@contextMenu.show evt.target

	initialize: ->
		@setElement @template()
		@listenTo @model, 'change', @render

	render: ->
		if @model.has 'colour'
			@$('.swatch').css
				'background-color': @model.get 'colour'

		@$('.label-link').attr 'href', "/labels/#{encodeURIComponent @model.get 'name'}"
		@$('.label-name').text @model.get 'name'


class DropdownLabelListItemView extends Backbone.View
	template: templatify 'tpl-dropdown-label-list-item'

	events:
		# Add or remove a label from the issue
		'change .label-selected': (evt) ->
			if evt.target.checked
				@selected.add @model
			else
				@selected.remove @model

	initialize: ->
		@setElement @template()

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

	template: templatify 'tpl-dropdown-label-list'

	events:
		'keyup .label-filter': (evt) ->
			if evt.keyCode == 27
				# If the filter is not yet cleared, clear it
				if @filterField.val() != ''
					@filterField.val ''
				# Second press closes the filter field
				else
					@hide()

				evt.stopPropagation()
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

		@setElement @template()
		@filterField = @$ '.label-filter'
		@createLabelButton = @$ '.create-new-label-button'

		@blurCallback = (evt) =>
			if @isVisible() and not jQuery(evt.target).isOrIsChildOf @el
				@hide()

		jQuery(document).on 'click', @blurCallback

		@$el.hide()

	remove: ->
		jQuery(document).off 'click', @blurCallback
		super()

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

	isVisible: ->
		@$el.is ':visible'

	show: (parent) ->
		# Clear the filter field
		@filterField.val ''

		# Show all elements
		@filter ''

		# Show the popover
		@$el.show()

		# Position the popover
		parent_pos = jQuery(parent).offsetTo @el.parentNode

		@$el.css
			top: parent_pos.top + jQuery(parent).height() + 12
			left: parent_pos.left + jQuery(parent).width() / 2 - @$el.width() / 2

		# .. and focus the filter field
		defer => @filterField.focus()

	hide: ->
		@$el.hide()
		@selected.save()

	toggle: (parent) ->
		if @isVisible()
			@hide()
		else
			@show parent

class LabelContextMenu extends Backbone.View
	events:
		'change input[name=label-colour]': (evt) ->
			@model.save colour: evt.target.value

		'click .rename-label-button': (evt) ->
			evt.preventDefault()

			if name = prompt 'Label name', @model.get 'name'
				@model.save name: name

			@hide()

		'click .delete-label-button': (evt) ->
			evt.preventDefault()

			if confirm "Do you want to delete the label '#{@model.get 'name'}'?"
				@model.destroy()

			@hide()

	template: '
		<div class="popover bottom label-context-menu">
			<div class="arrow"></div>
			<div class="popover-content">
				<div class="label-colour">
					<input type="radio" name="label-colour" value="#7bd148" id="label-colour-7bd148">
					<label for="label-colour-7bd148" style="background-color: #7bd148">Green</label>
					
					<input type="radio" name="label-colour" value="#5484ed" id="label-colour-5484ed">
					<label for="label-colour-5484ed" style="background-color: #5484ed">Bold blue</label>
					
					<input type="radio" name="label-colour" value="#a4bdfc" id="label-colour-a4bdfc">
					<label for="label-colour-a4bdfc" style="background-color: #a4bdfc">Blue</label>
					
					<input type="radio" name="label-colour" value="#46d6db" id="label-colour-46d6db">
					<label for="label-colour-46d6db" style="background-color: #46d6db">Turquoise</label>
					
					<input type="radio" name="label-colour" value="#7ae7bf" id="label-colour-7ae7bf">
					<label for="label-colour-7ae7bf" style="background-color: #7ae7bf">Light green</label>
					
					<input type="radio" name="label-colour" value="#51b749" id="label-colour-51b749">
					<label for="label-colour-51b749" style="background-color: #51b749">Bold green</label>
					
					<input type="radio" name="label-colour" value="#fbd75b" id="label-colour-fbd75b">
					<label for="label-colour-fbd75b" style="background-color: #fbd75b">Yellow</label>
					
					<input type="radio" name="label-colour" value="#ffb878" id="label-colour-ffb878">
					<label for="label-colour-ffb878" style="background-color: #ffb878">Orange</label>
					
					<input type="radio" name="label-colour" value="#ff887c" id="label-colour-ff887c">
					<label for="label-colour-ff887c" style="background-color: #ff887c">Red</label>
					
					<input type="radio" name="label-colour" value="#dc2127" id="label-colour-dc2127">
					<label for="label-colour-dc2127" style="background-color: #dc2127">Bold red</label>
					
					<input type="radio" name="label-colour" value="#dbadff" id="label-colour-dbadff">
					<label for="label-colour-dbadff" style="background-color: #dbadff">Purple</label>
					
					<input type="radio" name="label-colour" value="#e1e1e1" id="label-colour-e1e1e1">
					<label for="label-colour-e1e1e1" style="background-color: #e1e1e1">Gray</label>
				</div>
				<ul class="menu">
					<li><a href="#" class="rename-label-button">Rename Label…</a></li>
					<li><a href="#" class="delete-label-button">Delete Label…</a></li>
				</ul>
			</div>
		</div>'

	initialize: (options) ->
		@setElement jQuery(@template).get 0
		@$el.hide()

		jQuery(document.body).append @el
		jQuery(document.body).on 'click', @blurCallback

	render: ->
		current_colour = @model.get 'colour'
		@$el.find('input[name=label-colour]').each ->
			not @checked = @value == current_colour

	isVisible: ->
		@$el.is ':visible'

	show: (parent) ->
		@trigger = parent

		@$el.show()
		
		parent_pos = jQuery(parent).offset()
		@$el.css
			top: parent_pos.top + jQuery(parent).height() + 12
			left: parent_pos.left + jQuery(parent).width() / 2 - @$el.width() / 2

	hide: ->
		@remove()

	remove: ->
		jQuery(document).off 'click', @blurCallback
		super()

	blurCallback: (evt) =>
		if not @isVisible()
			return

		if jQuery(evt.target).isOrIsChildOf @el
			return 

		if jQuery(evt.target).isOrIsChildOf @trigger
			return
		else
			@hide()

