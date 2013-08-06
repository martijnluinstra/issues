class Backbone.Subset extends Backbone.Collection
	constructor: (options) ->
		if not options.superset instanceof Backbone.Collection
			throw 'options.superset has to be an instance of Backbone.Collection'

		if not options.filter?
			throw 'options.filter has to be a function'

		{@superset, @filter} = options

		super [], options

		@superset.on 'add', @filterAdd, this
		@superset.on 'remove', @filterRemove, this
		@superset.on 'change', @filterChange, this

		@on 'change', @filterChange, this

	# Reading can be done from our own url (if we have one). All other sync
	# actions are deferred to the superset. Changes should trickle down through
	# the events we are listening for.
	sync: (action, model, options) ->
		if action == 'read' and @url?
			super action, model, options
		else
			@superset.sync action, @superset, options

	# When a model that is of interest to us is added to the superset, add it
	# to our own collection as well.
	filterAdd: (model) ->
		if @filter model
			Subset.__super__.add.call this, model

	# If a model is removed from the superset, remove it from our own collection.
	filterRemove: (model) ->
		Subset.__super__.remove.call this, model

	# If a model is changed in the superset, it may be that it (no longer) 
	# matches our filter. In that case, it should be added or removed from our
	# own collection.
	filterChange: (model) ->
		if @filter model
				Subset.__super__.add.call this, model
			else
				Subset.__super__.remove.call this, model

	# Add and Remove operations are applied to the superset. Changes
	# will trickle down eventually through events
	add: (models, options) ->
		@superset.add models, options

	remove: (models, options) ->
		@superset.remove models, options