from flask import jsonify
from issues import app, db
from models import Issue

@app.route('/api/issues/<int:issue_id>', methods = ['GET'])
def issues(issue_id):
    issue = Issue.query.filter_by(id=issue_id).first_or_404()
    return 'hello'

@app.route('/api/issues/all', methods = ['GET'])
def issues_all():
    issues = Issue.query.all()
    return 'hello!'