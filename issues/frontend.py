from flask import render_template
from flask.ext.login import current_user
from issues import app, db
from models import Issue
from session import is_admin, is_logged_in
import json

def jsonify(data):
    return json.dumps(data, indent=2, ensure_ascii=False).encode('utf-8')

def page_attributes():
    attributes = []

    if is_logged_in():
        attributes.append('user-logged-in')
    else:
        attributes.append('user-not-logged-in')

    if is_admin():
        attributes.append('user-is-admin')
    else:
        attributes.append('user-is-not-admin')

    return attributes

def uncompleted_issues():
    conditions = {'completed': None}

    # Only show public issues to non-admins
    if not is_admin():
        conditions['public'] = True

    return Issue.query.filter_by(**conditions).all()

@app.route('/', methods=['GET'])
@app.route('/<path:path>', methods=['GET'])
def view_frontend(path=None):
    return render_template('index.html',
        page_attributes=' '.join(page_attributes()),
        current_user=jsonify(current_user.to_dict() if is_logged_in() else None),
        issues=jsonify([issue.to_dict() for issue in uncompleted_issues()]))
