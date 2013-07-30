from flask import Flask, render_template
import json

class Issue(object):
	def __init__(self, id, title):
		self.id = id
		self.title = title


class IssueEncoder(json.JSONEncoder):
	def default(self, obj):
		if isinstance(obj, Issue):
			return obj.__dict__


def jsonify(data):
	return json.dumps(data, indent=2, cls=IssueEncoder, ensure_ascii=False).encode('utf-8')

app = Flask(__name__,
	static_folder='issues/static',
	static_url_path='/static',
	template_folder='issues/templates')

dummy_issues = [
	Issue(1, 'Test Issue 1'),
	Issue(2, 'Test Issue 2'),
	Issue(3, 'Test Issue 3')
]

@app.context_processor
def utility_processor():
	return dict(jsonify=jsonify)

# API routes (all return JSON)
@app.route('/api/issues/all')
def list_all_issues():
	return jsonify(dummy_issues)

# Frontend routes (return HTML)
@app.route('/')
def show_index():
	return render_template('index.html', issues=dummy_issues)

if __name__ == '__main__':
	app.run(debug=True)