class Backbone.CollectionIntersection
	@extend: Backbone.Model.extend
	_.extend @::, Backbone.Events

	parents: []

	operations: 0

	constructor: (options = {}) ->
		if not _.isArray options.parents
			throw 'No options.parent passed to the CollectionIntersection'

		@addParent parent, refresh:no for parent in options.parents
		@setChild options.child

	addParent: (collection, options) ->
		@parents.push collection
		collection.on 'add', @_onParentAdd, @
		collection.on 'remove', @_onParentRemove, @
		collection.on 'reset', @_onParentReset, @
		collection.on 'change', @_onParentChange, @
		collection.on 'dispose', @_onParentDispose, @
		collection.on 'loading', @_onParentLoading, @
		collection.on 'ready', @_onParentReady, @

		unless options and options.refresh is no
			for model in @child.models
				if not @filter model
					@child.remove model, subset:this

	removeParent: (collection, options) ->
		index = @parents.indexOf collection
		return if index is -1

		collection.off null, null, @
		@parents.splice index, 1

	setChild: (collection) ->
		@child?.off null, null, @
		@child = collection
		@child.on 'add', @_onChildAdd, @
		@child.on 'remove', @_onChildRemove, @
		@child.on 'reset', @_onChildReset, @
		@child.on 'dispose', @dispose, @
		@child.filterer = this
		# @child.model = @parents[0].model
		@refresh()

	filter: (model) ->
		for parent in @parents			
			if (parent.get model.cid) is undefined
				return no

		console.log (model.get 'name'), 'is present in all parents'
		return yes

	refresh: ->
		if @parents.length > 0
			models = (model for model in @parents[0].models when @filter model)
		else
			models = []

		@child.reset models, subset: this
		@child.trigger 'refresh'

	_replaceChildModel: (parentModel) ->
		childModel = @child.get parentModel.cid
		return if childModel is parentModel

		if not childModel?
			@child.add parentModel, subset: this
		else
			index = @child.indexOf childModel
			@child.remove childModel
			@child.add parentModel, subset: this

	_onParentAdd: (model, collection, options) ->
		return if options and options.subset is this
		if @filter model
			@_replaceChildModel model

	_onParentRemove: (model, collection, options) ->
		@child.remove model, options

	_onParentReset: (collection, options) ->
		@refresh()

	_onParentChange: (model, changes) ->
		# do nothing :)
		return

	_onParentLoading: ->
		# When this is the first loading operation, trigger it as well on the child
		if @operations++ is 0
			@child.trigger 'loading'

	_onParentReady: ->
		# If this is the last task completing, finally trigger ready on the child
		if --@operations is 0
			@child.trigger 'ready'

	_onChildAdd: (model, collection, options) ->
		return if options and options.subset is this

		for parent in @parents
			parent.add model

	_onChildRemove: (model, collection, options) ->
		console.log 'Removing', model.cid

		return if options and options.subset is this

		for parent in @parents
			console.log 'Removing', model.cid, 'from', parent, parent.get model.cid
			parent.remove parent.get model.cid

	_onChildReset: (collection, options) ->
		return if options and options.subset is this
		@parents.add @child.models
		@refresh

	dispose: ->
		return if @disposed
		@trigger 'dispose'
		
		for parent in @parents
			@removeParent parent

		@child.off null, null, @
		@child.dispose?()
		@off()

		delete this[prop] for prop in ['parents', 'child', 'options']
		@disposed = true

module?.exports = Backbone.CollectionIntersection



