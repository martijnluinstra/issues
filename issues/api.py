from flask import make_response, request
from flask.ext.login import current_user
from issues import app, db
from models import Issue, Comment, Label
from session import api_login_required, api_admin_required, is_admin
import json, re

TIME_FORMAT = '%Y:%m:%d %H:%M:%S'


def jsonify(data):
    """ Create a json response from data """
    response = make_response(json.dumps(data, indent=2, ensure_ascii=False).encode('utf-8'))
    response.content_type = 'application/json'
    return response


@app.route('/api/issues', methods=['POST'])
@api_admin_required
def add_issue():
    """ Create an issue """
    data = request.get_json()
    if 'title' in data and 'description' in data and data['title'].strip() and data ['description'].strip():
        issue = Issue(data['title'].strip(), data['description'].strip(), current_user.id)
        db.session.add(issue)
        db.session.commit()
        return str(issue.id), 201
    return 'Invalid title or description', 422


@app.route('/api/issues/<int:issue_id>', methods=['GET'])
def view_issue(issue_id):
    """ Get all details of an issue """
    conditions = {'id': issue_id}
    if not is_admin():
        conditions['public'] = True
    issue = Issue.query.filter_by(**conditions).first_or_404()
    return jsonify(issue.to_dict(details=True))


@app.route('/api/issues/<int:issue_id>', methods=['PUT'])
@api_admin_required
def update_issue(issue_id):
    """ Update an issue """
    data = request.get_json()
    issue = Issue.query.filter_by(id=issue_id).first_or_404()
    if 'title' in data and data['title'].strip():
        issue.title = data['title'].strip()
    else:
        return 'Invalid title', 422
    if 'description' in data and data['description'].strip():
        issue.description = data['description'].strip()
    else:
        return 'Invalid description', 422
    if 'completed' in data:
        issue.completed = data['completed']
    if 'public' in data:
        issue.public = data['public']
    if 'deadline' in data:
        issue.deadline = datetime.strptime(data['deadline'], TIME_FORMAT)
    db.session.commit()
    return 'OK'


@app.route('/api/issues/todo', methods=['GET'])
def list_todo_issues():
    """ Get a list containing all uncompleted issues """
    conditions = {'completed': False}
    # Only show public issues to non-admins
    if not is_admin():
        conditions.public = True
    issues = Issue.query.filter_by(**conditions).all()
    return jsonify([issue.to_dict() for issue in issues])


@app.route('/api/issues/all', methods=['GET'])
def list_all_issues():
    """ Get a list containing all issues """  
    conditions = {}
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


@app.route('/api/issues/<int:issue_id>/labels', methods=['POST'])
@api_admin_required
def add_label(issue_id):
    """ Add a label to an issue """
    data = request.get_json()
    label = None
    if 'name' in data and data["name"].strip():
        name = data["name"].strip()
        label = Label.query.filter_by(name=name).first()
        if label is None:
            if re.match('^[\w]+[\w-]*$', name) is None:
                return 'Invalid label name', 422
            label = Label(name)
            db.session.add(label)
        issue = Issue.query.filter_by(id=issue_id).first_or_404()
        issue.labels.append(label)
        db.session.commit()
        return 'Label added', 201
    return 'No label name', 500


@app.route('/api/issues/<int:issue_id>/labels/<name>', methods=['DELETE'])
@api_admin_required
def remove_label(issue_id, name):
    """ Remove a label from an issue """
    label = Label.query.filter_by(name=name).first_or_404()
    issue = Issue.query.filter_by(id=issue_id).first_or_404()
    issue.labels.remove(label)
    db.session.commit()
    return 'Label removed'


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