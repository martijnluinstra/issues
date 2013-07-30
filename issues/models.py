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
    name = db.Column(db.String(80))
    password = db.Column(db.String(40))
    email = db.Column(db.String(255), unique=True)
    admin = db.Column(db.Boolean())

    def __init__(self, name, password, email, admin=False):
        self.name = name
        self.set_password(password)
        self.email = email
        self.admin = admin

    def is_authenticated(self):
        return True

    def is_active(self):
        return True

    def is_anonymous(self):
        return False

    def get_id(self):
        return self.id

    def set_password(self, password):
        self.password = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password, password)

    def to_dict(self):
        return {
            'name': self.name,
            'email': self.email
        }


class Issue(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(255))
    description = db.Column(db.Text())
    owner_id = db.Column(db.Integer, db.ForeignKey('user.id'))
    completed = db.Column(db.Boolean())
    public = db.Column(db.Boolean())
    deadline = db.Column(db.DateTime(), nullable=True)
    comments = db.relationship('Comment', backref='issue',
                                lazy='dynamic')
    labels = db.relationship('Label', secondary=issues_labels,
        backref=db.backref('issues', lazy='dynamic'))

    def __init__(self, title, description, owner_id, public=False, deadline=None):
        self.title = title
        self.description = description
        self.owner_id = owner_id
        self.completed = False
        self.public = public
        self.deadline = deadline

    def to_dict(self, compact=True):
        owner = User.query.filter_by(id=self.owner_id).first()
        if compact:
            return {
                'id': self.id,
                'title': self.title,
                'description': self.description,
                'completed': self.completed,
                'deadline': self.deadline,
                'labels': list([label.to_dict() for label in self.labels])
            }
        comments = self.comments.all()
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'owner': owner.to_dict(),
            'completed': self.completed,
            'deadline': self.deadline,
            'public': self. public,
            'labels': [label.to_dict() for label in self.labels],
            'deadline': self.deadline.isoformat() if self.deadline is not None else None,
            'comments': list([comment.to_dict() for comment in comments])
        }

class Comment(db.Model):
    issue_id = db.Column(db.Integer, db.ForeignKey('issue.id'), primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), primary_key=True)
    text = db.Column(db.Text())
    time = db.Column(db.DateTime(), primary_key=True)

    def __init__(self, issue_id, user_id, text):
        self.issue_id = issue_id
        self.user_id = user_id
        self.text = text
        self.time = datetime.now()

    def to_dict(self):
        return {
            'issue': self.issue_id,
            'user': self.user_id,
            'text': self.text,
            'time': self.time.isoformat()
        }

class Label(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True)
    colour = db.Column(db.String(40), nullable=True)

    def __init__(self, name, colour=None):
        self.name = name
        self.colour = colour

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'colour': self.colour
        }