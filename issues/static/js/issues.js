// Generated by CoffeeScript 1.6.3
(function() {
  var AppRouter, Comment, CommentCollection, CommentListItemView, CommentListView, Issue, IssueCollection, IssueListItemView, IssueListView, IssueView, Label, LabelCollection, NewIssuePanel, Panel, app, _ref, _ref1, _ref10, _ref11, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9,
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

    CollectionView.prototype.addChildView = function(childModel) {
      var view;
      view = new this.childView({
        model: childModel
      });
      view.render();
      this.children[childModel.cid] = view;
      return this.$el.append(view.el);
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

  Issue = (function(_super) {
    __extends(Issue, _super);

    function Issue() {
      _ref = Issue.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    Issue.prototype.defaults = {
      id: null,
      title: '',
      description: ''
    };

    Issue.prototype.initialize = function() {
      this.comments = new CommentCollection([], {
        issue: this
      });
      return this.labels = new LabelCollection([], {
        issue: this
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

    IssueCollection.prototype.url = '/api/issues';

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

    CommentCollection.prototype.initialize = function(models, options) {
      this.issue = options.issue;
      return this.url = "/api/issues/" + (this.issue.get('id')) + "/comments";
    };

    return CommentCollection;

  })(Backbone.Collection);

  Label = (function(_super) {
    __extends(Label, _super);

    function Label() {
      _ref4 = Label.__super__.constructor.apply(this, arguments);
      return _ref4;
    }

    return Label;

  })(Backbone.Model);

  LabelCollection = (function(_super) {
    __extends(LabelCollection, _super);

    function LabelCollection() {
      _ref5 = LabelCollection.__super__.constructor.apply(this, arguments);
      return _ref5;
    }

    LabelCollection.prototype.model = Label;

    return LabelCollection;

  })(Backbone.Model);

  IssueListItemView = (function(_super) {
    __extends(IssueListItemView, _super);

    function IssueListItemView() {
      _ref6 = IssueListItemView.__super__.constructor.apply(this, arguments);
      return _ref6;
    }

    IssueListItemView.prototype.tagName = 'li';

    IssueListItemView.prototype.template = _.template(jQuery('#tpl-issue-list-item').text());

    IssueListItemView.prototype.initialize = function() {
      return this.$el.addClass('list-group-item');
    };

    IssueListItemView.prototype.render = function(eventName) {
      return this.$el.html(this.template({
        id: this.model.escape('id'),
        title: this.model.escape('title'),
        description: this.model.strip('description')
      }));
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

    IssueListView.prototype.initialize = function() {
      IssueListView.__super__.initialize.call(this);
      return this.$el.addClass('issue-list');
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
      'submit form': function(evt) {
        evt.preventDefault();
        return this.addComment();
      },
      'keypress textarea': function(evt) {
        if (evt.keyCode === 13 && evt.ctrlKey) {
          evt.preventDefault();
          return this.addComment();
        }
      }
    };

    IssueView.prototype.initialize = function() {
      this.setElement(this.template.clone().get(0));
      this.listenTo(this.model, 'change', this.render);
      this.commentListView = new CommentListView({
        model: this.model.comments,
        el: this.$('.comment-list')
      });
      return this.model.comments.fetch();
    };

    IssueView.prototype.render = function(eventName) {
      this.$('.issue-title').text(this.model.get('title'));
      this.$('.issue-description').html(this.model.get('description'));
      return this.commentListView.render();
    };

    IssueView.prototype.addComment = function() {
      var comment, options;
      comment = {
        issue_id: this.model.get('id'),
        user: app.user,
        text: this.$('.comments form textarea[name=text]').val()
      };
      options = {
        validate: true
      };
      if (this.model.comments.create(comment, options)) {
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
        evt.preventDefault();
        _this.createIssue(jQuery(evt.target).serializeObject());
        return evt.target.reset();
      });
    }

    NewIssuePanel.prototype.createIssue = function(data) {
      return this.model.create(data, {
        wait: true,
        success: function(model, reponse) {
          return model.set('id', response);
        }
      });
    };

    return NewIssuePanel;

  })(Panel);

  AppRouter = (function(_super) {
    __extends(AppRouter, _super);

    function AppRouter() {
      _ref11 = AppRouter.__super__.constructor.apply(this, arguments);
      return _ref11;
    }

    AppRouter.prototype.initialize = function(config) {
      this.route('', 'list');
      this.route(/^issues\/new$/, 'newIssue');
      this.route(/^issues\/(\d+)$/, 'showIssue');
      this.route(/^labels\/([a-zA-Z0-9-]+)$/, 'showLabel');
      this.user = config.user;
      this.issueCollection = new IssueCollection(config.issues);
      this.panels = {
        newIssue: new NewIssuePanel('#new-issue-panel', this.issueCollection),
        showIssue: new Panel('#issue-details-panel'),
        listIssues: new Panel('#issue-list-panel')
      };
      this.showPanel(null);
      return this.list();
    };

    AppRouter.prototype.list = function() {
      var view;
      view = new IssueListView({
        model: this.issueCollection
      });
      return this.showPanel('listIssues', view);
    };

    AppRouter.prototype.newIssue = function() {
      return this.showPanel('newIssue');
    };

    AppRouter.prototype.showIssue = function(id) {
      var issue, view;
      issue = this.issueCollection.get(id);
      view = new IssueView({
        model: issue
      });
      return this.showPanel('showIssue', view);
    };

    AppRouter.prototype.showPanel = function(id, view) {
      var name, panel, _ref12, _results;
      _ref12 = this.panels;
      _results = [];
      for (name in _ref12) {
        panel = _ref12[name];
        if (name === id) {
          panel.render(view);
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
      issues: data.issues
    });
    jQuery('#new-issue-panel').hide();
    jQuery('#issue-details-panel').hide();
    Backbone.history.start({
      pushState: true
    });
    jQuery(document.body).on('click', 'a', function(evt) {
      evt.preventDefault();
      return app.navigate((jQuery(this)).attr('href'), true);
    });
    return app;
  };

}).call(this);
