class Issue extends Backbone.Model
	defaults:
		id: null
		title: ''
		description: ''
		owner: null
		public: no
		deadline: null
		accepted: yes
		added: null
		modified: null
		completed: null
		last_read: null
		labels: []
		comments: []

	urlRoot: '/api/issues'

	initialize: ->
		@comments = new CommentCollection (@get 'comments'),
			issue: this
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

	parse: (resp, options) ->
		if resp.last_read?
			resp.last_read = new Date resp.last_read

		resp.modified = new Date resp.modified

		return resp

	is_read: ->
		(@get 'last_read') isnt null and (@get 'last_read') >= (@get 'modified')

	mark_read: ->
		if app.user is null
			return

		@set 'last_read', new Date()

		jQuery.ajax "/api/issues/#{@get 'id'}/read",
			cache: no
			global: no
			type: 'PUT'
			contentType: 'application/json'
			data: JSON.stringify last_read: @get 'last_read'


class IssueCollection extends Backbone.Collection
	model: Issue


# Comments
class Comment extends Backbone.Model
	validate: (attr, options) ->
		if (jQuery.trim attr.text) == ''
			return 'The comment has no text'

	parse: (resp, options) ->
		resp.time = new Date resp.time
		return resp

	is_read: ->
		last_read = @collection.issue.get 'last_read'
		return last_read isnt null and last_read >= @get 'time'
		

class CommentCollection extends Backbone.Collection
	model: Comment

	initialize: (models, options) ->
		@issue = options.issue


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
