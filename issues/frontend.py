from flask import render_template
from flask.ext.login import current_user
from issues import app, db
from models import Issue
from session import is_admin, is_logged_in
import json

def jsonify(data):
    return json.dumps(data, indent=2, ensure_ascii=False).encode('utf-8')

@app.route('/', methods=['GET'])
@app.route('/<path:path>', methods=['GET'])
def view_frontend(path=None):
    issues = Issue.query.filter_by(public=not is_admin()).all()
    data = [issue.to_dict() for issue in issues]

    attributes = []

    if is_logged_in():
        attributes.append('user-logged-in')
    else:
        attributes.append('user-not-logged-in')

    if is_admin():
        attributes.append('user-is-admin')
    else:
        attributes.append('user-is-not-admin')

    return render_template('index.html',
        page_attributes=' '.join(attributes),
        current_user=jsonify(current_user.to_dict() if is_logged_in() else None),
        issues=jsonify(data))
