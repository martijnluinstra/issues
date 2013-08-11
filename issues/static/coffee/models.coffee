class Issue extends Backbone.Model
	defaults:
		id: null
		title: ''
		description: ''
		labels: []

	urlRoot: '/api/issues'

	initialize: ->
		@comments = new CommentCollection [],
			url: =>
				"#{@url()}/comments"

		@labels = new LabelCollection (@get 'labels'),
			url: =>
				"#{@url()}/labels"


class IssueCollection extends Backbone.Collection
	model: Issue


# Comments
class Comment extends Backbone.Model
	validate: (attr, options) ->
		if (jQuery.trim attr.text) == ''
			return 'The comment has no text'
		

class CommentCollection extends Backbone.Collection
	model: Comment


# Labels
class Label extends Backbone.Model
	defaults:
		id: null
		name: ''
		colour: 'grey'

	urlRoot: '/api/labels'


class LabelCollection extends Backbone.Collection
	model: Label

	save: ->
		Backbone.sync 'update', this,
			url: @url()
