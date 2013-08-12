// Generated by CoffeeScript 1.6.3
(function() {
  var AppRouter, Comment, CommentCollection, CommentListItemView, CommentListView, DropdownLabelListItemView, DropdownLabelListView, InlineLabelListItemView, Issue, IssueCollection, IssueListItemView, IssueListView, IssueView, Label, LabelCollection, NewIssuePanel, Panel, app, bestContrastingColour, defer, hex2rgb, lumdiff, _ref, _ref1, _ref10, _ref11, _ref12, _ref13, _ref14, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  Backbone.CollectionView = (function(_super) {
    __extends(CollectionView, _super);

    CollectionView.prototype.tagName = 'ol';

    function CollectionView(options) {
      this.children = {};
      if (options.childView != null) {
        this.childView = options.childView;
      }
      if (this.childView == null) {
        console.error('childView option is missing');
      }
      CollectionView.__super__.constructor.call(this, options);
    }

    CollectionView.prototype.initialize = function() {
      this.listenTo(this.model, 'add', this.addChildView);
      return this.listenTo(this.model, 'remove', this.removeChildModel);
    };

    CollectionView.prototype.createChildView = function(model) {
      return new this.childView({
        model: model
      });
    };

    CollectionView.prototype.appendChildView = function(el) {
      return this.$el.append(el);
    };

    CollectionView.prototype.addChildView = function(childModel) {
      var view;
      view = this.createChildView(childModel);
      view.render();
      this.children[childModel.cid] = view;
      return this.appendChildView(view.el);
    };

    CollectionView.prototype.removeChildModel = function(childModel) {
      if (this.children[childModel.cid] == null) {
        return false;
      }
      this.children[childModel.cid].remove();
      return delete this.children[childModel.cid];
    };

    CollectionView.prototype.render = function() {
      var model, _i, _len, _ref, _results;
      this.clear();
      _ref = this.model.models;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        model = _ref[_i];
        if (this.children[model.cid] == null) {
          _results.push(this.addChildView(model));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    CollectionView.prototype.remove = function() {
      this.clear();
      return CollectionView.__super__.remove.call(this);
    };

    CollectionView.prototype.clear = function() {
      var child, cid, _ref;
      _ref = this.children;
      for (cid in _ref) {
        child = _ref[cid];
        child.remove();
      }
      return this.children = {};
    };

    return CollectionView;

  })(Backbone.View);

  Backbone.CollectionSubset = (function() {
    CollectionSubset.extend = Backbone.Model.extend;

    _.extend(CollectionSubset.prototype, Backbone.Events);

    function CollectionSubset(options) {
      if (options == null) {
        options = {};
      }
      options = _.defaults(options, {
        refresh: true,
        triggers: null,
        filter: function() {
          return true;
        },
        name: null,
        child: null,
        parent: null
      });
      this.triggers = options.triggers ? options.triggers.split(' ') : [];
      if (!options.child) {
        options.child = new options.parent.constructor;
      }
      this.setParent(options.parent);
      this.setChild(options.child);
      this.setFilter(options.filter);
      if (options.model) {
        this.child.model = options.model;
      }
      if (options.refresh) {
        this.refresh();
      }
      this.name = options.name;
    }

    CollectionSubset.prototype.setParent = function(collection) {
      var _ref,
        _this = this;
      if ((_ref = this.parent) != null) {
        _ref.off(null, null, this);
      }
      this.parent = collection;
      this.parent.on('add', this._onParentAdd, this);
      this.parent.on('remove', this._onParentRemove, this);
      this.parent.on('reset', this._onParentReset, this);
      this.parent.on('change', this._onParentChange, this);
      this.parent.on('dispose', this.dispose, this);
      this.parent.on('loading', (function() {
        return _this.child.trigger('loading');
      }), this);
      return this.parent.on('ready', (function() {
        return _this.child.trigger('ready');
      }), this);
    };

    CollectionSubset.prototype.setChild = function(collection) {
      var _ref;
      if ((_ref = this.child) != null) {
        _ref.off(null, null, this);
      }
      this.child = collection;
      this.child.on('add', this._onChildAdd, this);
      this.child.on('reset', this._onChildReset, this);
      this.child.on('dispose', this.dispose, this);
      this.child.superset = this.parent;
      this.child.filterer = this;
      this.child.url = this.parent.url;
      return this.child.model = this.parent.model;
    };

    CollectionSubset.prototype.setFilter = function(fn) {
      var filter;
      filter = function(model) {
        var matchesFilter, matchesParentFilter;
        matchesFilter = fn.call(this, model);
        matchesParentFilter = this.parent.filterer ? this.parent.filterer.filter(model) : true;
        return matchesFilter && matchesParentFilter;
      };
      return this.filter = _.bind(filter, this);
    };

    CollectionSubset.prototype.refresh = function(options) {
      var models;
      if (options == null) {
        options = {};
      }
      models = this.parent.filter(this.filter);
      this.child.reset(models, {
        subset: this
      });
      return this.child.trigger('refresh');
    };

    CollectionSubset.prototype._replaceChildModel = function(parentModel) {
      var childModel, index;
      childModel = this._getByCid(this.child, parentModel.cid);
      if (childModel === parentModel) {
        return;
      }
      if (_.isUndefined(childModel)) {
        return this.child.add(parentModel, {
          subset: this
        });
      } else {
        index = this.child.indexOf(childModel);
        this.child.remove(childModel);
        return this.child.add(parentModel, {
          at: index,
          subset: this
        });
      }
    };

    CollectionSubset.prototype._onParentAdd = function(model, collection, options) {
      if (options && options.subset === this) {
        return;
      }
      if (this.filter(model)) {
        return this._replaceChildModel(model);
      }
    };

    CollectionSubset.prototype._onParentRemove = function(model, collection, options) {
      return this.child.remove(model, options);
    };

    CollectionSubset.prototype._onParentReset = function(collection, options) {
      return this.refresh();
    };

    CollectionSubset.prototype._onParentChange = function(model, changes) {
      if (!this.triggerMatched(model)) {
        return;
      }
      if (this.filter(model)) {
        return this.child.add(model);
      } else {
        return this.child.remove(model);
      }
    };

    CollectionSubset.prototype._onChildAdd = function(model, collection, options) {
      var parentModel;
      if (options && options.subset === this) {
        return;
      }
      this.parent.add(model);
      parentModel = this._getByCid(this.parent, model.cid);
      if (!parentModel) {
        return;
      }
      if (this.filter(parentModel)) {
        return this._replaceChildModel(parentModel);
      } else {
        return this.child.remove(model);
      }
    };

    CollectionSubset.prototype._onChildReset = function(collection, options) {
      if (options && options.subset === this) {
        return;
      }
      this.parent.add(this.child.models);
      return this.refresh();
    };

    CollectionSubset.prototype._getByCid = function(model, cid) {
      var fn;
      fn = model.getByCid || model.get;
      return fn.apply(model, [cid]);
    };

    CollectionSubset.prototype.triggerMatched = function(model) {
      var changedAttrs;
      if (this.triggers.length === 0) {
        return true;
      }
      if (!model.hasChanged()) {
        return false;
      }
      changedAttrs = _.keys(model.changedAttributes());
      return _.intersection(this.triggers, changedAttrs).length > 0;
    };

    CollectionSubset.prototype.dispose = function() {
      var prop, _base, _i, _len, _ref;
      if (this.disposed) {
        return;
      }
      this.trigger('dispose', this);
      this.parent.off(null, null, this);
      this.child.off(null, null, this);
      if (typeof (_base = this.child).dispose === "function") {
        _base.dispose();
      }
      this.off();
      _ref = ['parent', 'child', 'options'];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        prop = _ref[_i];
        delete this[prop];
      }
      return this.disposed = true;
    };

    return CollectionSubset;

  })();

  Backbone.Collection.prototype.subcollection = function(options) {
    var subset;
    if (options == null) {
      options = {};
    }
    _.defaults(options, {
      child: new this.constructor,
      parent: this
    });
    subset = new Backbone.CollectionSubset(options);
    return subset.child;
  };

  if (typeof module !== "undefined" && module !== null) {
    module.exports = Backbone.CollectionSubset;
  }

  hex2rgb = function(hex) {
    var colour;
    if (hex.charAt(0 === '#')) {
      hex = hex.substring(1, 7);
    }
    return colour = {
      r: parseInt(hex.substring(0, 2), 16),
      g: parseInt(hex.substring(2, 4), 16),
      b: parseInt(hex.substring(4, 6), 16)
    };
  };

  lumdiff = function(c1, c2) {
    var l1, l2;
    l1 = (0.2126 * Math.pow(c1.r / 255, 2.2)) + (0.7152 * Math.pow(c1.g / 255, 2.2)) + (0.0722 * Math.pow(c1.b / 255, 2.2));
    l2 = (0.2126 * Math.pow(c2.r / 255, 2.2)) + (0.7152 * Math.pow(c2.g / 255, 2.2)) + (0.0722 * Math.pow(c2.b / 255, 2.2));
    if (l1 > l2) {
      return (l1 + 0.05) / (l2 + 0.05);
    } else {
      return (l2 + 0.05) / (l1 + 0.05);
    }
  };

  bestContrastingColour = function(hex) {
    var bc, black, wc, white;
    black = '#000000';
    white = '#ffffff';
    bc = lumdiff(hex2rgb(black), hex2rgb(hex));
    wc = lumdiff(hex2rgb(white), hex2rgb(hex));
    if (bc > wc) {
      return black;
    } else {
      return white;
    }
  };

  Issue = (function(_super) {
    __extends(Issue, _super);

    function Issue() {
      _ref = Issue.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Issue.prototype.defaults = {
      id: null,
      title: '',
      description: '',
      labels: []
    };

    Issue.prototype.urlRoot = '/api/issues';

    Issue.prototype.initialize = function() {
      var _this = this;
      this.comments = new CommentCollection([], {
        url: function() {
          return "" + (_this.url()) + "/comments";
        }
      });
      return this.labels = new LabelCollection(this.get('labels'), {
        url: function() {
          return "" + (_this.url()) + "/labels";
        }
      });
    };

    return Issue;

  })(Backbone.Model);

  IssueCollection = (function(_super) {
    __extends(IssueCollection, _super);

    function IssueCollection() {
      _ref1 = IssueCollection.__super__.constructor.apply(this, arguments);
      return _ref1;
    }

    IssueCollection.prototype.model = Issue;

    return IssueCollection;

  })(Backbone.Collection);

  Comment = (function(_super) {
    __extends(Comment, _super);

    function Comment() {
      _ref2 = Comment.__super__.constructor.apply(this, arguments);
      return _ref2;
    }

    Comment.prototype.validate = function(attr, options) {
      if ((jQuery.trim(attr.text)) === '') {
        return 'The comment has no text';
      }
    };

    return Comment;

  })(Backbone.Model);

  CommentCollection = (function(_super) {
    __extends(CommentCollection, _super);

    function CommentCollection() {
      _ref3 = CommentCollection.__super__.constructor.apply(this, arguments);
      return _ref3;
    }

    CommentCollection.prototype.model = Comment;

    return CommentCollection;

  })(Backbone.Collection);

  Label = (function(_super) {
    __extends(Label, _super);

    function Label() {
      _ref4 = Label.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    Label.prototype.defaults = {
      id: null,
      name: '',
      colour: null
    };

    Label.prototype.urlRoot = '/api/labels';

    return Label;

  })(Backbone.Model);

  LabelCollection = (function(_super) {
    __extends(LabelCollection, _super);

    function LabelCollection() {
      _ref5 = LabelCollection.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    LabelCollection.prototype.model = Label;

    LabelCollection.prototype.save = function() {
      return Backbone.sync('update', this, {
        url: this.url()
      });
    };

    return LabelCollection;

  })(Backbone.Collection);

  IssueListItemView = (function(_super) {
    __extends(IssueListItemView, _super);

    function IssueListItemView() {
      _ref6 = IssueListItemView.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    IssueListItemView.prototype.template = jQuery('#tpl-issue-list-item').detach();

    IssueListItemView.prototype.initialize = function() {
      this.setElement(this.template.clone().get(0));
      this.listenTo(this.model, 'change', this.render);
      return this.labelView = new Backbone.CollectionView({
        childView: InlineLabelListItemView,
        model: this.model.labels,
        el: this.$('.issue-labels')
      });
    };

    IssueListItemView.prototype.render = function(eventName) {
      this.$('.issue-link').attr('href', "/issues/" + (this.model.get('id')));
      this.$('.issue-title').text(this.model.get('title'));
      this.$('.issue-description').text(this.model.strip('description'));
      this.$el.toggleClass('issue-completed', !!this.model.get('completed'));
      return this.labelView.render();
    };

    IssueListItemView.prototype.isSelected = function() {
      return this.$('input[type=checkbox]').get(0).checked;
    };

    return IssueListItemView;

  })(Backbone.View);

  IssueListView = (function(_super) {
    __extends(IssueListView, _super);

    function IssueListView() {
      _ref7 = IssueListView.__super__.constructor.apply(this, arguments);
      return _ref7;
    }

    IssueListView.prototype.childView = IssueListItemView;

    IssueListView.prototype.template = jQuery('#tpl-issue-list-panel').detach();

    IssueListView.prototype.events = {
      'click .close-issues-button': function(evt) {
        var child, cid, _ref8, _results;
        evt.preventDefault();
        _ref8 = this.children;
        _results = [];
        for (cid in _ref8) {
          child = _ref8[cid];
          if (child.isSelected()) {
            _results.push(child.model.save({
              completed: true
            }, {
              patch: true
            }));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      }
    };

    IssueListView.prototype.initialize = function() {
      IssueListView.__super__.initialize.call(this);
      return this.setElement(this.template.clone().get(0));
    };

    IssueListView.prototype.appendChildView = function(el) {
      return this.$('.issue-list').append(el);
    };

    return IssueListView;

  })(Backbone.CollectionView);

  IssueView = (function(_super) {
    __extends(IssueView, _super);

    function IssueView() {
      _ref8 = IssueView.__super__.constructor.apply(this, arguments);
      return _ref8;
    }

    IssueView.prototype.template = jQuery('#tpl-issue-details-panel').detach();

    IssueView.prototype.events = {
      'submit .comments form': function(evt) {
        evt.preventDefault();
        return this.addComment();
      },
      'keypress textarea': function(evt) {
        if (evt.keyCode === 13 && evt.ctrlKey) {
          evt.preventDefault();
          return this.addComment();
        }
      },
      'click .close-issue-button': function(evt) {
        evt.preventDefault();
        return this.model.save({
          'completed': true
        }, {
          patch: true
        });
      },
      'click .reopen-issue-button': function(evt) {
        evt.preventDefault();
        return this.model.save({
          'completed': false
        }, {
          patch: true
        });
      },
      'click .edit-issue-button': function(evt) {
        evt.preventDefault();
        return this.$el.addClass('editable');
      },
      'click .finish-editing-issue-button': function(evt) {
        evt.preventDefault();
        return this.$('.edit-issue').submit();
      },
      'submit .edit-issue': function(evt) {
        evt.preventDefault();
        this.model.save(this.$('.edit-issue').serializeObject(), {
          patch: true
        });
        return this.$el.removeClass('editable');
      },
      'click .label-issue-button': function(evt) {
        return this.labelDropdownView.toggle(evt.target);
      }
    };

    IssueView.prototype.initialize = function() {
      console.assert(this.model != null, 'IssueView has no model');
      this.setElement(this.template.clone().get(0));
      this.listenTo(this.model, 'change', this.render);
      this.commentListView = new CommentListView({
        model: this.model.comments,
        el: this.$('.comment-list')
      });
      this.labelListView = new Backbone.CollectionView({
        childView: InlineLabelListItemView,
        model: this.model.labels,
        el: this.$('.issue-labels')
      });
      this.labelDropdownView = new DropdownLabelListView({
        model: app.labelCollection,
        selected: this.model.labels,
        el: this.$('.label-dropdown')
      });
      return this.model.comments.fetch();
    };

    IssueView.prototype.render = function(eventName) {
      this.$('.read-issue .issue-title').text(this.model.get('title'));
      this.$('.read-issue .issue-description').html(this.model.get('description'));
      this.$('.edit-issue .issue-title').val(this.model.get('title'));
      this.$('.edit-issue .issue-description').val(this.model.get('description'));
      this.$el.toggleClass('loading', !this.model.get('added'));
      this.$el.toggleClass('issue-completed', !!this.model.get('completed'));
      this.commentListView.render();
      this.labelListView.render();
      return this.labelDropdownView.render();
    };

    IssueView.prototype.addComment = function() {
      var data, options;
      data = {
        issue_id: this.model.get('id'),
        user: app.user,
        text: this.$('.comments form textarea[name=text]').val()
      };
      options = {
        validate: true
      };
      if (this.model.comments.create(data, options)) {
        return this.$('.comments form').get(0).reset();
      }
    };

    IssueView.prototype.remove = function() {
      this.commentListView.remove();
      return IssueView.__super__.remove.call(this);
    };

    return IssueView;

  })(Backbone.View);

  CommentListItemView = (function(_super) {
    __extends(CommentListItemView, _super);

    function CommentListItemView() {
      _ref9 = CommentListItemView.__super__.constructor.apply(this, arguments);
      return _ref9;
    }

    CommentListItemView.prototype.tagName = 'li';

    CommentListItemView.prototype.template = _.template(jQuery('#tpl-comment-list-item').text());

    CommentListItemView.prototype.initialize = function() {
      return this.listenTo(this.model, 'change', this.render);
    };

    CommentListItemView.prototype.render = function(eventName) {
      return this.$el.html(this.template(this.model.toJSON()));
    };

    return CommentListItemView;

  })(Backbone.View);

  CommentListView = (function(_super) {
    __extends(CommentListView, _super);

    function CommentListView() {
      _ref10 = CommentListView.__super__.constructor.apply(this, arguments);
      return _ref10;
    }

    CommentListView.prototype.childView = CommentListItemView;

    return CommentListView;

  })(Backbone.CollectionView);

  InlineLabelListItemView = (function(_super) {
    __extends(InlineLabelListItemView, _super);

    function InlineLabelListItemView() {
      _ref11 = InlineLabelListItemView.__super__.constructor.apply(this, arguments);
      return _ref11;
    }

    InlineLabelListItemView.prototype.tagName = 'span';

    InlineLabelListItemView.prototype.initialize = function() {
      return this.listenTo(this.model, 'change', this.render);
    };

    InlineLabelListItemView.prototype.render = function() {
      if (this.model.has('colour')) {
        this.$el.css({
          'color': bestContrastingColour(this.model.get('colour')),
          'background-color': this.model.get('colour')
        });
      }
      return this.$el.text(this.model.get('name'));
    };

    return InlineLabelListItemView;

  })(Backbone.View);

  DropdownLabelListItemView = (function(_super) {
    __extends(DropdownLabelListItemView, _super);

    function DropdownLabelListItemView() {
      _ref12 = DropdownLabelListItemView.__super__.constructor.apply(this, arguments);
      return _ref12;
    }

    DropdownLabelListItemView.prototype.template = jQuery('#tpl-dropdown-label-list-item').detach();

    DropdownLabelListItemView.prototype.events = {
      'change .label-selected': function(evt) {
        if (evt.target.checked) {
          return this.selected.add(this.model);
        } else {
          return this.selected.remove(this.model);
        }
      }
    };

    DropdownLabelListItemView.prototype.initialize = function() {
      this.setElement(this.template.clone().get(0));
      return this.listenTo(this.model, 'change', this.render);
    };

    DropdownLabelListItemView.prototype.render = function() {
      if (this.model.has('colour')) {
        this.$el.css({
          'color': bestContrastingColour(this.model.get('colour')),
          'background-color': this.model.get('colour')
        });
      }
      this.$('.label-name').text(this.model.get('name'));
      return this.$('.label-selected').attr('checked', !!this.selected.get(this.model.get('id')));
    };

    return DropdownLabelListItemView;

  })(Backbone.View);

  DropdownLabelListView = (function(_super) {
    __extends(DropdownLabelListView, _super);

    function DropdownLabelListView() {
      _ref13 = DropdownLabelListView.__super__.constructor.apply(this, arguments);
      return _ref13;
    }

    DropdownLabelListView.prototype.childView = DropdownLabelListItemView;

    DropdownLabelListView.prototype.template = jQuery('#tpl-dropdown-label-list').detach();

    DropdownLabelListView.prototype.events = {
      'keyup .label-filter': function(evt) {
        var _this = this;
        if (evt.keyCode === 27) {
          if (this.filterField.val() !== '') {
            this.filterField.val('');
          } else {
            this.hide();
          }
          evt.preventDefault();
        }
        return defer(function() {
          return _this.filter(_this.filterField.val());
        });
      },
      'click .create-new-label-button': function() {
        var label;
        label = this.model.create({
          name: this.filterField.val()
        });
        if (label) {
          return this.selected.add(label);
        }
      }
    };

    DropdownLabelListView.prototype.initialize = function(options) {
      DropdownLabelListView.__super__.initialize.call(this, options);
      this.selected = options.selected;
      this.listenTo(this.selected, 'add', this.updateChildren);
      this.listenTo(this.selected, 'remove', this.updateChildren);
      console.log(this.template.get(0));
      this.setElement(this.template.clone().get(0));
      this.filterField = this.$('.label-filter');
      this.createLabelButton = this.$('.create-new-label-button');
      this.hide();
      return jQuery(document.body).append(this.el);
    };

    DropdownLabelListView.prototype.createChildView = function(model) {
      var view;
      view = DropdownLabelListView.__super__.createChildView.call(this, model);
      view.selected = this.selected;
      return view;
    };

    DropdownLabelListView.prototype.appendChildView = function(el) {
      return this.$('.label-list').append(el);
    };

    DropdownLabelListView.prototype.updateChildren = function() {
      var child, cid, _i, _len, _ref14, _results;
      _ref14 = this.children;
      _results = [];
      for (child = _i = 0, _len = _ref14.length; _i < _len; child = ++_i) {
        cid = _ref14[child];
        _results.push(child.render());
      }
      return _results;
    };

    DropdownLabelListView.prototype.filter = function(query) {
      var child, cid, pattern, _ref14;
      pattern = new RegExp('.*' + query.split('').join('.*') + '.*', 'i');
      _ref14 = this.children;
      for (cid in _ref14) {
        child = _ref14[cid];
        if (pattern.test(child.model.get('name'))) {
          child.$el.show();
        } else {
          child.$el.hide();
        }
      }
      if (query !== '') {
        this.createLabelButton.text("Create label '" + query + "'");
        return this.createLabelButton.show();
      } else {
        return this.createLabelButton.hide();
      }
    };

    DropdownLabelListView.prototype.show = function(parent) {
      var parent_pos,
        _this = this;
      parent_pos = jQuery(parent).offset();
      this.$el.css({
        top: parent_pos.top + jQuery(parent).height() + 12,
        left: parent_pos.left + jQuery(parent).width() / 2 - this.$el.width() / 2
      });
      this.filterField.val('');
      this.filter('');
      this.$el.show();
      return defer(function() {
        return _this.filterField.focus();
      });
    };

    DropdownLabelListView.prototype.hide = function() {
      this.$el.hide();
      return this.selected.save();
    };

    DropdownLabelListView.prototype.toggle = function(parent) {
      if (this.$el.is(':visible')) {
        return this.hide();
      } else {
        return this.show(parent);
      }
    };

    return DropdownLabelListView;

  })(Backbone.CollectionView);

  app = null;

  jQuery.fn.serializeObject = function() {
    var data;
    data = {};
    jQuery(jQuery(this).serializeArray()).each(function(i, pair) {
      return data[pair.name] = pair.value;
    });
    return data;
  };

  Backbone.Model.prototype.strip = function(attribute) {
    return jQuery("<p>" + (this.get(attribute)) + "</p>").wrap('p').text();
  };

  defer = function(fn) {
    return setTimeout(fn, 1);
  };

  Panel = (function() {
    function Panel(el) {
      this.$el = jQuery(el);
    }

    Panel.prototype.render = function(view) {
      if ((this.view != null) && this.view !== view) {
        this.view.remove();
      }
      this.view = view;
      this.view.render();
      return this.view.$el.appendTo(this.$el);
    };

    Panel.prototype.show = function() {
      return this.$el.show();
    };

    Panel.prototype.hide = function() {
      return this.$el.hide();
    };

    return Panel;

  })();

  NewIssuePanel = (function(_super) {
    __extends(NewIssuePanel, _super);

    function NewIssuePanel(el, model) {
      var _this = this;
      this.model = model;
      NewIssuePanel.__super__.constructor.call(this, el);
      this.$el.on('submit', 'form', function(evt) {
        var data, issue, options;
        evt.preventDefault();
        data = jQuery(evt.target).serializeObject();
        options = {
          success: function(issue) {
            return app.navigate("/issues/" + (issue.get('id')), true);
          }
        };
        issue = new Issue;
        if (issue.save(data, options)) {
          _this.model.add(issue);
          return evt.target.reset();
        }
      });
    }

    return NewIssuePanel;

  })(Panel);

  AppRouter = (function(_super) {
    __extends(AppRouter, _super);

    function AppRouter() {
      _ref14 = AppRouter.__super__.constructor.apply(this, arguments);
      return _ref14;
    }

    AppRouter.prototype.initialize = function(config) {
      this.route('', function() {
        return this.navigate('/todo', true);
      });
      this.route(/^issues\/new$/, 'newIssue');
      this.route(/^issues\/(\d+)$/, 'showIssue');
      this.route(/^labels\/([a-zA-Z0-9-]+)$/, 'showLabel');
      this.route(/^todo$/, 'listTodoIssues');
      this.route(/^archive$/, 'listAllIssues');
      this.user = config.user;
      this.issueCollection = new IssueCollection(config.issues);
      this.issueCollection.url = '/api/issues';
      this.todoCollection = this.issueCollection.subcollection({
        filter: function(issue) {
          return !issue.get('completed');
        }
      });
      this.todoCollection.url = '/api/issues/todo';
      this.labelCollection = new LabelCollection(config.labels);
      this.panels = {
        newIssue: new NewIssuePanel('#new-issue-panel', this.issueCollection),
        showIssue: new Panel('#issue-details-panel'),
        listIssues: new Panel('#issue-list-panel')
      };
      return this.showPanel(null);
    };

    AppRouter.prototype.listTodoIssues = function() {
      var view;
      view = new IssueListView({
        model: this.todoCollection
      });
      this.todoCollection.fetch();
      return this.showPanel('listIssues', view);
    };

    AppRouter.prototype.listAllIssues = function() {
      var view;
      view = new IssueListView({
        model: this.issueCollection
      });
      this.issueCollection.fetch();
      return this.showPanel('listIssues', view);
    };

    AppRouter.prototype.newIssue = function() {
      return this.showPanel('newIssue');
    };

    AppRouter.prototype.showIssue = function(id) {
      var issue, view;
      issue = this.issueCollection.get(id);
      if (!issue) {
        issue = new Issue({
          id: id
        });
        issue.fetch();
      }
      view = new IssueView({
        model: issue
      });
      return this.showPanel('showIssue', view);
    };

    AppRouter.prototype.showPanel = function(id, view) {
      var name, panel, _ref15, _results;
      _ref15 = this.panels;
      _results = [];
      for (name in _ref15) {
        panel = _ref15[name];
        if (name === id) {
          if (view != null) {
            panel.render(view);
          }
          _results.push(panel.show());
        } else {
          _results.push(panel.hide());
        }
      }
      return _results;
    };

    return AppRouter;

  })(Backbone.Router);

  window.init = function(data) {
    app = new AppRouter({
      user: data.user,
      issues: data.issues,
      labels: data.labels
    });
    jQuery('#new-issue-panel').hide();
    jQuery('#issue-details-panel').hide();
    Backbone.history.start({
      pushState: true
    });
    jQuery(document.body).on('click', 'a', function(evt) {
      if (jQuery(this).data('external')) {
        return;
      }
      evt.preventDefault();
      return app.navigate((jQuery(this)).attr('href'), true);
    });
    return app;
  };

}).call(this);
