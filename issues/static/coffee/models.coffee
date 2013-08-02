class Issue extends Backbone.Model
	defaults:
		id: null
		title: ''
		description: ''

	initialize: ->
		@comments = new CommentCollection [], issue:this

		@labels = new LabelCollection [], issue:this


class IssueCollection extends Backbone.Collection
	model: Issue
	url: '/api/issues'


# Comments
class Comment extends Backbone.Model
		

class CommentCollection extends Backbone.Collection
	model: Comment

	initialize: (models, options) ->
		@issue = options.issue
		@url = "/api/issues/#{ @issue.get 'id' }/comments"


# Labels
class Label extends Backbone.Model


class LabelCollection extends Backbone.Model
	model: Label