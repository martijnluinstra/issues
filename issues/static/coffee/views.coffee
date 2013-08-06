class IssueListItemView extends Backbone.View
	tagName: 'li'

	template: _.template jQuery('#tpl-issue-list-item').text()

	initialize: ->
		@$el.addClass 'list-group-item'

	render: (eventName) ->
		@$el.html @template
			id: @model.escape 'id'
			title: @model.escape 'title'
			description: @model.strip 'description'


class IssueListView extends Backbone.CollectionView
	childView: IssueListItemView

	initialize: ->
		super()
		@$el.addClass 'issue-list'

class IssueView extends Backbone.View
	template: jQuery('#tpl-issue-details-panel').detach()

	events:
		# catch the submit-event of the comment form
		'submit form': (evt) ->
			evt.preventDefault()
			@addComment()

		# Also catch the cmd/ctrl+enter key combination on the textarea
		'keypress textarea': (evt) ->
			if evt.keyCode == 13 and evt.ctrlKey
				evt.preventDefault()
				@addComment()

	initialize: ->
		@setElement @template.clone().get 0

		@listenTo @model, 'change', @render

		@commentListView = new CommentListView
			model: @model.comments
			el: @$ '.comment-list'

		@model.comments.fetch()

	render: (eventName) ->
		@$('.issue-title').text @model.get 'title'
		@$('.issue-description').html @model.get 'description'
		@commentListView.render()

	addComment: ->
		comment =
			issue_id: @model.get 'id'
			user: app.user
			text: @$('.comments form textarea[name=text]').val(),
		
		options = 
			validate: yes

		if @model.comments.create comment, options
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
