from flask import jsonify
from flask.ext.login import current_user, login_required
from issues import app, db
from models import Issue

def is_admin():
    if current_user is None or current_user.is_anonymous() or not current_user.admin:
        return False
    return True

@app.route('/api/issues/<int:issue_id>', methods = ['GET'])
def issues(issue_id):
    issue = Issue.query.filter_by(id=issue_id, public= not is_admin()).first_or_404()
    return issue

@app.route('/api/issues/all', methods = ['GET'])
def issues_all():
    issues = Issue.query.filter_by(public= not is_admin()).all()
    return issues