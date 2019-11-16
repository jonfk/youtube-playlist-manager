
.PHONY: package-elm clean deep-clean dependencies serve

JS_FILES = $(shell find src -type f -name '*.js')
ELM_FILES = $(shell find src -type f -name '*.elm')

target/main.js: $(ELM_FILES)
	elm-make src/Main/Main.elm --output target/main.js

serve:
	python -m SimpleHTTPServer 9000

clean:
	rm -rf elm-stuff
	rm -rf target

deep-clean: clean
	rm -rf node_modules
