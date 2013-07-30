from flask import render_template
from flask.ext.login import current_user
from issues import app, db
from models import Issue
from session import is_admin
import json

def jsonify(data):
    return json.dumps(data, indent=2, ensure_ascii=False).encode('utf-8')

@app.route('/', methods=['GET'])
@app.route('/<path:path>', methods=['GET'])
def view_frontend(path=None):
    issues = Issue.query.filter_by(public=not is_admin()).all()
    data = [issue.to_dict() for issue in issues]
    return render_template('index.html', issues=jsonify(data))
