.PHONY: all

all: issues/static/js/issues.js

run:
	coffee --watch --bare --compile --map --output issues/static/js issues/static/js/issues.coffee &
	python ./server.py

issues/static/js/issues.js: issues/static/js/issues.coffee
	coffee --bare --compile --map --output issues/static/js issues/static/js/issues.coffee

clean:
	$(MAKE) -C $(AUDIO_SPRITES_DIR) clean