(function() {
  var AppRouter, Comment, CommentCollection, CommentListItemView, CommentListView, DropdownLabelListItemView, DropdownLabelListView, InlineLabelListItemView, Issue, IssueCollection, IssueListItemView, IssueListView, IssueView, Label, LabelCollection, LabelListItemView, NewIssueView, OverlayPanel, Panel, Triangle, Turtle, app, bestContrastingColour, defer, hex2rgb, loadPopup, lumdiff, templatify;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Backbone.CollectionView = (function() {
    __extends(CollectionView, Backbone.View);
    CollectionView.prototype.tagName = 'ol';
    function CollectionView(options) {
      this.children = {};
      if (options.childView != null) {
        this.childView = options.childView;
      }
      if (!(this.childView != null)) {
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
      if (!(this.children[childModel.cid] != null)) {
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
        _results.push(!(this.children[model.cid] != null) ? this.addChildView(model) : void 0);
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
  })();
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
      var _ref;
      if ((_ref = this.parent) != null) {
        _ref.off(null, null, this);
      }
      this.parent = collection;
      this.parent.on('add', this._onParentAdd, this);
      this.parent.on('remove', this._onParentRemove, this);
      this.parent.on('reset', this._onParentReset, this);
      this.parent.on('change', this._onParentChange, this);
      this.parent.on('dispose', this.dispose, this);
      this.parent.on('loading', (__bind(function() {
        return this.child.trigger('loading');
      }, this)), this);
      return this.parent.on('ready', (__bind(function() {
        return this.child.trigger('ready');
      }, this)), this);
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
  Turtle = (function() {
    function Turtle(ctx, x, y, color) {
      this.ctx = ctx;
      this.x = x;
      this.y = y;
      this.color = color;
      this.angle = 0.0;
    }
    Turtle.prototype.line = function(length, color) {
      this.ctx.beginPath();
      this.ctx.moveTo(this.x, this.y);
      this.x += Math.cos(Math.PI * 2 * -this.angle) * length;
      this.y += Math.sin(Math.PI * 2 * -this.angle) * length;
      this.ctx.lineTo(this.x, this.y);
      this.ctx.strokeStyle = color || this.color;
      this.ctx.stroke();
      return this.ctx.closePath();
    };
    Turtle.prototype.move = function(length) {
      this.x += Math.cos(Math.PI * 2 * -this.angle) * length;
      this.y += Math.sin(Math.PI * 2 * -this.angle) * length;
      return this.ctx.moveTo(this.x, this.y);
    };
    Turtle.prototype.rotate = function(angle) {
      return this.angle = (this.angle + angle) % 1.0;
    };
    return Turtle;
  })();
  Triangle = (function() {
    Triangle.prototype.playing = false;
    Triangle.prototype.requestFrame = window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame;
    function Triangle(canvas) {
      this.canvas = canvas;
      this.ctx = this.canvas.getContext('2d');
      this.animateCallback = __bind(function(t) {
        if (this.playing) {
          this.drawStep(t);
          return this.requestFrame.call(window, this.animateCallback);
        }
      }, this);
      this.resizeCallback = __bind(function() {
        this.canvas.width = this.canvas.parentNode.offsetWidth;
        return this.canvas.height = this.canvas.parentNode.offsetHeight;
      }, this);
    }
    Triangle.prototype.start = function() {
      if (this.playing) {
        return;
      }
      this.playing = true;
      this.requestFrame.call(window, this.animateCallback);
      window.addEventListener('resize', this.resizeCallback);
      return setTimeout(this.resizeCallback, 10);
    };
    Triangle.prototype.stop = function() {
      if (!this.playing) {
        return;
      }
      this.playing = false;
      return window.removeEventListener('resize', this.resizeCallback);
    };
    Triangle.prototype.smooth = function(start, end, duration, t) {
      var state;
      state = Math.cos(Math.PI * ((t % duration) / duration - .5));
      return start + (end - start) * state;
    };
    Triangle.prototype.draw = function(x, y, r, d, w, n) {
      var a, b, c, e, f, i, t, _results;
      _results = [];
      for (i = 0; 0 <= n ? i <= n : i >= n; 0 <= n ? i++ : i--) {
        t = new Turtle(this.ctx, x, y, '#ccc');
        t.rotate(r + -1 / 4 + i / n);
        t.move(d);
        a = 2 * Math.cos(.5 / n * Math.PI) * d;
        b = w / Math.cos(.5 / n * Math.PI);
        c = Math.tan(.5 / n * Math.PI) * w + a + b + Math.tan(1 / n * Math.PI) * w;
        e = Math.tan(1 / n * Math.PI) * w + c - Math.tan(.5 / n * Math.PI) * w;
        f = b;
        t.rotate(1 / 4);
        t.rotate(.5 / n);
        t.line(a + b);
        t.rotate(1 / n);
        t.line(c);
        t.rotate(1 / n);
        t.line(e);
        t.rotate(.5 / n);
        _results.push(t.line(f));
      }
      return _results;
    };
    Triangle.prototype.drawStep = function(t) {
      var d, n, r, w;
      r = this.smooth(0, 1, 120000, t);
      n = 3;
      d = this.smooth(0, 50, 10000, t);
      w = this.smooth(10, 50, 15000, t);
      this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
      return this.draw(this.canvas.width / 2, this.canvas.height / 2, r, d, w, n);
    };
    return Triangle;
  })();
  window.Triangle = Triangle;
  Issue = (function() {
    __extends(Issue, Backbone.Model);
    function Issue() {
      Issue.__super__.constructor.apply(this, arguments);
    }
    Issue.prototype.defaults = {
      id: null,
      title: '',
      description: '',
      owner: null,
      public: false,
      deadline: null,
      added: null,
      modified: null,
      completed: null,
      labels: [],
      comments: []
    };
    Issue.prototype.urlRoot = '/api/issues';
    Issue.prototype.initialize = function() {
      var label_ids, labels;
      this.comments = new CommentCollection(this.get('comments'), {
        url: __bind(function() {
          return "" + (this.url()) + "/comments";
        }, this)
      });
      label_ids = _.pluck(this.get('labels'), 'id');
      labels = window.app.labelCollection.filter(function(label) {
        return _.contains(label_ids, label.get('id'));
      });
      return this.labels = new LabelCollection(labels, {
        url: __bind(function() {
          return "" + (this.url()) + "/labels";
        }, this)
      });
    };
    return Issue;
  })();
  IssueCollection = (function() {
    __extends(IssueCollection, Backbone.Collection);
    function IssueCollection() {
      IssueCollection.__super__.constructor.apply(this, arguments);
    }
    IssueCollection.prototype.model = Issue;
    return IssueCollection;
  })();
  Comment = (function() {
    __extends(Comment, Backbone.Model);
    function Comment() {
      Comment.__super__.constructor.apply(this, arguments);
    }
    Comment.prototype.validate = function(attr, options) {
      if ((jQuery.trim(attr.text)) === '') {
        return 'The comment has no text';
      }
    };
    return Comment;
  })();
  CommentCollection = (function() {
    __extends(CommentCollection, Backbone.Collection);
    function CommentCollection() {
      CommentCollection.__super__.constructor.apply(this, arguments);
    }
    CommentCollection.prototype.model = Comment;
    return CommentCollection;
  })();
  Label = (function() {
    __extends(Label, Backbone.Model);
    function Label() {
      Label.__super__.constructor.apply(this, arguments);
    }
    Label.prototype.defaults = {
      id: null,
      name: '',
      colour: null
    };
    Label.prototype.urlRoot = '/api/labels';
    return Label;
  })();
  LabelCollection = (function() {
    __extends(LabelCollection, Backbone.Collection);
    function LabelCollection() {
      LabelCollection.__super__.constructor.apply(this, arguments);
    }
    LabelCollection.prototype.model = Label;
    LabelCollection.prototype.isDirty = false;
    LabelCollection.prototype.initialize = function() {
      this.on('add', this.markDirty, this);
      return this.on('remove', this.markDirty, this);
    };
    LabelCollection.prototype.markDirty = function() {
      return this.isDirty = true;
    };
    LabelCollection.prototype.save = function() {
      var isDirty;
      if (this.isDirty) {
        Backbone.sync('update', this, {
          url: this.url()
        });
        return isDirty = false;
      }
    };
    return LabelCollection;
  })();
  templatify = function(id) {
    var element;
    element = jQuery("#" + id);
    element.detach();
    element.removeAttr('id');
    return function() {
      return element.clone().get(0);
    };
  };
  IssueListItemView = (function() {
    __extends(IssueListItemView, Backbone.View);
    function IssueListItemView() {
      IssueListItemView.__super__.constructor.apply(this, arguments);
    }
    IssueListItemView.prototype.template = templatify('tpl-issue-list-item');
    IssueListItemView.prototype.initialize = function() {
      this.setElement(this.template());
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
      this.$el.toggleClass('issue-missed-deadline', (this.model.has('deadline')) && !(this.model.get('completed')) && moment(this.model.get('deadline')).isBefore());
      this.$el.toggleClass('issue-completed', !!this.model.get('completed'));
      return this.labelView.render();
    };
    IssueListItemView.prototype.isSelected = function() {
      return this.$('input[type=checkbox]').get(0).checked;
    };
    IssueListItemView.prototype.remove = function() {
      this.labelView.remove();
      return IssueListItemView.__super__.remove.call(this);
    };
    return IssueListItemView;
  })();
  IssueListView = (function() {
    __extends(IssueListView, Backbone.CollectionView);
    function IssueListView() {
      IssueListView.__super__.constructor.apply(this, arguments);
    }
    IssueListView.prototype.childView = IssueListItemView;
    IssueListView.prototype.template = templatify('tpl-issue-list-panel');
    IssueListView.prototype.title = function() {
      return 'Issues';
    };
    IssueListView.prototype.events = {
      'click .close-issues-button': function(evt) {
        var child, cid, _ref, _results;
        evt.preventDefault();
        _ref = this.children;
        _results = [];
        for (cid in _ref) {
          child = _ref[cid];
          _results.push(child.isSelected() ? child.model.save({
            completed: true
          }, {
            patch: true
          }) : void 0);
        }
        return _results;
      }
    };
    IssueListView.prototype.initialize = function() {
      IssueListView.__super__.initialize.call(this);
      return this.setElement(this.template());
    };
    IssueListView.prototype.appendChildView = function(el) {
      return this.$('.issue-list').append(el);
    };
    return IssueListView;
  })();
  IssueView = (function() {
    __extends(IssueView, Backbone.View);
    function IssueView() {
      IssueView.__super__.constructor.apply(this, arguments);
    }
    IssueView.prototype.template = templatify('tpl-issue-details-panel');
    IssueView.prototype.title = function() {
      return this.model.get('title');
    };
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
      'dblclick .issue-title': function(evt) {
        evt.preventDefault();
        return this.$el.addClass('editable');
      },
      'click .finish-editing-issue-button': function(evt) {
        evt.preventDefault();
        return this.$('.edit-issue').submit();
      },
      'submit .edit-issue': function(evt) {
        var data;
        evt.preventDefault();
        data = this.$('.edit-issue').serializeObject();
        data.deadline = data.deadline != null ? moment(data.deadline) : null;
        this.model.save(data, {
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
      this.setElement(this.template());
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
      this.$el.append(this.labelDropdownView.el);
      this.model.comments.fetch();
      return this.loadingAnimation = new Triangle(this.$('.loading-overlay canvas').get(0));
    };
    IssueView.prototype.render = function(eventName) {
      this.$('.read-issue .issue-title').text(this.model.get('title'));
      this.$('.read-issue .issue-description').html(this.model.get('description'));
      if (this.model.has('added')) {
        this.$('.read-issue .issue-added').text("Added " + (moment(this.model.get('added')).fromNow()) + " by " + (this.model.get('owner').name));
        this.$('.read-issue .issue-added').attr('title', moment(this.model.get('added')).calendar());
      }
      this.$('.read-issue .issue-deadline').text(this.model.has('deadline') ? "Deadline " + (moment(this.model.get('deadline')).fromNow()) : "No deadline");
      this.$('.read-issue .issue-deadline').attr('title', this.model.has('deadline') ? moment(this.model.get('deadline')).calendar() : "");
      this.$('.edit-issue .issue-title').val(this.model.get('title'));
      this.$('.edit-issue .issue-description').val(this.model.get('description'));
      this.$('.edit-issue .issue-deadline').val(this.model.has('deadline') ? moment(this.model.get('deadline')).format('YYYY-MM-DD') : void 0);
      this.$el.toggleClass('loading', !this.model.get('added'));
      this.$el.toggleClass('issue-completed', !!this.model.get('completed'));
      if (this.model.get('added')) {
        this.loadingAnimation.stop();
      } else {
        this.loadingAnimation.start();
      }
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
      this.labelListView.remove();
      this.labelDropdownView.remove();
      this.loadingAnimation.stop();
      return IssueView.__super__.remove.call(this);
    };
    return IssueView;
  })();
  NewIssueView = (function() {
    __extends(NewIssueView, Backbone.View);
    function NewIssueView() {
      NewIssueView.__super__.constructor.apply(this, arguments);
    }
    NewIssueView.prototype.template = templatify('tpl-new-issue-panel');
    NewIssueView.prototype.title = function() {
      return 'New Issue';
    };
    NewIssueView.prototype.events = {
      'submit form': function(evt) {
        var data, issue, options;
        evt.preventDefault();
        data = jQuery(evt.target).serializeObject();
        options = {
          success: function(issue) {
            return window.app.navigate("/issues/" + (issue.get('id')), true);
          }
        };
        issue = new Issue;
        if (issue.save(data, options)) {
          this.model.add(issue);
          return evt.target.reset();
        }
      }
    };
    NewIssueView.prototype.initialize = function() {
      return this.setElement(this.template());
    };
    NewIssueView.prototype.render = function() {
      return setTimeout((__bind(function() {
        return this.$('input[name=title]').get(0).focus();
      }, this)), 500);
    };
    return NewIssueView;
  })();
  CommentListItemView = (function() {
    __extends(CommentListItemView, Backbone.View);
    function CommentListItemView() {
      CommentListItemView.__super__.constructor.apply(this, arguments);
    }
    CommentListItemView.prototype.template = templatify('tpl-comment-list-item');
    CommentListItemView.prototype.initialize = function() {
      this.setElement(this.template());
      return this.listenTo(this.model, 'change', this.render);
    };
    CommentListItemView.prototype.render = function(eventName) {
      this.$('time[pubdate]').text(moment(this.model.get('time')).fromNow());
      this.$('time[pubdate]').attr('title', moment(this.model.get('time')).calendar());
      this.$('.gravatar').attr('src', (this.model.get('user')).gravatar);
      this.$('.comment-text').text(this.model.get('text'));
      return this.$('.user-name').text((this.model.get('user')).name);
    };
    return CommentListItemView;
  })();
  CommentListView = (function() {
    __extends(CommentListView, Backbone.CollectionView);
    function CommentListView() {
      CommentListView.__super__.constructor.apply(this, arguments);
    }
    CommentListView.prototype.childView = CommentListItemView;
    return CommentListView;
  })();
  InlineLabelListItemView = (function() {
    __extends(InlineLabelListItemView, Backbone.View);
    function InlineLabelListItemView() {
      InlineLabelListItemView.__super__.constructor.apply(this, arguments);
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
  })();
  LabelListItemView = (function() {
    __extends(LabelListItemView, Backbone.View);
    function LabelListItemView() {
      LabelListItemView.__super__.constructor.apply(this, arguments);
    }
    LabelListItemView.prototype.template = templatify('tpl-label-list-item');
    LabelListItemView.prototype.events = {
      'click .delete-label-button': function(evt) {
        if (confirm("Do you want to delete the label " + (this.model.get('name')) + "?")) {
          return this.model.destroy();
        }
      }
    };
    LabelListItemView.prototype.initialize = function() {
      this.setElement(this.template());
      return this.listenTo(this.model, 'change', this.render);
    };
    LabelListItemView.prototype.render = function() {
      if (this.model.has('colour')) {
        this.$('.swatch').css({
          'background-color': this.model.get('colour')
        });
      }
      this.$('.label-link').attr('href', "/labels/" + (encodeURIComponent(this.model.get('name'))));
      return this.$('.label-name').text(this.model.get('name'));
    };
    return LabelListItemView;
  })();
  DropdownLabelListItemView = (function() {
    __extends(DropdownLabelListItemView, Backbone.View);
    function DropdownLabelListItemView() {
      DropdownLabelListItemView.__super__.constructor.apply(this, arguments);
    }
    DropdownLabelListItemView.prototype.template = templatify('tpl-dropdown-label-list-item');
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
      this.setElement(this.template());
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
  })();
  DropdownLabelListView = (function() {
    __extends(DropdownLabelListView, Backbone.CollectionView);
    function DropdownLabelListView() {
      DropdownLabelListView.__super__.constructor.apply(this, arguments);
    }
    DropdownLabelListView.prototype.childView = DropdownLabelListItemView;
    DropdownLabelListView.prototype.template = templatify('tpl-dropdown-label-list');
    DropdownLabelListView.prototype.events = {
      'keyup .label-filter': function(evt) {
        if (evt.keyCode === 27) {
          if (this.filterField.val() !== '') {
            this.filterField.val('');
          } else {
            this.hide();
          }
          evt.stopPropagation();
          evt.preventDefault();
        }
        if (evt.keyCode === 13) {
          evt.preventDefault();
          this.hide();
        }
        if (evt.keyCode === 40) {
          evt.preventDefault();
          this.$('.label-list li:visible input').first().focus();
        }
        return defer(__bind(function() {
          return this.filter(this.filterField.val());
        }, this));
      },
      'click .create-new-label-button': function() {
        var label;
        label = this.model.create({
          name: this.filterField.val()
        });
        if (label) {
          return this.selected.add(label);
        }
      },
      'keydown .label-list input': function(evt) {
        if (evt.keyCode === 40) {
          evt.preventDefault();
          jQuery(evt.target).closest('li').next('.visible').find('input,button').focus();
        }
        if (evt.keyCode === 38) {
          evt.preventDefault();
          jQuery(evt.target).closest('li').prev('.visible').find('input,button').focus();
        }
        if (evt.keyCode === 27) {
          evt.preventDefault();
          return this.hide();
        }
      }
    };
    DropdownLabelListView.prototype.initialize = function(options) {
      DropdownLabelListView.__super__.initialize.call(this, options);
      this.selected = options.selected;
      this.listenTo(this.selected, 'add', this.updateChildren);
      this.listenTo(this.selected, 'remove', this.updateChildren);
      this.setElement(this.template());
      this.filterField = this.$('.label-filter');
      this.createLabelButton = this.$('.create-new-label-button');
      this.blurCallback = __bind(function(evt) {
        if (this.isVisible() && !jQuery(evt.target).isOrIsChildOf(this.el)) {
          return this.hide();
        }
      }, this);
      jQuery(document).on('click', this.blurCallback);
      return this.$el.hide();
    };
    DropdownLabelListView.prototype.remove = function() {
      jQuery(document).off('click', this.blurCallback);
      return DropdownLabelListView.__super__.remove.call(this);
    };
    DropdownLabelListView.prototype.createChildView = function(model) {
      var view;
      view = DropdownLabelListView.__super__.createChildView.call(this, model);
      view.selected = this.selected;
      return view;
    };
    DropdownLabelListView.prototype.appendChildView = function(el) {
      jQuery(el).addClass('visible');
      return this.$('.label-list').append(el);
    };
    DropdownLabelListView.prototype.updateChildren = function() {
      var child, cid, _len, _ref, _results;
      _ref = this.children;
      _results = [];
      for (child = 0, _len = _ref.length; child < _len; child++) {
        cid = _ref[child];
        _results.push(child.render());
      }
      return _results;
    };
    DropdownLabelListView.prototype.filter = function(query) {
      var child, cid, pattern, _ref;
      pattern = new RegExp('.*' + query.split('').join('.*') + '.*', 'i');
      _ref = this.children;
      for (cid in _ref) {
        child = _ref[cid];
        child.$el.toggleClass('visible', pattern.test(child.model.get('name')));
      }
      if (query !== '') {
        this.createLabelButton.text("Create label '" + query + "'");
        return this.createLabelButton.show();
      } else {
        return this.createLabelButton.hide();
      }
    };
    DropdownLabelListView.prototype.isVisible = function() {
      return this.$el.is(':visible');
    };
    DropdownLabelListView.prototype.show = function(parent) {
      var parent_pos;
      parent_pos = jQuery(parent).offsetTo(this.el.parentNode);
      this.$el.css({
        top: parent_pos.top + jQuery(parent).height() + 12,
        left: parent_pos.left + jQuery(parent).width() / 2 - this.$el.width() / 2
      });
      this.filterField.val('');
      this.filter('');
      this.$el.show();
      return defer(__bind(function() {
        return this.filterField.focus();
      }, this));
    };
    DropdownLabelListView.prototype.hide = function() {
      this.$el.hide();
      return this.selected.save();
    };
    DropdownLabelListView.prototype.toggle = function(parent) {
      if (this.isVisible()) {
        return this.hide();
      } else {
        return this.show(parent);
      }
    };
    return DropdownLabelListView;
  })();
  app = null;
  jQuery.fn.serializeObject = function() {
    var data;
    data = {};
    jQuery(jQuery(this).serializeArray()).each(function(i, pair) {
      return data[pair.name] = pair.value;
    });
    return data;
  };
  jQuery.fn.offsetTo = function(parent) {
    var el, p, position;
    el = jQuery(this);
    position = {
      top: 0,
      left: 0
    };
    while (el.length && (el.get(0)) !== parent) {
      p = el.position();
      position.top += p.top;
      position.left += p.left;
      el = el.parent();
    }
    return position;
  };
  jQuery.fn.isOrIsChildOf = function(parent) {
    var el, _results;
    el = jQuery(this);
    _results = [];
    while (true) {
      if ((el.get(0)) === parent) {
        return true;
      }
      el = el.parent();
      if (!el.length) {
        return false;
      }
    }
    return _results;
  };
  Backbone.Model.prototype.strip = function(attribute) {
    return jQuery("<p>" + (this.get(attribute)) + "</p>").wrap('p').text();
  };
  Backbone.Collection.prototype.containsWhere = function(attributes) {
    return this.findWhere(attributes === !null);
  };
  defer = function(fn) {
    return setTimeout(fn, 1);
  };
  loadPopup = function(url) {
    var catchEscapeKey, hide, overlay;
    overlay = jQuery('<div class="overlay hidden"></div>');
    catchEscapeKey = function(evt) {
      if (evt.keyCode === 27) {
        evt.preventDefault();
        evt.stopPropagation();
        return hide();
      }
    };
    hide = function() {
      overlay.addClass('hidden');
      jQuery(document).off('keyup', catchEscapeKey);
      return setTimeout((function() {
        return overlay.remove();
      }), 500);
    };
    overlay.click(function(evt) {
      if (evt.target === overlay.get(0)) {
        return hide();
      }
    });
    jQuery(document).on('keyup', catchEscapeKey);
    jQuery(document.body).append(overlay);
    return jQuery.ajax({
      url: url,
      success: function(response) {
        var closeButton, panel;
        panel = jQuery(response).filter('.panel');
        panel.addClass('popup');
        closeButton = panel.find('.panel-title').append('<button type="button" class="close" data-dismiss="popup">&times;</button>');
        closeButton.click(hide);
        panel.find('a[href]').attr('rel', 'external');
        overlay.append(panel);
        return defer(function() {
          return overlay.removeClass('hidden');
        });
      }
    });
  };
  Panel = (function() {
    function Panel(el) {
      _.extend(this, Backbone.Events);
      this.$el = jQuery(el);
    }
    Panel.prototype.render = function(view) {
      this.clear();
      this.view = view;
      this.view.render();
      this.view.$el.appendTo(this.$el);
      this.trigger('render', this.view);
      return defer(__bind(function() {
        return this.$el.addClass('visible');
      }, this));
    };
    Panel.prototype.clear = function() {
      if (this.view != null) {
        this.view.remove();
        return this.view = null;
      }
    };
    Panel.prototype.hide = function() {
      if (!this.isVisible()) {
        return;
      }
      this.trigger('hide', this.view);
      this.$el.removeClass('visible');
      return setTimeout((__bind(function() {
        return this.clear;
      }, this)), 500);
    };
    Panel.prototype.isVisible = function() {
      return this.$el.hasClass('visible');
    };
    return Panel;
  })();
  OverlayPanel = (function() {
    __extends(OverlayPanel, Panel);
    function OverlayPanel(el) {
      OverlayPanel.__super__.constructor.call(this, el);
      this.$el.on('click', __bind(function(evt) {
        if (evt.target === this.$el.get(0)) {
          return this.hide();
        }
      }, this));
      jQuery(document).on('keyup', __bind(function(evt) {
        if (evt.keyCode === 27 && this.isVisible()) {
          evt.stopPropagation();
          evt.preventDefault();
          return this.hide();
        }
      }, this));
    }
    return OverlayPanel;
  })();
  AppRouter = (function() {
    __extends(AppRouter, Backbone.Router);
    function AppRouter() {
      AppRouter.__super__.constructor.apply(this, arguments);
    }
    AppRouter.prototype.initialize = function(config) {
      var setTitle;
      window.app = this;
      this.route('', function() {
        return this.navigate('/todo', true);
      });
      this.route(/^issues\/new$/, 'newIssue');
      this.route(/^issues\/(\d+)$/, 'showIssue');
      this.route(/^labels\/([^\/]+)$/, 'listIssuesWithLabel');
      this.route(/^todo$/, 'listTodoIssues');
      this.route(/^archive$/, 'listAllIssues');
      this.user = config.user;
      this.labelCollection = new LabelCollection(config.labels);
      this.issueCollection = new IssueCollection(config.issues, {
        parse: true
      });
      this.issueCollection.url = '/api/issues';
      this.todoCollection = this.issueCollection.subcollection({
        filter: function(issue) {
          return !issue.get('completed');
        }
      });
      this.todoCollection.url = '/api/issues/todo';
      this.listPanel = new Panel('#list-panel');
      this.detailPanel = new OverlayPanel('#detail-panel');
      this.labelListView = new Backbone.CollectionView({
        childView: LabelListItemView,
        model: this.labelCollection,
        el: jQuery('#label-panel .label-list').get(0)
      });
      this.labelListView.render();
      this.listTodoIssues();
      setTitle = function(view) {
        return window.document.title = "" + (view.title()) + " – Issues";
      };
      this.listPanel.on('render', setTitle);
      this.detailPanel.on('render', setTitle);
      return this.detailPanel.on('hide', __bind(function() {
        app.navigate(this.listPanel.view.url);
        return setTitle(this.listPanel.view);
      }, this));
    };
    AppRouter.prototype.listTodoIssues = function() {
      var view;
      this.todoCollection.fetch();
      view = new IssueListView({
        model: this.todoCollection
      });
      view.url = '/todo';
      view.title = function() {
        return 'Todo';
      };
      return this.listPanel.render(view);
    };
    AppRouter.prototype.listAllIssues = function() {
      var view;
      this.issueCollection.fetch();
      view = new IssueListView({
        model: this.issueCollection
      });
      view.url = '/archive';
      view.title = function() {
        return 'Archive';
      };
      return this.listPanel.render(view);
    };
    AppRouter.prototype.listIssuesWithLabel = function(name) {
      var collection, label, view;
      label = this.labelCollection.findWhere({
        name: name
      });
      collection = this.issueCollection.subcollection({
        filter: function(issue) {
          return issue.labels.containsWhere({
            id: label.get('id')
          });
        }
      });
      collection.url = "/api/labels/" + (label.get('id'));
      collection.fetch();
      view = new IssueListView({
        model: collection
      });
      view.url = '/labels/' + encodeURIComponent(name);
      view.title = function() {
        return name;
      };
      return this.listPanel.render(view);
    };
    AppRouter.prototype.newIssue = function() {
      var view;
      view = new NewIssueView({
        model: this.issueCollection
      });
      view.url = '/issues/new';
      return this.detailPanel.render(view);
    };
    AppRouter.prototype.showIssue = function(id) {
      var issue;
      issue = this.issueCollection.get(id);
      if (!issue) {
        issue = new Issue({
          id: id
        });
        issue.fetch();
      }
      return this.detailPanel.render(new IssueView({
        model: issue
      }));
    };
    return AppRouter;
  })();
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
      if (jQuery(this).attr('rel') === 'external') {
        return;
      }
      if (jQuery(this).attr('rel') === 'popup') {
        evt.preventDefault();
        return loadPopup(jQuery(this).attr('href'));
      }
      evt.preventDefault();
      return app.navigate(jQuery(this).attr('href'), true);
    });
    return app;
  };
}).call(this);
