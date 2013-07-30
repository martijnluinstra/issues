from flask import make_response, request
from flask.ext.login import current_user, login_required
from issues import app, db
from models import Issue, Comment
import json

def is_admin():
    if current_user is None or current_user.is_anonymous() or not current_user.admin:
        return False
    return True


def jsonify(data):
    response = make_response(json.dumps(data, indent=2, ensure_ascii=False).encode('utf-8'))
    response.content_type = 'application/json'
    return response


@app.route('/api/issues/<int:issue_id>', methods=['GET'])
def view_issue(issue_id):
    issue = Issue.query.filter_by(id=issue_id, public=not is_admin()).first_or_404()
    return jsonify(issue.to_dict(compact=False))


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
@login_required
def add_comment(issue_id):
    comment = Comment(issue_id, current_user.id, request.get_json()['text'])
    db.session.add(comment)
    db.session.commit()
    return ''