class Issue extends Backbone.Model
	defaults:
		id: null
		title: ''
		description: ''

	initialize: ->
		@comments = new CommentCollection
		@labels = new LabelCollection

		@on 'change:id', @updateURLs, this
		@updateURLs()

	updateURLs: ->
		@comments.url = "/api/issues/#{ @get 'id' }/comments"
		@labels.url = "/api/issues/#{ @get 'id' }/labels"


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