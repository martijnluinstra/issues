class Issue extends Backbone.Model
	defaults:
		id: null
		title: ''
		description: ''

	urlRoot: '/api/issues'

	initialize: ->
		@comments = new CommentCollection [],
			url: =>
				"#{@urlRoot}/#{@get 'id'}/comments"

		@labels = new LabelCollection [],
			url: =>
				"#{@urlRoot}/#{@get 'id'}/labels"


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


class LabelCollection extends Backbone.Model
	model: Label