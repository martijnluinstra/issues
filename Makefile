COFFEE=coffee
COFFEE_FLAGS=

.PHONY: all run clean

all: issues/static/js/issues.js

run:
	python ./run.py

clean:
	rm -f database.db
	find . -name "*.pyc" -exec rm {} \;

issues/static/js/issues.js: \
	issues/static/coffee/CollectionView.coffee \
	issues/static/coffee/Subset.coffee \
	issues/static/coffee/models.coffee \
	issues/static/coffee/views.coffee \
	issues/static/coffee/issues.coffee
	$(COFFEE) $(COFFEE_FLAGS) --compile --join $@ $^

issues/static/test/collectionview.js: \
	issues/static/coffee/CollectionView.coffee \
	issues/static/test/collectionview.coffee
	$(COFFEE) $(COFFEE_FLAGS) --compile --join $@ $^

issues/static/test/subset.js: \
	issues/static/coffee/Subset.coffee
	$(COFFEE) $(COFFEE_FLAGS) --compile --join $@ $^

database.db: issues/models.py setup.py
	rm -f database.db
	python ./setup.py
