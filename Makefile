COFFEE=coffee
COFFEE_FLAGS=

.PHONY: all run

all: issues/static/js/issues.js

run:
	python ./run.py

issues/static/js/issues.js: \
	issues/static/coffee/CollectionView.coffee \
	issues/static/coffee/models.coffee \
	issues/static/coffee/views.coffee \
	issues/static/coffee/issues.coffee
	$(COFFEE) $(COFFEE_FLAGS) --compile --join $@ $^

issues/static/test/collectionview.js: \
	issues/static/coffee/CollectionView.coffee \
	issues/static/test/collectionview.coffee
	$(COFFEE) $(COFFEE_FLAGS) --compile --join $@ $^

database.db: issues/models.py
	echo "from issues import db\ndb.create_all()" | python -
