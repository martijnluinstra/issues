#!/usr/bin/env python
# -*- coding: utf-8 -*-

from flask import Flask, render_template, request
from copy import deepcopy
import json

class Issue(object):
	def __init__(self, id, title, description):
		self.id = id
		self.title = title
		self.description = description

class Comment(object):
	def __init__(self, id, text, author_name):
		self.id = id
		self.text = text
		self.user = {'name': author_name}

class IssueEncoder(json.JSONEncoder):
	def default(self, obj):
		if isinstance(obj, Issue) or isinstance(obj, Comment):
			return obj.__dict__


def jsonify(data):
	return json.dumps(data, indent=2, cls=IssueEncoder, ensure_ascii=False).encode('utf-8')

app = Flask(__name__,
	static_folder='issues/static',
	static_url_path='/static',
	template_folder='issues/templates')

dummy_issues = [
	Issue(1, 'Test Issue 1', 'This is <strong>Awesome</strong>'),
	Issue(2, 'Test Issue 2', 'This is <em>Awesome</em>'),
	Issue(3, 'Test Issue 3', 'This is <strong>Awesome</strong>')
]

dummy_comments = [
	Comment(1, 'This is a comment', 'Jelmer'),
	Comment(2, 'This is a comment', 'Martijn'),
	Comment(3, 'This is a comment', u'Mjölk')
]

@app.context_processor
def utility_processor():
	return dict(jsonify=jsonify)

# API routes (all return JSON)
@app.route('/api/issues/all')
def list_all_issues():
	return jsonify(dummy_issues)

@app.route('/api/issues/<int:issue_id>/comments')
def list_comments(issue_id):
	specific_comments = deepcopy(dummy_comments)

	for comment in specific_comments:
		comment.text = 'This is a comment for issue %d' % issue_id

	return jsonify(specific_comments)

# Frontend routes (return HTML)
@app.route('/')
@app.route('/<path:page>')
def show_index(page=None):
	return render_template('index.html', issues=dummy_issues)

if __name__ == '__main__':
	app.run(debug=True)