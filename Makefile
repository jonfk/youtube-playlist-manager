
.PHONY: package-elm clean deep-clean dependencies

JS_FILES = $(shell find src -type f -name '*.js')
ELM_FILES = $(shell find src -type f -name '*.elm')

package: dependencies build/main.js build/main-interop.js config/manifest.json style/style.css
	mkdir -p build/main build/popup

	cp src/main/main.html build/main/

	cp src/popup/popup-interop.js build/popup/
	cp src/popup/popup.html build/popup/

	cp style/style.css build/
	cp config/manifest.json build/
	@echo successfully packaged elm generated files and js files

build/main.js: $(ELM_FILES)
	elm-make src/Main/Main.elm --output build/main/main.js

build/main-interop.js: $(JS_FILES)
	./node_modules/.bin/webpack-cli

clean:
	rm -rf build

deep-clean: clean
	rm -rf elm-stuff
	rm -rf node_modules

# PouchDB
node_modules:
	npm install

.PHONY: tools
tools: tools/compiler-20170626.tar.gz

# closure compiler tools
tools/compiler-20170626.tar.gz:
	wget http://dl.google.com/closure-compiler/compiler-20170626.tar.gz -O tools/compiler-20170626.tar.gz
	tar xf tools/compiler-20170626.tar.gz -C tools
