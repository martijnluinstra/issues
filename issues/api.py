from flask import make_response, request
from flask.ext.login import current_user
from datetime import datetime
from issues import app, db
from models import Issue, Comment, Label
from session import api_login_required, api_admin_required, is_admin
import json, re, time

TIME_FORMAT = '%Y:%m:%d %H:%M:%S'


def jsonify(data):
    """ Create a json response from data """
    response = make_response(json.dumps(data, indent=2, ensure_ascii=False).encode('utf-8'))
    response.content_type = 'application/json'
    return response


@app.route('/api/issues', methods=['GET'])
def list_all_issues():
    """ Get a list containing all issues """  
    conditions = {}
    if not is_admin():
        conditions['public'] = True
    issues = Issue.query.filter_by(**conditions).all()
    return jsonify([issue.to_dict() for issue in issues])


@app.route('/api/issues', methods=['POST'])
@api_admin_required
def add_issue():
    """ Create an issue """
    data = request.get_json()
    if 'title' in data and 'description' in data and data['title'].strip() and data ['description'].strip():
        issue = Issue(data['title'].strip(), data['description'].strip(), current_user.id)
        db.session.add(issue)
        db.session.commit()
        return jsonify(issue.to_dict()), 201
    return 'Invalid title or description', 422


@app.route('/api/issues/<int:issue_id>', methods=['GET'])
def view_issue(issue_id):
    """ Get all details of an issue """
    time.sleep(1)
    conditions = {'id': issue_id}
    if not is_admin():
        conditions['public'] = True
    issue = Issue.query.filter_by(**conditions).first_or_404()
    return jsonify(issue.to_dict())


@app.route('/api/issues/<int:issue_id>', methods=['PUT', 'PATCH'])
@api_admin_required
def update_issue(issue_id):
    """ Update an issue """
    data = request.get_json()
    issue = Issue.query.filter_by(id=issue_id).first_or_404()
    if 'title' in data:
        if data['title'].strip():
            issue.title = data['title'].strip()
        else:
            return 'Invalid title', 422
    if 'description' in data:
        if data['description'].strip():
            issue.description = data['description'].strip()
        else:
            return 'Invalid description', 422
    if 'completed' in data:
        if data['completed']:
            issue.completed = datetime.now()
        else: 
            issue.completed = None
    if 'public' in data:
        issue.public = bool(data['public'])
    if 'deadline' in data:
        try:
            issue.deadline = datetime.strptime(data['deadline'], TIME_FORMAT)
        except ValueError:
            return 'Invalid datetime format', 422
    issue.modified = datetime.now()
    db.session.commit()
    return 'OK'


@app.route('/api/issues/todo', methods=['GET'])
def list_todo_issues():
    """ Get a list containing all uncompleted issues """
    conditions = {'completed': None}
    # Only show public issues to non-admins
    if not is_admin():
        conditions['public'] = True
    issues = Issue.query.filter_by(**conditions).all()
    return jsonify([issue.to_dict() for issue in issues])


@app.route('/api/issues/<int:issue_id>/comments', methods=['GET'])
def list_comments(issue_id):
    """ Get a list containing all comments of an issue """
    conditions = {'id': issue_id}
    if not is_admin():
        conditions['public'] = True
    issue = Issue.query.filter_by(**conditions).first_or_404()
    comments = issue.comments.all()
    return jsonify([comment.to_dict() for comment in comments])


@app.route('/api/issues/<int:issue_id>/comments', methods=['POST'])
@api_login_required
def add_comment(issue_id):
    """ Add a comment to an issue """
    data = request.get_json()
    if 'text' in data and data['text'].strip():
        comment = Comment(issue_id, current_user.id, data['text'].strip())
        db.session.add(comment)
        db.session.commit()
        return 'Comment added', 201
    return 'Invalid text', 422


@app.route('/api/issues/<int:issue_id>/labels', methods=['PUT'])
@api_admin_required
def add_label(issue_id):
    """ Update the labels of an issue """
    data = request.get_json()

    issue = Issue.query.filter_by(id=issue_id).first_or_404()

    # Clear all current labels
    issue.labels = []

    for label_data in data:
        label = None

        if not 'name' in label_data:
            return 'One of the labels is missing a label name', 500

        if not label_data['name'].strip():
            return 'One of the labels has an empty name', 500

        name = label_data["name"].strip()

        # Find the label
        label = Label.query.filter_by(name=name).first()

        # Label not found? Create a new one
        if label is None:
            if re.match('^[\w]+[\w-]*$', name) is None:
                return 'Invalid label name "' + name + '"', 422

            label = Label(name)
            db.session.add(label)

        # Add label to the issue
        issue.labels.append(label)

    # Save the changes to the issue
    db.session.add(issue)
    db.session.commit()

    return jsonify([label.to_dict() for label in issue.labels]), 201


@app.route('/api/labels', methods=['GET'])
def list_labels():
    """ List all labels """
    labels = Label.query.all()
    return jsonify([label.to_dict() for label in labels])


@app.route('/api/labels/<names>', methods=['GET'])
def list_issues_labels(names):
    """ List all issues with given labels """
    labels = names.split('+')
    issues = Issue.query.filter(Issue.labels.any(Label.name.in_(labels))).all()
    return jsonify([issue.to_dict() for issue in issues])


@app.route('/api/labels/<name>', methods=['PUT'])
@api_admin_required
def update_label(name):
    """ Update label (change colour) """
    data = request.get_json()
    label = Label.query.filter_by(name=name).first_or_404()
    if 'colour' in data and data['colour'].strip():
        label.colour = data['colour'].strip()
    db.session.commit()
    return 'OK'


@app.route('/api/labels/<name>', methods=['DELETE'])
@api_admin_required
def delete_label(name):
    """ Remove label from database """
    label = Label.query.filter_by(name=name).first_or_404()
    db.session.delete(label)
    db.session.commit()
    return 'Label deleted'