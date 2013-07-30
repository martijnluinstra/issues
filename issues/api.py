from flask import make_response, request
from flask.ext.login import current_user
from issues import app, db
from models import Issue, Comment, Label
from session import api_login_required, api_admin_required, is_admin
import json, re

TIME_FORMAT = '%Y:%m:%d %H:%M:%S'


def jsonify(data):
    response = make_response(json.dumps(data, indent=2, ensure_ascii=False).encode('utf-8'))
    response.content_type = 'application/json'
    return response


@app.route('/api/issues', methods=['POST'])
@api_admin_required
def add_issue():
    data = request.get_json()
    issue = Issue(data['title'], data['description'], current_user.id)
    db.session.add(issue)
    db.session.commit()
    return 'Issue added', 201


@app.route('/api/issues/<int:issue_id>', methods=['GET'])
def view_issue(issue_id):
    issue = Issue.query.filter_by(id=issue_id, public=not is_admin()).first_or_404()
    return jsonify(issue.to_dict(details=True))


@app.route('/api/issues/<int:issue_id>', methods=['PUT'])
@api_admin_required
def update_issue(issue_id):
    data = request.get_json()
    issue = Issue.query.filter_by(id=issue_id).first_or_404()
    if 'title' in data:
        issue.title = data['title']
    if 'description' in data:
        issue.description = data['description']
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
    issues = Issue.query.filter_by(completed=False, public=not is_admin()).all()
    return jsonify([issue.to_dict() for issue in issues])


@app.route('/api/issues/all', methods=['GET'])
def list_all_issues():
    issues = Issue.query.filter_by(public=not is_admin()).all()
    return jsonify([issue.to_dict() for issue in issues])


@app.route('/api/issues/<int:issue_id>/comments', methods=['GET'])
def list_comments(issue_id):
    issue = Issue.query.filter_by(id=issue_id, public=not is_admin()).first_or_404()
    comments = issue.comments.all()
    return jsonify([comment.to_dict() for comment in comments])


@app.route('/api/issues/<int:issue_id>/comments', methods=['POST'])
@api_login_required
def add_comment(issue_id):
    data = request.get_json()
    if 'text' in data:
        comment = Comment(issue_id, current_user.id, data['text'])
        db.session.add(comment)
        db.session.commit()
        return 'Comment added', 201
    return 'No text', 500


@app.route('/api/issues/<int:issue_id>/labels', methods=['POST'])
@api_admin_required
def add_label(issue_id):
    data = request.get_json()
    label = None
    if 'name' in data:
        label = Label.query.filter_by(name=data['name']).first()
        if label is None:
            if re.match('^[\w]+[\w-]*$', data['name']) is None:
                return 'Incorrect label name', 500
            label = Label(data['name'])
            db.session.add(label)
        issue = Issue.query.filter_by(id=issue_id).first_or_404()
        issue.labels.append(label)
        db.session.commit()
        return 'Label added', 201
    return 'No label name', 500


@app.route('/api/labels/<name>', methods=['PUT'])
def update_label(name):
    data = request.get_json()
    label = Label.query.filter_by(name=name).first_or_404()
    if 'colour' in data:
        label.colour = data['colour']
    db.session.commit()
    return 'OK'


@app.route('/api/labels/<names>', methods=['GET'])
def view_label(names):
    labels = names.split('+')
    issues = Issue.query.filter(Issue.labels.any(Label.name.in_(labels))).all()
    return jsonify([issue.to_dict() for issue in issues])
