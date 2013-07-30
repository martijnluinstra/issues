.PHONY: all

all: issues/static/js/issues.js

run:
	python ./run.py

issues/static/js/issues.js: issues/static/js/issues.coffee
	coffee --compile issues/static/js/issues.coffee

database.db: issues/models.py
	echo "from issues import db\ndb.create_all()" | python -
