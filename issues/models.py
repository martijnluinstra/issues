from issues import db
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash


issues_labels = db.Table('issues_labels',
    db.Column('issue', db.Integer, db.ForeignKey('issue.id')),
    db.Column('label', db.Integer, db.ForeignKey('label.id'))
)

notifications = db.Table('notifications',
    db.Column('issue', db.Integer, db.ForeignKey('issue.id')),
    db.Column('user', db.Integer, db.ForeignKey('user.id'))
)

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True)
    password = db.Column(db.String(40))
    email = db.Column(db.String(255))
    admin = db.Column(db.Boolean())

    def __init__(self, name, password, email, admin):
        self.name = name
        self.self.set_password(password)
        self.email = email
        self.admin = admin

    def set_password(self, password):
        self.pw_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.pw_hash, password)


class Issue(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255))
    description = db.Column(db.Text())
    owner = db.Column(db.Integer, db.ForeignKey('user.id'))
    completed = db.Column(db.Boolean())
    public = db.Column(db.Boolean())
    deadline = db.Column(db.DateTime(), nullable=True)
    comments = db.relationship('Comment', backref='issue',
                                lazy='dynamic')
    labels = db.relationship('Label', secondary=issues_labels,
        backref=db.backref('pages', lazy='dynamic'))

    def __init__(self, title, description, owner, public, deadline=None):
        self.title = title
        self.description = description
        self.owner = owner
        self.completed = False
        self.public = public
        self.deadline = deadline

class Comment(db.Model):
    issue = db.Column(db.Integer, db.ForeignKey('issue.id'), primary_key=True)
    user = db.Column(db.Integer, db.ForeignKey('user.id'), primary_key=True)
    text = db.Column(db.Text())
    time = db.Column(db.DateTime(), primary_key=True)

    def __init__(self, issue, user, text):
        self.issue = issue
        self.user = user
        self.text = text
        self.time = datetime.now()

class Label(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True)
    colour = db.Column(db.String(40))

    def __init__(self, name, colour):
        self.name = name
        self.colour = colour