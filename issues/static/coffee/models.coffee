class Issue extends Backbone.Model
	defaults:
		id: null
		title: ''
		description: ''
		owner: null
		public: no
		deadline: null
		added: null
		modified: null
		completed: null
		labels: []
		comments: []

	urlRoot: '/api/issues'

	initialize: ->
		@comments = new CommentCollection (@get 'comments'),
			url: =>
				"#{@url()}/comments"

		# This bit of ugly code is there to make sure all the labels used in the
		# application are the same instances. So now when you destroy a label,
		# it is deleted from all the issues their label collections as well.
		label_ids = _.pluck (@get 'labels'), 'id'

		labels = window.app.labelCollection.filter (label) ->
			_.contains label_ids, label.get 'id'

		@labels = new LabelCollection labels,
			url: =>
				"#{@url()}/labels"
	
	parse: (response, options) ->
		if response.deadline?
			response.deadline = moment response.deadline

		if response.added?
			response.added = moment response.added

		if response.modified?
			response.modified = moment response.modified

		if response.completed?
			response.completed = moment response.completed

		return response


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
		colour: null

	urlRoot: '/api/labels'


class LabelCollection extends Backbone.Collection
	model: Label

	isDirty: no

	initialize: ->
		@on 'add', @markDirty, this
		@on 'remove', @markDirty, this

	markDirty: ->
		@isDirty = yes

	save: ->
		if @isDirty
			Backbone.sync 'update', this,
				url: @url()
			isDirty = no
