from issues import db
from sqlalchemy import Table, Column, Integer, ForeignKey, String, Boolean, Text, DateTime
from sqlalchemy.orm import relationship
from werkzeug.security import generate_password_hash, check_password_hash


issues_labels_table = Table('issues_labels', db.Model.metadata,
    Column('issue', Integer, ForeignKey('issue.id')),
    Column('label', Integer, ForeignKey('label.id'))
)

notifications_table = Table('notifications', db.Model.metadata,
    Column('issue', Integer, ForeignKey('issue.id')),
    Column('user', Integer, ForeignKey('user.id'))
)

class User(db.Model):
    id = Column(Integer, primary_key=True)
    name = Column(String(80), unique=True)
    password = Column(String(40))
    email = Column(String(255))

    def __init__(self, name, password, email):
        self.name = name
        self.self.set_password(password)
        self.email = email

    def set_password(self, password):
        self.pw_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.pw_hash, password)


class Issue(db.Model):
    id = Column(Integer, primary_key=True)
    title = Column(String(255))
    description = Column(Text())
    owner = Column(Integer, ForeignKey('user.id'))
    completed = Column(Boolean())
    public = Column(Boolean())
    deadline = Column(DateTime(), nullable=True)

    def __init__(self, title, description, owner, public, deadline=None):
        self.title = title
        self.description = description
        self.owner = owner
        self.completed = False
        self.public = public
        self.deadline = deadline

class Comment(db.Model):
    issue = Column(Integer, ForeignKey('issue.id'), primary_key=True)
    user = Column(Integer, ForeignKey('user.id'), primary_key=True)
    text = Column(Text())
    time = Column(DateTime(), primary_key=True)

    def __init__(self, issue, user, text, time):
        self.issue = issue
        self.user = user
        self.text = text
        self.time = time

class Label(db.Model):
    id = Column(Integer, primary_key=True)
    name = Column(String(80), unique=True)
    colour = Column(String(40))

    def __init__(self, name, colour):
        self.name = name
        self.colour = colour

